import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: strikeDialog
    title: "Issue Moderator Strike (BIP-340)"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: 450

    property string targetTracingTag: ""
    property string targetCommitment: ""
    signal strikeIssued(string tracingTag, string commitment, string evidence)

    ColumnLayout {
        spacing: 12
        width: parent.width

        Label {
            text: "Target Tracing Tag:"
            font.bold: true
            font.pixelSize: 12
        }

        Label {
            text: strikeDialog.targetTracingTag
            font.family: "Monospace"
            font.pixelSize: 11
            color: "#8892b0"
            wrapMode: Text.WrapAnywhere
            Layout.fillWidth: true
        }

        Label {
            text: "Target Commitment:"
            font.bold: true
            font.pixelSize: 12
        }

        Label {
            text: strikeDialog.targetCommitment
            font.family: "Monospace"
            font.pixelSize: 11
            color: "#8892b0"
            wrapMode: Text.WrapAnywhere
            Layout.fillWidth: true
        }

        TextField {
            id: evidenceField
            Layout.fillWidth: true
            placeholderText: "Evidence description / Violation reason"
        }
    }

    onAccepted: {
        strikeDialog.strikeIssued(
            strikeDialog.targetTracingTag,
            strikeDialog.targetCommitment,
            evidenceField.text
        );
        evidenceField.text = "";
    }
}
