import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 520
    height: 570
    modal: true
    anchors.centerIn: parent
    padding: 24

    property string commitmentHex: ""
    property string nskHex: ""
    property string currentUsername: ""
    property bool isRevealed: false
    property int blockHeight: 0
    property int collateralAmount: 0
    property bool isLezConnected: false

    signal updateUsernameRequested(string newUsername)
    signal generateNewIdentityRequested()
    signal stakeViaWalletRequested(int amount, string commitment)

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

        // Title
        RowLayout {
            spacing: 10
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: theme.accentLogos
                Text {
                    anchors.centerIn: parent
                    text: "ZK"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#12151c"
                }
            }
            ColumnLayout {
                spacing: 2
                Text {
                    text: "Zero-Knowledge Identity Vault"
                    font.bold: true
                    font.pixelSize: 18
                    color: theme.textHeader
                }
                Text {
                    text: "Backed by 32-byte Nullifier Secret Key (NSK) & Shamir Secret Sharing."
                    font.pixelSize: 11
                    color: theme.textMuted
                }
            }
        }

        // Username Field
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "PSEUDONYMOUS USERNAME"
                font.bold: true
                font.pixelSize: 11
                color: theme.textMuted
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: userField
                    Layout.fillWidth: true
                    text: modal.currentUsername
                    color: theme.textHeader
                    font.pixelSize: 14
                    background: Rectangle {
                        color: theme.bgInput
                        radius: theme.radiusSmall
                    }
                }

                Button {
                    text: "Save"
                    contentItem: Text {
                        text: "Save"
                        font.bold: true
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: theme.accentBlurple
                        radius: theme.radiusSmall
                    }
                    onClicked: modal.updateUsernameRequested(userField.text.trim())
                }
            }
        }

        // Public Commitment Field
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "PUBLIC COMMITMENT (SHA256(NSK))"
                font.bold: true
                font.pixelSize: 11
                color: theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: theme.radiusSmall
                color: theme.bgInput

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: modal.commitmentHex || "0x0000000000000000000000000000000000000000000000000000000000000000"
                        color: theme.accentLogos
                        font.family: "monospace"
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        // Nullifier Secret Key (NSK) Field
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Text {
                    text: "NULLIFIER SECRET KEY (NSK) — PRIVATE"
                    font.bold: true
                    font.pixelSize: 11
                    color: theme.accentDanger
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: modal.isRevealed ? "Hide" : "Reveal"
                    font.pixelSize: 11
                    color: theme.accentBlurple
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modal.isRevealed = !modal.isRevealed
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: theme.radiusSmall
                color: theme.bgInput
                border.color: theme.accentDanger
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: modal.isRevealed ? (modal.nskHex || "Not generated") : "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••"
                        color: modal.isRevealed ? theme.textHeader : theme.textMuted
                        font.family: "monospace"
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        // LEZ Status Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: modal.collateralAmount >= 150 ? 50 : 80
            radius: theme.radiusSmall
            color: modal.collateralAmount >= 150 ? "#1a382e" : (modal.isLezConnected ? "#2d2416" : "#382e1a")
            border.color: modal.collateralAmount >= 150 ? theme.accentLogos : theme.accentWarning
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: modal.collateralAmount >= 150 ? "●" : (modal.isLezConnected ? "●" : "○")
                        font.pixelSize: 14
                        color: modal.collateralAmount >= 150 ? theme.accentLogos : theme.accentWarning
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: modal.collateralAmount >= 150
                                  ? "LEZ Membership Registry — 150 LEZ Collateral Active"
                                  : "Logos Execution Zone (LEZ) — 150 LEZ Collateral Required"
                            font.bold: true
                            font.pixelSize: 11
                            color: modal.collateralAmount >= 150 ? theme.accentLogos : theme.accentWarning
                        }
                        Text {
                            text: modal.collateralAmount >= 150
                                  ? "Identity protected by Zero-Knowledge nullifiers and strike slashing."
                                  : "Staking 150 LEZ collateral binds your commitment to the on-chain forum."
                            font.pixelSize: 10
                            color: modal.collateralAmount >= 150 ? "#a8e6cf" : "#d4a574"
                        }
                    }
                }

                // Stake Action Button if not yet staked
                RowLayout {
                    Layout.fillWidth: true
                    visible: modal.collateralAmount < 150
                    spacing: 8

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        contentItem: Text {
                            text: "⚡ Stake 150 LEZ via Basecamp Wallet"
                            font.bold: true
                            font.pixelSize: 11
                            color: "#12151c"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.accentLogos
                            radius: theme.radiusSmall
                        }
                        onClicked: modal.stakeViaWalletRequested(150, modal.commitmentHex)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Bottom Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Generate New Identity"
                contentItem: Text {
                    text: "Generate New Identity"
                    color: theme.accentDanger
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle { color: "transparent" }
                onClicked: modal.generateNewIdentityRequested()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Done"
                Layout.preferredWidth: 100
                contentItem: Text {
                    text: "Done"
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    color: theme.accentBlurple
                    radius: theme.radiusSmall
                }
                onClicked: modal.accept()
            }
        }
    }
}
