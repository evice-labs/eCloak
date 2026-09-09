import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: identityView
    property var anonCore: null
    signal identityUpdated(string commitment, string username)

    property string currentNsk: ""
    property string currentCommitment: ""
    property string currentUsername: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        Label {
            text: "Identity & Cryptographic Credential Management"
            font.bold: true
            font.pixelSize: 20
            color: "#ffffff"
        }

        Rectangle {
            Layout.fillWidth: true
            height: 140
            radius: 8
            color: "#181b22"
            border.color: "#272c38"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Label {
                    text: "Nullifier Secret Key (NSK):"
                    font.bold: true
                    font.pixelSize: 12
                    color: "#a0aec0"
                }

                Label {
                    text: identityView.currentNsk.length > 0 ? identityView.currentNsk : "Not yet generated"
                    font.family: "Monospace"
                    font.pixelSize: 11
                    color: "#00d4aa"
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }

                Label {
                    text: "Public Commitment (SHA256):"
                    font.bold: true
                    font.pixelSize: 12
                    color: "#a0aec0"
                }

                Label {
                    text: identityView.currentCommitment.length > 0 ? identityView.currentCommitment : "Not yet generated"
                    font.family: "Monospace"
                    font.pixelSize: 11
                    color: "#63b3ed"
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            spacing: 12

            Button {
                text: "Generate New NSK"
                onClicked: {
                    if (identityView.anonCore) {
                        var res = identityView.anonCore.createIdentity("");
                        try {
                            var p = JSON.parse(res);
                            identityView.currentNsk = p.nsk;
                            identityView.currentCommitment = p.commitment;
                            identityView.identityUpdated(p.commitment, identityView.currentUsername);
                        } catch(e) {}
                    }
                }
            }

            TextField {
                id: customNskField
                placeholderText: "Or paste 32-byte hex NSK"
                Layout.preferredWidth: 320
            }

            Button {
                text: "Import NSK"
                onClicked: {
                    if (identityView.anonCore && customNskField.text.length === 64) {
                        var res = identityView.anonCore.createIdentity(customNskField.text.trim());
                        try {
                            var p = JSON.parse(res);
                            identityView.currentNsk = p.nsk;
                            identityView.currentCommitment = p.commitment;
                            identityView.identityUpdated(p.commitment, identityView.currentUsername);
                        } catch(e) {}
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#2a303c"
        }

        Label {
            text: "Username Binding (Off-chain Schnorr-verified)"
            font.bold: true
            font.pixelSize: 16
            color: "#ffffff"
        }

        RowLayout {
            spacing: 12

            TextField {
                id: usernameInput
                placeholderText: "Choose a pseudonym (e.g. Satoshi99)"
                Layout.preferredWidth: 260
            }

            Button {
                text: "Register Pseudonym"
                highlighted: true
                onClicked: {
                    if (identityView.anonCore && usernameInput.text.length > 0 && identityView.currentCommitment.length > 0) {
                        identityView.anonCore.registerUsername(usernameInput.text.trim());
                        identityView.currentUsername = usernameInput.text.trim();
                        identityView.identityUpdated(identityView.currentCommitment, identityView.currentUsername);
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
