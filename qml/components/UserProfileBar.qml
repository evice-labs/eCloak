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
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 14
                    color: "#12151c"
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

            // Username & Public Commitment in a single horizontal row
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: profileBar.myUsername
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: theme.textHeader
                    elide: Text.ElideRight
                    Layout.maximumWidth: 95
                }

                // Public Commitment aligned in the same row with underline and click-to-copy
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter

                    property bool justCopied: false

                    Timer {
                        id: copyFeedbackTimer
                        interval: 1800
                        onTriggered: parent.justCopied = false
                    }

                    Text {
                        id: commText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.justCopied ? "✔ Copied!" : (profileBar.myCommitment ?
                            (profileBar.myCommitment.substring(0, 6) + "..." + profileBar.myCommitment.substring(profileBar.myCommitment.length - 4)) :
                            "0x00...00")
                        font.pixelSize: 10
                        font.family: theme.fontFamilyMono
                        font.underline: true
                        color: parent.justCopied ? theme.accentSuccess : (commMouse.containsMouse ? theme.accentLogos : theme.textMuted)
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: commMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (profileBar.myCommitment && profileBar.myCommitment.length > 0) {
                                clipHelper.text = profileBar.myCommitment;
                                clipHelper.selectAll();
                                clipHelper.copy();
                                parent.justCopied = true;
                                copyFeedbackTimer.restart();
                                profileBar.copyCommitmentRequested();
                            }
                        }
                    }
                }

                TextInput {
                    id: clipHelper
                    visible: false
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
