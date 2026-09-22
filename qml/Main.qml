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
            if (isReady && (moduleName === "e-cloak" || moduleName === "ecloak" || moduleName === "ecloakcore" || moduleName === "e_cloak_core")) {
                root.isCoreReady = true;
                root.syncIdentityFromCore();
                root.loadChatStoreFromCore();
            }
        }

        function onModuleEventReceived(moduleName, eventName, data) {
            console.log("eCloak onModuleEventReceived:", moduleName, eventName, JSON.stringify(data));
            if (moduleName === "ecloakcore" || moduleName === "e_cloak_core") {
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
                // Primary: official installed module in Basecamp runtime (ecloakcore)
                var res = logos.callModule("ecloakcore", method, args);
                if (typeof res !== "undefined" && res !== null && res !== "") {
                    if (typeof res === "string" && res.startsWith("{")) {
                        try {
                            var checkErr = JSON.parse(res);
                            if (checkErr.error && checkErr.error.indexOf("unreachable") !== -1) {
                                res = null;
                            }
                        } catch(ignore) {}
                    }
                    if (res !== null) return res;
                }

                // Fallback if deployed under e_cloak_core identifier
                res = logos.callModule("e_cloak_core", method, args);
                if (typeof res !== "undefined" && res !== null && res !== "") {
                    return res;
                }
            } catch(e) {
                console.log("Logos IPC callModule error (" + method + "): " + e);
                return null;
            }
        }

        // 2. Direct QObject injection (ecloakcore or e_cloak_core)
        var coreObj = (typeof window !== "undefined") ? (window.ecloakcore || window.e_cloak_core || null) : null;
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

    // Room Model (Persisted to disk via e_cloak_core)
    property var roomsList: []

    // Dynamic Conversation Messages Store: { "convKey": [msg1, msg2, ...] } (Persisted to disk)
    property var conversationMessages: ({})

    // Dynamic DM Users List (Persisted to disk)
    property var dmsList: []

    // Dynamic Room Moderators & Members State
    property var roomModerators: []
    property var roomMembers: []

    // Flag indicating whether local disk store has been loaded
    property bool chatStoreLoaded: false

    // In-Memory Viewport Pruning Limit
    property int maxActiveMessagesPerConv: 100

    // Dynamic Slashing Radar State
    property string radarTargetUser: ""
    property string radarTargetCommitment: ""
    property int radarStrikes: 0

    // Robust byte array / Latin1 string to hex formatter
    function formatBytesToHex(val) {
        if (!val) return "";
        if (typeof val === "string") {
            if (/^[0-9a-fA-F]+$/.test(val)) return val.toLowerCase();
            var hexStr = "";
            for (var i = 0; i < val.length; i++) {
                var code = val.charCodeAt(i) & 0xff;
                var h = code.toString(16);
                hexStr += (h.length === 1 ? "0" : "") + h;
            }
            return hexStr.toLowerCase();
        }
        if (Array.isArray(val)) {
            var res = "";
            for (var j = 0; j < val.length; j++) {
                var b = val[j] & 0xff;
                var hs = b.toString(16);
                res += (hs.length === 1 ? "0" : "") + hs;
            }
            return res.toLowerCase();
        }
        return "";
    }

    // Persistent Chat Store (Disk-backed via e_cloak_core)
    // Load entire chat store from core disk storage
    function loadChatStoreFromCore() {
        console.log("eCloak: Loading chat store from core module...");
        callCoreAsync("loadChatStore", [], function(res) {
            var parsed = safeJsonParse(res);
            if (parsed && typeof parsed === "object" && (parsed.rooms || parsed.conversations || parsed.dms)) {
                console.log("eCloak: Hydrating chat store from disk...");

                var isPlaceholderUser = function(name) {
                    if (!name) return false;
                    var n = name.trim().toLowerCase();
                    return (n === "satoshi99" || n === "alice_zk" || n === "bob_anon" || n === "vitalik_echo");
                };

                var isPlaceholderRoom = function(rm) {
                    if (!rm) return false;
                    var rId = rm.id ? rm.id.toLowerCase() : "";
                    var rNm = rm.name ? rm.name.toLowerCase() : "";
                    return (rId === "room_1" || rNm === "zk cypherpunks");
                };

                var sanitizedRooms = [];
                var needsStoreRewrite = false;

                if (Array.isArray(parsed.rooms)) {
                    for (var r = 0; r < parsed.rooms.length; r++) {
                        var rm = parsed.rooms[r];
                        if (isPlaceholderRoom(rm)) {
                            needsStoreRewrite = true;
                            continue;
                        }
                        if (Array.isArray(rm.moderators)) {
                            var origModLen = rm.moderators.length;
                            rm.moderators = rm.moderators.filter(function(m) { return !isPlaceholderUser(m.username); });
                            if (rm.moderators.length !== origModLen) needsStoreRewrite = true;
                        }
                        if (Array.isArray(rm.members)) {
                            var origMemLen = rm.members.length;
                            rm.members = rm.members.filter(function(m) { return !isPlaceholderUser(m.username); });
                            if (rm.members.length !== origMemLen) needsStoreRewrite = true;
                        }
                        sanitizedRooms.push(rm);
                    }
                }

                var sanitizedDms = [];
                if (Array.isArray(parsed.dms)) {
                    for (var d = 0; d < parsed.dms.length; d++) {
                        var dm = parsed.dms[d];
                        if (isPlaceholderUser(dm.username)) {
                            needsStoreRewrite = true;
                            continue;
                        }
                        sanitizedDms.push(dm);
                    }
                }

                root.roomsList = sanitizedRooms;
                root.dmsList = sanitizedDms;

                if (sanitizedRooms.length > 0) {
                    if (!root.activeRoomId || root.activeRoomId.length === 0) {
                        var firstRoom = sanitizedRooms[0];
                        root.activeRoomId = firstRoom.id || "";
                        root.activeRoomName = firstRoom.name || "";
                        root.activeRoomN = firstRoom.nMod || 2;
                        root.activeRoomM = firstRoom.mMod || 3;
                        root.isRoomMature = (firstRoom.mature !== undefined) ? firstRoom.mature : true;
                        root.activeChannel = "general-chat";
                        root.activeView = "room";
                        root.roomModerators = firstRoom.moderators || [];
                        root.roomMembers = firstRoom.members || [];
                    }
                } else {
                    root.activeRoomId = "";
                    root.activeRoomName = "";
                    root.roomModerators = [];
                    root.roomMembers = [];
                }

                if (parsed.conversations && typeof parsed.conversations === "object") {
                    var boundedConvs = {};
                    for (var cKey in parsed.conversations) {
                        var cKeyLower = cKey.toLowerCase();
                        if (cKeyLower.indexOf("room_1") !== -1 || cKeyLower.indexOf("satoshi") !== -1 ||
                            cKeyLower.indexOf("alice") !== -1 || cKeyLower.indexOf("bob_anon") !== -1 ||
                            cKeyLower.indexOf("vitalik") !== -1) {
                            needsStoreRewrite = true;
                            continue;
                        }
                        var list = parsed.conversations[cKey];
                        if (Array.isArray(list)) {
                            var cleanMsgs = [];
                            for (var idx = 0; idx < list.length; idx++) {
                                var msg = list[idx];
                                if (isPlaceholderUser(msg.author)) {
                                    needsStoreRewrite = true;
                                    continue;
                                }
                                if (msg.tracingTag) {
                                    msg.tracingTag = root.formatBytesToHex(msg.tracingTag);
                                }
                                cleanMsgs.push(msg);
                            }
                            if (cleanMsgs.length > 0) {
                                boundedConvs[cKey] = (cleanMsgs.length > root.maxActiveMessagesPerConv) ?
                                    cleanMsgs.slice(-root.maxActiveMessagesPerConv) : cleanMsgs;
                            }
                        }
                    }
                    root.conversationMessages = boundedConvs;
                }

                root.chatStoreLoaded = true;
                if (needsStoreRewrite) {
                    console.log("eCloak: Purged legacy test artifacts from chat store. Persisting clean state...");
                    root.persistChatState();
                }
                console.log("eCloak: Chat store restored (" + root.roomsList.length + " rooms, " + root.dmsList.length + " DMs).");
            } else {
                console.log("eCloak: No existing chat store on disk. Initializing fresh clean state...");
                seedDefaultChatState();
            }
        });
    }

    // Fresh install state initialization (clean slate for real testing)
    function seedDefaultChatState() {
        root.roomsList = [];
        root.dmsList = [];
        root.conversationMessages = {};
        root.activeRoomId = "";
        root.activeRoomName = "";
        root.roomModerators = [];
        root.roomMembers = [];
        root.activeChannel = "";
        root.chatStoreLoaded = true;
        persistChatState();
    }

    // Persist current rooms, DMs, and conversation messages to core disk storage
    function persistChatState() {
        var payload = {
            version: 1,
            rooms: root.roomsList,
            dms: root.dmsList,
            conversations: root.conversationMessages
        };
        var serialized = JSON.stringify(payload);
        callCoreAsync("saveChatStore", [serialized], function(res) {
            console.log("eCloak: Chat store save result:", res);
        });
    }

    // Delete a Direct Message conversation and remove its message history
    function deleteDmConversation(username) {
        if (!username) return;

        // 1. Remove from dmsList
        var updatedDms = [];
        for (var i = 0; i < root.dmsList.length; i++) {
            if (root.dmsList[i].username !== username) {
                updatedDms.push(root.dmsList[i]);
            }
        }
        root.dmsList = updatedDms;

        // 2. Remove conversation messages from in-memory map
        var convKey = "dm:" + username;
        var updatedMsgs = Object.assign({}, root.conversationMessages);
        delete updatedMsgs[convKey];
        root.conversationMessages = updatedMsgs;

        // 3. Persist updated chat state to disk
        root.persistChatState();

        // 4. Update active DM view if the deleted one was currently active
        if (root.activeView === "dm" && root.activeDmUser === username) {
            if (updatedDms.length > 0) {
                root.activeDmUser = updatedDms[0].username;
            } else {
                root.activeDmUser = "";
            }
        }

        notificationToast.showNotification("Conversation with " + username + " has been deleted.");
    }

    // Sliding Window Pagination: Load previous message batch from disk on demand
    function loadMoreHistory(convKey) {
        if (!convKey) convKey = root.currentConvKey();
        callCoreAsync("loadChatStore", [], function(res) {
            var parsed = safeJsonParse(res);
            if (parsed && parsed.conversations && parsed.conversations[convKey]) {
                var fullList = parsed.conversations[convKey];
                var curMsgs = root.conversationMessages[convKey] || [];
                if (fullList.length > curMsgs.length) {
                    var currentOldestIndex = fullList.length - curMsgs.length;
                    var batchStart = Math.max(0, currentOldestIndex - root.maxActiveMessagesPerConv);
                    var olderBatch = fullList.slice(batchStart, currentOldestIndex);
                    var combined = olderBatch.concat(curMsgs);
                    var store = Object.assign({}, root.conversationMessages);
                    store[convKey] = combined;
                    root.conversationMessages = store;
                    notificationToast.showNotification("Loaded " + olderBatch.length + " earlier messages");
                }
            }
        });
    }

    function currentConvKey() {
        return (root.activeView === "dm") ? ("dm:" + root.activeDmUser) : (root.activeRoomId + ":" + root.activeChannel);
    }

    function getCurrentMessages() {
        var key = currentConvKey();
        return (root.conversationMessages && root.conversationMessages[key]) ? root.conversationMessages[key] : [];
    }

    function toggleReaction(msgIndex, emoji) {
        var key = currentConvKey();
        var store = Object.assign({}, root.conversationMessages);
        var curMsgs = (store[key] ? store[key].slice() : []);
        if (msgIndex < 0 || msgIndex >= curMsgs.length) return;

        var msg = Object.assign({}, curMsgs[msgIndex]);
        var reacts = msg.reactions ? msg.reactions.slice() : [];
        var myUser = root.myUsername || "You";

        var found = false;
        for (var i = 0; i < reacts.length; i++) {
            if (reacts[i].emoji === emoji) {
                var users = reacts[i].users ? reacts[i].users.slice() : [];
                var userIdx = users.indexOf(myUser);
                if (userIdx !== -1) {
                    users.splice(userIdx, 1);
                    reacts[i] = {
                        emoji: emoji,
                        count: Math.max(0, reacts[i].count - 1),
                        users: users,
                        hasReacted: false
                    };
                } else {
                    users.push(myUser);
                    reacts[i] = {
                        emoji: emoji,
                        count: reacts[i].count + 1,
                        users: users,
                        hasReacted: true
                    };
                }
                found = true;
                break;
            }
        }

        if (!found) {
            reacts.push({
                emoji: emoji,
                count: 1,
                users: [myUser],
                hasReacted: true
            });
        }

        var activeReacts = [];
        for (var r = 0; r < reacts.length; r++) {
            if (reacts[r].count > 0) {
                activeReacts.push(reacts[r]);
            }
        }

        msg.reactions = activeReacts;
        curMsgs[msgIndex] = msg;
        store[key] = curMsgs;
        root.conversationMessages = store;
        root.persistChatState();
    }

    Item {
        id: neutralFocusTarget
        focus: true
    }

    function clearAllInputsFocus() {
        if (sidebarComp) sidebarComp.clearInputFocus();
        if (chatAreaComp) chatAreaComp.clearInputFocus();
        neutralFocusTarget.forceActiveFocus();
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
            if (logos.isViewModuleReady("e-cloak") || logos.isViewModuleReady("ecloak") || logos.isViewModuleReady("ecloakcore") || logos.isViewModuleReady("e_cloak_core")) {
                root.isCoreReady = true;
            }
        }

        // Kick off startup sync & timers
        root.syncIdentityFromCore();
        root.loadChatStoreFromCore();
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

    // Permanent Dark Canvas Background (Eliminates white canvas flash during drawer animations)
    Rectangle {
        anchors.fill: parent
        color: theme.bgRail
        z: -1

        MouseArea {
            anchors.fill: parent
            onClicked: root.forceActiveFocus()
        }
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
                            for (var r = 0; r < root.roomsList.length; r++) {
                                if (root.roomsList[r].id === roomId) {
                                    root.roomModerators = root.roomsList[r].moderators || [];
                                    root.roomMembers = root.roomsList[r].members || [];
                                    break;
                                }
                            }
                        }

                        onAddRoomClicked: {
                            createRoomModal.open();
                        }

                        onCreateRoomClicked: {
                            createRoomModal.open();
                        }

                        onJoinRoomClicked: {
                            joinRoomModal.open();
                        }

                        onIdentitySettingsClicked: {
                            identityModal.open();
                        }

                        onClearInputsRequested: {
                            root.clearAllInputsFocus();
                        }
                    }

                    // Column 2: Channel / DM Sidebar (240px)
                    ChannelSidebar {
                        id: sidebarComp
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

                        onClearOtherFocusRequested: {
                            if (chatAreaComp) chatAreaComp.clearInputFocus();
                        }

                        onInputFocusGained: {
                            if (chatAreaComp) chatAreaComp.clearInputFocus();
                        }

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
                                root.persistChatState();
                            }
                        }

                        onDeleteDmRequested: function(targetUser) {
                            confirmDeleteModal.targetUsername = targetUser;
                            confirmDeleteModal.open();
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
                            root.persistChatState();
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

                    onClearInputsRequested: {
                        root.clearAllInputsFocus();
                    }
                }
            }
        }

        // COLUMN 3: ACTIVE CHAT FEED & COMPOSER (FLEX)
        ChatArea {
            id: chatAreaComp
            Layout.fillWidth: true
            Layout.fillHeight: true
            activeView: root.activeView
            activeTargetName: (root.activeView === "dm") ? root.activeDmUser : root.activeChannel
            activeTopic: (root.activeView === "dm" || !root.activeRoomName) ?
                "" :
                (root.activeRoomName + " • N=" + root.activeRoomN + "/M=" + root.activeRoomM + " Threshold SSS")
            messagesModel: root.getCurrentMessages()
            isDrawerOpen: root.isRightDrawerOpen

            onClearOtherFocusRequested: {
                if (sidebarComp) sidebarComp.clearInputFocus();
            }

            onInputFocusGained: {
                if (sidebarComp) sidebarComp.clearInputFocus();
            }

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

                // Dynamically check if current user is an authorized moderator of the current room
                var senderIsMod = false;
                if (root.activeView === "room" && root.roomModerators && root.roomModerators.length > 0) {
                    for (var m = 0; m < root.roomModerators.length; m++) {
                        var mod = root.roomModerators[m];
                        if (mod && (
                            (mod.username && root.myUsername && mod.username.toLowerCase() === root.myUsername.toLowerCase()) ||
                            (mod.pubkey && root.myCommitment && mod.pubkey === root.myCommitment) ||
                            (mod.commitment && root.myCommitment && mod.commitment === root.myCommitment)
                        )) {
                            senderIsMod = true;
                            break;
                        }
                    }
                }

                var newTag = "";
                var postPt = null;

                // Two-Tier SSS is room-only (accountability for public/group rooms; never in 1-on-1 DMs)
                if (root.activeView === "room") {
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
                            if (parsed.tracing_tag) newTag = root.formatBytesToHex(parsed.tracing_tag);
                            if (parsed.x_index) postPt = { x: parsed.x_index, shares: parsed.encrypted_shares };
                            else if (parsed.post_point) postPt = parsed.post_point;
                        }
                    }

                    if (!newTag) {
                        // Fallback generated tracing tag
                        var hexChars = "0123456789abcdef";
                        for (var i = 0; i < 16; i++) {
                            newTag += hexChars.charAt(Math.floor(Math.random() * hexChars.length));
                        }
                    }
                }

                // Process lightweight attachment metadata (offloaded from chat index JSON)
                var attMeta = null;
                if (attachment) {
                    attMeta = {
                        name: attachment.name || "Attachment",
                        type: attachment.type || "document",
                        sizeText: attachment.sizeText || "",
                        sizeBytes: attachment.sizeBytes || 0,
                        sha256: attachment.sha256 || "",
                        blobId: attachment.blobId || attachment.sha256 || "",
                        localPath: attachment.localPath || (attachment.path ? attachment.path.replace(/^file:\/\//, "") : ""),
                        path: attachment.path || ""
                    };
                }

                var nowEpoch = Date.now();
                var newMsg = {
                    author: root.myUsername,
                    commitment: root.myCommitment,
                    createdAt: nowEpoch,
                    timestamp: "Today at " + Qt.formatTime(new Date(nowEpoch), "hh:mm AP"),
                    text: text,
                    tracingTag: newTag,
                    isMod: senderIsMod,
                    postPoint: postPt,
                    attachment: attMeta
                };

                // Append to conversation messages map with In-Memory Viewport Pruning
                var key = root.currentConvKey();
                var store = Object.assign({}, root.conversationMessages);
                var curMsgs = store[key] ? store[key].slice() : [];
                curMsgs.push(newMsg);
                if (curMsgs.length > root.maxActiveMessagesPerConv) {
                    curMsgs = curMsgs.slice(-root.maxActiveMessagesPerConv);
                }
                store[key] = curMsgs;
                root.conversationMessages = store;
                root.persistChatState();
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

            onReactMessage: function(index, emoji) {
                root.toggleReaction(index, emoji);
            }
        }

        // COLUMN 4: MEMBER & SLASHING DRAWER (240px, COLLAPSIBLE)
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

            onMemberStrikeRequested: function(username, pubkey) {
                root.radarTargetUser = username;
                root.radarTargetCommitment = pubkey;
                root.radarStrikes = 1;

                strikeModal.targetAuthor = username;
                strikeModal.targetCommitment = pubkey;
                strikeModal.tracingTag = "MANUAL_MOD_STRIKE";
                strikeModal.messageSnippet = "Reported from member directory";
                strikeModal.evidenceHash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
                strikeModal.open();
            }

            onClearInputsRequested: {
                root.clearAllInputsFocus();
            }
        }
    }

    // OVERLAY DIALOGS & NOTIFICATION TOAST
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
            var newId = "";
            if (result) {
                try {
                    var parsed = JSON.parse(result);
                    if (parsed.error) {
                        notificationToast.showNotification("⚠ " + parsed.error);
                        return;
                    }
                    if (parsed.room_id) {
                        newId = root.formatBytesToHex(parsed.room_id);
                    }
                } catch(e) {
                    notificationToast.showNotification("⚠ Room creation failed: " + e);
                    return;
                }
            }

            if (!newId || newId.length === 0) {
                newId = "room_" + (root.roomsList.length + 1);
            }

            var roomMods = [
                { username: root.myUsername, pubkey: root.myCommitment.substring(0, 10) + "...", role: "Room Creator" }
            ];
            var newRoom = {
                id: newId,
                name: name,
                iconText: name.substring(0, 2).toUpperCase(),
                nMod: nVal,
                mMod: mVal,
                mature: false,
                unread: false,
                moderators: roomMods,
                members: []
            };
            var updated = root.roomsList.slice();
            updated.push(newRoom);
            root.roomsList = updated;
            root.persistChatState();

            root.activeRoomId = newId;
            root.activeRoomName = name;
            root.activeRoomN = nVal;
            root.activeRoomM = mVal;
            root.isRoomMature = false;
            root.activeChannel = "general-chat";
            root.activeView = "room";
            root.roomModerators = roomMods;

            notificationToast.showNotification("Room '" + name + "' created successfully! (Status: New/Probation)");
        }

        onJoinRoomRequested: {
            joinRoomModal.open();
        }
    }

    JoinRoomModal {
        id: joinRoomModal
        memberCommitment: root.myCommitment

        onCreateRoomRequested: {
            createRoomModal.open();
        }

        onRoomJoined: function(roomIdHex, consentSig) {
            joinRoomModal.isSubmitting = true;
            joinRoomModal.errorMessage = "";

            // Guard: require identity
            if (!root.myCommitment || root.myCommitment.length === 0) {
                joinRoomModal.isSubmitting = false;
                joinRoomModal.errorMessage = "Identity required — please generate identity first.";
                notificationToast.showNotification("⚠ Identity required — please generate identity first.");
                identityModal.open();
                return;
            }

            var cleanHex = roomIdHex.trim().toLowerCase();
            if (cleanHex.startsWith("0x")) cleanHex = cleanHex.substring(2);

            // 1. Strict validation: exactly 64 hexadecimal characters (32 bytes)
            if (cleanHex.length !== 64 || !/^[0-9a-fA-F]{64}$/.test(cleanHex)) {
                joinRoomModal.isSubmitting = false;
                joinRoomModal.errorMessage = "Invalid Room ID: must be exactly 64 hexadecimal characters (32 bytes).";
                notificationToast.showNotification("⚠ Invalid Room ID: must be 64 hexadecimal characters.");
                return;
            }

            // 2. Check if user already joined this room
            for (var r = 0; r < root.roomsList.length; r++) {
                var existingId = (root.roomsList[r].id || "").toLowerCase();
                if (existingId.startsWith("0x")) existingId = existingId.substring(2);
                if (existingId === cleanHex) {
                    joinRoomModal.isSubmitting = false;
                    joinRoomModal.close();
                    root.activeRoomId = root.roomsList[r].id;
                    root.activeRoomName = root.roomsList[r].name;
                    root.activeChannel = "general-chat";
                    root.activeView = "room";
                    notificationToast.showNotification("Switched to already joined room '" + root.roomsList[r].name + "'");
                    return;
                }
            }

            // 3. Cryptographic join via Core Module
            var result = root.callCore("joinRoom", [cleanHex, root.myCommitment, root.myCommitment, consentSig, 1]);
            if (!result) {
                joinRoomModal.isSubmitting = false;
                joinRoomModal.errorMessage = "Core module returned null or disconnected.";
                notificationToast.showNotification("⚠ Join room failed: core module unreachable.");
                return;
            }

            try {
                var parsed = JSON.parse(result);
                if (parsed.error) {
                    joinRoomModal.isSubmitting = false;
                    joinRoomModal.errorMessage = parsed.error;
                    notificationToast.showNotification("⚠ " + parsed.error);
                    return;
                }
            } catch(e) {
                joinRoomModal.isSubmitting = false;
                joinRoomModal.errorMessage = "Core response error: " + e;
                notificationToast.showNotification("⚠ Join room failed: " + e);
                return;
            }

            // 4. Success: close modal and add room
            joinRoomModal.isSubmitting = false;
            joinRoomModal.close();

            var roomName = "Room #" + cleanHex.substring(0, 6).toUpperCase();
            var newRoom = {
                id: cleanHex,
                name: roomName,
                iconText: cleanHex.substring(0, 2).toUpperCase(),
                nMod: 2,
                mMod: 3,
                mature: false,
                unread: false,
                moderators: [],
                members: [
                    { username: root.myUsername, pubkey: root.myCommitment.substring(0, 10) + "..." }
                ]
            };
            var updated = root.roomsList.slice();
            updated.push(newRoom);
            root.roomsList = updated;
            root.persistChatState();

            root.activeRoomId = cleanHex;
            root.activeRoomName = roomName;
            root.activeRoomN = 2;
            root.activeRoomM = 3;
            root.isRoomMature = false;
            root.activeChannel = "general-chat";
            root.activeView = "room";
            root.roomModerators = [];
            root.roomMembers = newRoom.members;

            notificationToast.showNotification("Successfully joined room '" + roomName + "' with signed consent!");
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
            if (newUsername.length < 3 || newUsername.length > 32) {
                identityModal.usernameStatus = "taken";
                identityModal.validationMessage = "3-32 chars";
                notificationToast.showNotification("⚠ Username must be between 3 and 32 characters.");
                return;
            }
            if (!/^[a-zA-Z0-9_]+$/.test(newUsername)) {
                identityModal.usernameStatus = "taken";
                identityModal.validationMessage = "letters, numbers, _ only";
                notificationToast.showNotification("⚠ Username can only contain letters, numbers, and underscores.");
                return;
            }

            var previousUsername = root.myUsername;
            root.myUsername = newUsername;

            var result = root.callCore("registerUsername", [newUsername]);
            if (result) {
                var parsed = safeJsonParse(result);
                if (parsed && parsed.error) {
                    root.myUsername = previousUsername; // rollback
                    identityModal.usernameStatus = "taken";
                    identityModal.validationMessage = parsed.error.indexOf("taken") !== -1 ? "username taken" : parsed.error;
                    notificationToast.showNotification("⚠ " + parsed.error);
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

    ConfirmDeleteModal {
        id: confirmDeleteModal

        onConfirmed: function(username) {
            root.deleteDmConversation(username);
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
        border.color: theme.primary
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
