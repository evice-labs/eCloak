import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: feed

    property var messagesModel: []
    property string channelName: "general-chat"
    property string activeView: "room" // "room" or "dm"

    signal flagRequested(string author, string commitment, string tag, string text)
    signal inspectRequested(string tag, var point)

    Theme { id: theme }

    ListView {
        id: msgList
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 12
        clip: true
        model: feed.messagesModel

        // Header for beginning of channel
        header: ColumnLayout {
            width: msgList.width
            spacing: 8
            visible: feed.messagesModel.length === 0 || true

            Item { Layout.preferredHeight: 16 }

            // Title Row: Icon and Title Text aligned horizontally
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: (feed.activeView === "dm" && feed.channelName) ? theme.accentBlurple : theme.bgHover
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: !feed.channelName ?
                            (feed.activeView === "dm" ? "💬" : "🛡️") :
                            (feed.activeView === "dm" ? feed.channelName.substring(0, 1).toUpperCase() : "#")
                        font.family: theme.fontFamily
                        font.bold: true
                        font.pixelSize: (feed.activeView === "dm" && feed.channelName) ? 20 : 24
                        color: (feed.activeView === "dm" && feed.channelName) ? "#ffffff" : theme.textHeader
                    }
                }

                Text {
                    text: !feed.channelName ?
                        (feed.activeView === "dm" ? "No Conversation Selected" : "Welcome to Logos AnonChat") :
                        (feed.activeView === "dm" ? ("Direct Chat with " + feed.channelName) : ("Welcome to #" + feed.channelName + "!"))
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 22
                    color: theme.textHeader
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            Text {
                text: !feed.channelName ?
                    (feed.activeView === "dm" ?
                        "Select an anonymous peer from the sidebar or click 'Find or start a DM...' above to begin." :
                        "Create a room using '+' on the left server rail or join an existing room with signed consent.") :
                    (feed.activeView === "dm" ?
                        "End-to-End Encrypted via ECDH + ChaCha20Poly1305. Topics rotate per epoch." :
                        "This is the start of the #" + feed.channelName + " channel. Messages are protected by Two-Tier SSS accountability.")
                font.pixelSize: 14
                color: theme.textMuted
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 12
                Layout.bottomMargin: 8
                height: 1
                color: theme.borderSubtle
            }
        }

        delegate: MessageItem {
            width: msgList.width
            author: modelData.author || "Anonymous"
            authorCommitment: modelData.commitment || ""
            timestamp: modelData.timestamp || "Just now"
            contentText: modelData.text || ""
            tracingTag: modelData.tracingTag || ""
            isMod: modelData.isMod || false
            isVerified: true
            postPoint: modelData.postPoint || null
            attachment: modelData.attachment || null

            onFlagClicked: function(author, comm, tag, text) {
                feed.flagRequested(author, comm, tag, text)
            }

            onInspectClicked: function(tag, point) {
                feed.inspectRequested(tag, point)
            }
        }

        onCountChanged: {
            Qt.callLater(function() { msgList.positionViewAtEnd() })
        }
    }
}
