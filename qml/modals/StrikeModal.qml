import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 480
    height: 480
    modal: true
    anchors.centerIn: parent
    padding: 24

    property string targetAuthor: ""
    property string targetCommitment: ""
    property string tracingTag: ""
    property string messageSnippet: ""
    property string evidenceHash: ""

    signal strikeSigned(string targetComm, string tag, string evidence)

    Theme { id: theme }

    background: Rectangle {
        color: theme.bgModal
        radius: theme.radiusLarge
        border.color: theme.accentDanger
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Header
        RowLayout {
            spacing: 8
            Text { text: "🚩"; font.pixelSize: 20 }
            ColumnLayout {
                spacing: 2
                Text {
                    text: "Issue Moderation Strike"
                    font.bold: true
                    font.pixelSize: 18
                    color: theme.accentDanger
                }
                Text {
                    text: "BIP-340 Schnorr threshold moderation evidence review."
                    font.pixelSize: 11
                    color: theme.textMuted
                }
            }
        }

        // Target Details
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: theme.radiusSmall
            color: theme.bgRail

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Text { text: "Target User:"; font.bold: true; font.pixelSize: 12; color: theme.textHeader }
                    Text { text: modal.targetAuthor || "Anonymous"; font.pixelSize: 12; color: theme.accentWarning }
                    Item { Layout.fillWidth: true }
                    Text { text: "Tag: " + (modal.tracingTag ? ("#" + modal.tracingTag.substring(0, 8)) : "#00000000"); font.pixelSize: 11; font.family: "monospace"; color: theme.accentLogos }
                }

                Text {
                    text: "Commitment: " + (modal.targetCommitment || "0x3f1a...4e2b")
                    font.pixelSize: 10
                    font.family: "monospace"
                    color: theme.textMuted
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }

        // Message Snippet Box
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "EVIDENCE CONTENT"
                font.bold: true
                font.pixelSize: 10
                color: theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: theme.radiusSmall
                color: theme.bgInput

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    Text {
                        width: parent.width
                        text: modal.messageSnippet || "(Flagged message content)"
                        color: theme.textNormal
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        // Evidence Hash
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "SHA256 EVIDENCE HASH"
                font.bold: true
                font.pixelSize: 10
                color: theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: theme.radiusSmall
                color: theme.bgInput

                Text {
                    anchors.centerIn: parent
                    text: modal.evidenceHash || "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                    font.family: "monospace"
                    font.pixelSize: 10
                    color: theme.textInteractive
                }
            }
        }

        // Quorum Notice
        Text {
            text: "⚠️ Slashing requires K strikes from mature rooms. Single strikes do NOT reveal user identity."
            font.pixelSize: 10
            color: theme.accentWarning
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Dismiss"
                Layout.fillWidth: true
                contentItem: Text {
                    text: "Dismiss"
                    color: theme.textInteractiveActive
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle { color: "transparent" }
                onClicked: modal.reject()
            }

            Button {
                text: "Sign & Broadcast Strike"
                Layout.fillWidth: true
                contentItem: Text {
                    text: "Sign & Broadcast Strike"
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    color: theme.accentDanger
                    radius: theme.radiusSmall
                }
                onClicked: {
                    modal.strikeSigned(modal.targetCommitment, modal.tracingTag, modal.evidenceHash)
                    modal.accept()
                }
            }
        }
    }
}
