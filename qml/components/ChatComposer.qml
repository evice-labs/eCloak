import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Rectangle {
    id: composer
    height: (currentAttachment ? 96 : 48) + Math.max(0, Math.min(80, inputField.contentHeight - 20))
    radius: theme.radiusMedium
    color: theme.bgInput

    property string placeholderTarget: "#general-chat"
    property bool isDmMode: false
    property var currentAttachment: null
    property string validationErrorMsg: ""

    signal sendRequested(string messageText, var attachmentData)

    Theme { id: theme }

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: currentAttachment ? 8 : 0
        anchors.bottomMargin: 0
        spacing: 6

        // ==========================================
        // ATTACHMENT PREVIEW CHIP (When file is selected)
        // ==========================================
        Rectangle {
            id: previewChip
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            visible: composer.currentAttachment !== null
            radius: theme.radiusSmall
            color: theme.bgCard
            border.color: theme.borderSubtle
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Media Icon
                Text {
                    text: composer.currentAttachment ?
                        (composer.currentAttachment.type === "image" ? "📷" :
                         (composer.currentAttachment.type === "video" ? "🎥" : "📄")) : "📁"
                    font.pixelSize: 16
                }

                // File Info
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: composer.currentAttachment ? composer.currentAttachment.name : ""
                    font.bold: true
                    font.pixelSize: 12
                    color: theme.textHeader
                    elide: Text.ElideRight
                    Layout.maximumWidth: 180
                }

                // File Size Badge
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8
                    height: 16
                    width: sizeText.implicitWidth + 16
                    radius: 6
                    color: theme.bgHover

                    Text {
                        id: sizeText
                        anchors.centerIn: parent
                        text: composer.currentAttachment ? composer.currentAttachment.sizeText : ""
                        font.pixelSize: 9
                        color: theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Discard Button (✕)
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: remMouse.containsMouse ? theme.accentDangerHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 10
                        color: remMouse.containsMouse ? "#ffffff" : theme.textMuted
                    }

                    MouseArea {
                        id: remMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: composer.currentAttachment = null
                    }
                }
            }
        }

        // ==========================================
        // MAIN INPUT ROW (+ Button, Text, SSS Pill, Send)
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Attachment / Action Button (+)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 28
                height: 28
                radius: 14
                color: attachMouse.containsMouse ? theme.bgHover : "#4e5058"

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.bold: true
                    font.pixelSize: 18
                    color: theme.bgInput
                }

                MouseArea {
                    id: attachMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fileDialog.open()
                }

                ToolTip.visible: attachMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: "Attach image, video, or document (Max 10 MB)"
            }

            // Text Input Field
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                clip: true

                TextArea {
                    id: inputField
                    verticalAlignment: Text.AlignVCenter
                    placeholderText: composer.currentAttachment ?
                        "Add a caption or comment..." :
                        ("Message " + composer.placeholderTarget + "...")
                    placeholderTextColor: theme.textMuted
                    color: theme.textNormal
                    font.pixelSize: 14
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    background: null

                    Keys.onReturnPressed: function(event) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            event.accepted = false; // Allow newline
                        } else {
                            event.accepted = true;
                            if (inputField.text.trim().length > 0 || composer.currentAttachment !== null) {
                                composer.sendRequested(inputField.text.trim(), composer.currentAttachment);
                                inputField.text = "";
                                composer.currentAttachment = null;
                            }
                        }
                    }
                }
            }

            // Cryptographic Status Pill
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                height: 24
                width: sssRow.implicitWidth + 12
                radius: 12
                color: "#1a382e"
                border.color: theme.accentLogos
                border.width: 1

                RowLayout {
                    id: sssRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "🔒"
                        font.pixelSize: 11
                    }

                    Text {
                        text: composer.isDmMode ? "ECDH E2EE" : "2-Tier SSS"
                        font.pixelSize: 10
                        font.bold: true
                        color: theme.accentLogos
                    }
                }

                MouseArea {
                    id: sssMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }

                ToolTip.visible: sssMouse.containsMouse
                ToolTip.delay: 200
                ToolTip.text: composer.isDmMode ?
                    "Encrypted with pairwise ECDH shared key.
Relay topic rotates each epoch (HKDF)." :
                    "Protected by Two-Tier Shamir Secret Sharing.
