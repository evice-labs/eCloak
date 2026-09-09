import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: modView
    property var anonCore: null
    property string roomId: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        Label {
            text: "Decentralized Moderator Dashboard & Lagrange Slashing"
            font.bold: true
            font.pixelSize: 20
            color: "#ffffff"
        }

        Rectangle {
            Layout.fillWidth: true
            height: 110
            radius: 8
            color: "#181b22"
            border.color: "#272c38"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Label {
                    text: "Moderator Key Status:"
                    font.bold: true
                    font.pixelSize: 12
                    color: "#a0aec0"
                }

                Label {
                    text: "Secp256k1 Key Active — Ready to issue BIP-340 strike certificates"
                    font.pixelSize: 13
                    color: "#00d4aa"
                }

                Label {
                    text: "Multi-Signature Threshold: N = 2 / M = 3"
                    font.pixelSize: 12
                    color: "#8892b0"
                }
            }
        }

        Label {
            text: "Lagrange Polynomial Reconstruction & Slashing (>= K Strikes)"
            font.bold: true
            font.pixelSize: 16
            color: "#ffffff"
        }

        TextField {
            id: targetCommitmentInput
            Layout.fillWidth: true
            placeholderText: "Enter Target Commitment to Inspect Strikes"
        }

        RowLayout {
            spacing: 12

            Button {
                text: "Reconstruct Strike (Tier-1)"
                onClicked: {
                    console.log("Reconstructing strike shares via GF(2^8) Lagrange interpolation");
                }
            }

            Button {
                text: "Reconstruct NSK & Slash (Tier-2)"
                highlighted: true
                onClicked: {
                    console.log("Reconstructing full NSK and executing on-chain slashing");
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
