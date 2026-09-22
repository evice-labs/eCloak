import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 440
    height: 260
    modal: true
    anchors.centerIn: parent
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string targetUsername: ""
    property string dialogTitle: "Delete Conversation"
    property string confirmMessage: "Are you sure you want to delete this conversation? Once deleted, it cannot be recovered."

    signal confirmed(string username)
    signal cancelled()

    Theme { id: theme }

    background: Rectangle {
        color: theme.bgCard
        radius: theme.radiusLarge
        border.color: theme.borderSubtle
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Title & Target Pill
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: modal.dialogTitle
                font.bold: true
                font.pixelSize: 18
                color: theme.textHeader
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                visible: modal.targetUsername.length > 0
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 24
                implicitWidth: targetRow.implicitWidth + 24
                Layout.preferredHeight: 24
                Layout.preferredWidth: targetRow.implicitWidth + 24
                radius: 12
                color: theme.bgInput
                border.color: theme.borderSubtle
                border.width: 1

                Row {
                    id: targetRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: theme.primary
                    }

                    Text {
                        id: targetText
                        anchors.verticalCenter: parent.verticalCenter
                        text: "@" + modal.targetUsername
                        font.family: theme.fontFamily
                        font.bold: true
                        font.pixelSize: 11
                        color: theme.textHeader
                    }
                }
            }
        }

        // Centered Confirmation Message Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                width: parent.width - 24
                text: modal.confirmMessage
                font.pixelSize: 13
                font.family: theme.fontFamily
                lineHeight: 1.4
                color: theme.textNormal
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Action Buttons: Cancel vs Delete
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                id: cancelBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: cancelMouse.containsMouse ? theme.bgHover : theme.bgCard
                radius: theme.radiusSmall
                border.color: cancelMouse.containsMouse ? theme.border : theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.bold: true
                    font.pixelSize: 13
                    color: cancelMouse.containsMouse ? theme.textHeader : theme.textInteractive
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        modal.cancelled();
                        modal.reject();
                    }
                }
            }

            Rectangle {
                id: deleteBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: deleteMouse.containsMouse ? "#A8242C" : "#80181E"
                radius: theme.radiusSmall
                border.color: deleteMouse.containsMouse ? "#C53030" : "#5F1216"
                border.width: 1

                Behavior on color { ColorAnimation { duration: theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "Delete Conversation"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#ffffff"
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        modal.confirmed(modal.targetUsername);
                        modal.accept();
                    }
                }
            }
        }
    }
}
