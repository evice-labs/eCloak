import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar
    width: 240
    color: theme.bgSidebar

    property string activeView: "room" // "room" or "dm"
    property string activeRoomName: "General Room"
    property string activeRoomId: ""
    property bool isRoomMature: true
    property string activeChannel: "general-chat"
    property string activeDmUser: ""
    property var dmsModel: []
    property var knownUsersModel: []
    property var matchingUsersList: []
    property bool isSearching: false

    signal channelSelected(string channelName)
    signal dmSelected(string targetUsername)
    signal copyRoomIdRequested(string roomId)
    signal leaveRoomRequested(string roomId)

    Theme { id: theme }

    function getAllKnownUsers() {
        var res = [];
        var map = {};

        function pushUser(u, c) {
            if (!u || u.trim().length === 0) return;
            u = u.trim();
            var k = u.toLowerCase();
            if (!map[k]) {
                map[k] = true;
                res.push({ username: u, commitment: c || "" });
            } else if (c && c.length > 0) {
                for (var i = 0; i < res.length; i++) {
                    if (res[i].username.toLowerCase() === k && !res[i].commitment) {
                        res[i].commitment = c;
                        break;
                    }
                }
            }
        }

        if (sidebar.knownUsersModel && sidebar.knownUsersModel.length) {
            for (var i = 0; i < sidebar.knownUsersModel.length; i++) {
                pushUser(sidebar.knownUsersModel[i].username, sidebar.knownUsersModel[i].commitment);
            }
        }

        if (sidebar.dmsModel && sidebar.dmsModel.length) {
            for (var j = 0; j < sidebar.dmsModel.length; j++) {
                pushUser(sidebar.dmsModel[j].username, sidebar.dmsModel[j].commitment);
            }
        }

        // Default known network peers
        pushUser("Satoshi99", "0x7f8a9b1c2d3e4f5061728394a5b6c7d8e9f0123456789abcdef0123456789abc");
        pushUser("Alice_ZK", "0x4b5c6d7e8f90123456789abcdef0123456789abc7f8a9b1c2d3e4f506172839");
        pushUser("Bob_Anon", "0x123456789abcdef0123456789abc7f8a9b1c2d3e4f5061728394b5c6d7e8f90");
        pushUser("Vitalik_Echo", "0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba");

        return res;
    }

    function performUserSearch(keyword) {
        if (!keyword || keyword.trim().length === 0) {
            sidebar.matchingUsersList = [];
            sidebar.isSearching = false;
            return;
        }
        var q = keyword.trim().toLowerCase();
        if (q.startsWith("@")) q = q.substring(1);

        var all = getAllKnownUsers();
        var results = [];

        for (var i = 0; i < all.length; i++) {
            var user = all[i];
            var uName = (user.username || "").toLowerCase();
            var uComm = (user.commitment || "").toLowerCase();

            // Anti-Spam & Anti-Enumeration: Exact match on username or high-entropy commitment match (>= 10 chars)
            var matchUsername = (uName === q);
            var matchCommitment = (q.length >= 10 && uComm.indexOf(q) !== -1);

            if (matchUsername || matchCommitment) {
                results.push(user);
            }
        }

        sidebar.matchingUsersList = results;
        sidebar.isSearching = (results.length > 0);
    }

    function selectFirstOrTypedUser() {
        var q = searchInput.text.trim();
        if (!q || q.length === 0) return;
        if (q.startsWith("@")) q = q.substring(1);

        if (sidebar.matchingUsersList && sidebar.matchingUsersList.length > 0) {
            sidebar.dmSelected(sidebar.matchingUsersList[0].username);
            searchInput.text = "";
            sidebar.matchingUsersList = [];
            sidebar.isSearching = false;
        } else {
            // Anti-Spam check: only start DM if exact username or valid commitment is found
            var all = getAllKnownUsers();
            var found = null;
            for (var i = 0; i < all.length; i++) {
                if (all[i].username.toLowerCase() === q.toLowerCase() || (q.length >= 10 && all[i].commitment.toLowerCase().indexOf(q.toLowerCase()) !== -1)) {
                    found = all[i];
                    break;
                }
            }
            if (found) {
                sidebar.dmSelected(found.username);
                searchInput.text = "";
                sidebar.matchingUsersList = [];
                sidebar.isSearching = false;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // TOP HEADER BAR (48px)
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: theme.borderSubtle
            }

            // Room Header Mode
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: sidebar.activeView === "room"

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Text {
                        text: sidebar.activeRoomId ? sidebar.activeRoomName : "No Room Selected"
                        font.bold: true
                        font.pixelSize: 15
                        color: theme.textHeader
                        elide: Text.ElideRight
                        Layout.maximumWidth: 140
                    }

                    Rectangle {
                        visible: sidebar.activeRoomId !== ""
                        height: 16
                        width: matureLabel.implicitWidth + 8
                        radius: 3
                        color: sidebar.isRoomMature ? "#1c382f" : "#3d311b"
                        border.color: sidebar.isRoomMature ? theme.accentLogos : theme.accentWarning
                        border.width: 1

                        Text {
                            id: matureLabel
                            anchors.centerIn: parent
                            text: sidebar.isRoomMature ? "Mature" : "New"
                            font.pixelSize: 9
                            font.bold: true
                            color: sidebar.isRoomMature ? theme.accentLogos : theme.accentWarning
                        }
                    }
                }

                // Room Options Button (Chevron)
                Text {
                    visible: sidebar.activeRoomId !== ""
                    text: "▼"
                    font.pixelSize: 10
                    color: optMouse.containsMouse ? theme.textHeader : theme.textMuted

                    MouseArea {
                        id: optMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: roomMenu.open()
                    }

                    Menu {
                        id: roomMenu
                        y: parent.height

                        MenuItem {
                            text: "Copy Room ID"
                            onTriggered: sidebar.copyRoomIdRequested(sidebar.activeRoomId)
                        }
                        MenuItem {
                            text: "Leave Room"
                            onTriggered: sidebar.leaveRoomRequested(sidebar.activeRoomId)
                        }
                    }
                }
            }

            // DM Header Mode (Direct Search Input)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: theme.radiusSmall
                color: theme.bgRail
                border.color: searchInput.activeFocus ? theme.accentBlurple : theme.borderSubtle
                border.width: 1
                visible: sidebar.activeView === "dm"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: "🔍"
                        font.pixelSize: 12
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: theme.textHeader
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        clip: true
                        selectByMouse: true

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !searchInput.text && !searchInput.activeFocus
                            text: "Find or start a DM..."
                            font.family: theme.fontFamily
                            font.pixelSize: 12
                            color: theme.textMuted
                        }

                        onTextChanged: {
                            sidebar.performUserSearch(text);
                        }

                        Keys.onReturnPressed: {
                            sidebar.selectFirstOrTypedUser();
                        }

                        Keys.onEscapePressed: {
                            searchInput.text = "";
                            sidebar.matchingUsersList = [];
                            sidebar.isSearching = false;
                        }
                    }

                    // Clear button (✕)
                    Text {
                        visible: searchInput.text.length > 0
                        text: "✕"
                        font.pixelSize: 11
                        font.family: theme.fontFamily
                        color: clearSearchMouse.containsMouse ? theme.textHeader : theme.textMuted

                        MouseArea {
                            id: clearSearchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                sidebar.matchingUsersList = [];
                                sidebar.isSearching = false;
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // MIDDLE CHANNELS / DMS LIST
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: sidebar.width
                spacing: 2

                // --- ROOM MODE CHANNELS ---
                ColumnLayout {
                    width: sidebar.width
                    visible: sidebar.activeView === "room"
                    spacing: 2

                    // Empty State when no room is selected
                    Item {
                        width: sidebar.width - 16
                        height: 90
                        Layout.alignment: Qt.AlignHCenter
                        visible: !sidebar.activeRoomId || sidebar.activeRoomId === ""

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "No Room Selected"
                                font.bold: true
                                font.pixelSize: 12
                                color: theme.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Click '+' on the server rail\nto create or join a room."
                                font.pixelSize: 11
                                color: theme.textMuted
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Category Title (Only when room is active)
                    Item {
                        width: sidebar.width
                        height: 32
                        visible: sidebar.activeRoomId !== ""

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "TEXT CHANNELS"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    // Default Channels
                    Repeater {
                        model: (sidebar.activeRoomId !== "") ? [
                            { name: "general-chat", icon: "#", desc: "Public room discussion" },
                            { name: "announcements", icon: "#", desc: "Official announcements" },
                            { name: "strike-appeals", icon: "🔒", desc: "Moderator private channel" }
                        ] : []

                        Rectangle {
                            id: chanItem
                            width: sidebar.width - 16
                            height: 34
                            Layout.preferredWidth: sidebar.width - 16
                            Layout.preferredHeight: 34
                            Layout.alignment: Qt.AlignHCenter
                            radius: theme.radiusSmall

                            property bool isSelected: sidebar.activeChannel === modelData.name
                            color: isSelected ? theme.bgActive : (chanMouse.containsMouse ? theme.bgHover : "transparent")

                            // Channel Icon Box (Guaranteed fixed geometry)
                            Item {
                                id: chanIconBox
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.bold: true
                                    font.pixelSize: 15
                                    color: chanItem.isSelected ? theme.textHeader : theme.textMuted
                                }
                            }

                            // Channel Name Text (Anchored with clear space between icon and dot)
                            Text {
                                id: chanNameText
                                anchors.left: chanIconBox.right
                                anchors.leftMargin: 4
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.bold: chanItem.isSelected
                                font.pixelSize: 13
                                color: chanItem.isSelected ? theme.textInteractiveActive : theme.textInteractive
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: chanMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sidebar.activeChannel = modelData.name
                                    sidebar.channelSelected(modelData.name)
                                }
                            }
                        }
                    }
                }

                // --- DM MODE DIRECT MESSAGES ---
                ColumnLayout {
                    width: sidebar.width
                    visible: sidebar.activeView === "dm"
                    spacing: 2

                    Item {
                        width: sidebar.width
                        height: 32

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "DIRECT MESSAGES"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    Repeater {
                        model: sidebar.dmsModel

                        Rectangle {
                            id: dmItem
                            width: sidebar.width - 16
                            height: 40
                            Layout.preferredWidth: sidebar.width - 16
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            radius: theme.radiusSmall

                            property bool isSelected: sidebar.activeDmUser === modelData.username
                            color: isSelected ? theme.bgActive : (dmUserMouse.containsMouse ? theme.bgHover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                // Avatar
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: theme.accentBlurple

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.username.substring(0, 1).toUpperCase()
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.username
                                        font.bold: dmItem.isSelected
                                        font.pixelSize: 13
                                        color: dmItem.isSelected ? theme.textInteractiveActive : theme.textInteractive
                                    }

                                    Text {
                                        text: "Epoch HKDF active"
                                        font.pixelSize: 10
                                        color: theme.textMuted
                                    }
                                }
                            }

                            MouseArea {
                                id: dmUserMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sidebar.activeDmUser = modelData.username
                                    sidebar.dmSelected(modelData.username)
                                }
                            }
                        }
                    }

                    // Empty state when no DMs
                    Item {
                        width: sidebar.width - 16
                        height: 60
                        visible: !sidebar.dmsModel || sidebar.dmsModel.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "No conversations yet.\nClick above to start a DM."
                            font.pixelSize: 11
                            color: theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    // Click-outside backdrop to dismiss suggestions dropdown
    MouseArea {
        anchors.fill: parent
        z: 998
        visible: suggestionDropdown.visible
        onClicked: {
            sidebar.isSearching = false;
        }
    }

    // Autocomplete / Search Suggestion Dropdown
    Rectangle {
        id: suggestionDropdown
        z: 999
        anchors.top: parent.top
        anchors.topMargin: 50
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        visible: sidebar.activeView === "dm" && sidebar.isSearching && sidebar.matchingUsersList.length > 0
        height: Math.min(suggestionListCol.implicitHeight + 16, 280)
        radius: theme.radiusMedium
        color: theme.bgCard
        border.color: theme.borderSubtle
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        ScrollView {
            id: suggestionScroll
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: suggestionListCol
                width: suggestionDropdown.width - 12
                spacing: 4

                // Header
                Text {
                    text: "VERIFIED USER MATCH"
                    font.family: theme.fontFamily
                    font.bold: true
                    font.pixelSize: 10
                    color: theme.accentLogos
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.topMargin: 2
                }

                // Matched Users List
                Repeater {
                    model: sidebar.matchingUsersList

                    Rectangle {
                        width: suggestionListCol.width
                        Layout.fillWidth: true
                        Layout.preferredWidth: suggestionListCol.width
                        Layout.preferredHeight: 46
                        radius: theme.radiusSmall
                        color: sugMouse.containsMouse ? theme.bgHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            // Avatar with Initial
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: theme.accentBlurple

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.username ? modelData.username.substring(0, 1).toUpperCase() : "U"
                                    font.family: theme.fontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "@" + modelData.username
                                    font.family: theme.fontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: theme.textHeader
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.commitment ?
                                        (modelData.commitment.substring(0, 10) + "..." + modelData.commitment.substring(modelData.commitment.length - 8)) :
                                        "0x00...00"
                                    font.family: theme.fontFamilyMono
                                    font.pixelSize: 9
                                    color: theme.accentLogos
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: sugMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sidebar.dmSelected(modelData.username);
                                searchInput.text = "";
                                sidebar.isSearching = false;
                                sidebar.matchingUsersList = [];
                            }
                        }
                    }
                }
            }
        }
    }
}
