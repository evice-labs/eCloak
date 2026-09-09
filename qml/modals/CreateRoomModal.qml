import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 480
    height: 520
    modal: true
    anchors.centerIn: parent
    padding: 24

    property string adminCommitment: ""

    signal roomCreated(string name, int nThreshold, int mTotal, string modKeysJson, int minMembers)

    Theme { id: theme }

    background: Rectangle {
        color: theme.bgModal
        radius: theme.radiusLarge
        border.color: theme.borderSubtle
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Title & Description
        Text {
            text: "Create Your Room"
            font.bold: true
            font.pixelSize: 20
            color: theme.textHeader
        }

        Text {
            text: "Your room is governed by N-of-M threshold moderation. Abuse strikes require consensus among room moderators."
            font.pixelSize: 12
            color: theme.textMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Room Name Field
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "ROOM NAME"
                font.bold: true
                font.pixelSize: 11
                color: theme.textMuted
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: "e.g. ZK Research Hub"
                placeholderTextColor: theme.textMuted
                color: theme.textHeader
                font.pixelSize: 14
                text: "Logos Anonymous Lounge"
                background: Rectangle {
                    color: theme.bgInput
                    radius: theme.radiusSmall
                    border.color: nameField.activeFocus ? theme.accentBlurple : "transparent"
                }
            }
        }

        // Threshold Sliders (N-of-M)
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: "RECONSTRUCTION THRESHOLD (N: " + nSlider.value + ")"
                    font.bold: true
                    font.pixelSize: 10
                    color: theme.accentLogos
                }
                Slider {
                    id: nSlider
                    Layout.fillWidth: true
                    from: 1
                    to: mSlider.value
                    stepSize: 1
                    value: 2
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: "TOTAL MODERATORS (M: " + mSlider.value + ")"
                    font.bold: true
                    font.pixelSize: 10
                    color: theme.accentBlurple
                }
                Slider {
                    id: mSlider
                    Layout.fillWidth: true
                    from: 1
                    to: 5
                    stepSize: 1
                    value: 3
                    onValueChanged: {
                        if (nSlider.value > mSlider.value) {
                            nSlider.value = mSlider.value
                        }
                    }
                }
            }
        }

        // Moderator Public Keys
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "MODERATOR PUBLIC KEYS (JSON Array)"
                font.bold: true
                font.pixelSize: 11
                color: theme.textMuted
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                clip: true

                TextArea {
                    id: modKeysArea
                    text: '["02e4f82a1b9c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789", "03a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef", "029876543210fedcba9876543210fedcba9876543210fedcba9876543210fedc"]'
                    color: theme.textNormal
                    font.family: "monospace"
                    font.pixelSize: 10
                    wrapMode: TextEdit.Wrap
                    background: Rectangle {
                        color: theme.bgInput
                        radius: theme.radiusSmall
                    }
                }
            }
        }

        // Anti-Sybil Notice Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: theme.radiusSmall
            color: "#1a2a38"
            border.color: "#244b6b"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text { text: "🛡️"; font.pixelSize: 14 }
                Text {
                    text: "Sybil Guard: New rooms enter a probation period until age & active member requirements are met."
                    font.pixelSize: 10
                    color: "#8bc4eb"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Cancel"
                Layout.fillWidth: true
                contentItem: Text {
                    text: "Cancel"
                    color: theme.textInteractiveActive
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    color: "transparent"
                }
                onClicked: modal.reject()
            }

            Button {
                text: "Create Room"
                Layout.fillWidth: true
                contentItem: Text {
                    text: "Create Room"
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    color: theme.accentBlurple
                    radius: theme.radiusSmall
                }
                onClicked: {
                    modal.roomCreated(
                        nameField.text.trim(),
                        nSlider.value,
                        mSlider.value,
                        modKeysArea.text.trim(),
                        10
                    )
                    modal.accept()
                }
            }
        }
    }
}
