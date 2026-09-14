import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: modal
    width: 480
    height: modal.mVal === 1 ? 470 : 540
    modal: true
    anchors.centerIn: parent
    padding: 24

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    property string adminCommitment: ""
    property string creatorUsername: ""
    property var knownUsers: []
    property bool isIdentityReady: adminCommitment.length > 0

    property int selectedPreset: 0 // 0: 2 of 3, 1: 1 of 1, 2: 3 of 5, 3: Custom
    property int nVal: 2
    property int mVal: 3
    property var extraMods: []

    readonly property int totalSelectedMods: 1 + extraMods.length
    readonly property bool isQuorumMet: totalSelectedMods >= mVal

    signal roomCreated(string name, int nThreshold, int mTotal, string modKeysJson, int minMembers)

    Theme { id: theme }

    background: Rectangle {
        color: theme.bgCard
        radius: theme.radiusSquircle
        border.color: theme.borderCard
        border.width: 1
    }

    // Compile valid JSON array of public keys/commitments
    function compileModKeys() {
        var keys = [];

        // 1. First key is ALWAYS the creator / owner
        if (modal.adminCommitment && modal.adminCommitment.length > 0) {
            keys.push(modal.adminCommitment);
        } else {
            keys.push("02e4f82a1b9c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789");
        }

        // 2. Extra moderators added by the user
        for (var i = 0; i < modal.extraMods.length; i++) {
            var c = modal.extraMods[i].commitment;
            if (c && keys.indexOf(c) === -1) {
                keys.push(c);
            }
        }

        return JSON.stringify(keys.slice(0, modal.mVal));
    }

    onOpened: {
        nameField.text = "Logos Anonymous Lounge";
        modal.selectedPreset = 0;
        modal.nVal = 2;
        modal.mVal = 3;
        modal.extraMods = [];
        if (addModInput) addModInput.text = "";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // 1. Sleek Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Create Room"
                font.family: theme.fontFamily
                font.bold: true
                font.pixelSize: 17
                color: theme.textHeader
            }
        }

        // Subtle Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.divider
        }

        // 2. Room Name Input
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Room Name"
                font.family: theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: theme.textMuted
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "e.g. ZK Research Lounge"
                placeholderTextColor: theme.textMuted
                color: theme.textHeader
                font.family: theme.fontFamily
                font.pixelSize: 13
                text: "Logos Anonymous Lounge"
                selectByMouse: true
                leftPadding: 12
                rightPadding: 12
                background: Rectangle {
                    color: theme.bgCardInner
                    radius: theme.radiusSmall
                    border.color: nameField.activeFocus ? theme.accentBlurple : theme.borderCard
                    border.width: 1
                }
            }
        }

        // 3. Governance Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Governance"
                    font.family: theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.textMuted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Consensus: " + modal.nVal + " of " + modal.mVal + " signatures"
                    font.family: theme.fontFamilyMono
                    font.pixelSize: 10
                    color: theme.accentLogos
                }
            }

            // Preset Pills (Single clean row, no sub-labels)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { label: "2 of 3", n: 2, m: 3 },
                        { label: "1 of 1", n: 1, m: 1 },
                        { label: "3 of 5", n: 3, m: 5 },
                        { label: "Custom", n: modal.nVal, m: modal.mVal }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: theme.radiusSmall
                        property bool isSelected: modal.selectedPreset === index
                        color: isSelected ? theme.bgActive : (pillMouse.containsMouse ? theme.bgHover : theme.bgCardInner)
                        border.color: isSelected ? theme.accentBlurple : theme.borderCard
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 12
                            color: isSelected ? theme.accentBlurple : theme.textHeader
                        }

                        MouseArea {
                            id: pillMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                modal.selectedPreset = index;
                                if (index === 0) { modal.nVal = 2; modal.mVal = 3; }
                                else if (index === 1) { modal.nVal = 1; modal.mVal = 1; }
                                else if (index === 2) { modal.nVal = 3; modal.mVal = 5; }
                            }
                        }
                    }
                }
            }

            // Compact Custom Stepper (Visible only if Custom selected)
            RowLayout {
                Layout.fillWidth: true
                visible: modal.selectedPreset === 3
                spacing: 16

                RowLayout {
                    spacing: 6
                    Text { text: "Threshold (N):"; font.family: theme.fontFamily; font.pixelSize: 11; color: theme.textMuted }
                    Rectangle {
                        width: 24; height: 22; radius: 3; color: theme.bgCardInner; border.color: theme.borderCard; border.width: 1
                        Text { anchors.centerIn: parent; text: "-"; font.bold: true; color: theme.textHeader }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (modal.nVal > 1) modal.nVal-- }
                    }
                    Text { text: modal.nVal.toString(); font.bold: true; font.pixelSize: 12; color: theme.accentLogos }
                    Rectangle {
                        width: 24; height: 22; radius: 3; color: theme.bgCardInner; border.color: theme.borderCard; border.width: 1
                        Text { anchors.centerIn: parent; text: "+"; font.bold: true; color: theme.textHeader }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (modal.nVal < modal.mVal) modal.nVal++ }
                    }
                }

                RowLayout {
                    spacing: 6
                    Text { text: "Total Mods (M):"; font.family: theme.fontFamily; font.pixelSize: 11; color: theme.textMuted }
                    Rectangle {
                        width: 24; height: 22; radius: 3; color: theme.bgCardInner; border.color: theme.borderCard; border.width: 1
                        Text { anchors.centerIn: parent; text: "-"; font.bold: true; color: theme.textHeader }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modal.mVal > 1) {
                                    modal.mVal--;
                                    if (modal.nVal > modal.mVal) modal.nVal = modal.mVal;
                                }
                            }
                        }
                    }
                    Text { text: modal.mVal.toString(); font.bold: true; font.pixelSize: 12; color: theme.accentBlurple }
                    Rectangle {
                        width: 24; height: 22; radius: 3; color: theme.bgCardInner; border.color: theme.borderCard; border.width: 1
                        Text { anchors.centerIn: parent; text: "+"; font.bold: true; color: theme.textHeader }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (modal.mVal < 7) modal.mVal++ }
                    }
                }
            }
        }

        // 4. Moderators Section (with Quorum Validation)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Moderators (" + modal.totalSelectedMods + "/" + modal.mVal + ")"
                    font.family: theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.textMuted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: modal.isQuorumMet ? "✔ Quorum Complete" : ("Requires " + (modal.mVal - modal.totalSelectedMods) + " more")
                    font.family: theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: modal.isQuorumMet ? theme.accentSuccess : theme.accentWarning
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: modal.mVal === 1 ? 44 : 84
                radius: theme.radiusSmall
                color: theme.bgCardInner
                border.color: theme.borderCard
                border.width: 1
                clip: true

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 4
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        // Card 1: Creator (Automatically set as Lead Moderator)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: theme.radiusSmall
                            color: theme.bgHover

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: theme.accentLogos
                                    Text {
                                        anchors.centerIn: parent
                                        text: modal.creatorUsername ? modal.creatorUsername.substring(0, 1).toUpperCase() : "Y"
                                        font.family: theme.fontFamily
                                        font.bold: true
                                        font.pixelSize: 10
                                        color: "#12151c"
                                    }
                                }

                                Text {
                                    text: (modal.creatorUsername || "You") + " (Creator)"
                                    font.family: theme.fontFamily
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: theme.textHeader
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: modal.adminCommitment ?
                                        (modal.adminCommitment.substring(0, 8) + "..." + modal.adminCommitment.substring(modal.adminCommitment.length - 6)) :
                                        "Pending ZK ID"
                                    font.family: theme.fontFamilyMono
                                    font.pixelSize: 9
                                    color: theme.accentLogos
                                }

                                Rectangle {
                                    height: 16
                                    width: 44
                                    radius: 3
                                    color: "#153026"
                                    border.color: theme.accentLogos
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "OWNER"
                                        font.family: theme.fontFamily
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: theme.accentLogos
                                    }
                                }
                            }
                        }

                        // Additional invited moderators
                        Repeater {
                            model: modal.extraMods

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: theme.radiusSmall
                                color: theme.bgCard

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: theme.accentBlurple
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.username ? modelData.username.substring(0, 1).toUpperCase() : "M"
                                            font.family: theme.fontFamily
                                            font.bold: true
                                            font.pixelSize: 10
                                            color: "#ffffff"
                                        }
                                    }

                                    Text {
                                        text: "@" + modelData.username
                                        font.family: theme.fontFamily
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: theme.textHeader
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: modelData.commitment ?
                                            (modelData.commitment.substring(0, 8) + "..." + modelData.commitment.substring(modelData.commitment.length - 6)) : ""
                                        font.family: theme.fontFamilyMono
                                        font.pixelSize: 9
                                        color: theme.textMuted
                                    }

                                    // Remove button
                                    Text {
                                        text: "✕"
                                        font.pixelSize: 11
                                        color: delMouse.containsMouse ? theme.accentDanger : theme.textMuted
                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var updated = modal.extraMods.slice();
                                                updated.splice(index, 1);
                                                modal.extraMods = updated;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Quick Add Moderator Bar (Visible only if Quorum is NOT yet met)
            ColumnLayout {
                Layout.fillWidth: true
                visible: !modal.isQuorumMet
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    TextField {
                        id: addModInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        placeholderText: "Add moderator by @username or 0x commitment..."
                        placeholderTextColor: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        color: theme.textHeader
                        leftPadding: 10
                        rightPadding: 10
                        background: Rectangle {
                            color: theme.bgCardInner
                            radius: theme.radiusSmall
                            border.color: addModInput.activeFocus ? theme.accentBlurple : theme.borderCard
                            border.width: 1
                        }
                        Keys.onReturnPressed: addModBtn.clicked()
                    }

                    Button {
                        id: addModBtn
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 30
                        enabled: addModInput.text.trim().length > 0
                        contentItem: Text {
                            text: "+ Add"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: parent.enabled ? "#ffffff" : theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.enabled ? theme.accentBlurple : theme.bgHover
                            radius: theme.radiusSmall
                        }
                        onClicked: {
                            var val = addModInput.text.trim().replace("@", "");
                            if (val.length === 0) return;
                            var comm = "";
                            if (modal.knownUsers) {
                                for (var i = 0; i < modal.knownUsers.length; i++) {
                                    if (modal.knownUsers[i].username && modal.knownUsers[i].username.toLowerCase() === val.toLowerCase()) {
                                        comm = modal.knownUsers[i].commitment;
                                        break;
                                    }
                                }
                            }
                            if (!comm) {
                                if (val.length >= 32) comm = val;
                                else comm = "03" + Qt.md5(val) + Qt.md5(val + "_salt");
                            }
                            var updated = modal.extraMods.slice();
                            updated.push({ username: val, commitment: comm });
                            modal.extraMods = updated;
                            addModInput.text = "";
                        }
                    }
                }

                // Suggested Peers Quick-Add Chips (1-click to complete quorum)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Suggested:"
                        font.family: theme.fontFamily
                        font.pixelSize: 10
                        color: theme.textMuted
                    }

                    Repeater {
                        model: [
                            { username: "Satoshi99", commitment: "0x7f8a9b1c2d3e4f5061728394a5b6c7d8e9f0123456789abcdef0123456789abc" },
                            { username: "Alice_ZK", commitment: "0x4b5c6d7e8f90123456789abcdef0123456789abc7f8a9b1c2d3e4f506172839" },
                            { username: "Bob_Anon", commitment: "0x123456789abcdef0123456789abc7f8a9b1c2d3e4f5061728394b5c6d7e8f90" }
                        ]

                        Rectangle {
                            height: 20
                            width: sugTxt.implicitWidth + 14
                            radius: 10
                            color: sugMouse.containsMouse ? theme.bgActive : theme.bgCardInner
                            border.color: theme.borderCard
                            border.width: 1

                            // Hide if already in extraMods
                            property bool isAdded: {
                                for (var k = 0; k < modal.extraMods.length; k++) {
                                    if (modal.extraMods[k].username === modelData.username) return true;
                                }
                                return false;
                            }
                            visible: !isAdded && !modal.isQuorumMet

                            Text {
                                id: sugTxt
                                anchors.centerIn: parent
                                text: "+ @" + modelData.username
                                font.family: theme.fontFamily
                                font.pixelSize: 9
                                color: sugMouse.containsMouse ? theme.accentBlurple : theme.textMuted
                            }

                            MouseArea {
                                id: sugMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var updated = modal.extraMods.slice();
                                    updated.push({ username: modelData.username, commitment: modelData.commitment });
                                    modal.extraMods = updated;
                                }
                            }
                        }
                    }
                }
            }
        }

        // 5. Subtle Sybil Guard Note
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "🛡️"; font.pixelSize: 11 }
            Text {
                text: "Sybil Guard: New rooms enter an initial accountability probation on the LEZ network."
                font.family: theme.fontFamily
                font.pixelSize: 10
                color: theme.textMuted
                Layout.fillWidth: true
            }
        }

        Item { Layout.fillHeight: true }

        // 6. Footer Action Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                Layout.preferredWidth: 80
                Layout.preferredHeight: 32
                contentItem: Text {
                    text: "Cancel"
                    font.family: theme.fontFamily
                    font.pixelSize: 12
                    color: cancelMouse.containsMouse ? theme.textHeader : theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: cancelMouse.containsMouse ? theme.bgHover : "transparent"
                    radius: theme.radiusSmall
                }
                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modal.reject()
                }
            }

            Button {
                text: "Create Room"
                Layout.preferredWidth: 120
                Layout.preferredHeight: 32
                enabled: modal.isIdentityReady && nameField.text.trim().length > 0 && modal.isQuorumMet
                contentItem: Text {
                    text: !modal.isIdentityReady ? "🔒 ID Required" :
                          (nameField.text.trim().length === 0 ? "Name Required" :
                          (!modal.isQuorumMet ? ("Add " + (modal.mVal - modal.totalSelectedMods) + " Mod" + ((modal.mVal - modal.totalSelectedMods) > 1 ? "s" : "")) : "Create Room"))
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 12
                    color: parent.enabled ? "#ffffff" : theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.enabled ? theme.accentBlurple : theme.bgHover
                    radius: theme.radiusSmall
                }
                onClicked: {
                    var jsonKeys = modal.compileModKeys();
                    modal.roomCreated(
                        nameField.text.trim(),
                        modal.nVal,
                        modal.mVal,
                        jsonKeys,
                        10
                    );
                    modal.accept();
                }
            }
        }
    }
}
