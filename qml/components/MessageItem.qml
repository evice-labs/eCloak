import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: msgItem
    width: parent ? parent.width : 600
    height: contentLayout.height + 16
    color: msgMouse.containsMouse ? theme.bgHover : "transparent"
    radius: theme.radiusSmall

    property string author: "Anonymous"
    property string authorCommitment: ""
    property string timestamp: "Today at 12:00"
    property string contentText: ""
    property string tracingTag: ""
    property bool isMod: false
    property bool isVerified: true
    property var postPoint: null
    property var attachment: null

    signal flagClicked(string author, string commitment, string tag, string text)
    signal inspectClicked(string tag, var point)
    signal reactClicked(string emoji)

    Theme { id: theme }

    MouseArea {
        id: msgMouse
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: contentLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 14

        // Author Avatar Identicon
        Rectangle {
            Layout.alignment: Qt.AlignTop
            width: 40
            height: 40
            radius: 20
            color: msgItem.isMod ? theme.accentBlurple : theme.accentLogos

            Text {
                anchors.centerIn: parent
                text: msgItem.author.substring(0, 1).toUpperCase()
                font.bold: true
                font.pixelSize: 16
                color: msgItem.isMod ? "#ffffff" : "#12151c"
            }
        }

        // Message Content & Meta
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Top Meta Row: Author, Role Badges, Timestamp
            RowLayout {
                spacing: 8

                Text {
                    text: msgItem.author
                    font.bold: true
                    font.pixelSize: 14
                    color: theme.textHeader
                }

                // Moderator Badge
                Rectangle {
                    visible: msgItem.isMod
                    height: 16
                    width: modLabel.implicitWidth + 8
                    radius: 3
                    color: theme.accentBlurple

                    Text {
                        id: modLabel
                        anchors.centerIn: parent
                        text: "MOD"
                        font.pixelSize: 9
                        font.bold: true
                        color: "#ffffff"
                    }
                }

                // ZK Verified Badge
                Rectangle {
                    visible: msgItem.isVerified
                    height: 16
                    width: verLabel.implicitWidth + 8
                    radius: 3
                    color: "#1a382e"
                    border.color: theme.accentLogos
                    border.width: 1

                    Text {
                        id: verLabel
                        anchors.centerIn: parent
                        text: "VERIFIED ZK"
                        font.pixelSize: 9
                        font.bold: true
                        color: theme.accentLogos
                    }
                }

                Text {
                    text: msgItem.timestamp
                    font.pixelSize: 11
                    color: theme.textMuted
                }

                Item { Layout.fillWidth: true }
            }

            // Cryptographic Accountability Pill (Tracing Tag & Two-Tier SSS)
            RowLayout {
                spacing: 6
                visible: msgItem.tracingTag !== ""

                Rectangle {
                    height: 18
                    width: tagRow.implicitWidth + 12
                    radius: 9
                    color: theme.bgRail
                    border.color: theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        id: tagRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "🔒 2-Tier SSS:"
                            font.pixelSize: 10
                            color: theme.accentLogos
                        }

                        Text {
                            text: msgItem.tracingTag ? ("Tag #" + msgItem.tracingTag.substring(0, 8)) : "#00000000"
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: theme.textInteractive
                        }
                    }
                }
            }

            // Message Body Text
            Text {
                Layout.fillWidth: true
                text: msgItem.contentText
                font.pixelSize: 14
                color: theme.textNormal
                wrapMode: Text.Wrap
                lineHeight: 1.25
                visible: msgItem.contentText.length > 0
            }

            // Attached Media / File Card
            Rectangle {
                visible: msgItem.attachment !== null && msgItem.attachment !== undefined
                Layout.fillWidth: true
                Layout.maximumWidth: 380
                height: msgItem.attachment ? (msgItem.attachment.type === "image" ? 140 : 54) : 0
                radius: theme.radiusSmall
                color: theme.bgCard
                border.color: theme.borderSubtle
                border.width: 1
                clip: true

                // Image Preview Mode
                Item {
                    anchors.fill: parent
                    visible: msgItem.attachment && msgItem.attachment.type === "image"

                    Image {
                        anchors.fill: parent
                        source: msgItem.attachment ? msgItem.attachment.path : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        color: "#cc111214"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 6
                            Text { text: "📷"; font.pixelSize: 12 }
                            Text {
                                text: msgItem.attachment ? msgItem.attachment.name : ""
                                font.pixelSize: 10
                                color: theme.textHeader
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: msgItem.attachment ? msgItem.attachment.sizeText : ""
                                font.pixelSize: 9
                                color: theme.textMuted
                            }
                        }
                    }
                }

                // Document / Video Mode
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    visible: msgItem.attachment && msgItem.attachment.type !== "image"

                    Rectangle {
                        width: 34
                        height: 34
                        radius: theme.radiusSmall
                        color: theme.bgHover
                        Text {
                            anchors.centerIn: parent
                            text: msgItem.attachment ? (msgItem.attachment.type === "video" ? "🎥" : "📄") : "📄"
                            font.pixelSize: 18
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: msgItem.attachment ? msgItem.attachment.name : ""
                            font.bold: true
                            font.pixelSize: 12
                            color: theme.textHeader
                            elide: Text.ElideRight
                        }
                        Text {
                            text: msgItem.attachment ? (msgItem.attachment.sizeText + " • SHA-256 Verified") : ""
                            font.pixelSize: 10
                            color: theme.accentLogos
                        }
                    }
                }
            }
        }
    }

    // --- Floating Action Bar on Hover ---
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        height: 32
        radius: theme.radiusSmall
        color: theme.bgSidebar
        border.color: theme.borderSubtle
        border.width: 1
        visible: msgMouse.containsMouse

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 2

            // Quick Emoji Reaction
            Rectangle {
                width: 26
                height: 26
                radius: 3
                color: r1.containsMouse ? theme.bgHover : "transparent"
                Text { anchors.centerIn: parent; text: "👍"; font.pixelSize: 13 }
                MouseArea {
                    id: r1
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: msgItem.reactClicked("👍")
                }
                ToolTip.visible: r1.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "React 👍"
            }

            Rectangle {
                width: 26
                height: 26
                radius: 3
                color: r2.containsMouse ? theme.bgHover : "transparent"
                Text { anchors.centerIn: parent; text: "🚀"; font.pixelSize: 13 }
                MouseArea {
                    id: r2
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: msgItem.reactClicked("🚀")
                }
                ToolTip.visible: r2.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "React 🚀"
            }

            // Inspect SSS Share
            Rectangle {
                width: 26
                height: 26
                radius: 3
                color: inspMouse.containsMouse ? theme.bgHover : "transparent"
                Text { anchors.centerIn: parent; text: "🔍"; font.pixelSize: 12 }
                MouseArea {
                    id: inspMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: msgItem.inspectClicked(msgItem.tracingTag, msgItem.postPoint)
                }
                ToolTip.visible: inspMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "Inspect Two-Tier SSS Payload"
            }

            // Flag Post Button
            Rectangle {
                width: 26
                height: 26
                radius: 3
                color: flagMouse.containsMouse ? theme.accentDangerHover : "transparent"
                Text { anchors.centerIn: parent; text: "🚩"; font.pixelSize: 12 }
                MouseArea {
                    id: flagMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: msgItem.flagClicked(msgItem.author, msgItem.authorCommitment, msgItem.tracingTag, msgItem.contentText)
                }
                ToolTip.visible: flagMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "Flag Message (Trigger Moderator Review)"
            }
        }
    }
}
