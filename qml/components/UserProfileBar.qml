import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: profileBar
    height: 72
    Layout.preferredHeight: 72
    Layout.fillWidth: true

    property string myUsername: "Anonymous"
    property string myCommitment: ""

    signal openIdentitySettings()
    signal copyCommitmentRequested()

    Theme { id: theme }

    // Floating Modal/Card Container (Matches ChatArea bottom banner height & bottomMargin)
    Rectangle {
        id: floatingCard
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 12
        anchors.topMargin: 0
        radius: theme.radiusMedium
        color: theme.bgCard
        border.color: theme.borderSubtle
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            // User Avatar with Online Status Indicator
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 34
                height: 34
                radius: 17
                color: theme.accentLogos

                Text {
                    anchors.centerIn: parent
                    text: profileBar.myUsername ? profileBar.myUsername.substring(0, 1).toUpperCase() : "A"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#12151c"
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 9
                    height: 9
                    radius: 4.5
                    color: theme.accentSuccess
                    border.color: theme.bgCard
                    border.width: 1.5
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: profileBar.openIdentitySettings()
                }

                ToolTip.delay: 200
                ToolTip.text: "Manage ZK Identity"
            }

            // Username, ZK Badge & Public Commitment in a single horizontal row
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: profileBar.myUsername
                    font.bold: true
                    font.pixelSize: 13
                    color: theme.textHeader
                    elide: Text.ElideRight
                    Layout.maximumWidth: 95
                }

                // Mini ZK Badge
                Rectangle {
                    height: 15
                    width: zkBadgeText.implicitWidth + 6
                    radius: 3
                    color: "#153026"
                    border.color: theme.accentLogos
                    border.width: 1

                    Text {
                        id: zkBadgeText
                        anchors.centerIn: parent
                        text: "ZK"
                        font.pixelSize: 8
                        font.bold: true
                        color: theme.accentLogos
                    }
                }

                // Public Commitment aligned in the same row
                Text {
                    text: profileBar.myCommitment ?
                        (profileBar.myCommitment.substring(0, 6) + "..." + profileBar.myCommitment.substring(profileBar.myCommitment.length - 4)) :
                        "0x00...00"
                    font.pixelSize: 10
                    font.family: "monospace"
                    color: theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Identity Settings Gear Action (Copy button removed)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30
                height: 30
                radius: theme.radiusSmall
                color: gearProfileMouse.containsMouse ? theme.bgHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⚙️"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: gearProfileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: profileBar.openIdentitySettings()
                }

                ToolTip.visible: gearProfileMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "Identity & Security Settings"
            }
        }
    }
}
