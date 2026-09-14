import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 530
    height: modal.collateralAmount < 150 ? 470 : 410
    modal: true
    anchors.centerIn: parent
    padding: 20

    Behavior on height {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    property string commitmentHex: ""
    property string nskHex: ""
    property string currentUsername: ""
    property bool isRevealed: false
    property int blockHeight: 0
    property int collateralAmount: 0
    property bool isLezConnected: false
    property string validationMessage: ""
    property bool isValidationError: false
    property string usernameStatus: "idle" // "idle", "checking", "available", "taken"
    property bool waitingForManualStake: false

    property bool commCopied: false
    property bool nskCopied: false

    Timer {
        id: checkTimer
        interval: 350
        property string valToSave: ""
        onTriggered: {
            modal.updateUsernameRequested(valToSave);
        }
    }

    Timer {
        id: copyCommTimer
        interval: 1800
        onTriggered: modal.commCopied = false
    }

    Timer {
        id: copyNskTimer
        interval: 1800
        onTriggered: modal.nskCopied = false
    }

    onOpened: {
        userField.text = modal.currentUsername;
        modal.validationMessage = "";
        modal.usernameStatus = "idle";
        modal.waitingForManualStake = false;
        modal.isRevealed = false;
        modal.commCopied = false;
        modal.nskCopied = false;
    }

    onCurrentUsernameChanged: {
        if (!userField.activeFocus) {
            userField.text = modal.currentUsername;
            modal.usernameStatus = "idle";
        }
    }

    signal updateUsernameRequested(string newUsername)
    signal stakeViaWalletRequested(int amount, string commitment)
    signal confirmStakeRequested(int amount)

    Theme { id: theme }

    TextInput {
        id: clipHelper
        visible: false
    }

    background: Rectangle {
        color: theme.bgCard
        radius: theme.radiusSquircle
        border.color: theme.borderCard
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // 1. Sleek Minimalist Header: Profile Icon & Synchronized Username
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: theme.accentLogos

                Text {
                    anchors.centerIn: parent
                    text: modal.currentUsername ? modal.currentUsername.substring(0, 1).toUpperCase() : "A"
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 16
                    color: "#12151c"
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: modal.currentUsername || "Anonymous"
                font.family: theme.fontFamily
                font.bold: true
                font.pixelSize: 16
                color: theme.textHeader
                elide: Text.ElideRight
            }
        }

        // Subtle Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.divider
        }

        // 2. Username Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Username"
                font.family: theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: theme.radiusMedium
                color: theme.bgCardInner
                border.color: modal.usernameStatus === "taken" ? theme.accentDanger : (modal.usernameStatus === "available" ? theme.accentSuccess : (userField.activeFocus ? theme.accentBlurple : theme.borderCard))
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6

                    Text {
                        text: "@"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    TextInput {
                        id: userField
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: modal.currentUsername
                        color: theme.textHeader
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onTextChanged: {
                            if (modal.usernameStatus !== "idle" && text.trim() !== modal.currentUsername) {
                                modal.usernameStatus = "idle";
                                modal.validationMessage = "";
                            }
                        }
                        Keys.onReturnPressed: {
                            if (saveBtnArea.enabled) {
                                triggerSave();
                            }
                        }
                    }

                    // Trailing Inline Status Indicator
                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4
                        visible: modal.usernameStatus !== "idle"

                        // Spinner (Checking)
                        Canvas {
                            id: spinnerCanvas
                            width: 14
                            height: 14
                            visible: modal.usernameStatus === "checking"
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = theme.accentLogos;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.arc(7, 7, 5, 0, 1.5 * Math.PI);
                                ctx.stroke();
                            }
                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 750
                                loops: Animation.Infinite
                                running: modal.usernameStatus === "checking"
                            }
                        }

                        // Checkmark (Available)
                        Text {
                            visible: modal.usernameStatus === "available"
                            text: "✔"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 12
                            color: theme.accentSuccess
                        }

                        // Exclamation (Taken)
                        RowLayout {
                            visible: modal.usernameStatus === "taken"
                            spacing: 3

                            Text {
                                text: "⚠"
                                font.family: theme.fontFamily
                                font.pixelSize: 11
                                color: theme.accentDanger
                            }

                            Text {
                                text: modal.validationMessage || "username taken"
                                font.family: theme.fontFamily
                                font.pixelSize: 11
                                color: theme.accentDanger
                            }
                        }
                    }

                    // Uniform Fixed-Size Save Button (64x28)
                    Rectangle {
                        id: saveBtn
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 28
                        radius: theme.radiusSmall
                        color: userField.text.trim() !== modal.currentUsername ? theme.accentBlurple : (saveBtnArea.containsMouse ? theme.bgCardHover : "transparent")
                        border.color: userField.text.trim() !== modal.currentUsername ? "transparent" : theme.borderCard
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: userField.text.trim() !== modal.currentUsername ? "#ffffff" : theme.textMuted
                        }

                        MouseArea {
                            id: saveBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: triggerSave()
                        }
                    }
                }
            }
        }

        function triggerSave() {
            var val = userField.text.trim();
            if (val.length === 0) {
                modal.usernameStatus = "taken";
                modal.validationMessage = "empty";
                return;
            }
            if (!modal.commitmentHex || modal.commitmentHex.length < 32) {
                modal.usernameStatus = "taken";
                modal.validationMessage = "no identity";
                return;
            }
            modal.usernameStatus = "checking";
            modal.validationMessage = "";
            checkTimer.valToSave = val;
            checkTimer.restart();
        }

        // 3. Public Identity Card (No ZK Icon, Full Hex String Without Truncation)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Public Identity"
                font.family: theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: theme.radiusMedium
                color: theme.bgCardInner
                border.color: theme.borderCard
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: modal.commitmentHex || "0x0000000000000000000000000000000000000000000000000000000000000000"
                        color: theme.textHeader
                        font.family: theme.fontFamilyMono
                        font.pixelSize: 10
                        elide: Text.None
                    }

                    // Uniform Fixed-Size Copy Button (64x28)
                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 28
                        radius: theme.radiusSmall
                        color: copyCommMouse.containsMouse ? theme.bgCardHover : "transparent"
                        border.color: modal.commCopied ? theme.accentSuccess : theme.borderCard
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modal.commCopied ? "✔ Copied" : "Copy"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: modal.commCopied ? theme.accentSuccess : theme.textInteractive
                        }

                        MouseArea {
                            id: copyCommMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modal.commitmentHex && modal.commitmentHex.length > 0) {
                                    clipHelper.text = modal.commitmentHex;
                                    clipHelper.selectAll();
                                    clipHelper.copy();
                                    modal.commCopied = true;
                                    copyCommTimer.restart();
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. Security & Backup (NSK in-place transition, no extra row created)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Security & Backup"
                font.family: theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: theme.radiusMedium
                color: theme.bgCardInner
                border.color: theme.borderCard
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 8

                    // In-place text transition: shows "🔒  Private Secret Key (NSK)" when hidden, underlined full NSK string with inline copied feedback when revealed
                    Text {
                        id: nskDisplayText
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: modal.nskCopied ? "✔ Copied!" : (modal.isRevealed ?
                            (modal.nskHex || "Not generated") :
                            "🔒  Private Secret Key (NSK)")
                        color: modal.nskCopied ? theme.accentSuccess : (nskMouse.containsMouse && modal.isRevealed ? theme.accentLogos : (modal.isRevealed ? theme.textHeader : theme.textNormal))
                        font.family: (modal.isRevealed && !modal.nskCopied) ? theme.fontFamilyMono : theme.fontFamily
                        font.pixelSize: (modal.isRevealed && !modal.nskCopied) ? 10 : 12
                        font.weight: modal.isRevealed ? Font.Normal : Font.Medium
                        font.underline: modal.isRevealed && !modal.nskCopied
                        elide: Text.None

                        MouseArea {
                            id: nskMouse
                            anchors.fill: parent
                            enabled: modal.isRevealed
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (modal.nskHex && modal.nskHex.length > 0) {
                                    clipHelper.text = modal.nskHex;
                                    clipHelper.selectAll();
                                    clipHelper.copy();
                                    modal.nskCopied = true;
                                    copyNskTimer.restart();
                                }
                            }
                        }
                    }

                    // Uniform Fixed-Size Reveal / Hide Button (64x28)
                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 28
                        radius: theme.radiusSmall
                        color: toggleNskMouse.containsMouse ? theme.bgCardHover : "transparent"
                        border.color: theme.borderCard
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modal.isRevealed ? "Hide" : "Reveal"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: modal.isRevealed ? theme.textMuted : theme.textInteractive
                        }

                        MouseArea {
                            id: toggleNskMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modal.isRevealed = !modal.isRevealed
                        }
                    }
                }
            }
        }

        // 5. Staking Action (Only displayed if collateral < 150)
        ColumnLayout {
            Layout.fillWidth: true
            visible: modal.collateralAmount < 150
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: theme.radiusMedium
                color: "#23241b"
                border.color: "#3d3a24"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Stake 150 LEZ to participate in chat."
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        color: theme.accentWarning
                    }

                    Button {
                        visible: !modal.waitingForManualStake
                        Layout.preferredHeight: 28
                        contentItem: Text {
                            text: "Stake 150 LEZ"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: "#12151c"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.accentLogos
                            radius: theme.radiusSmall
                        }
                        onClicked: {
                            modal.validationMessage = "Requesting 150 LEZ stake...";
                            modal.isValidationError = false;
                            modal.waitingForManualStake = true;
                            modal.stakeViaWalletRequested(150, modal.commitmentHex);
                        }
                    }

                    Button {
                        visible: modal.waitingForManualStake
                        Layout.preferredHeight: 28
                        contentItem: Text {
                            text: "✔ Confirm Staked"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.accentSuccess
                            radius: theme.radiusSmall
                        }
                        onClicked: {
                            modal.validationMessage = "Confirmed 150 LEZ collateral active.";
                            modal.isValidationError = false;
                            modal.waitingForManualStake = false;
                            modal.confirmStakeRequested(150);
                        }
                    }

                    Button {
                        visible: modal.waitingForManualStake
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 28
                        contentItem: Text {
                            text: "Cancel"
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            color: theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: "transparent"
                            border.color: theme.borderCard
                            border.width: 1
                            radius: theme.radiusSmall
                        }
                        onClicked: {
                            modal.waitingForManualStake = false;
                            modal.validationMessage = "";
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // 6. Bottom Action Bar: Done Button (Comfortably inside the modal card)
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item { Layout.fillWidth: true }

            Button {
                text: "Done"
                Layout.preferredWidth: 80
                Layout.preferredHeight: 32
                contentItem: Text {
                    text: "Done"
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 12
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: theme.accentBlurple
                    radius: theme.radiusSmall
                }
                onClicked: {
                    var val = userField.text.trim();
                    if (val.length === 0) {
                        modal.validationMessage = "Username cannot be empty";
                        modal.usernameStatus = "taken";
                        return;
                    }
                    if (val !== modal.currentUsername) {
                        modal.updateUsernameRequested(val);
                    }
                    modal.accept();
                }
            }
        }
    }
}
