import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: roomListComponent

    property var anonCore: null
    signal roomSelected(string roomId, string roomName)

    ListModel {
        id: roomsModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Chat Rooms"
                font.bold: true
                font.pixelSize: 20
                color: "#ffffff"
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "+ Create New Room"
                onClicked: createRoomDialog.open()
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: roomsModel
            spacing: 10

            delegate: Rectangle {
                width: ListView.view.width
                height: 72
                radius: 8
                color: "#1e222b"
                border.color: mouseArea.containsMouse ? "#00d4aa" : "#2a303c"
                border.width: 1

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: roomListComponent.roomSelected(model.roomId, model.name)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    ColumnLayout {
                        spacing: 4
                        Label {
                            text: model.name
                            font.bold: true
                            font.pixelSize: 15
                            color: "#ffffff"
                        }
                        Label {
                            text: "ID: " + model.roomId.substring(0, 20) + "..."
                            font.family: "Monospace"
                            font.pixelSize: 11
                            color: "#8892b0"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "Moderators: " + model.nThreshold + "-of-" + model.mModerators
                        font.pixelSize: 12
                        color: "#a0aec0"
                    }

                    Label {
                        text: model.memberCount + " Members"
                        font.bold: true
                        font.pixelSize: 12
                        color: "#00d4aa"
                    }

                    Button {
                        text: "Enter"
                        onClicked: roomListComponent.roomSelected(model.roomId, model.name)
                    }
                }
            }
        }
    }

    Dialog {
        id: createRoomDialog
        title: "Create Anonymous Room"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        width: 400

        ColumnLayout {
            spacing: 12
            width: parent.width

            TextField {
                id: newRoomNameField
                Layout.fillWidth: true
                placeholderText: "Room Name (e.g. Evice Builders)"
            }

            RowLayout {
                Label { text: "Threshold (N): " }
                SpinBox { id: nThresholdSpin; from: 1; to: 5; value: 2 }
            }

            RowLayout {
                Label { text: "Total Mods (M): " }
                SpinBox { id: mTotalSpin; from: 1; to: 10; value: 3 }
            }
        }

        onAccepted: {
            if (newRoomNameField.text.length > 0) {
                var randomHex = "";
                var hexChars = "0123456789abcdef";
                for (var i = 0; i < 64; i++) {
                    randomHex += hexChars.charAt(Math.floor(Math.random() * hexChars.length));
                }
                roomsModel.append({
                    name: newRoomNameField.text,
                    roomId: randomHex,
                    nThreshold: nThresholdSpin.value,
                    mModerators: mTotalSpin.value,
                    memberCount: 1
                });
                newRoomNameField.text = "";
            }
        }
    }
}
