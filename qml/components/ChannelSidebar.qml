import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar
    width: 240
    color: theme.bgSidebar

    property string activeView: "room" // "room" or "dm"
    property string activeRoomName: "General Room"
    property string activeRoomId: ""
    property bool isRoomMature: true
    property string activeChannel: "general-chat"
    property string activeDmUser: ""
    property var dmsModel: []

    signal channelSelected(string channelName)
    signal dmSelected(string targetUsername)
    signal copyRoomIdRequested(string roomId)
    signal leaveRoomRequested(string roomId)

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // TOP HEADER BAR (48px)
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: theme.borderSubtle
            }

            // Room Header Mode
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: sidebar.activeView === "room"

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Text {
                        text: sidebar.activeRoomId ? sidebar.activeRoomName : "No Room Selected"
                        font.bold: true
                        font.pixelSize: 15
                        color: theme.textHeader
                        elide: Text.ElideRight
                        Layout.maximumWidth: 140
                    }

                    Rectangle {
                        visible: sidebar.activeRoomId !== ""
                        height: 16
                        width: matureLabel.implicitWidth + 8
                        radius: 3
                        color: sidebar.isRoomMature ? "#1c382f" : "#3d311b"
                        border.color: sidebar.isRoomMature ? theme.accentLogos : theme.accentWarning
                        border.width: 1

                        Text {
                            id: matureLabel
                            anchors.centerIn: parent
                            text: sidebar.isRoomMature ? "Mature" : "New"
                            font.pixelSize: 9
                            font.bold: true
                            color: sidebar.isRoomMature ? theme.accentLogos : theme.accentWarning
                        }
                    }
                }

                // Room Options Button (Chevron)
                Text {
                    visible: sidebar.activeRoomId !== ""
                    text: "▼"
                    font.pixelSize: 10
                    color: optMouse.containsMouse ? theme.textHeader : theme.textMuted

                    MouseArea {
                        id: optMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: roomMenu.open()
                    }

                    Menu {
                        id: roomMenu
                        y: parent.height

                        MenuItem {
                            text: "Copy Room ID"
                            onTriggered: sidebar.copyRoomIdRequested(sidebar.activeRoomId)
                        }
                        MenuItem {
                            text: "Leave Room"
                            onTriggered: sidebar.leaveRoomRequested(sidebar.activeRoomId)
                        }
                    }
                }
            }

            // DM Header Mode (Search Button)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: theme.radiusSmall
                color: theme.bgRail
                visible: sidebar.activeView === "dm"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "🔍"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "Find or start a DM..."
                        font.pixelSize: 12
                        color: theme.textMuted
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: searchDmDialog.open()
                }
            }
        }

        // MIDDLE CHANNELS / DMS LIST
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: sidebar.width
                spacing: 2

                // --- ROOM MODE CHANNELS ---
                ColumnLayout {
                    width: sidebar.width
                    visible: sidebar.activeView === "room"
                    spacing: 2

                    // Empty State when no room is selected
                    Item {
                        width: sidebar.width - 16
                        height: 90
                        Layout.alignment: Qt.AlignHCenter
                        visible: !sidebar.activeRoomId || sidebar.activeRoomId === ""

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "No Room Selected"
                                font.bold: true
                                font.pixelSize: 12
                                color: theme.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Click '+' on the server rail\nto create or join a room."
                                font.pixelSize: 11
                                color: theme.textMuted
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Category Title (Only when room is active)
                    Item {
                        width: sidebar.width
                        height: 32
                        visible: sidebar.activeRoomId !== ""

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "TEXT CHANNELS"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    // Default Channels
                    Repeater {
                        model: (sidebar.activeRoomId !== "") ? [
                            { name: "general-chat", icon: "#", desc: "Public room discussion" },
                            { name: "announcements", icon: "#", desc: "Official announcements" },
                            { name: "strike-appeals", icon: "🔒", desc: "Moderator private channel" }
                        ] : []

                        Rectangle {
                            id: chanItem
                            width: sidebar.width - 16
                            height: 34
                            Layout.preferredWidth: sidebar.width - 16
                            Layout.preferredHeight: 34
                            Layout.alignment: Qt.AlignHCenter
                            radius: theme.radiusSmall

                            property bool isSelected: sidebar.activeChannel === modelData.name
                            color: isSelected ? theme.bgActive : (chanMouse.containsMouse ? theme.bgHover : "transparent")

                            // Channel Icon Box (Guaranteed fixed geometry)
                            Item {
                                id: chanIconBox
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.bold: true
                                    font.pixelSize: 15
                                    color: chanItem.isSelected ? theme.textHeader : theme.textMuted
                                }
                            }

                            // Channel Name Text (Anchored with clear space between icon and dot)
                            Text {
                                id: chanNameText
                                anchors.left: chanIconBox.right
                                anchors.leftMargin: 4
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.bold: chanItem.isSelected
                                font.pixelSize: 13
                                color: chanItem.isSelected ? theme.textInteractiveActive : theme.textInteractive
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: chanMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sidebar.activeChannel = modelData.name
                                    sidebar.channelSelected(modelData.name)
                                }
                            }
                        }
                    }
                }

                // --- DM MODE DIRECT MESSAGES ---
                ColumnLayout {
                    width: sidebar.width
                    visible: sidebar.activeView === "dm"
                    spacing: 2

                    Item {
                        width: sidebar.width
                        height: 32

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "DIRECT MESSAGES"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    Repeater {
                        model: sidebar.dmsModel

                        Rectangle {
                            id: dmItem
                            width: sidebar.width - 16
                            height: 40
                            Layout.preferredWidth: sidebar.width - 16
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            radius: theme.radiusSmall

                            property bool isSelected: sidebar.activeDmUser === modelData.username
                            color: isSelected ? theme.bgActive : (dmUserMouse.containsMouse ? theme.bgHover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                // Avatar
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: theme.accentBlurple

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.username.substring(0, 1).toUpperCase()
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                    }

                                    // Online status dot
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: modelData.online ? theme.accentSuccess : theme.textMuted
                                        border.color: theme.bgSidebar
                                        border.width: 1.5
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.username
                                        font.bold: dmItem.isSelected
                                        font.pixelSize: 13
                                        color: dmItem.isSelected ? theme.textInteractiveActive : theme.textInteractive
                                    }

                                    Text {
                                        text: "Epoch HKDF active"
                                        font.pixelSize: 10
                                        color: theme.textMuted
                                    }
                                }
                            }

                            MouseArea {
                                id: dmUserMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sidebar.activeDmUser = modelData.username
                                    sidebar.dmSelected(modelData.username)
                                }
                            }
                        }
                    }

                    // Empty state when no DMs
                    Item {
                        width: sidebar.width - 16
                        height: 60
                        visible: !sidebar.dmsModel || sidebar.dmsModel.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "No conversations yet.\nClick above to start a DM."
                            font.pixelSize: 11
                            color: theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: searchDmDialog
        title: "Start Anonymous 1-on-1 DM"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 8
            Label { text: "Enter recipient's username:"; color: theme.textHeader }
            TextField {
                id: targetUserInput
                placeholderText: "e.g. Satoshi99"
                color: theme.textHeader
                background: Rectangle { color: theme.bgInput; radius: 4 }
            }
            Label {
                text: "🔒 Keys negotiated via ECDH, relay topic rotating per epoch."
                font.pixelSize: 10
                color: theme.accentLogos
            }
        }

        onAccepted: {
            if (targetUserInput.text.trim()) {
                sidebar.dmSelected(targetUserInput.text.trim())
            }
        }
    }
}
