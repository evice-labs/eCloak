import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: banner
    height: 40
    color: "#212631"

    property string commitment: ""
    property string username: ""
    property bool isRevoked: false

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        Label {
            text: "User: " + (banner.username.length > 0 ? banner.username : "Unregistered")
            font.bold: true
            font.pixelSize: 12
            color: "#ffffff"
        }

        Label {
            text: "Commitment: " + (banner.commitment.length > 16 ? banner.commitment.substring(0, 16) + "..." : (banner.commitment.length > 0 ? banner.commitment : "None"))
            font.family: "Monospace"
            font.pixelSize: 11
            color: "#8892b0"
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 80
            height: 22
            radius: 11
            color: banner.isRevoked ? "#4d1a1a" : "#1a3d31"

            Label {
                anchors.centerIn: parent
                text: banner.isRevoked ? "REVOKED" : "ACTIVE"
                font.bold: true
                font.pixelSize: 10
                color: banner.isRevoked ? "#ff6b6b" : "#00d4aa"
            }
        }
    }
}
