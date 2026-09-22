import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: drawer
    width: isOpen ? 240 : 0
    Layout.preferredWidth: width
    visible: width > 0
    clip: true
    color: theme.bgSidebar

    property bool isOpen: true
    property var moderatorsList: []
    property var membersList: []

    property string radarTargetUser: ""
    property string radarTargetCommitment: ""
    property int radarStrikes: 0
    property int radarStrikesRequired: 3

    signal executeSlashingRequested(string targetComm)
    signal issueStrikeRequested()
    signal memberStrikeRequested(string username, string pubkey)
    signal clearInputsRequested()

    Behavior on width {
        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
    }

    Theme { id: theme }

    MouseArea {
        anchors.fill: parent
        onClicked: drawer.clearInputsRequested()
    }

    // Left Border Divider
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: theme.borderSubtle
        z: 2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // SECTION: MODERATORS
        Text {
            text: "MODERATORS — " + (drawer.moderatorsList ? drawer.moderatorsList.length : 0)
            font.bold: true
            font.pixelSize: 11
            color: theme.textMuted
        }

        Text {
            visible: !drawer.moderatorsList || drawer.moderatorsList.length === 0
            text: "No registered moderators"
            font.pixelSize: 11
            color: theme.textMuted
            font.italic: true
        }

        Repeater {
            model: drawer.moderatorsList

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: theme.radiusSmall
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 8

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: theme.primary

                        Text {
                            anchors.centerIn: parent
                            text: modelData.username ? modelData.username.substring(0, 1).toUpperCase() : "M"
                            font.bold: true
                            font.pixelSize: 11
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: modelData.username
                            font.bold: true
                            font.pixelSize: 12
                            color: theme.textHeader
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.pubkey || ""
                            font.pixelSize: 9
                            color: theme.textMuted
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }
            }
        }

        // SECTION: MEMBERS
        Text {
            Layout.topMargin: 8
            text: "MEMBERS — " + (drawer.membersList ? drawer.membersList.length : 0)
            font.bold: true
            font.pixelSize: 11
            color: theme.textMuted
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 2

                Text {
                    visible: !drawer.membersList || drawer.membersList.length === 0
                    text: "No other members"
                    font.pixelSize: 11
                    color: theme.textMuted
                    font.italic: true
                }

                Repeater {
                    model: drawer.membersList

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: theme.radiusSmall
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 8

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: theme.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.username.substring(0, 1).toUpperCase()
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: "#ffffff"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.username
                                font.pixelSize: 12
                                color: theme.textInteractive
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Filler spacer in members ScrollView
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 30
                    MouseArea {
                        anchors.fill: parent
                        onClicked: drawer.clearInputsRequested()
                    }
                }
            }
        }

        // SECTION: SLASHING RADAR (BOTTOM CARD)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 154
            radius: theme.radiusMedium
            color: theme.bgCard
            border.color: (drawer.radarTargetUser && drawer.radarStrikes >= drawer.radarStrikesRequired) ? theme.accentDanger : theme.borderSubtle
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    spacing: 6
                    Text { text: drawer.radarTargetUser ? "⚡" : "🛡️"; font.pixelSize: 13 }
                    Text {
                        text: "SLASHING RADAR"
                        font.bold: true
                        font.pixelSize: 11
                        color: drawer.radarTargetUser ? theme.accentDanger : theme.primary
                    }
                }

                Text {
                    text: drawer.radarTargetUser ? ("Target: " + drawer.radarTargetUser) : "Network Status: Clean"
                    font.bold: true
                    font.pixelSize: 12
                    color: theme.textHeader
                }

                Text {
                    text: drawer.radarTargetCommitment ? drawer.radarTargetCommitment : "No active strikes in this room"
                    font.pixelSize: 9
                    color: theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Visual Strike Boxes [X][X][ ]
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: drawer.radarStrikesRequired

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 4
                            color: (drawer.radarTargetUser && index < drawer.radarStrikes) ? theme.accentDanger : theme.bgHover
                            border.color: (drawer.radarTargetUser && index < drawer.radarStrikes) ? theme.accentDangerHover : theme.borderSubtle
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: (drawer.radarTargetUser && index < drawer.radarStrikes) ? "✕" : ""
                                font.bold: true
                                font.pixelSize: 13
                                color: "#ffffff"
                            }
                        }
                    }

                    Text {
                        text: drawer.radarTargetUser ?
                            (drawer.radarStrikes + "/" + drawer.radarStrikesRequired + " strikes") :
                            "0 active strikes"
                        font.pixelSize: 11
                        font.bold: true
                        color: (drawer.radarTargetUser && drawer.radarStrikes >= drawer.radarStrikesRequired) ? theme.accentDanger : theme.textMuted
                    }
                }

                // Action Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: theme.radiusSmall
                    color: (drawer.radarTargetUser && drawer.radarStrikes >= drawer.radarStrikesRequired) ? theme.accentDanger :
                           (drawer.radarTargetUser ? theme.primary : theme.bgHover)

                    Text {
                        anchors.centerIn: parent
                        text: (drawer.radarTargetUser && drawer.radarStrikes >= drawer.radarStrikesRequired) ? "⚡ Execute Slashing (LEZ)" :
                              (drawer.radarTargetUser ? "Issue Strike Review" : "Clean Standing")
                        font.bold: true
                        font.pixelSize: 11
                        color: drawer.radarTargetUser ? "#ffffff" : theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: drawer.radarTargetUser !== ""
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            drawer.clearInputsRequested();
                            if (drawer.radarStrikes >= drawer.radarStrikesRequired) {
                                drawer.executeSlashingRequested(drawer.radarTargetCommitment)
                            } else {
                                drawer.issueStrikeRequested()
                            }
                        }
                    }
                }
            }
        }
    }
}
