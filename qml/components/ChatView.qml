import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: chatView

    property var messagesModel: []
    signal flagPost(string tracingTag, string authorCommitment)

    ListView {
        id: messageList
        anchors.fill: parent
        clip: true
        spacing: 12
        model: chatView.messagesModel

        delegate: Rectangle {
            width: ListView.view.width
            height: contentCol.height + 24
            radius: 8
            color: "#1a1e27"
            border.color: "#272c38"
            border.width: 1

            ColumnLayout {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: model.authorName
                        font.bold: true
                        font.pixelSize: 13
                        color: "#00d4aa"
                    }

                    Label {
                        text: "Tag: " + model.tracingTag.substring(0, 10) + "..."
                        font.family: "Monospace"
                        font.pixelSize: 10
                        color: "#6b7280"
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Flag / Strike"
                        implicitHeight: 26
                        onClicked: chatView.flagPost(model.tracingTag, model.authorCommitment)
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: model.content
                    wrapMode: Text.Wrap
                    font.pixelSize: 14
                    color: "#e2e8f0"
                }
            }
        }
    }
}
