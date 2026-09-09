import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import "views"

Item {
    id: root
    width: 960
    height: 700

    property string currentTab: "chat" // "identity", "rooms", "chat", "moderation"
    property string activeRoomId: ""
    property string activeRoomName: "General Chat"
    property string myCommitment: ""
    property string myUsername: "Anonymous"
    property string statusMessage: "Ready"

    // Reference to Core Plugin
    property var anonCore: null

    Component.onCompleted: {
        // Core plugin is injected by Basecamp runtime
        if (typeof el_anon_chat_core !== "undefined") {
            anonCore = el_anon_chat_core;
            var idRes = anonCore.createIdentity("");
            try {
                var parsed = JSON.parse(idRes);
                if (parsed.commitment) {
                    myCommitment = parsed.commitment;
                }
            } catch(e) {}
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Navigation Bar
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "#1a1d24"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Label {
                    text: "AnonChat"
                    font.bold: true
                    font.pixelSize: 18
                    color: "#00d4aa"
                }

                Label {
                    text: "| Basecamp ZK-Identity"
                    font.pixelSize: 12
                    color: "#8892b0"
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 8

                    Button {
                        text: "Identity"
                        highlighted: root.currentTab === "identity"
                        onClicked: root.currentTab = "identity"
                    }

                    Button {
                        text: "Rooms"
                        highlighted: root.currentTab === "rooms"
                        onClicked: root.currentTab = "rooms"
                    }

                    Button {
                        text: "Chat"
                        highlighted: root.currentTab === "chat"
                        onClicked: root.currentTab = "chat"
                    }

                    Button {
                        text: "Moderation"
                        highlighted: root.currentTab === "moderation"
                        onClicked: root.currentTab = "moderation"
                    }
                }
            }
        }

        // Subheader Banner
        IdentityBanner {
            Layout.fillWidth: true
            commitment: root.myCommitment
            username: root.myUsername
        }

        // Main View Stack
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab === "identity" ? 0 :
                          root.currentTab === "rooms" ? 1 :
                          root.currentTab === "chat" ? 2 : 3

            IdentityView {
                anonCore: root.anonCore
                onIdentityUpdated: function(comm, user) {
                    root.myCommitment = comm;
                    root.myUsername = user;
                }
            }

            RoomList {
                anonCore: root.anonCore
                onRoomSelected: function(roomId, roomName) {
                    root.activeRoomId = roomId;
                    root.activeRoomName = roomName;
                    root.currentTab = "chat";
                }
            }

            ChatRoomView {
                anonCore: root.anonCore
                roomId: root.activeRoomId
                roomName: root.activeRoomName
                myCommitment: root.myCommitment
            }

            ModerationView {
                anonCore: root.anonCore
                roomId: root.activeRoomId
            }
        }

        // Bottom Status Bar
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#12151c"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Label {
                    text: root.statusMessage
                    font.pixelSize: 11
                    color: "#8892b0"
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "Logos Execution Zone (LEZ) — Two-Tier SSS Enabled"
                    font.pixelSize: 11
                    color: "#5f6c87"
                }
            }
        }
    }
}
