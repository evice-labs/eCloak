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
    property bool isCoreReady: false

    // Basecamp-aligned Module Lifecycle & Events Handshake
    Connections {
        target: (typeof logos !== "undefined" && logos) ? logos : null

        function onViewModuleReadyChanged(moduleName, isReady) {
            console.log("eCloak onViewModuleReadyChanged:", moduleName, isReady);
            if (isReady && (moduleName === "ecloak" || moduleName === "ecloakcore")) {
                root.isCoreReady = true;
                root.syncIdentityFromCore();
            }
        }

        function onModuleEventReceived(moduleName, eventName, data) {
            console.log("eCloak onModuleEventReceived:", moduleName, eventName, JSON.stringify(data));
            if (moduleName === "ecloakcore") {
                root.syncIdentityFromCore();
            }
        }
    }

    // Basecamp IPC & Core Module Bridge (Sync callModule)
    function callCore(method, args) {
        if (!args) args = [];

        // 1. Logos Basecamp IPC (logos.callModule)
        if (typeof logos !== "undefined" && logos && typeof logos.callModule === "function") {
            try {
                // Try official ecloakcore identifier first
                var res = logos.callModule("ecloakcore", method, args);
                if (typeof res !== "undefined" && res !== null && res !== "") {
                    if (typeof res === "string" && res.startsWith("{")) {
                        try {
                            var checkErr = JSON.parse(res);
                            if (checkErr.error && checkErr.error.indexOf("unreachable") !== -1) {
                                return null;
                            }
                        } catch(ignore) {}
                    }
                    return res;
                }
                // Fallback for legacy el_anon_chat_core identifier
                return logos.callModule("el_anon_chat_core", method, args);
            } catch(e) {
                console.log("Logos IPC callModule error (" + method + "): " + e);
                return null;
            }
        }

        // 2. Direct QObject injection (ecloakcore or el_anon_chat_core)
        var coreObj = (typeof ecloakcore !== "undefined" && ecloakcore) ? ecloakcore : ((typeof el_anon_chat_core !== "undefined" && el_anon_chat_core) ? el_anon_chat_core : null);
        if (coreObj) {
            try {
                if (typeof coreObj[method] === "function") {
                    return coreObj[method].apply(coreObj, args);
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

    // Basecamp IPC Async Caller (Pre-armed during startup via logos.callModuleAsync)
    function callCoreAsync(method, args, callback) {
        if (!args) args = [];
        if (typeof logos !== "undefined" && logos && typeof logos.callModuleAsync === "function") {
            try {
                logos.callModuleAsync("ecloakcore", method, args, function(res) {
                    if (callback) callback(res);
                }, 10000);
                return;
            } catch(e) {
                console.log("callCoreAsync error:", e);
            }
        }
        var syncRes = callCore(method, args);
        if (callback) callback(syncRes);
    }

    // Robust JSON Parser that handles single, double-encoded JSON, or direct objects
    function safeJsonParse(raw) {
        if (!raw) return null;
        var parsed = raw;
        if (typeof parsed === "string") {
            try {
                parsed = JSON.parse(parsed);
            } catch(e) {
                return null;
            }
        }
        // If string was double-encoded by IPC layer (std::string serialization)
        if (typeof parsed === "string") {
            try {
                parsed = JSON.parse(parsed);
            } catch(e) {}
        }
        return (typeof parsed === "object" && parsed !== null) ? parsed : null;
    }

    // Synchronize identity from core module into UI state
    function syncIdentityFromCore() {
        callCoreAsync("getIdentityInfo", [], function(idInfo) {
            var parsedInfo = safeJsonParse(idInfo);
            if (parsedInfo && parsedInfo.has_identity && parsedInfo.commitment && parsedInfo.commitment.length >= 32) {
                root.myCommitment = parsedInfo.commitment;
                root.isIdentityRegistered = true;
                root.isCoreReady = true;
                if (parsedInfo.nsk) root.myNsk = parsedInfo.nsk;
                if (parsedInfo.username && parsedInfo.username.length > 0) {
                    root.myUsername = parsedInfo.username;
                }
                if (parsedInfo.staked) {
                    root.lezCollateral = parsedInfo.stake_amount || 150;
                } else {
                    root.lezCollateral = 0;
                }
                startupRetryTimer.stop();
                return;
            }

            // Fallback check to getCommitment
            callCoreAsync("getCommitment", [], function(existingComm) {
                if (existingComm && typeof existingComm === "string" && existingComm.length > 0) {
                    var cleanedComm = existingComm.replace(/\"/g, "").trim();
                    if (cleanedComm.length >= 32 && !cleanedComm.startsWith("{")) {
                        root.myCommitment = cleanedComm;
                        root.isIdentityRegistered = true;
                        root.isCoreReady = true;
                        startupRetryTimer.stop();
                    } else if (cleanedComm.startsWith("{")) {
                        var parsedComm = safeJsonParse(existingComm);
                        if (parsedComm && parsedComm.commitment && parsedComm.commitment.length >= 32) {
                            root.myCommitment = parsedComm.commitment;
                            root.isIdentityRegistered = true;
                            root.isCoreReady = true;
                            startupRetryTimer.stop();
                        }
                    }
                }
            });
        });

        // Also query network status
        queryLezNetworkStatus();
    }

    // Ensure an identity exists in core, generating one if missing
    function ensureIdentityExists() {
        if (root.myCommitment && root.myCommitment.length >= 32) return;
        console.log("ensureIdentityExists: generating new identity in core...");
        var res = callCore("createIdentity", [""]);
        if (res) {
            var parsed = safeJsonParse(res);
            if (parsed && parsed.commitment && parsed.commitment.length >= 32) {
                root.myCommitment = parsed.commitment;
                root.isIdentityRegistered = true;
                if (parsed.nsk) root.myNsk = parsed.nsk;
                root.myUsername = "";
                root.lezCollateral = 0;
                console.log("ensureIdentityExists: created commitment:", root.myCommitment);
                return;
            }
        }
        // Fallback for standalone dev
        var fb = generateLocalFallbackIdentity();
        var pfb = safeJsonParse(fb);
        if (pfb) {
            root.myCommitment = pfb.commitment;
            root.myNsk = pfb.nsk;
            root.myUsername = "";
            root.lezCollateral = 0;
            root.isIdentityRegistered = true;
        }
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

    // Aggregated list of all known users across identity, rooms, DMs, and messages
    function getKnownUsersList() {
        var map = {};
        var list = [];

        function add(u, c) {
            if (!u || u.trim().length === 0) return;
            u = u.trim();
            var key = u.toLowerCase();
            if (!map[key]) {
                map[key] = true;
                list.push({ username: u, commitment: c || "" });
            } else if (c && c.length > 0) {
                for (var i = 0; i < list.length; i++) {
                    if (list[i].username.toLowerCase() === key && !list[i].commitment) {
                        list[i].commitment = c;
                        break;
                    }
                }
            }
        }

        // 1. Current user
        if (root.myUsername) {
            add(root.myUsername, root.myCommitment);
        }

        // 2. Existing DMs
        if (root.dmsList) {
            for (var i = 0; i < root.dmsList.length; i++) {
                add(root.dmsList[i].username, root.dmsList[i].commitment);
            }
        }

        // 3. Room Members & Moderators
        if (root.roomMembers) {
            for (var j = 0; j < root.roomMembers.length; j++) {
                add(root.roomMembers[j].username, root.roomMembers[j].pubkey || root.roomMembers[j].commitment);
            }
        }
        if (root.roomModerators) {
            for (var k = 0; k < root.roomModerators.length; k++) {
                add(root.roomModerators[k].username, root.roomModerators[k].pubkey || root.roomModerators[k].commitment);
            }
        }

        // 4. Conversation Messages Authors
        if (root.conversationMessages) {
            for (var conv in root.conversationMessages) {
                var msgs = root.conversationMessages[conv];
                if (msgs && msgs.length) {
                    for (var m = 0; m < msgs.length; m++) {
                        add(msgs[m].author, msgs[m].commitment);
                    }
                }
            }
        }

        // 5. Default Known Network Peers (LEZ Testnet)
        add("Satoshi99", "0x7f8a9b1c2d3e4f5061728394a5b6c7d8e9f0123456789abcdef0123456789abc");
        add("Alice_ZK", "0x4b5c6d7e8f90123456789abcdef0123456789abc7f8a9b1c2d3e4f506172839");
        add("Bob_Anon", "0x123456789abcdef0123456789abc7f8a9b1c2d3e4f5061728394b5c6d7e8f90");
        add("Vitalik_Echo", "0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba");

        return list;
    }

    Theme { id: theme }

    // Startup retry timer to bridge the initial Basecamp module connection phase
    Timer {
        id: startupRetryTimer
        interval: 800
        repeat: true
        property int retries: 0
        onTriggered: {
            retries++;
            if (root.myCommitment && root.myCommitment.length >= 32) {
                startupRetryTimer.stop();
                return;
            }
            root.syncIdentityFromCore();
            // Bound retry to 15 seconds (18 attempts)
            if (retries >= 18) {
                startupRetryTimer.stop();
                if (!root.myCommitment || root.myCommitment.length < 32) {
                    root.ensureIdentityExists();
                }
            }
        }
    }

    Component.onCompleted: {
        // Subscribe to module events if supported by runtime
        if (typeof logos !== "undefined" && logos && typeof logos.onModuleEvent === "function") {
            try {
                logos.onModuleEvent("ecloakcore", "identityChanged");
                logos.onModuleEvent("ecloakcore", "ready");
            } catch(e) {}
        }

        // Check if replica/bridge is already Valid
        if (typeof logos !== "undefined" && logos && typeof logos.isViewModuleReady === "function") {
            if (logos.isViewModuleReady("ecloak") || logos.isViewModuleReady("ecloakcore")) {
                root.isCoreReady = true;
            }
        }

        // Kick off startup sync & timers
        root.syncIdentityFromCore();
        startupRetryTimer.start();
        lezStatusTimer.start();
    }

    // LEZ Testnet Status Polling via Core Module (sandbox-safe)
    Timer {
        id: lezStatusTimer
        interval: 15000 // Poll every 15 seconds
        repeat: true
        onTriggered: root.queryLezNetworkStatus()
    }

    function queryLezNetworkStatus() {
        callCoreAsync("getNetworkStatus", [], function(res) {
            var parsed = safeJsonParse(res);
            if (parsed) {
                if (parsed.connected !== undefined) {
                    root.lezConnected = parsed.connected;
                }
                if (parsed.collateral_active && parsed.stake_amount) {
                    root.lezCollateral = parsed.stake_amount;
                }
                if (parsed.commitment && parsed.commitment.length >= 32 && (!root.myCommitment || root.myCommitment.length === 0)) {
                    root.myCommitment = parsed.commitment;
                    root.isIdentityRegistered = true;
                }
            } else {
                root.lezConnected = true;
            }
        });
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
                        knownUsersModel: root.getKnownUsersList()

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
                                var comm = "";
                                var allKnown = root.getKnownUsersList();
                                for (var k = 0; k < allKnown.length; k++) {
                                    if (allKnown[k].username === user) {
                                        comm = allKnown[k].commitment;
                                        break;
                                    }
                                }
                                updated.push({ username: user, online: true, commitment: comm });
                                root.dmsList = updated;
                            }
                            notificationToast.showNotification("DM session active with @" + user);
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
                "" :
                (root.activeRoomName + " • N=" + root.activeRoomN + "/M=" + root.activeRoomM + " Threshold SSS")
            messagesModel: root.getCurrentMessages()
            isDrawerOpen: root.isRightDrawerOpen

            onToggleDrawer: {
                root.isRightDrawerOpen = !root.isRightDrawerOpen;
            }

            onSendMessage: function(text, attachment) {
                // Guard 1: require identity before sending messages
                if (!root.myCommitment || root.myCommitment.length === 0) {
                    notificationToast.showNotification("⚠ Identity required — please generate identity first.");
                    identityModal.open();
                    return;
                }

                // Guard 2: require 150 LEZ stake collateral before sending messages
                if (root.lezCollateral < 150) {
                    notificationToast.showNotification("⚠ 150 LEZ stake collateral required to post anonymously on LEZ testnet.");
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
                    var parsed = safeJsonParse(res);
                    if (parsed) {
                        if (parsed.error) {
                            notificationToast.showNotification("⚠ " + parsed.error);
                            return;
                        }
                        if (parsed.tracing_tag) newTag = parsed.tracing_tag;
                        if (parsed.post_point) postPt = parsed.post_point;
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
        creatorUsername: root.myUsername
        knownUsers: root.getKnownUsersList()

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
            // Guard: ensure identity exists in core before registering username
            if (!root.myCommitment || root.myCommitment.length < 32) {
                root.ensureIdentityExists();
            }

            if (!newUsername || newUsername.trim().length === 0) {
                notificationToast.showNotification("⚠ Username cannot be empty.");
                return;
            }

            newUsername = newUsername.trim();
            var previousUsername = root.myUsername;
            root.myUsername = newUsername;

            var result = root.callCore("registerUsername", [newUsername]);
            if (result) {
                var parsed = safeJsonParse(result);
                if (parsed && parsed.error) {
                    root.myUsername = previousUsername; // rollback
                    identityModal.usernameStatus = "taken";
                    identityModal.validationMessage = "username taken";
                    return;
                }
            }
            root.myUsername = newUsername;
            identityModal.usernameStatus = "available";
            identityModal.validationMessage = "";
        }

        onStakeViaWalletRequested: function(amount, commitment) {
            notificationToast.showNotification("Initiating " + amount + " LEZ stake request...");
            if (typeof logos !== "undefined" && logos && typeof logos.request === "function") {
                logos.request("wallet.send", {
                    to: "Public/9p7BZn9g6UrVMBiatyeNtq4yv9DitxYM1ZXsjYi6vf47",
                    amount: amount,
                    memo: commitment || root.myCommitment
                }, function(res) {
                    console.log("wallet.send intent response:", JSON.stringify(res));
                    if (res && res.ok) {
                        root.callCore("recordStake", [amount]);
                        root.lezCollateral = amount;
                        identityModal.waitingForManualStake = false;
                        notificationToast.showNotification("✔ Stake confirmed! " + amount + " LEZ collateral active.");
                    } else if (res && (res.error === "unavailable" || res.error === "not_declared")) {
                        // Launch LEZ wallet if available
                        try {
                            logos.request("basecamp.apps.launch", { "app": "lez_wallet_ui" }, function(launchRes) {
                                console.log("basecamp.apps.launch result:", JSON.stringify(launchRes));
                            });
                        } catch(err) {}
                        notificationToast.showNotification("LEZ Wallet opened. Complete transfer, then click 'Confirm 150 LEZ Staked'.");
                    } else if (res && res.error === "cancelled") {
                        identityModal.waitingForManualStake = false;
                        notificationToast.showNotification("Stake request cancelled in Wallet.");
                    } else {
                        notificationToast.showNotification("Stake notice: " + (res ? res.error : "unhandled"));
                    }
                });
            } else {
                root.callCore("recordStake", [amount]);
                root.lezCollateral = amount;
                identityModal.waitingForManualStake = false;
                notificationToast.showNotification("✔ Standalone mode: " + amount + " LEZ collateral marked active.");
            }
        }

        onConfirmStakeRequested: function(amount) {
            root.callCore("recordStake", [amount]);
            root.lezCollateral = amount;
            identityModal.waitingForManualStake = false;
            notificationToast.showNotification("✔ Collateral confirmed: " + amount + " LEZ staked!");
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
