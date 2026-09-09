import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: composer
    height: 70
    color: "#181b22"
    border.color: "#272c38"
    border.width: 1
    radius: 8

    signal sendMessage(string message)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        TextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: "Type an anonymous message (split via 2-tier SSS)..."
            color: "#ffffff"
            onAccepted: sendBtn.clicked()
        }

        Button {
            id: sendBtn
            text: "Send"
            highlighted: true
            enabled: inputField.text.trimmed().length > 0
            onClicked: {
                composer.sendMessage(inputField.text.trimmed());
                inputField.text = "";
            }
        }
    }
}
