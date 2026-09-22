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
    signal createRoomClicked()
    signal joinRoomClicked()
    signal identitySettingsClicked()
    signal clearInputsRequested()

    MouseArea {
        anchors.fill: parent
        onClicked: rail.clearInputsRequested()
    }

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
                color: rail.activeView === "dm" ? theme.primary : (dmMouse.containsMouse ? theme.primaryHover : theme.bgCard)
                Behavior on radius { NumberAnimation { duration: theme.animFast } }
                Behavior on color { ColorAnimation { duration: theme.animFast } }

                Image {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    source: "../assets/eCloakLogoCircle.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: dmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        rail.clearInputsRequested();
                        rail.dmSelected();
                    }
                }

                ToolTip {
                    id: dmTip
                    visible: dmMouse.containsMouse
                    delay: 200
                    text: "Direct Messages (Anon DMs)"
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 10
                    rightPadding: 10
                    contentItem: Text {
                        text: dmTip.text
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

        // Divider Pill
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 32
            height: 2
            radius: 1
            color: theme.divider
        }

        // Scrollable Room List
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
                            color: roomDelegate.isSelected ? theme.primary : (roomDelegate.isHovered ? theme.primaryHover : theme.bgCard)
                            Behavior on radius { NumberAnimation { duration: theme.animFast } }
                            Behavior on color { ColorAnimation { duration: theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.iconText || modelData.name.substring(0, 2).toUpperCase()
                                font.bold: true
                                font.pixelSize: 15
                                color: (roomDelegate.isSelected || roomDelegate.isHovered) ? "#ffffff" : theme.textInteractive
                            }

                            MouseArea {
                                id: roomMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    rail.clearInputsRequested();
                                    rail.roomSelected(modelData.id, modelData.name, modelData.nMod, modelData.mMod, modelData.mature);
                                }
                            }

                            ToolTip {
                                id: roomTip
                                visible: roomMouse.containsMouse
                                delay: 200
                                text: modelData.name
                                topPadding: 6
                                bottomPadding: 6
                                leftPadding: 10
                                rightPadding: 10
                                contentItem: Text {
                                    text: roomTip.text
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

                // Add Room Button (+)
                Item {
                    width: 72
                    height: 48

                    Rectangle {
                        id: addBtnBox
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        radius: (addMouse.containsMouse || addRoomMenu.visible) ? theme.radiusSquircle : theme.radiusCircle
                        color: (addMouse.containsMouse || addRoomMenu.visible) ? theme.primary : theme.bgCard
                        Behavior on radius { NumberAnimation { duration: theme.animFast } }
                        Behavior on color { ColorAnimation { duration: theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 24
                            color: (addMouse.containsMouse || addRoomMenu.visible) ? "#ffffff" : theme.primary
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rail.clearInputsRequested();
                                addRoomMenu.open();
                            }
                        }

                        Menu {
                            id: addRoomMenu
                            x: addBtnBox.width + 8
                            y: 0
                            topPadding: 4
                            bottomPadding: 4
                            leftPadding: 4
                            rightPadding: 4

                            background: Rectangle {
                                implicitWidth: 180
                                color: theme.bgCard
                                border.color: theme.borderSubtle
                                border.width: 1
                                radius: 8
                            }

                            MenuItem {
                                id: itemCreateRoom
                                text: "➕ Create a Room"
                                contentItem: Text {
                                    text: itemCreateRoom.text
                                    font.family: theme.fontFamily
                                    font.pixelSize: 13
                                    color: itemCreateRoom.highlighted ? "#ffffff" : theme.textHeader
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                    rightPadding: 8
                                }
                                background: Rectangle {
                                    implicitWidth: 172
                                    implicitHeight: 34
                                    color: itemCreateRoom.highlighted ? theme.bgHover : "transparent"
                                    radius: 6
                                }
                                onTriggered: {
                                    rail.createRoomClicked();
                                    rail.addRoomClicked();
                                }
                            }

                            MenuItem {
                                id: itemJoinRoom
                                text: "🔗 Join with Room ID"
                                contentItem: Text {
                                    text: itemJoinRoom.text
                                    font.family: theme.fontFamily
                                    font.pixelSize: 13
                                    color: itemJoinRoom.highlighted ? "#ffffff" : theme.textHeader
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                    rightPadding: 8
                                }
                                background: Rectangle {
                                    implicitWidth: 172
                                    implicitHeight: 34
                                    color: itemJoinRoom.highlighted ? theme.bgHover : "transparent"
                                    radius: 6
                                }
                                onTriggered: rail.joinRoomClicked()
                            }
                        }

                        ToolTip {
                            id: addTip
                            visible: addMouse.containsMouse && !addRoomMenu.visible
                            delay: 200
                            text: "Create or Join Room"
                            topPadding: 6
                            bottomPadding: 6
                            leftPadding: 10
                            rightPadding: 10
                            contentItem: Text {
                                text: addTip.text
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
        }
    }
}
