import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: chatRoomView

    property var anonCore: null
    property string roomId: ""
    property string roomName: "Active Room"
    property string myCommitment: ""

    ListModel {
        id: messageFeed
        ListElement {
            authorName: "Anon#3912"
            authorCommitment: "0a0b0c0d0e0f1011121314151617181920212223242526272829303132333435"
            tracingTag: "e4f82a1b9c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f"
            content: "Welcome to Logos AnonChat! Every post published here is protected by 2-tier SSS."
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Room Header
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: chatRoomView.roomName
                font.bold: true
                font.pixelSize: 18
                color: "#ffffff"
            }

            Label {
                text: "• " + (chatRoomView.roomId.length > 16 ? chatRoomView.roomId.substring(0, 16) + "..." : "No Room")
                font.family: "Monospace"
                font.pixelSize: 11
                color: "#8892b0"
            }

            Item { Layout.fillWidth: true }

            Label {
                text: "Active SSS Protection"
                font.pixelSize: 12
                color: "#00d4aa"
            }
        }

        // Chat View
        ChatView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            messagesModel: messageFeed
            onFlagPost: function(tag, comm) {
                strikeDialog.targetTracingTag = tag;
                strikeDialog.targetCommitment = comm;
                strikeDialog.open();
            }
        }

        // Message Composer
        MessageComposer {
            Layout.fillWidth: true
            onSendMessage: function(msg) {
                var salt = "0102030405060708091011121314151617181920212223242526272829303132";
                var modKeys = JSON.stringify(["aa01020304050607080910111213141516171819202122232425262728293031"]);
                var tag = "f3a1c89b" + Math.floor(Math.random()*1000000);

                messageFeed.append({
                    authorName: "Me (Anon)",
                    authorCommitment: chatRoomView.myCommitment,
                    tracingTag: tag,
                    content: msg
                });
            }
        }
    }

    StrikeModal {
        id: strikeDialog
        onStrikeIssued: function(tag, comm, evidence) {
            console.log("Strike issued against " + comm + " for " + evidence);
        }
    }
}