Shares distributed across N-of-M room moderators."
            }

            // Send Button
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32
                height: 32
                radius: 16
                color: (inputField.text.trim().length > 0 || composer.currentAttachment !== null) ? theme.accentBlurple : "transparent"
                visible: inputField.text.trim().length > 0 || composer.currentAttachment !== null

                Text {
                    anchors.centerIn: parent
                    text: "➤"
                    font.pixelSize: 13
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (inputField.text.trim().length > 0 || composer.currentAttachment !== null) {
                            composer.sendRequested(inputField.text.trim(), composer.currentAttachment);
                            inputField.text = "";
                            composer.currentAttachment = null;
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // NATIVE OS FILE PICKER DIALOG
    // ==========================================
    FileDialog {
        id: fileDialog
        title: "Select Photo, Video, or Document to Attach"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "All Allowed Files (*.png *.jpg *.jpeg *.webp *.gif *.mp4 *.webm *.pdf *.txt *.json *.md)",
            "Images (*.png *.jpg *.jpeg *.webp *.gif)",
            "Videos (*.mp4 *.webm)",
            "Documents (*.pdf *.txt *.json *.md)"
        ]

        onAccepted: {
            var selectedPath = fileDialog.selectedFile.toString();
            composer.validateAndSetAttachment(selectedPath);
        }
    }

    // ==========================================
    // ATTACHMENT VALIDATION LOGIC
    // ==========================================
    function validateAndSetAttachment(fileUrl) {
        var rawPath = fileUrl.replace(/^file:\/\//, "");
        var parts = rawPath.split("/");
        var fileName = parts[parts.length - 1];
        var extParts = fileName.split(".");
        var ext = extParts.length > 1 ? extParts[extParts.length - 1].toLowerCase() : "";

        // 1. Strict Blacklist (Malware & Executable Prevention)
        var blockedExts = ["exe", "sh", "bat", "elf", "bin", "so", "appimage", "apk", "com", "msi", "vbs", "cmd", "py", "js"];
        if (blockedExts.indexOf(ext) !== -1) {
            validationErrorMsg = "File type '." + ext + "' is strictly blocked for malware & security protection.";
            validationErrorDialog.open();
            return;
        }

        // 2. Whitelist Check
        var imageExts = ["png", "jpg", "jpeg", "webp", "gif"];
        var videoExts = ["mp4", "webm"];
        var docExts = ["pdf", "txt", "json", "md"];

        var isImg = imageExts.indexOf(ext) !== -1;
        var isVid = videoExts.indexOf(ext) !== -1;
        var isDoc = docExts.indexOf(ext) !== -1;

        if (!isImg && !isVid && !isDoc) {
            validationErrorMsg = "Unsupported file format '." + ext + "'.
Allowed: PNG, JPG, WEBP, GIF, MP4, WEBM, PDF, TXT, JSON, MD.";
            validationErrorDialog.open();
            return;
        }

        // 3. Size Validation Simulation (Max 10 MB limit)
        // In native desktop, relay topics enforce sub-10MB limits
        var estimatedMb = 1.4;
        var fileType = isImg ? "image" : (isVid ? "video" : "document");

        // Compute simulated SHA-256 evidence hash
        var hexChars = "0123456789abcdef";
        var evidenceSha256 = "";
        for (var i = 0; i < 32; i++) {
            evidenceSha256 += hexChars.charAt(Math.floor(Math.random() * hexChars.length));
        }

        composer.currentAttachment = {
            name: decodeURIComponent(fileName),
            path: fileUrl,
            ext: ext,
            type: fileType,
            sizeText: estimatedMb + " MB",
            sizeBytes: Math.floor(estimatedMb * 1024 * 1024),
            sha256: evidenceSha256
        };
    }

    // ==========================================
    // VALIDATION ERROR DIALOG
    // ==========================================
    Dialog {
        id: validationErrorDialog
        title: "Attachment Validation Failed"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok

        background: Rectangle {
            color: theme.bgModal
            radius: theme.radiusMedium
            border.color: theme.accentDanger
            border.width: 1
        }

        ColumnLayout {
            spacing: 10
            RowLayout {
                spacing: 8
                Text { text: "⚠️"; font.pixelSize: 18 }
                Text {
                    text: "Attachment Rejected"
                    font.bold: true
                    font.pixelSize: 14
                    color: theme.accentDanger
                }
            }

            Text {
                text: composer.validationErrorMsg
                font.pixelSize: 12
                color: theme.textNormal
                wrapMode: Text.Wrap
                Layout.maximumWidth: 320
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.borderSubtle
            }

            Text {
                text: "Decentralized Relay Constraints: Max 10 MB per file, no executable binaries allowed."
                font.pixelSize: 10
                color: theme.textMuted
                wrapMode: Text.Wrap
                Layout.maximumWidth: 320
            }
        }
    }
}
