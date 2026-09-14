import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: rail
    width: 72
    color: theme.bgRail

    property string activeView: "room" // "dm" or "room"
    property string activeRoomId: ""
    property var roomsModel: []

    signal dmSelected()
    signal roomSelected(string roomId, string roomName, int nMod, int mMod, bool mature)
    signal addRoomClicked()
    signal identitySettingsClicked()

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 8

        // Direct Messages / Home Button 
        Item {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 48

            // Left Active/Hover Pill Indicator
            Rectangle {
                id: dmPill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                radius: 2
                color: "#ffffff"
                height: rail.activeView === "dm" ? 40 : (dmMouse.containsMouse ? 20 : 0)
                visible: height > 0
                Behavior on height { NumberAnimation { duration: theme.animFast } }
            }

            // Squircle Button
            Rectangle {
                id: dmIconBox
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: (rail.activeView === "dm" || dmMouse.containsMouse) ? theme.radiusSquircle : theme.radiusCircle
                color: rail.activeView === "dm" ? theme.accentBlurple : (dmMouse.containsMouse ? theme.accentBlurpleHover : theme.bgChat)
                Behavior on radius { NumberAnimation { duration: theme.animFast } }
                Behavior on color { ColorAnimation { duration: theme.animFast } }

                Image {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    source: "../assets/EviceLogo-white.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: dmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rail.dmSelected()
                }

                ToolTip.visible: dmMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "Direct Messages (Anon DMs)"
            }
        }

        // --- Divider Pill ---
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 32
            height: 2
            radius: 1
            color: theme.divider
        }

        // --- Scrollable Room List ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    model: rail.roomsModel

                    Item {
                        id: roomDelegate
                        width: 72
                        height: 48

                        property bool isSelected: rail.activeView === "room" && rail.activeRoomId === modelData.id
                        property bool isHovered: roomMouse.containsMouse

                        // Left Active/Hover Pill Indicator
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            radius: 2
                            color: "#ffffff"
                            height: roomDelegate.isSelected ? 40 : (roomDelegate.isHovered ? 20 : (modelData.unread ? 8 : 0))
                            visible: height > 0
                            Behavior on height { NumberAnimation { duration: theme.animFast } }
                        }

                        // Squircle Button
                        Rectangle {
                            id: roomIconBox
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            radius: (roomDelegate.isSelected || roomDelegate.isHovered) ? theme.radiusSquircle : theme.radiusCircle
                            color: roomDelegate.isSelected ? theme.accentBlurple : (roomDelegate.isHovered ? theme.accentBlurpleHover : theme.bgChat)
                            Behavior on radius { NumberAnimation { duration: theme.animFast } }
                            Behavior on color { ColorAnimation { duration: theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.iconText || modelData.name.substring(0, 2).toUpperCase()
                                font.bold: true
                                font.pixelSize: 15
                                color: (roomDelegate.isSelected || roomDelegate.isHovered) ? "#ffffff" : theme.textInteractive
                            }

                            // SSS Shield mini badge
                            Rectangle {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: -2
                                width: 14
                                height: 14
                                radius: 7
                                color: modelData.mature ? theme.accentLogos : theme.accentWarning
                                border.color: theme.bgRail
                                border.width: 2
                                visible: true
                            }

                            MouseArea {
                                id: roomMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rail.roomSelected(modelData.id, modelData.name, modelData.nMod, modelData.mMod, modelData.mature)
                            }

                            ToolTip.visible: roomMouse.containsMouse
                            ToolTip.delay: 200
                            ToolTip.text: modelData.name + (modelData.mature ? " • (Mature N=" + modelData.nMod + "/M=" + modelData.mMod + ")" : " • (New Room)")
                        }
                    }
                }

                // --- Add Room Button (+) ---
                Item {
                    width: 72
                    height: 48

                    Rectangle {
                        id: addBtnBox
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        radius: addMouse.containsMouse ? theme.radiusSquircle : theme.radiusCircle
                        color: addMouse.containsMouse ? theme.accentSuccess : theme.bgChat
                        Behavior on radius { NumberAnimation { duration: theme.animFast } }
                        Behavior on color { ColorAnimation { duration: theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 24
                            color: addMouse.containsMouse ? "#ffffff" : theme.accentSuccess
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rail.addRoomClicked()
                        }

                        ToolTip.visible: addMouse.containsMouse
                        ToolTip.delay: 200
                        ToolTip.text: "Create or Join Room"
                    }
                }
            }
        }
    }
}
