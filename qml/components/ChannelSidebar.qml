import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar
    width: 240
    color: theme.bgSidebar

    property string activeView: "room" // "room" or "dm"
    property string activeRoomName: ""
    property string activeRoomId: ""
    property bool isRoomMature: true
    property string activeChannel: ""
    property string activeDmUser: ""
    property var dmsModel: []
    property var knownUsersModel: []
    property var matchingUsersList: []
    property bool isSearching: false

    signal channelSelected(string channelName)
    signal dmSelected(string targetUsername)
    signal deleteDmRequested(string targetUsername)
    signal copyRoomIdRequested(string roomId)
    signal leaveRoomRequested(string roomId)
    signal inputFocusGained()
    signal clearOtherFocusRequested()

    function clearInputFocus() {
        searchInput.focus = false;
        sidebar.isSearching = false;
    }

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

        // TOP HEADER BAR (48px)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    sidebar.clearInputFocus();
                    sidebar.clearOtherFocusRequested();
                }
            }

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
                        height: 18
                        width: matureLabel.implicitWidth + 12
                        radius: 9
                        color: theme.bgCard
                        border.color: theme.borderSubtle
                        border.width: 1

                        Text {
                            id: matureLabel
                            anchors.centerIn: parent
                            text: sidebar.isRoomMature ? "Mature" : "New"
                            font.pixelSize: 9
                            font.bold: true
                            color: sidebar.isRoomMature ? theme.accentSuccess : theme.accentWarning
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
                        topPadding: 4
                        bottomPadding: 4
                        leftPadding: 4
                        rightPadding: 4

                        background: Rectangle {
                            implicitWidth: 160
                            color: theme.bgCard
                            border.color: theme.borderSubtle
                            border.width: 1
                            radius: 8
                        }

                        MenuItem {
                            id: itemCopyRoom
                            text: "Copy Room ID"
                            contentItem: Text {
                                text: itemCopyRoom.text
                                font.family: theme.fontFamily
                                font.pixelSize: 13
                                color: itemCopyRoom.highlighted ? "#ffffff" : theme.textHeader
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                                rightPadding: 8
                            }
                            background: Rectangle {
                                implicitWidth: 152
                                implicitHeight: 32
                                color: itemCopyRoom.highlighted ? theme.bgHover : "transparent"
                                radius: 6
                            }
                            onTriggered: sidebar.copyRoomIdRequested(sidebar.activeRoomId)
                        }

                        MenuItem {
                            id: itemLeaveRoom
                            text: "Leave Room"
                            contentItem: Text {
                                text: itemLeaveRoom.text
                                font.family: theme.fontFamily
                                font.pixelSize: 13
                                color: itemLeaveRoom.highlighted ? theme.accentDanger : theme.textHeader
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                                rightPadding: 8
                            }
                            background: Rectangle {
                                implicitWidth: 152
                                implicitHeight: 32
                                color: itemLeaveRoom.highlighted ? theme.bgHover : "transparent"
                                radius: 6
                            }
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

                        onActiveFocusChanged: {
                            if (searchInput.activeFocus) {
                                sidebar.inputFocusGained();
                            }
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
                            sidebar.clearInputFocus();
                            sidebar.clearOtherFocusRequested();
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
                                sidebar.clearInputFocus();
                                sidebar.clearOtherFocusRequested();
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

                // ROOM MODE CHANNELS
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

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                sidebar.clearInputFocus();
                                sidebar.clearOtherFocusRequested();
                            }
                        }

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

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                sidebar.clearInputFocus();
                                sidebar.clearOtherFocusRequested();
                            }
                        }

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
                                    sidebar.clearInputFocus();
                                    sidebar.clearOtherFocusRequested();
                                    sidebar.activeChannel = modelData.name;
                                    sidebar.channelSelected(modelData.name);
                                }
                            }
                        }
                    }
                }

                // DM MODE DIRECT MESSAGES
                ColumnLayout {
                    width: sidebar.width
                    visible: sidebar.activeView === "dm"
                    spacing: 2

                    Item {
                        width: sidebar.width
                        height: 32

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                sidebar.clearInputFocus();
                                sidebar.clearOtherFocusRequested();
                            }
                        }

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
                                anchors.rightMargin: 34
                                spacing: 10

                                // Avatar
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: theme.primary

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
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "Epoch HKDF active"
                                        font.pixelSize: 10
                                        color: theme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: dmUserMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sidebar.clearInputFocus();
                                    sidebar.clearOtherFocusRequested();
                                    sidebar.activeDmUser = modelData.username;
                                    sidebar.dmSelected(modelData.username);
                                }
                            }

                            // Delete Conversation Button (X)
                            Rectangle {
                                id: deleteDmBtn
                                z: 3
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                radius: 11
                                color: deleteDmMouse.containsMouse ? theme.bgHover : "transparent"
                                border.color: deleteDmMouse.containsMouse ? theme.borderSubtle : "transparent"
                                border.width: 1
                                opacity: (dmUserMouse.containsMouse || deleteDmMouse.containsMouse) ? 1.0 : 0.0
                                visible: opacity > 0

                                Behavior on opacity { NumberAnimation { duration: theme.animFast } }
                                Behavior on color { ColorAnimation { duration: theme.animFast } }

                                Text {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "✕"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: theme.fontFamily
                                    color: deleteDmMouse.containsMouse ? theme.textHeader : theme.textMuted
                                }

                                MouseArea {
                                    id: deleteDmMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        mouse.accepted = true;
                                        sidebar.deleteDmRequested(modelData.username);
                                    }
                                }

                                ToolTip {
                                    id: deleteDmTip
                                    visible: deleteDmMouse.containsMouse
                                    delay: 250
                                    text: "Delete Conversation"
                                    topPadding: 6
                                    bottomPadding: 6
                                    leftPadding: 10
                                    rightPadding: 10
                                    contentItem: Text {
                                        text: deleteDmTip.text
                                        font.family: theme.fontFamily
                                        font.pixelSize: 12
                                        color: theme.textHeader
                                    }
                                    background: Rectangle {
                                        color: theme.bgCard
                                        border.color: theme.borderSubtle
                                        border.width: 1
                                        radius: 6
                                    }
                                }
                            }
                        }
                    }

                    // Empty state when no DMs
                    Item {
                        width: sidebar.width - 16
                        height: 60
                        visible: !sidebar.dmsModel || sidebar.dmsModel.length === 0

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                sidebar.clearInputFocus();
                                sidebar.clearOtherFocusRequested();
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "No conversations yet.\nClick above to start a DM."
                            font.pixelSize: 11
                            color: theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Spacer capturing clicks in empty space of ScrollView
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 60

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            sidebar.clearInputFocus();
                            sidebar.clearOtherFocusRequested();
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
            sidebar.clearInputFocus();
            sidebar.clearOtherFocusRequested();
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
                                color: theme.primary

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
                                sidebar.clearInputFocus();
                                sidebar.clearOtherFocusRequested();
                            }
                        }
                    }
                }
            }
        }
    }

    // Vertical divider left (separating ServerRail from ChannelSidebar)
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: theme.borderSubtle
    }

    // Vertical divider right (separating ChannelSidebar from ChatArea)
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: theme.borderSubtle
    }
}


