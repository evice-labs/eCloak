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
    property var createdAt: 0
    property var currentTick: 0
    property string activeView: "room" // "room" or "dm"
    property string contentText: ""
    property string tracingTag: ""
    property bool isMod: false
    property bool isVerified: true
    property var postPoint: null
    property var attachment: null

    function formatDisplayTimestamp(rawTime, epochMs, tick) {
        if (!epochMs || epochMs <= 0) {
            if (rawTime && rawTime !== "Just now") {
                return rawTime;
            }
            return "Just now";
        }

        var now = (tick && tick > 0) ? tick : Date.now();
        var diffMs = Math.max(0, now - epochMs);
        var diffSec = Math.floor(diffMs / 1000);
        var diffMin = Math.floor(diffSec / 60);
        var diffHour = Math.floor(diffMin / 60);
        var diffDay = Math.floor(diffHour / 24);
        var diffWeek = Math.floor(diffDay / 7);
        var diffMonth = Math.floor(diffDay / 30);
        var diffYear = Math.floor(diffDay / 365);

        if (diffSec < 10) {
            return "Just now";
        } else if (diffSec < 60) {
            return diffSec + "s ago";
        } else if (diffMin < 60) {
            return diffMin + "m ago";
        } else if (diffHour < 24) {
            return diffHour + "h ago";
        } else if (diffDay < 7) {
            return (diffDay === 1) ? "Yesterday" : (diffDay + "d ago");
        } else if (diffWeek < 5) {
            return (diffWeek === 1) ? "1w ago" : (diffWeek + "w ago");
        } else if (diffMonth < 12) {
            return (diffMonth === 1) ? "1mo ago" : (diffMonth + "mo ago");
        } else {
            return (diffYear === 1) ? "1y ago" : (diffYear + "y ago");
        }
    }


    function cleanTracingTag() {
        if (!msgItem.tracingTag) return "";
        var tag = msgItem.tracingTag;
        if (/^[0-9a-fA-F]+$/.test(tag)) return tag;
        var hex = "";
        for (var i = 0; i < tag.length; i++) {
            var b = tag.charCodeAt(i) & 0xff;
            var hs = b.toString(16);
            hex += (hs.length === 1 ? "0" : "") + hs;
        }
        return hex;
    }

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
            color: ((msgItem.activeView === "room") && msgItem.isMod) ? theme.primaryHover : theme.primary

            Text {
                anchors.centerIn: parent
                text: msgItem.author.substring(0, 1).toUpperCase()
                font.bold: true
                font.pixelSize: 16
                color: "#ffffff"
            }
        }

        // Message Content & Meta
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Top Meta Row: Author, Role Badges, Timestamp, Subtle SSS Indicator
            RowLayout {
                spacing: 8

                Text {
                    text: msgItem.author
                    font.bold: true
                    font.pixelSize: 14
                    color: theme.textHeader
                }

                // Moderator Badge (Active only in room mode, never in DM)
                Rectangle {
                    visible: (msgItem.activeView === "room") && msgItem.isMod
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

                Text {
                    id: timeText
                    text: msgItem.formatDisplayTimestamp(msgItem.timestamp, msgItem.createdAt, msgItem.currentTick)
                    font.pixelSize: 11
                    color: timeHover.containsMouse ? theme.textNormal : theme.textMuted

                    MouseArea {
                        id: timeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    ToolTip.visible: timeHover.containsMouse
                    ToolTip.delay: 250
                    ToolTip.text: msgItem.createdAt > 0 ?
                        Qt.formatDateTime(new Date(msgItem.createdAt), "dddd, MMMM d, yyyy • hh:mm:ss AP") :
                        (msgItem.timestamp || "Just now")
                }


                // Minimalist Cryptographic SSS Badge (Subtle pill, only in room mode with tracing tag)
                Rectangle {
                    visible: (msgItem.activeView === "room") && msgItem.tracingTag !== ""
                    height: 16
                    width: tagLabel.implicitWidth + 10
                    radius: 4
                    color: tagMouse.containsMouse ? theme.bgHover : theme.bgCard
                    border.color: tagMouse.containsMouse ? theme.primary : theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        id: tagLabel
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            text: "🔒"
                            font.pixelSize: 9
                        }

                        Text {
                            text: "#" + (msgItem.cleanTracingTag().length >= 8 ? msgItem.cleanTracingTag().substring(0, 8) : msgItem.cleanTracingTag())
                            font.pixelSize: 9
                            font.family: "monospace"
                            color: theme.primary
                        }
                    }

                    MouseArea {
                        id: tagMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: msgItem.inspectClicked(msgItem.cleanTracingTag(), msgItem.postPoint)
                    }

                    ToolTip.visible: tagMouse.containsMouse
                    ToolTip.delay: 300
                    ToolTip.text: "Two-Tier SSS Tracing Tag:\n#" + msgItem.cleanTracingTag() + "\n\nClick to inspect cryptographic share"
                }

                Item { Layout.fillWidth: true }
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
                        source: msgItem.attachment ? (msgItem.attachment.path ? msgItem.attachment.path : (msgItem.attachment.localPath ? ("file://" + msgItem.attachment.localPath) : "")) : ""
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
                    onClicked: msgItem.inspectClicked(msgItem.cleanTracingTag(), msgItem.postPoint)
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
                    onClicked: msgItem.flagClicked(msgItem.author, msgItem.authorCommitment, msgItem.cleanTracingTag(), msgItem.contentText)
                }
                ToolTip.visible: flagMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "Flag Message (Trigger Moderator Review)"
            }
        }
    }
}
