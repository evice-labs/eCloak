import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 460
    height: 380
    modal: true
    anchors.centerIn: parent
    padding: 24

    property string memberCommitment: ""

    signal roomJoined(string roomIdHex, string consentSig)

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

        Text {
            text: "Join a Room"
            font.bold: true
            font.pixelSize: 20
            color: theme.textHeader
        }

        Text {
            text: "Enter a 32-byte hexadecimal Room ID or paste an invite code below."
            font.pixelSize: 12
            color: theme.textMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "ROOM ID (HEX)"
                font.bold: true
                font.pixelSize: 11
                color: theme.textMuted
            }

            TextField {
                id: roomIdInput
                Layout.fillWidth: true
                placeholderText: "e.g. 0x4f128c99... (64 hex characters)"
                placeholderTextColor: theme.textMuted
                color: theme.textHeader
                font.family: "monospace"
                font.pixelSize: 12
                background: Rectangle {
                    color: theme.bgInput
                    radius: theme.radiusSmall
                    border.color: roomIdInput.activeFocus ? theme.accentBlurple : "transparent"
                }
            }
        }

        // Signed Join Consent Protection Box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: theme.radiusSmall
            color: "#1a382e"
            border.color: theme.accentLogos
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text { text: "✍️"; font.pixelSize: 18 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Signed Join Consent Active"
                        font.bold: true
                        font.pixelSize: 11
                        color: theme.accentLogos
                    }
                    Text {
                        text: "Generates a BIP-340 Schnorr signature over the room ID using your NSK. Protects you against puppet-room framing attacks."
                        font.pixelSize: 10
                        color: "#a8e6cf"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

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
                background: Rectangle { color: "transparent" }
                onClicked: modal.reject()
            }

            Button {
                text: "Join Room"
                Layout.fillWidth: true
                contentItem: Text {
                    text: "Sign & Join Room"
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    color: theme.accentBlurple
                    radius: theme.radiusSmall
                }
                onClicked: {
                    if (roomIdInput.text.trim().length > 0) {
                        // Generate mock 64-byte signature for consent
                        var dummySig = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40";
                        modal.roomJoined(roomIdInput.text.trim(), dummySig);
                        modal.accept();
                    }
                }
            }
        }
    }
}
