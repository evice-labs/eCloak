import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: chatArea
    color: theme.bgChat

    property string activeView: "room" // "room" or "dm"
    property string activeTargetName: ""
    property string activeTopic: ""
    property var messagesModel: []
    property bool isDrawerOpen: true

    signal sendMessage(string text, var attachment)
    signal flagMessage(string author, string commitment, string tag, string text)
    signal inspectMessage(string tag, var point)
    signal reactMessage(int messageIndex, string emoji)
    signal toggleDrawer()
    signal inputFocusGained()
    signal clearOtherFocusRequested()

    function clearInputFocus() {
        if (composerComp) composerComp.clearInputFocus();
    }

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // TOP HEADER BAR (48px)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: theme.bgChat

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    chatArea.clearInputFocus();
                    chatArea.clearOtherFocusRequested();
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: theme.borderSubtle
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // Channel Room Icon (#)
                Text {
                    visible: chatArea.activeView !== "dm" && chatArea.activeTargetName !== ""
                    text: "#"
                    font.bold: true
                    font.pixelSize: 18
                    color: theme.textMuted
                }

                // DM User Avatar Profile Icon
                Rectangle {
                    visible: chatArea.activeView === "dm" && chatArea.activeTargetName !== ""
                    Layout.alignment: Qt.AlignVCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: chatArea.activeTargetName ? chatArea.activeTargetName.substring(0, 1).toUpperCase() : "U"
                        font.family: theme.fontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: "#ffffff"
                    }
                }

                Text {
                    text: !chatArea.activeTargetName ? (chatArea.activeView === "dm" ? "Direct Messages" : "Evice AnonChat") : chatArea.activeTargetName
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 15
                    color: theme.textHeader
                }

                Rectangle {
                    visible: chatArea.activeView !== "dm" && (chatArea.activeTopic !== "" || !chatArea.activeTargetName)
                    width: 1
                    height: 16
                    color: theme.borderSubtle
                }

                Text {
                    visible: chatArea.activeView !== "dm"
                    Layout.fillWidth: true
                    text: !chatArea.activeTargetName ?
                        "Create or join a room to begin anonymous group chatting" :
                        chatArea.activeTopic
                    font.pixelSize: 12
                    color: theme.textMuted
                    elide: Text.ElideRight
                }

                Item {
                    visible: chatArea.activeView === "dm"
                    Layout.fillWidth: true
                }

                // Member Drawer Toggle Button (Visible only in room mode with active room)
                Rectangle {
                    visible: chatArea.activeView !== "dm" && chatArea.activeTargetName !== ""
                    width: 32
                    height: 32
                    radius: theme.radiusSmall
                    color: drawerMouse.containsMouse ? theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "👥"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: drawerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chatArea.toggleDrawer()
                    }

                    ToolTip {
                        id: drawerTip
                        visible: drawerMouse.containsMouse
                        delay: 200
                        text: chatArea.isDrawerOpen ? "Hide Member List & Slashing Radar" : "Show Member List & Slashing Radar"
                        topPadding: 6
                        bottomPadding: 6
                        leftPadding: 10
                        rightPadding: 10
                        contentItem: Text {
                            text: drawerTip.text
                            font.family: theme.fontFamily
                            font.pixelSize: 12
                            color: theme.textHeader
                        }
                        background: Rectangle {
                            color: theme.bgCard
                            border.color: theme.borderSubtle
                            border.width: 1
                            radius: 6
                        }
                    }
                }
            }
        }

        // MESSAGE FEED AREA
        MessageFeed {
            Layout.fillWidth: true
            Layout.fillHeight: true
            messagesModel: chatArea.messagesModel
            channelName: chatArea.activeTargetName
            activeView: chatArea.activeView

            onFlagRequested: function(author, comm, tag, text) {
                chatArea.flagMessage(author, comm, tag, text)
            }

            onInspectRequested: function(tag, point) {
                chatArea.inspectMessage(tag, point)
            }

            onReactRequested: function(idx, emoji) {
                chatArea.reactMessage(idx, emoji)
            }

            onFeedClicked: {
                chatArea.clearInputFocus();
                chatArea.clearOtherFocusRequested();
            }
        }

        // BOTTOM MESSAGE COMPOSER
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: composerComp.height + 12

            // Placeholder Banner when no target is selected
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 12
                radius: theme.radiusMedium
                color: theme.bgCard
                border.color: theme.borderSubtle
                border.width: 1
                visible: !chatArea.activeTargetName || chatArea.activeTargetName === ""

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        chatArea.clearInputFocus();
                        chatArea.clearOtherFocusRequested();
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: chatArea.activeView === "dm" ? "🔒" : "🛡️"
                        font.pixelSize: 14
                    }

                    Text {
                        text: chatArea.activeView === "dm" ?
                            "Select an anonymous conversation from the sidebar or click 'Find or start a DM...' to chat." :
                            "Create or join a room from the left server rail (+) to start messaging."
                        font.pixelSize: 12
                        color: theme.textMuted
                    }
                }
            }

            ChatComposer {
                id: composerComp
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 12
                visible: chatArea.activeTargetName !== ""

                placeholderTarget: chatArea.activeTargetName ? ((chatArea.activeView === "dm" ? "@" : "#") + chatArea.activeTargetName) : ""
                isDmMode: chatArea.activeView === "dm"

                onInputFocusGained: chatArea.inputFocusGained()
                onClearOtherFocusRequested: chatArea.clearOtherFocusRequested()

                onSendRequested: function(msg, attach) {
                    chatArea.sendMessage(msg, attach)
                }
            }
        }
    }
}
