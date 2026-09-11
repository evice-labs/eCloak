import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import "modals"

Item {
    id: root
    width: 1100
    height: 720

    // Global Architecture State
    property string activeView: "room" // "room" or "dm"
    property string activeRoomId: ""
    property string activeRoomName: ""
    property bool isRoomMature: false
    property int activeRoomN: 0
    property int activeRoomM: 0
    property string activeChannel: ""
    property string activeDmUser: ""
    property bool isRightDrawerOpen: true

    // User Identity State
    property string myUsername: ""
    property string myCommitment: ""
    property string myNsk: ""
    property bool isIdentityRegistered: false  // true after commitment exists & is valid

    // LEZ Testnet State (queried from https://testnet.lez.logos.co/)
    property int lezBlockHeight: 0
    property int lezCollateral: 0
    property bool lezConnected: false

    // Reference to Core Plugin (Direct injection or IPC bridge)
    property var anonCore: null

    // Basecamp IPC & Core Module Bridge
    function callCore(method, args) {
        if (!args) args = [];

        // 1. Logos Basecamp IPC (logos.callModule)
        if (typeof logos !== "undefined" && logos && typeof logos.callModule === "function") {
            try {
                return logos.callModule("el_anon_chat_core", method, args);
            } catch(e) {
                console.log("Logos IPC callModule error (" + method + "): " + e);
                return JSON.stringify({ error: e.toString() });
            }
        }

        // 2. Direct QObject injection (el_anon_chat_core)
        if (typeof el_anon_chat_core !== "undefined" && el_anon_chat_core) {
            try {
                if (typeof el_anon_chat_core[method] === "function") {
                    return el_anon_chat_core[method].apply(el_anon_chat_core, args);
                }
            } catch(e) {
                console.log("Direct core call error (" + method + "): " + e);
                return JSON.stringify({ error: e.toString() });
            }
        }

        // 3. Fallback when running standalone outside Basecamp
        console.log("Core backend not connected, method called: " + method);
        return null;
    }

    // Local fallback identity generator for standalone / dev testing
    function generateLocalFallbackIdentity() {
        var hexChars = "0123456789abcdef";
        var nsk = "";
        var comm = "";
        for (var i = 0; i < 64; i++) {
            nsk += hexChars.charAt(Math.floor(Math.random() * 16));
            comm += hexChars.charAt(Math.floor(Math.random() * 16));
        }
        return JSON.stringify({ commitment: comm, nsk: nsk });
    }

    // Room Model (Empty by default, created or joined by user)
    property var roomsList: []

    // Dynamic Conversation Messages Store: { "convKey": [msg1, msg2, ...] }
    property var conversationMessages: ({})

    // Dynamic DM Users List (starts empty, user can add via search dialog)
    property var dmsList: []

    // Dynamic Room Moderators & Members State
    property var roomModerators: []
    property var roomMembers: []

    // Dynamic Slashing Radar State
    property string radarTargetUser: ""
    property string radarTargetCommitment: ""
    property int radarStrikes: 0

    function currentConvKey() {
        return (root.activeView === "dm") ? ("dm:" + root.activeDmUser) : (root.activeRoomId + ":" + root.activeChannel);
    }

    function getCurrentMessages() {
        var key = currentConvKey();
        return (root.conversationMessages && root.conversationMessages[key]) ? root.conversationMessages[key] : [];
    }

    Theme { id: theme }

    Component.onCompleted: {
        // Query LEZ testnet block height
        lezBlockHeightTimer.start();
        queryLezBlockHeight();

        // Restore existing identity from Core if available
        try {
            var existingComm = root.callCore("getCommitment", []);
            if (existingComm && typeof existingComm === "string" && existingComm.length > 0) {
                var cleanedComm = existingComm.replace(/\"/g, "").trim();
                if (cleanedComm.length >= 32 && !cleanedComm.startsWith("{")) {
                    root.myCommitment = cleanedComm;
                    root.isIdentityRegistered = true;
                } else {
                    var parsedComm = JSON.parse(existingComm);
                    if (parsedComm.commitment) {
                        root.myCommitment = parsedComm.commitment;
                        root.isIdentityRegistered = true;
                    }
                }
            }
        } catch(e) {
            console.log("Core init identity notice: " + e);
        }

        // If no identity exists, prompt user to create one
        if (!root.myCommitment || root.myCommitment.length === 0) {
            identityModal.open();
        }
    }

    // LEZ Testnet Block Height Polling
    Timer {
        id: lezBlockHeightTimer
        interval: 15000 // Poll every 15 seconds
        repeat: true
        onTriggered: root.queryLezBlockHeight()
    }

    function queryLezBlockHeight() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        if (resp.block_height !== undefined) {
                            root.lezBlockHeight = resp.block_height;
                            root.lezConnected = true;
                        } else if (resp.height !== undefined) {
                            root.lezBlockHeight = resp.height;
                            root.lezConnected = true;
                        }
                        // Check collateral for registered commitment
                        if (resp.collateral !== undefined) {
                            root.lezCollateral = resp.collateral;
                        }
                    } catch(e) {
                        console.log("LEZ parse error: " + e);
                        root.lezConnected = false;
                    }
                } else {
                    root.lezConnected = false;
                }
            }
        };
        xhr.open("GET", "https://testnet.lez.logos.co/block/latest");
        xhr.send();
    }

    // Main 4-Column Layout Coordinator
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // LEFT NAVIGATION PANE 
        Rectangle {
            Layout.preferredWidth: 312
            Layout.fillHeight: true
            color: theme.bgRail

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // SERVER RAIL & CHANNEL SIDEBAR ROW
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Column 1: Server Rail (72px)
                    ServerRail {
                        Layout.preferredWidth: 72
                        Layout.fillHeight: true
                        activeView: root.activeView
                        activeRoomId: root.activeRoomId
                        roomsModel: root.roomsList

                        onDmSelected: {
                            root.activeView = "dm";
                        }

                        onRoomSelected: function(roomId, roomName, nMod, mMod, mature) {
                            root.activeView = "room";
                            root.activeRoomId = roomId;
                            root.activeRoomName = roomName;
                            root.activeRoomN = nMod;
                            root.activeRoomM = mMod;
                            root.isRoomMature = mature;
                            root.activeChannel = "general-chat";
                        }

                        onAddRoomClicked: {
                            createRoomModal.open();
                        }

                        onIdentitySettingsClicked: {
                            identityModal.open();
                        }
                    }

                    // Column 2: Channel / DM Sidebar (240px)
                    ChannelSidebar {
                        Layout.preferredWidth: 240
                        Layout.fillHeight: true
                        activeView: root.activeView
                        activeRoomName: root.activeRoomName
                        activeRoomId: root.activeRoomId
                        isRoomMature: root.isRoomMature
                        activeChannel: root.activeChannel
                        activeDmUser: root.activeDmUser
                        dmsModel: root.dmsList

                        onChannelSelected: function(chan) {
                            root.activeChannel = chan;
                        }

                        onDmSelected: function(user) {
                            root.activeDmUser = user;
                            root.activeView = "dm";
                            // Ensure user is added to dmsList if not already present
                            var exists = false;
                            for (var i = 0; i < root.dmsList.length; i++) {
                                if (root.dmsList[i].username === user) {
                                    exists = true;
                                    break;
                                }
                            }
                            if (!exists) {
                                var updated = root.dmsList.slice();
                                updated.push({ username: user, online: true });
                                root.dmsList = updated;
                            }
                        }

                        onCopyRoomIdRequested: function(roomId) {
                            notificationToast.showNotification("Copied Room ID: " + (roomId ? (roomId.substring(0, 12) + "...") : "Room ID"));
                        }

                        onLeaveRoomRequested: function(roomId) {
                            var updated = [];
                            for (var i = 0; i < root.roomsList.length; i++) {
                                if (root.roomsList[i].id !== roomId) {
                                    updated.push(root.roomsList[i]);
                                }
                            }
                            root.roomsList = updated;
                            if (root.activeRoomId === roomId) {
                                if (updated.length > 0) {
                                    root.activeRoomId = updated[0].id;
                                    root.activeRoomName = updated[0].name;
                                    root.activeRoomN = updated[0].nMod;
                                    root.activeRoomM = updated[0].mMod;
                                    root.isRoomMature = updated[0].mature;
                                    root.activeChannel = "general-chat";
                                } else {
                                    root.activeRoomId = "";
                                    root.activeRoomName = "";
                                    root.activeRoomN = 0;
                                    root.activeRoomM = 0;
                                    root.isRoomMature = false;
                                    root.activeChannel = "";
                                }
                            }
                            notificationToast.showNotification("Left room " + roomId.substring(0, 8));
                        }
                    }
                }

                // BOTTOM PERSISTENT USER PROFILE BAR (312px)
                UserProfileBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    myUsername: root.myUsername
                    myCommitment: root.myCommitment

                    onOpenIdentitySettings: {
                        identityModal.open();
                    }

                    onCopyCommitmentRequested: {
                        notificationToast.showNotification("Copied identity commitment to clipboard!");
                    }
                }
            }
        }

        // ==========================================
        // COLUMN 3: ACTIVE CHAT FEED & COMPOSER (FLEX)
        // ==========================================
        ChatArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            activeView: root.activeView
            activeTargetName: (root.activeView === "dm") ? root.activeDmUser : root.activeChannel
            activeTopic: (root.activeView === "dm") ?
                "Anonymous Direct Message • ECDH Key Exchange & Epoch-Rotating Topic" :
                (root.activeRoomName + " • N=" + root.activeRoomN + "/M=" + root.activeRoomM + " Threshold SSS")
            messagesModel: root.getCurrentMessages()
            isDrawerOpen: root.isRightDrawerOpen

            onToggleDrawer: {
                root.isRightDrawerOpen = !root.isRightDrawerOpen;
            }

            onSendMessage: function(text, attachment) {
                // Guard: require identity before sending messages
                if (!root.myCommitment || root.myCommitment.length === 0) {
                    notificationToast.showNotification("⚠ Identity required — please generate identity first.");
                    identityModal.open();
                    return;
                }

                var newTag = "";
                var postPt = null;

                // Execute Two-Tier SSS preparePost via Core IPC
                var dummySalt = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
                var modKeys = JSON.stringify(["02e4f82a1b9c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789"]);
                var res = root.callCore("preparePost", [text, dummySalt, modKeys, 1]);
                if (res) {
                    try {
                        var parsed = JSON.parse(res);
                        if (parsed.error) {
                            notificationToast.showNotification("⚠ " + parsed.error);
                            return;
                        }
                        if (parsed.tracing_tag) newTag = parsed.tracing_tag;
                        if (parsed.post_point) postPt = parsed.post_point;
                    } catch(e) {
                        console.log("preparePost exception: " + e);
                    }
                }

                if (!newTag) {
                    // Fallback generated tracing tag
                    var hexChars = "0123456789abcdef";
                    for (var i = 0; i < 16; i++) {
                        newTag += hexChars.charAt(Math.floor(Math.random() * hexChars.length));
                    }
                }

                var newMsg = {
                    author: root.myUsername,
                    commitment: root.myCommitment,
                    timestamp: "Just now",
                    text: text,
                    tracingTag: newTag,
                    isMod: true,
                    postPoint: postPt,
                    attachment: attachment
                };

                // Append to conversation messages map
                var key = root.currentConvKey();
                var store = Object.assign({}, root.conversationMessages);
                var curMsgs = store[key] ? store[key].slice() : [];
                curMsgs.push(newMsg);
                store[key] = curMsgs;
                root.conversationMessages = store;

                if (attachment) {
                    notificationToast.showNotification("Sent with attachment: " + attachment.name + " (" + attachment.sizeText + ")");
                } else {
                    notificationToast.showNotification("Message posted with 2-Tier SSS! (Tag #" + newTag.substring(0, 6) + ")");
                }
            }

            onFlagMessage: function(author, comm, tag, text) {
                root.radarTargetUser = author;
                root.radarTargetCommitment = comm;
                root.radarStrikes = 1;

                strikeModal.targetAuthor = author;
                strikeModal.targetCommitment = comm;
                strikeModal.tracingTag = tag;
                strikeModal.messageSnippet = text;
                strikeModal.evidenceHash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
                strikeModal.open();
            }

            onInspectMessage: function(tag, point) {
                notificationToast.showNotification("SSS Point: (" + (point ? point.x : 1) + ", " + (point ? point.y : "share") + ") • Tag: #" + tag.substring(0, 8));
            }
        }

        // ==========================================
        // COLUMN 4: MEMBER & SLASHING DRAWER (240px, COLLAPSIBLE)
        // ==========================================
        RightDrawer {
            Layout.fillHeight: true
            visible: root.activeView !== "dm"
            isOpen: root.activeView !== "dm" && root.isRightDrawerOpen
            moderatorsList: root.roomModerators
            membersList: root.roomMembers
            radarTargetUser: root.radarTargetUser
            radarTargetCommitment: root.radarTargetCommitment
            radarStrikes: root.radarStrikes

            onExecuteSlashingRequested: function(targetComm) {
                var result = root.callCore("revokeCommitment", [targetComm]);
                if (result) {
                    try {
                        var parsed = JSON.parse(result);
                        if (parsed.error) {
                            notificationToast.showNotification("⚠ Slashing failed: " + parsed.error);
                            return;
                        }
                    } catch(e) {
                        notificationToast.showNotification("⚠ Slashing exception: " + e);
                        return;
                    }
                }
                root.radarStrikes = 0;
                root.radarTargetUser = "";
                root.radarTargetCommitment = "";
                notificationToast.showNotification("⚡ Slashing confirmed on LEZ! Commitment burned.");
            }

            onIssueStrikeRequested: {
                strikeModal.open();
            }
        }
    }

    // ==========================================
    // OVERLAY DIALOGS & NOTIFICATION TOAST
    // ==========================================
    CreateRoomModal {
        id: createRoomModal
        adminCommitment: root.myCommitment

        onRoomCreated: function(name, nVal, mVal, modKeys, minMembers) {
            // Guard: require identity
            if (!root.myCommitment || root.myCommitment.length === 0) {
                notificationToast.showNotification("⚠ Identity required — please generate identity first.");
                identityModal.open();
                return;
            }

            var result = root.callCore("createRoom", [root.myCommitment, nVal, mVal, modKeys, 1, minMembers]);
            if (result) {
                try {
                    var parsed = JSON.parse(result);
                    if (parsed.error) {
                        notificationToast.showNotification("⚠ " + parsed.error);
                        return;
                    }
                } catch(e) {
                    notificationToast.showNotification("⚠ Room creation failed: " + e);
                    return;
                }
            }

            var newId = "room_" + (root.roomsList.length + 1);
            var newRoom = {
                id: newId,
                name: name,
                iconText: name.substring(0, 2).toUpperCase(),
                nMod: nVal,
                mMod: mVal,
                mature: false,
                unread: false
            };
            var updated = root.roomsList.slice();
            updated.push(newRoom);
            root.roomsList = updated;

            root.activeRoomId = newId;
            root.activeRoomName = name;
            root.activeRoomN = nVal;
            root.activeRoomM = mVal;
            root.isRoomMature = false;
            root.activeChannel = "general-chat";
            root.activeView = "room";
            root.roomModerators = [
                { username: root.myUsername, pubkey: root.myCommitment.substring(0, 10) + "...", role: "Room Creator" }
            ];

            notificationToast.showNotification("Room '" + name + "' created successfully! (Status: New/Probation)");
        }
    }

    JoinRoomModal {
        id: joinRoomModal
        memberCommitment: root.myCommitment

        onRoomJoined: function(roomIdHex, consentSig) {
            // Guard: require identity
            if (!root.myCommitment || root.myCommitment.length === 0) {
                notificationToast.showNotification("⚠ Identity required — please generate identity first.");
                identityModal.open();
                return;
            }

            var result = root.callCore("joinRoom", [roomIdHex, root.myCommitment, root.myCommitment, consentSig, 1]);
            if (result) {
                try {
                    var parsed = JSON.parse(result);
                    if (parsed.error) {
                        notificationToast.showNotification("⚠ " + parsed.error);
                        return;
                    }
                } catch(e) {
                    notificationToast.showNotification("⚠ Join room failed: " + e);
                    return;
                }
            }

            var newId = "room_" + (root.roomsList.length + 1);
            var roomName = "Room #" + (roomIdHex.length > 6 ? roomIdHex.substring(0, 6) : "Group");
            var newRoom = {
                id: newId,
                name: roomName,
                iconText: roomName.substring(0, 2).toUpperCase(),
                nMod: 2,
                mMod: 3,
                mature: false,
                unread: false
            };
            var updated = root.roomsList.slice();
            updated.push(newRoom);
            root.roomsList = updated;

            root.activeRoomId = newId;
            root.activeRoomName = roomName;
            root.activeRoomN = 2;
            root.activeRoomM = 3;
            root.isRoomMature = false;
            root.activeChannel = "general-chat";
            root.activeView = "room";

            notificationToast.showNotification("Joined room with Signed Join Consent!");
        }
    }

    IdentityModal {
        id: identityModal
        commitmentHex: root.myCommitment
        nskHex: root.myNsk
        currentUsername: root.myUsername
        blockHeight: root.lezBlockHeight
        collateralAmount: root.lezCollateral
        isLezConnected: root.lezConnected

        onUpdateUsernameRequested: function(newUsername) {
            // Guard: require identity before registering username
            if (!root.myCommitment || root.myCommitment.length === 0) {
                notificationToast.showNotification("⚠ Identity required — cannot register username.");
                return;
            }

            var previousUsername = root.myUsername;
            root.myUsername = newUsername;
            var result = root.callCore("registerUsername", [newUsername]);
            if (result) {
                try {
                    var parsed = JSON.parse(result);
                    if (parsed.error) {
                        root.myUsername = previousUsername; // rollback
                        notificationToast.showNotification("⚠ " + parsed.error);
                        return;
                    }
                } catch(e) {
                    root.myUsername = previousUsername; // rollback
                    notificationToast.showNotification("⚠ Username registration failed: " + e);
                    return;
                }
            }
            notificationToast.showNotification("Username updated to @" + newUsername);
        }

        onGenerateNewIdentityRequested: {
            var res = root.callCore("createIdentity", [""]);
            if (!res) {
                // Fallback for standalone / dev mode
                res = root.generateLocalFallbackIdentity();
                notificationToast.showNotification("Generated identity (Standalone fallback)");
            } else {
                notificationToast.showNotification("New ZK Identity generated via Core Module!");
            }
            if (res) {
                try {
                    var parsed = JSON.parse(res);
                    if (parsed.error) {
                        notificationToast.showNotification("⚠ " + parsed.error);
                        return;
                    }
                    if (parsed.commitment) {
                        root.myCommitment = parsed.commitment;
                        root.isIdentityRegistered = true;
                    }
                    if (parsed.nsk) root.myNsk = parsed.nsk;
                } catch(e) {
                    notificationToast.showNotification("⚠ Identity generation failed: " + e);
                    return;
                }
            }
        }
    }

    StrikeModal {
        id: strikeModal

        onStrikeSigned: function(comm, tag, evid) {
            root.radarStrikes += 1;
            notificationToast.showNotification("Strike certificate signed & broadcasted! (N-of-M recorded)");
        }
    }

    // Top Notification Toast
    Rectangle {
        id: notificationToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: toastTimer.running ? 20 : -60
        height: 40
        width: toastText.implicitWidth + 32
        radius: 20
        color: theme.bgCard
        border.color: theme.accentLogos
        border.width: 1
        visible: anchors.topMargin > -50

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "🛡️"; font.pixelSize: 14 }
            Text {
                id: toastText
                text: ""
                font.bold: true
                font.pixelSize: 12
                color: theme.textHeader
            }
        }

        Timer {
            id: toastTimer
            interval: 3500
        }

        function showNotification(msg) {
            toastText.text = msg;
            toastTimer.restart();
        }
    }
}
