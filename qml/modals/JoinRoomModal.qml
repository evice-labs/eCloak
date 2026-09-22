import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 460
    height: 430
    modal: true
    anchors.centerIn: parent
    padding: 24

    property string memberCommitment: ""
    property bool isIdentityReady: memberCommitment.length > 0

    function getCleanRoomId() {
        if (!roomIdInput) return "";
        var raw = roomIdInput.text.trim();
        if (raw.startsWith("0x") || raw.startsWith("0X")) {
            raw = raw.substring(2);
        }
        return raw;
    }

    readonly property string cleanRoomId: getCleanRoomId()
    readonly property bool hasNonHexChars: cleanRoomId.length > 0 && !/^[0-9a-fA-F]+$/.test(cleanRoomId)
    readonly property bool isValidRoomId: cleanRoomId.length === 64 && /^[0-9a-fA-F]{64}$/.test(cleanRoomId)
    property string errorMessage: ""
    property bool isSubmitting: false

    signal roomJoined(string roomIdHex, string consentSig)
    signal createRoomRequested()

    Theme { id: theme }

    onOpened: {
        roomIdInput.text = "";
        errorMessage = "";
        isSubmitting = false;
        roomIdInput.forceActiveFocus();
    }

    background: Rectangle {
        color: theme.bgModal
        radius: theme.radiusLarge
        border.color: theme.borderSubtle
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Join a Room"
                font.bold: true
                font.pixelSize: 20
                color: theme.textHeader
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Create a room instead →"
                font.family: theme.fontFamily
                font.pixelSize: 12
                color: createLinkMouse.containsMouse ? theme.accentBlurple : theme.primary
                font.underline: createLinkMouse.containsMouse

                MouseArea {
                    id: createLinkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        modal.reject();
                        modal.createRoomRequested();
                    }
                }
            }
        }

        Text {
            text: "Enter the 32-byte hexadecimal Room ID (64 hex characters) below."
            font.pixelSize: 12
            color: theme.textMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "ROOM ID (HEX)"
                    font.bold: true
                    font.pixelSize: 11
                    color: theme.textMuted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: modal.cleanRoomId.length + " / 64 hex chars"
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: modal.isValidRoomId ? theme.accentSuccess : (modal.hasNonHexChars || modal.cleanRoomId.length > 64 ? theme.accentDanger : theme.textMuted)
                }
            }

            TextField {
                id: roomIdInput
                Layout.fillWidth: true
                placeholderText: "e.g. 0x4f128c99... (64 hex characters)"
                placeholderTextColor: theme.textMuted
                color: theme.textHeader
                font.family: "monospace"
                font.pixelSize: 12
                selectByMouse: true
                onTextChanged: {
                    modal.errorMessage = "";
                }
                background: Rectangle {
                    color: theme.bgInput
                    radius: theme.radiusSmall
                    border.color: modal.hasNonHexChars || (modal.errorMessage.length > 0) ? theme.accentDanger :
                                  (modal.isValidRoomId ? theme.accentSuccess : (roomIdInput.activeFocus ? theme.accentBlurple : "transparent"))
                    border.width: (modal.hasNonHexChars || modal.isValidRoomId || modal.errorMessage.length > 0) ? 1.5 : 1
                }
            }

            Text {
                visible: modal.hasNonHexChars || (modal.cleanRoomId.length > 0 && !modal.isValidRoomId) || modal.errorMessage.length > 0
                text: {
                    if (modal.errorMessage.length > 0) return "⚠ " + modal.errorMessage;
                    if (modal.hasNonHexChars) return "⚠ Room ID must only contain hexadecimal characters (0-9, a-f).";
                    if (modal.cleanRoomId.length > 64) return "⚠ Room ID too long: must be exactly 64 hexadecimal characters (32 bytes).";
                    if (modal.cleanRoomId.length > 0 && modal.cleanRoomId.length < 64) return "Room ID requires 64 characters (" + (64 - modal.cleanRoomId.length) + " more needed).";
                    return "";
                }
                font.pixelSize: 11
                color: (modal.hasNonHexChars || modal.cleanRoomId.length > 64 || modal.errorMessage.length > 0) ? theme.accentDanger : theme.textMuted
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        // Signed Join Consent Protection Box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: theme.radiusSmall
            color: Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.12)
            border.color: theme.primary
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
                        color: theme.primary
                    }
                    Text {
                        text: "Generates a BIP-340 Schnorr signature over the room ID using your NSK. Protects you against puppet-room framing attacks."
                        font.pixelSize: 10
                        color: theme.textNormal
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
                enabled: !modal.isSubmitting
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
                enabled: modal.isIdentityReady && modal.isValidRoomId && !modal.isSubmitting
                contentItem: Text {
                    text: !modal.isIdentityReady ? "🔒 Identity Required" :
                          (modal.isSubmitting ? "Signing & Joining..." :
                          (!modal.isValidRoomId ? "Enter 64-char Hex ID (" + modal.cleanRoomId.length + "/64)" : "Sign & Join Room"))
                    font.bold: true
                    color: parent.enabled ? "#ffffff" : theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    color: parent.enabled ? theme.accentBlurple : theme.bgInput
                    radius: theme.radiusSmall
                }
                onClicked: {
                    if (modal.isValidRoomId) {
                        modal.isSubmitting = true;
                        modal.errorMessage = "";
                        // Pass empty placeholder — Core Module will auto-sign via ffi_room_sign_join_consent
                        var consentPlaceholder = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
                        modal.roomJoined(modal.cleanRoomId, consentPlaceholder);
                    }
                }
            }
        }
    }
}
