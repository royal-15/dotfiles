import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.network

Item {
    id: root

    property string activeTab: "wifi"
    property int keyboardSelectedIndex: -1
    property string keyboardSelectedKey: ""
    property bool keyboardNavActive: false
    property bool isCurrentTab: false
    signal closeRequested()
    property var wifiNetworks: NetworkCenterState.wifiNetworks
    property var wifiProfiles: NetworkCenterState.wifiProfiles
    property var pairedDevices: NetworkCenterState.pairedDevices
    property var nearbyDevices: NetworkCenterState.nearbyDevices
    property var connectedDevices: NetworkCenterState.connectedDevices
    property var bluetoothBatteries: NetworkCenterState.bluetoothBatteries
    property var bluetoothBatteryAddresses: NetworkCenterState.bluetoothBatteryAddresses
    property string wifiDevice: NetworkCenterState.wifiDevice
    property string notice: NetworkCenterState.globalNotice
    property bool wifiBusy: NetworkCenterState.wifiBusy
    property bool bluetoothBusy: NetworkCenterState.bluetoothBusy
    readonly property bool busy: wifiBusy || bluetoothBusy
    readonly property bool activeBusy: activeTab === "wifi" ? wifiBusy : bluetoothBusy
    property bool confirmingForget: false
    property string forgetUuid: ""
    property string forgetName: ""
    property string forgetKind: "wifi"
    property string pendingSsid: ""
    property string pendingSecurity: ""
    property string pairingAddress: ""
    property string pairingName: ""
    property string pairingPrompt: ""
    property bool pairingInputRequired: false
    property string pairingPasskey: ""
    property bool pairingStarted: false
    property bool pairingCancellationPending: false
    property var wifiCommandQueue: NetworkCenterState.wifiCommandQueue
    property var wifiCommandResults: NetworkCenterState.wifiCommandResults
    property int wifiCommandIndex: NetworkCenterState.wifiCommandIndex
    property string wifiPendingOperation: NetworkCenterState.wifiPendingOperation
    property string wifiPendingTarget: NetworkCenterState.wifiPendingTarget
    property bool wifiPreviousRadioEnabled: NetworkCenterState.wifiPreviousRadioEnabled
    property bool wifiRefreshWhenIdle: NetworkCenterState.wifiRefreshWhenIdle
    onWifiNetworksChanged: reconcileKeyboardSelection()
    onPairedDevicesChanged: syncBluetoothList()
    onConnectedDevicesChanged: syncBluetoothList()
    onNearbyDevicesChanged: syncBluetoothList()
    onBluetoothBatteriesChanged: syncBluetoothList()
    onPairingInputRequiredChanged: {
        if (pairingDialog.visible)
            Qt.callLater(() => pairingDialog.focusPairingTarget());
    }
    onPairingStartedChanged: {
        if (pairingDialog.visible)
            Qt.callLater(() => pairingDialog.focusPairingTarget());
    }
    onPairingPromptChanged: {
        if (pairingDialog.visible)
            Qt.callLater(() => pairingDialog.focusPairingTarget());
    }
    onPairingPasskeyChanged: {
        if (pairingDialog.visible)
            Qt.callLater(() => pairingDialog.focusPairingTarget());
    }
    onWifiBusyChanged: {
        if (activeTab === "wifi")
            restoreKeyboardFocus();
    }
    property var bluetoothCommandQueue: NetworkCenterState.bluetoothCommandQueue
    property var bluetoothCommandResults: NetworkCenterState.bluetoothCommandResults
    property int bluetoothCommandIndex: NetworkCenterState.bluetoothCommandIndex
    property string bluetoothPendingOperation: NetworkCenterState.bluetoothPendingOperation
    property string bluetoothPendingTarget: NetworkCenterState.bluetoothPendingTarget
    property bool bluetoothPreviousRadioEnabled: NetworkCenterState.bluetoothPreviousRadioEnabled
    property bool bluetoothRefreshWhenIdle: NetworkCenterState.bluetoothRefreshWhenIdle
    onBluetoothBusyChanged: {
        if (activeTab === "bluetooth")
            restoreKeyboardFocus();
    }
    property bool wifiEnabled: NetworkCenterState.wifiEnabled
    property bool bluetoothEnabled: NetworkCenterState.bluetoothEnabled
    property bool wifiLoaded: NetworkCenterState.wifiLoaded
    property bool bluetoothLoaded: NetworkCenterState.bluetoothLoaded
    property bool wifiScanActive: NetworkCenterState.wifiScanActive
    property bool bluetoothScanActive: NetworkCenterState.bluetoothScanActive
    property string wifiError: NetworkCenterState.wifiError
    property string bluetoothError: NetworkCenterState.bluetoothError
    property string wifiScanError: NetworkCenterState.wifiScanError
    property string bluetoothScanError: NetworkCenterState.bluetoothScanError
    property bool closingWithAnimation: false
    readonly property bool isOpen: visible
    readonly property real contentRevealProgress: 1.0
    readonly property bool wifiSearching: wifiScanActive
    readonly property bool bluetoothSearching: bluetoothScanActive
    readonly property bool activeSearching: activeTab === "wifi" ? wifiEnabled && wifiSearching : bluetoothEnabled && bluetoothSearching
    readonly property bool activeEnabled: activeTab === "wifi" ? wifiEnabled : bluetoothEnabled
    readonly property string activeError: activeTab === "wifi" ? wifiError : bluetoothError
    readonly property string activeStatus: activeSearching ? (activeTab === "wifi" ? "Searching for networks" : "Searching for nearby devices") : activeError ? "Connection issue" : activeBusy ? "Updating connections" : activeEnabled ? (activeTab === "wifi" ? "Networks nearby" : "Your devices") : (activeTab === "wifi" ? "Wi‑Fi is turned off" : "Bluetooth is turned off")
    readonly property bool noticeIsError: /failed|error|could not|cannot|timed out|not available|no default|busy|blocked|in progress|please wait/i.test(notice)

    readonly property bool activeRadioOn: activeTab === "wifi" ? wifiEnabled : bluetoothEnabled
    readonly property int rawAvailableCount: activeTab === "wifi" ? wifiNetworks.length : (pairedDevices.length + nearbyDevices.length)

    // Smooth banner animation progress token inside the fixed panel
    property real bannerProgress: root.activeSearching ? 1.0 : 0.0
    Behavior on bannerProgress {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    function updateStableItemCount() { }

    implicitWidth: 360
    implicitHeight: 540

    readonly property bool dialogOpen: passwordDialog.visible || pairingDialog.visible || forgetDialog.visible

    function splitEscaped(line) {
        const fields = [];
        let field = "";
        let escaped = false;
        for (let i = 0; i < line.length; ++i) {
            const ch = line[i];
            if (escaped) {
                field += ch;
                escaped = false;
            } else if (ch === "\\") {
                escaped = true;
            } else if (ch === ":") {
                fields.push(field);
                field = "";
            } else {
                field += ch;
            }
        }
        if (escaped)
            field += "\\";
        fields.push(field);
        return fields;
    }

    function splitLines(value) {
        return value.split(/\r?\n/).filter((line) => line.length > 0);
    }

    Timer {
        id: noticeTimer
        interval: 4000
        repeat: false
        onTriggered: NetworkCenterState.globalNotice = ""
    }

    function setMessage(message) {
        NetworkCenterState.globalNotice = message || "";
        if (message)
            noticeTimer.restart();
        else
            noticeTimer.stop();
    }

    function syncBluetoothList() {
        if (!root.visible && !root.closingWithAnimation)
            return;

        const desired = pairedDevices.map((device) => ({
            address: device.address,
            name: device.name,
            nearby: false,
            connected: connectedDevices.some((item) => item.address === device.address),
            battery: bluetoothBatteries[device.address] === undefined ? -1 : bluetoothBatteries[device.address]
        })).concat(bluetoothEnabled ? nearbyDevices.map((device) => ({
            address: device.address,
            name: device.name,
            nearby: true,
            connected: false,
            battery: -1
        })) : []);

        for (let targetIndex = 0; targetIndex < desired.length; ++targetIndex) {
            const device = desired[targetIndex];
            let currentIndex = -1;
            for (let index = targetIndex; index < bluetoothListModel.count; ++index) {
                if (bluetoothListModel.get(index).address === device.address) {
                    currentIndex = index;
                    break;
                }
            }
            if (currentIndex < 0) {
                bluetoothListModel.insert(targetIndex, device);
            } else {
                if (currentIndex !== targetIndex)
                    bluetoothListModel.move(currentIndex, targetIndex, 1);
                bluetoothListModel.set(targetIndex, device);
            }
        }
        while (bluetoothListModel.count > desired.length)
            bluetoothListModel.remove(bluetoothListModel.count - 1);
        if (activeTab === "bluetooth")
            reconcileKeyboardSelection();
    }

    function toggleCenter() {
        if (visible && !closingWithAnimation)
            requestClose();
        else
            openForKeyboard(activeTab);
    }

    function activeKeyboardItemCount() {
        return activeTab === "wifi" ? wifiNetworks.length : bluetoothListModel.count;
    }

    function keyboardItemKeyAt(index, tab) {
        const listTab = tab || activeTab;
        if (index < 0 || index >= (listTab === "wifi" ? wifiNetworks.length : bluetoothListModel.count))
            return "";

        if (listTab === "wifi") {
            const network = wifiNetworks[index];
            if (network.bssid)
                return "wifi-bssid:" + network.bssid;
            if (network.savedUuid)
                return "wifi-profile:" + network.savedUuid;
            return "wifi-ssid:" + (network.ssid || "") + "\u001f" + (network.security || "");
        }

        return "bluetooth:" + bluetoothListModel.get(index).address;
    }

    function keyboardIndexForKey(key, tab) {
        if (!key)
            return -1;
        const listTab = tab || activeTab;
        const count = listTab === "wifi" ? wifiNetworks.length : bluetoothListModel.count;
        for (let index = 0; index < count; ++index) {
            if (keyboardItemKeyAt(index, listTab) === key)
                return index;
        }
        return -1;
    }

    function ensureKeyboardSelectionVisible() {
        if (!visible || closingWithAnimation)
            return;

        const selectedIndex = keyboardSelectedIndex;
        Qt.callLater(() => {
            if (!root.visible || root.closingWithAnimation || root.keyboardSelectedIndex !== selectedIndex)
                return;
            const list = root.activeTab === "wifi" ? wifiList : bluetoothList;
            if (selectedIndex >= 0 && selectedIndex < list.count)
                list.positionViewAtIndex(selectedIndex, ListView.Contain);
        });
    }

    function focusKeyboardTarget() {
        if (!isCurrentTab || root.dialogOpen)
            return;
        panelFocusScope.forceActiveFocus();
        ensureKeyboardSelectionVisible();
    }

    function handleEscape() {
        if (passwordDialog.visible) {
            passwordDialog.close();
            return true;
        } else if (pairingDialog.visible) {
            cancelPairing();
            return true;
        } else if (forgetDialog.visible) {
            forgetDialog.close();
            confirmingForget = false;
            return true;
        } else {
            root.closeRequested();
            return true;
        }
    }

    function restoreKeyboardFocus() {
        Qt.callLater(() => {
            if (root.visible && !root.closingWithAnimation && !passwordDialog.visible && !pairingDialog.visible && !forgetDialog.visible) {
                if (!root.keyboardNavActive)
                    root.resolveInitialFocus(root.activeTab);
                root.focusKeyboardTarget();
            }
        });
    }

    function selectKeyboardItem(index) {
        const count = activeKeyboardItemCount();
        if (count === 0) {
            keyboardSelectedIndex = -1;
            keyboardSelectedKey = "";
            return;
        }

        keyboardNavActive = true;
        keyboardSelectedIndex = Math.max(0, Math.min(index, count - 1));
        keyboardSelectedKey = keyboardItemKeyAt(keyboardSelectedIndex, activeTab);
        focusKeyboardTarget();
    }

    function reconcileKeyboardSelection() {
        if (!root.visible && !root.closingWithAnimation)
            return;

        const count = activeKeyboardItemCount();
        if (count === 0) {
            keyboardSelectedIndex = -1;
            keyboardSelectedKey = "";
            return;
        }

        if (!keyboardNavActive) {
            keyboardSelectedIndex = -1;
            keyboardSelectedKey = "";
            return;
        }

        let selectedIndex = keyboardIndexForKey(keyboardSelectedKey, activeTab);
        if (selectedIndex < 0) {
            selectedIndex = 0;
        }
        keyboardSelectedIndex = selectedIndex;
        keyboardSelectedKey = keyboardItemKeyAt(selectedIndex, activeTab);
        ensureKeyboardSelectionVisible();
    }

    function openForKeyboard(tab) {
        if (passwordDialog.visible || pairingDialog.visible || forgetDialog.visible)
            return;
        keyboardNavActive = true;
        keyboardSelectedIndex = -1;
        keyboardSelectedKey = "";
        StatusBarPanelCoordinator.openPanel(root, tab);
    }

    function resolveInitialFocus(tab) {
        const resolvedTab = tab || activeTab;
        const radioOn = resolvedTab === "wifi" ? wifiEnabled : bluetoothEnabled;
        const itemCount = resolvedTab === "wifi" ? wifiNetworks.length : bluetoothListModel.count;
        if (radioOn && itemCount > 0) {
            keyboardSelectedIndex = 0;
            keyboardSelectedKey = keyboardItemKeyAt(0, resolvedTab);
        } else {
            keyboardSelectedIndex = -1;
            keyboardSelectedKey = "";
        }
        keyboardNavActive = true;
    }

    function openNow(tab) {
        if (passwordDialog.visible || pairingDialog.visible || forgetDialog.visible)
            return;
        activeTab = tab || activeTab;
        resolveInitialFocus(activeTab);
        syncBluetoothList();
        reconcileKeyboardSelection();
        if (activeTab === "wifi") {
            if (wifiNetworks.length === 0 && wifiEnabled)
                scanWifi();
            else
                refreshWifi();
        } else {
            refreshBluetooth();
        }
        Qt.callLater(() => root.focusKeyboardTarget());
    }

    function moveKeyboardSelection(direction) {
        keyboardNavActive = true;
        const count = activeKeyboardItemCount();
        if (count === 0)
            return;
        if (keyboardSelectedIndex < 0) {
            selectKeyboardItem(direction > 0 ? 0 : count - 1);
            return;
        }
        if (direction < 0) {
            if (keyboardSelectedIndex > 0)
                selectKeyboardItem(keyboardSelectedIndex - 1);
        } else if (keyboardSelectedIndex < count - 1) {
            selectKeyboardItem(keyboardSelectedIndex + 1);
        }
    }

    function setKeyboardTab(tab) {
        activeTab = tab;
        resolveInitialFocus(tab);
        Qt.callLater(() => root.focusKeyboardTarget());
    }

    function switchKeyboardTab() {
        setKeyboardTab(activeTab === "wifi" ? "bluetooth" : "wifi");
    }

    function activateKeyboardSelection() {
        if (keyboardSelectedIndex < 0)
            return;

        const selectedIndex = keyboardIndexForKey(keyboardSelectedKey, activeTab);
        if (selectedIndex < 0) {
            reconcileKeyboardSelection();
            return;
        }
        keyboardSelectedIndex = selectedIndex;

        if (activeTab === "wifi") {
            const network = wifiNetworks[selectedIndex];
            if (network && !wifiBusy && wifiEnabled && (network.ssid !== "" || network.savedUuid !== "" || network.inUse))
                activateWifi(network);
        } else {
            const device = bluetoothListModel.get(selectedIndex);
            if (device && !bluetoothBusy && bluetoothEnabled)
                bluetoothAction(device.nearby ? "pair" : device.connected ? "disconnect" : "connect", device);
        }
    }

    function handlePanelKey(event) {
        if (!isCurrentTab || root.dialogOpen)
            return;

        if (event.key === Qt.Key_Escape) {
            handleEscape();
            event.accepted = true;
            return;
        }

        if ((event.modifiers & Qt.ControlModifier) !== 0) {
            if (event.key === Qt.Key_T && !event.isAutoRepeat) {
                root.toggleActiveRadio();
                event.accepted = true;
            } else if (event.key === Qt.Key_R && !event.isAutoRepeat) {
                root.activeTab === "wifi" ? root.scanWifi() : root.scanBluetooth();
                event.accepted = true;
            }
            return;
        }

        if (event.key === Qt.Key_Left) {
            setKeyboardTab("wifi");
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            setKeyboardTab("bluetooth");
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            moveKeyboardSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            moveKeyboardSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            if (!event.isAutoRepeat)
                switchKeyboardTab();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            if (!event.isAutoRepeat)
                switchKeyboardTab();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat)
                activateKeyboardSelection();
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat)
                activateKeyboardSelection();
            event.accepted = true;
        } else if (event.key === Qt.Key_T) {
            if (!event.isAutoRepeat)
                root.toggleActiveRadio();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            if (!event.isAutoRepeat)
                root.activeTab === "wifi" ? root.scanWifi() : root.scanBluetooth();
            event.accepted = true;
        }
    }

    function closeImmediate() {
        passwordDialog.close();
        if (NetworkPairingRunner.isRunning(root))
            cancelPairing();
        else
            pairingDialog.close();
        forgetDialog.close();
        confirmingForget = false;
    }

    function requestClose() {
        passwordDialog.close();
        if (NetworkPairingRunner.isRunning(root))
            cancelPairing();
        else
            pairingDialog.close();
        forgetDialog.close();
        confirmingForget = false;
        root.closeRequested();
    }

    function commandSucceeded(result) {
        return !!result && result.code === 0 && !/failed|error:|timed out/i.test((result.out || "") + "\n" + (result.err || ""));
    }

    function commandResult(radio, index) {
        const results = radio === "wifi" ? wifiCommandResults : bluetoothCommandResults;
        return results[index] || { code: -1, out: "", err: "No command result was received." };
    }

    function commandError(result, fallback) {
        const detail = (result.err || result.out || "").trim().split(/\r?\n/)[0];
        return detail ? detail.slice(0, 140) : fallback;
    }

    function startCommands(radio, commands, operation, target) {
        if (!commands || commands.length === 0)
            return;
        if (radio === "wifi") {
            if (wifiBusy)
                return;
            NetworkCenterState.wifiCommandQueue = commands;
            NetworkCenterState.wifiCommandResults = [];
            NetworkCenterState.wifiCommandIndex = 0;
            NetworkCenterState.wifiPendingOperation = operation || "";
            NetworkCenterState.wifiPendingTarget = target || "";
            NetworkCenterState.wifiBusy = true;
            if (wifiPendingOperation === "scanWifi" || wifiPendingOperation === "wifiAction" || wifiPendingOperation === "forget" || wifiPendingOperation === "radioToggle") {
                NetworkCenterState.wifiError = "";
                NetworkCenterState.wifiScanError = "";
            }
        } else {
            if (bluetoothBusy)
                return;
            NetworkCenterState.bluetoothCommandQueue = commands;
            NetworkCenterState.bluetoothCommandResults = [];
            NetworkCenterState.bluetoothCommandIndex = 0;
            NetworkCenterState.bluetoothPendingOperation = operation || "";
            NetworkCenterState.bluetoothPendingTarget = target || "";
            NetworkCenterState.bluetoothBusy = true;
            if (bluetoothPendingOperation === "scanBluetooth" || bluetoothPendingOperation === "bluetoothAction" || bluetoothPendingOperation === "unpair" || bluetoothPendingOperation === "radioToggle") {
                NetworkCenterState.bluetoothError = "";
                NetworkCenterState.bluetoothScanError = "";
            }
        }
        if (!(radio === "wifi" ? wifiPendingOperation : bluetoothPendingOperation).startsWith("refresh"))
            setMessage("");
        runNextCommand(radio);
    }

    function runNextCommand(radio) {
        const commandIndex = radio === "wifi" ? wifiCommandIndex : bluetoothCommandIndex;
        const commandQueue = radio === "wifi" ? wifiCommandQueue : bluetoothCommandQueue;
        if (commandIndex >= commandQueue.length) {
            if (radio === "wifi")
                NetworkCenterState.wifiBusy = false;
            else
                NetworkCenterState.bluetoothBusy = false;
            const completedOperation = radio === "wifi" ? wifiPendingOperation : bluetoothPendingOperation;
            if (completedOperation === "refreshWifi")
                NetworkCenterState.wifiRefreshWhenIdle = false;
            else if (completedOperation === "refreshBluetooth")
                NetworkCenterState.bluetoothRefreshWhenIdle = false;
            finishCommands(radio);
            if (radio === "wifi" && wifiRefreshWhenIdle && !wifiBusy) {
                NetworkCenterState.wifiRefreshWhenIdle = false;
                Qt.callLater(() => root.refreshWifi());
            } else if (radio === "bluetooth" && bluetoothRefreshWhenIdle && !bluetoothBusy) {
                NetworkCenterState.bluetoothRefreshWhenIdle = false;
                Qt.callLater(() => root.refreshBluetooth());
            } else if (radio === "wifi" && wifiBusy) {
                NetworkCenterState.wifiRefreshWhenIdle = false;
            } else if (radio === "bluetooth" && bluetoothBusy) {
                NetworkCenterState.bluetoothRefreshWhenIdle = false;
            }
            return;
        }
        NetworkCommandRunner.execute(root, radio, commandQueue[commandIndex]);
    }

    function finishCommands(radio) {
        const pendingOperation = radio === "wifi" ? wifiPendingOperation : bluetoothPendingOperation;
        const pendingTarget = radio === "wifi" ? wifiPendingTarget : bluetoothPendingTarget;
        if (pendingOperation === "refreshWifi") {
            const deviceResult = commandResult("wifi", 0);
            const networksResult = commandResult("wifi", 1);
            const profilesResult = commandResult("wifi", 2);
            const radioResult = commandResult("wifi", 3);
            if (commandSucceeded(deviceResult)) {
                let currentDevice = "";
                for (const line of splitLines(deviceResult.out)) {
                    const fields = splitEscaped(line);
                    if (fields.length > 1 && fields[1] === "wifi") {
                        currentDevice = fields[0];
                        break;
                    }
                }
                NetworkCenterState.wifiDevice = currentDevice;
            }
            const rows = commandSucceeded(networksResult) ? [] : wifiNetworks.filter((network) => !network.savedOnly);
            if (commandSucceeded(networksResult)) {
                for (const line of splitLines(networksResult.out)) {
                    const fields = splitEscaped(line);
                    if (fields.length < 5)
                        continue;
                    const parsedSignal = parseInt(fields[3], 10);
                    rows.push({
                        inUse: fields[0] === "*",
                        bssid: fields[1],
                        ssid: fields[2],
                        signal: isNaN(parsedSignal) ? 0 : Math.max(0, Math.min(100, parsedSignal)),
                        security: fields[4],
                        savedUuid: "",
                        savedName: ""
                    });
                }
            }
            if (commandSucceeded(radioResult))
                NetworkCenterState.wifiEnabled = radioResult.out.trim() === "enabled";
            const wifiRadioOff = commandSucceeded(radioResult) && !wifiEnabled;
            if (wifiRadioOff) {
                rows.splice(0, rows.length);
                NetworkCenterState.wifiScanError = "";
            }
            let profiles = wifiProfiles;
            if (commandSucceeded(profilesResult)) {
                profiles = [];
                for (const line of splitLines(profilesResult.out)) {
                    const fields = splitEscaped(line);
                    if (fields.length < 4 || fields[2] !== "802-11-wireless")
                        continue;
                    profiles.push({ uuid: fields[0], name: fields[1], device: fields[3] });
                }
                NetworkCenterState.wifiProfiles = profiles;
            }
            if (commandSucceeded(networksResult) || commandSucceeded(profilesResult) || wifiRadioOff) {
                let networkRows = rows.map((network) => {
                    const profile = profiles.find((item) => item.name === network.ssid);
                    return profile ? Object.assign({}, network, { savedUuid: profile.uuid, savedName: profile.name }) : network;
                });
                for (const profile of profiles) {
                    if (!networkRows.some((network) => network.savedUuid === profile.uuid))
                        networkRows.push({ inUse: false, ssid: profile.name, signal: 0, security: "", savedUuid: profile.uuid, savedName: profile.name, savedOnly: true });
                }
                NetworkCenterState.wifiNetworks = networkRows;
            }
            if (!wifiEnabled && commandSucceeded(radioResult))
                NetworkCenterState.wifiScanError = "";
            NetworkCenterState.wifiLoaded = true;
            NetworkCenterState.wifiScanActive = false;
            const failedWifiCommand = [deviceResult, wifiRadioOff ? null : networksResult, profilesResult, radioResult].filter((result) => !!result).find((result) => !commandSucceeded(result));
            NetworkCenterState.wifiError = failedWifiCommand ? commandError(failedWifiCommand, "Could not refresh Wi‑Fi networks.") : wifiRadioOff ? "" : wifiScanError;
            if (wifiError)
                setMessage(wifiError);
        } else if (pendingOperation === "refreshBluetooth") {
            const pairedResult = commandResult("bluetooth", 0);
            const connectedResult = commandResult("bluetooth", 1);
            const devicesResult = commandResult("bluetooth", 2);
            const powerResult = commandResult("bluetooth", 3);
            const paired = commandSucceeded(pairedResult) ? parseDevices(pairedResult.out) : pairedDevices;
            const connected = commandSucceeded(connectedResult) ? parseDevices(connectedResult.out) : connectedDevices;
            const allDevices = commandSucceeded(devicesResult) ? parseDevices(devicesResult.out) : nearbyDevices;
            if (commandSucceeded(powerResult))
                NetworkCenterState.bluetoothEnabled = powerResult.out.indexOf("Powered: yes") >= 0;
            const bluetoothRadioOff = commandSucceeded(powerResult) && !bluetoothEnabled;
            if (bluetoothRadioOff)
                NetworkCenterState.bluetoothScanError = "";
            NetworkCenterState.pairedDevices = paired;
            NetworkCenterState.connectedDevices = connected;
            NetworkCenterState.nearbyDevices = allDevices.filter((item) => !paired.some((saved) => saved.address === item.address));
            const pairedAddresses = paired.map((item) => item.address).filter((address, index, addresses) => addresses.indexOf(address) === index);
            const retainedBatteries = {};
            for (const address of pairedAddresses) {
                if (bluetoothBatteries[address] !== undefined)
                    retainedBatteries[address] = bluetoothBatteries[address];
            }
            NetworkCenterState.bluetoothBatteries = retainedBatteries;
            NetworkCenterState.bluetoothBatteryAddresses = bluetoothEnabled ? pairedAddresses : [];
            syncBluetoothList();
            NetworkCenterState.bluetoothLoaded = true;
            NetworkCenterState.bluetoothScanActive = false;
            const failedBtCommand = [bluetoothRadioOff ? null : pairedResult, bluetoothRadioOff ? null : connectedResult, bluetoothRadioOff ? null : devicesResult, powerResult].filter((result) => !!result).find((result) => !commandSucceeded(result));
            NetworkCenterState.bluetoothError = failedBtCommand ? commandError(failedBtCommand, "Could not refresh Bluetooth devices.") : bluetoothRadioOff ? "" : bluetoothScanError;
            if (bluetoothError)
                setMessage(bluetoothError);
            if (bluetoothBatteryAddresses.length > 0)
                startCommands("bluetooth", bluetoothBatteryAddresses.map((address) => ["bluetoothctl", "info", address]), "refreshBluetoothBattery");
        } else if (pendingOperation === "refreshBluetoothBattery") {
            const updatedBatteries = {};
            for (const device of pairedDevices) {
                if (bluetoothBatteries[device.address] !== undefined)
                    updatedBatteries[device.address] = bluetoothBatteries[device.address];
            }
            for (let index = 0; index < bluetoothBatteryAddresses.length; ++index) {
                const result = commandResult("bluetooth", index);
                if (!commandSucceeded(result))
                    continue;
                const percentage = parseBatteryPercentage(result.out);
                if (percentage >= 0)
                    updatedBatteries[bluetoothBatteryAddresses[index]] = percentage;
            }
            NetworkCenterState.bluetoothBatteries = updatedBatteries;
            syncBluetoothList();
        } else if (pendingOperation === "scanWifi") {
            const result = commandResult("wifi", 0);
            if (!commandSucceeded(result)) {
                NetworkCenterState.wifiScanError = commandError(result, "Could not scan for Wi‑Fi networks.");
                NetworkCenterState.wifiError = wifiScanError;
                setMessage(wifiError);
            }
            refreshWifi();
        } else if (pendingOperation === "scanBluetooth") {
            const result = commandResult("bluetooth", 0);
            if (!commandSucceeded(result)) {
                NetworkCenterState.bluetoothScanError = commandError(result, "Could not scan for Bluetooth devices.");
                NetworkCenterState.bluetoothError = bluetoothScanError;
                setMessage(bluetoothError);
            }
            refreshBluetooth();
        } else if (pendingOperation === "wifiAction") {
            const result = commandResult("wifi", 0);
            setMessage(commandSucceeded(result) ? "Wi‑Fi updated." : commandError(result, "Wi‑Fi action failed."));
            refreshWifi();
        } else if (pendingOperation === "forget") {
            const result = commandResult("wifi", 0);
            setMessage(commandSucceeded(result) ? `Forgot ${pendingTarget}.` : commandError(result, "Could not forget network."));
            confirmingForget = false;
            refreshWifi();
        } else if (pendingOperation === "bluetoothAction") {
            const result = commandResult("bluetooth", 0);
            setMessage(commandSucceeded(result) ? "Bluetooth updated." : commandError(result, "Bluetooth action failed."));
            refreshBluetooth();
        } else if (pendingOperation === "unpair") {
            const result = commandResult("bluetooth", 0);
            setMessage(commandSucceeded(result) ? `Unpaired ${pendingTarget}.` : commandError(result, "Could not unpair device."));
            refreshBluetooth();
        } else if (pendingOperation === "radioToggle") {
            const result = commandResult(radio, 0);
            let message;
            if (commandSucceeded(result)) {
                message = (radio === "wifi")
                    ? (wifiEnabled ? "Wi‑Fi turned on." : "Wi‑Fi turned off.")
                    : (bluetoothEnabled ? "Bluetooth turned on." : "Bluetooth turned off.");
            } else {
                if (radio === "wifi")
                    NetworkCenterState.wifiEnabled = wifiPreviousRadioEnabled;
                else
                    NetworkCenterState.bluetoothEnabled = bluetoothPreviousRadioEnabled;
                message = commandError(result, radio === "wifi" ? "Could not change Wi‑Fi setting." : "Could not change Bluetooth setting.");
            }
            if (radio === "wifi")
                refreshWifi();
            else
                refreshBluetooth();
            setMessage(message);
        }
    }

    function parseDevices(output) {
        const result = [];
        for (const line of splitLines(output)) {
            const match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
            if (match)
                result.push({ address: match[1], name: match[2] });
        }
        return result;
    }

    function parseBatteryPercentage(output) {
        for (const line of splitLines(output)) {
            const match = line.match(/^\s*Battery Percentage:\s*(0x[0-9a-f]+|\d{1,3})(?:\s+\((\d{1,3})%?\))?/i);
            if (!match)
                continue;
            const value = match[2] !== undefined ? parseInt(match[2], 10) : /^0x/i.test(match[1]) ? parseInt(match[1], 16) : parseInt(match[1], 10);
            return !isNaN(value) && value >= 0 && value <= 100 ? value : -1;
        }
        return -1;
    }

    function refreshWifi() {
        if (wifiBusy) {
            NetworkCenterState.wifiRefreshWhenIdle = true;
            return;
        }
        NetworkCenterState.wifiRefreshWhenIdle = false;
        startCommands("wifi", [
            ["nmcli", "-t", "-f", "DEVICE,TYPE", "device", "status"],
            ["nmcli", "-t", "-f", "IN-USE,BSSID,SSID,SIGNAL,SECURITY", "device", "wifi", "list"],
            ["nmcli", "-t", "-f", "UUID,NAME,TYPE,DEVICE", "connection", "show"],
            ["nmcli", "-t", "radio", "wifi"]
        ], "refreshWifi");
    }

    function refreshBluetooth() {
        if (bluetoothBusy) {
            NetworkCenterState.bluetoothRefreshWhenIdle = true;
            return;
        }
        NetworkCenterState.bluetoothRefreshWhenIdle = false;
        startCommands("bluetooth", [
            ["bluetoothctl", "devices", "Paired"],
            ["bluetoothctl", "devices", "Connected"],
            ["bluetoothctl", "devices"],
            ["bluetoothctl", "show"]
        ], "refreshBluetooth");
    }

    function scanWifi() {
        if (wifiBusy)
            return;
        if (!wifiEnabled) {
            refreshWifi();
            return;
        }
        NetworkCenterState.wifiScanActive = true;
        startCommands("wifi", [["nmcli", "device", "wifi", "rescan"]], "scanWifi");
    }

    function scanBluetooth() {
        if (bluetoothBusy)
            return;
        if (!bluetoothEnabled) {
            refreshBluetooth();
            return;
        }
        NetworkCenterState.bluetoothScanActive = true;
        startCommands("bluetooth", [["bluetoothctl", "--timeout", "6", "scan", "on"]], "scanBluetooth");
    }

    function refreshAll() {
        if (wifiEnabled)
            scanWifi();
        else
            refreshWifi();
        if (bluetoothEnabled)
            scanBluetooth();
        else
            refreshBluetooth();
    }

    function getWifiBlockingReason() {
        if (passwordDialog.visible)
            return "Cannot toggle Wi‑Fi while password dialog is open.";
        if (pairingDialog.visible)
            return "Cannot toggle Wi‑Fi while pairing dialog is open.";
        if (forgetDialog.visible)
            return "Cannot toggle Wi‑Fi while confirmation dialog is open.";
        if (wifiBusy) {
            if (wifiPendingOperation === "radioToggle")
                return "Wi‑Fi power is currently updating. Please wait.";
            if (wifiPendingOperation === "wifiAction")
                return "Cannot toggle Wi‑Fi while connection is updating.";
            if (wifiPendingOperation === "forget")
                return "Cannot toggle Wi‑Fi while forgetting a network.";
            if (wifiPendingOperation === "scanWifi" || wifiScanActive)
                return "Wi‑Fi scan is in progress. Please wait a moment.";
            if (wifiPendingOperation === "refreshWifi")
                return "Updating Wi‑Fi networks. Please wait a moment.";
            return "Wi‑Fi is currently busy. Please wait.";
        }
        return "";
    }

    function getBluetoothBlockingReason() {
        if (pairingDialog.visible || pairingStarted || NetworkPairingRunner.isRunning(root))
            return "Cannot toggle Bluetooth while pairing is in progress.";
        if (passwordDialog.visible)
            return "Cannot toggle Bluetooth while password prompt is open.";
        if (forgetDialog.visible)
            return "Cannot toggle Bluetooth while confirmation dialog is open.";
        if (bluetoothBusy) {
            if (bluetoothPendingOperation === "radioToggle")
                return "Bluetooth power is currently updating. Please wait.";
            if (bluetoothPendingOperation === "bluetoothAction")
                return "Cannot toggle Bluetooth while connection is updating.";
            if (bluetoothPendingOperation === "unpair")
                return "Cannot toggle Bluetooth while unpairing a device.";
            if (bluetoothPendingOperation === "scanBluetooth" || bluetoothScanActive)
                return "Bluetooth scan is in progress. Please wait a moment.";
            if (bluetoothPendingOperation.startsWith("refresh"))
                return "Updating Bluetooth devices. Please wait a moment.";
            return "Bluetooth is currently busy. Please wait.";
        }
        return "";
    }

    function toggleActiveRadio() {
        if (activeTab === "wifi")
            toggleWifi();
        else if (activeTab === "bluetooth")
            toggleBluetooth();
    }

    function toggleWifi(explicitTarget) {
        if (closingWithAnimation)
            return;
        const blocking = getWifiBlockingReason();
        if (blocking !== "") {
            setMessage(blocking);
            return;
        }
        const nextState = (explicitTarget !== undefined) ? explicitTarget : !NetworkCenterState.wifiEnabled;
        NetworkCenterState.wifiPreviousRadioEnabled = NetworkCenterState.wifiEnabled;
        NetworkCenterState.wifiEnabled = nextState;
        wifiToggle.checked = nextState;
        setMessage("");
        startCommands("wifi", [["nmcli", "radio", "wifi", nextState ? "on" : "off"]], "radioToggle");
    }

    function toggleBluetooth(explicitTarget) {
        if (closingWithAnimation)
            return;
        const blocking = getBluetoothBlockingReason();
        if (blocking !== "") {
            setMessage(blocking);
            return;
        }
        const nextState = (explicitTarget !== undefined) ? explicitTarget : !NetworkCenterState.bluetoothEnabled;
        NetworkCenterState.bluetoothPreviousRadioEnabled = NetworkCenterState.bluetoothEnabled;
        NetworkCenterState.bluetoothEnabled = nextState;
        bluetoothToggle.checked = nextState;
        syncBluetoothList();
        setMessage("");
        startCommands("bluetooth", [["bluetoothctl", "power", nextState ? "on" : "off"]], "radioToggle");
    }

    function activateWifi(network) {
        if (network.inUse) {
            if (!wifiDevice) {
                setMessage("Could not identify the active Wi‑Fi adapter.");
                return;
            }
            startCommands("wifi", [["nmcli", "device", "disconnect", wifiDevice]], "wifiAction");
            return;
        }
        if (network.savedUuid) {
            startCommands("wifi", [["nmcli", "connection", "up", "uuid", network.savedUuid]], "wifiAction");
            return;
        }
        pendingSsid = network.ssid;
        pendingSecurity = network.security;
        passwordDialog.open();
    }

    function connectWifiWithPassword(password) {
        const command = ["nmcli", "device", "wifi", "connect", pendingSsid];
        if (pendingSecurity !== "" && pendingSecurity !== "--")
            command.push("password", password);
        startCommands("wifi", [command], "wifiAction");
    }

    function confirmForget() {
        startCommands("wifi", [["nmcli", "connection", "delete", "uuid", forgetUuid]], "forget", forgetName);
    }

    function bluetoothAction(action, device) {
        NetworkCenterState.bluetoothPendingTarget = device.name;
        let operation;
        if (action === "pair") {
            pairingAddress = device.address;
            pairingName = device.name;
            pairingPrompt = "Pair with " + device.name + "?";
            pairingInputRequired = false;
            pairingPasskey = "";
            pairingStarted = false;
            pairingDialog.open();
            return;
        }
        if (action === "connect")
            operation = ["bluetoothctl", "connect", device.address];
        else if (action === "disconnect")
            operation = ["bluetoothctl", "disconnect", device.address];
        else
            operation = ["bluetoothctl", "remove", device.address];
        startCommands("bluetooth", [operation], "bluetoothAction");
    }

    function confirmRemove() {
        if (forgetKind === "wifi") {
            confirmForget();
        } else {
            startCommands("bluetooth", [["bluetoothctl", "remove", forgetUuid]], "unpair", forgetName);
        }
    }

    function pairWithPin() {
        if (bluetoothBusy)
            return;
        pairingCancellationPending = false;
        setMessage("Pairing with " + pairingName + "…");
        pairingStarted = true;
        NetworkCenterState.bluetoothBusy = true;
        pairingPrompt = "Waiting for the Bluetooth device…";
        pairingInputRequired = false;
        if (!NetworkPairingRunner.start(root, pairingAddress)) {
            NetworkCenterState.bluetoothBusy = false;
            pairingStarted = false;
            setMessage("Another Bluetooth pairing is already in progress.");
        }
    }

    function handlePairingOutput(line) {
        const text = line.trim();
        const lower = text.toLowerCase();
        if (lower.indexOf("enter pin code") >= 0 || lower.indexOf("enter passkey") >= 0) {
            pairingPrompt = text.replace(/^.*?\[agent\]\s*/i, "");
            pairingInputRequired = true;
            pairingPasskey = "";
            pairingDialog.open();
        } else if (lower.indexOf("confirm passkey") >= 0 || lower.indexOf("authorize service") >= 0) {
            pairingPrompt = text.replace(/^.*?\[agent\]\s*/i, "");
            const match = text.match(/\b(\d{6})\b/);
            pairingPasskey = match ? match[1] : "";
            pairingInputRequired = false;
            pairingDialog.open();
        } else if (lower.indexOf("pairing successful") >= 0 || lower.indexOf("paired: yes") >= 0) {
            setMessage("Paired with " + pairingName + ".");
            pairingDialog.close();
            NetworkPairingRunner.write(root, "quit\n");
        } else if (lower.indexOf("failed to pair") >= 0 || lower.indexOf("pairing failed") >= 0 || lower.indexOf("no default controller") >= 0 || lower.indexOf("not available") >= 0) {
            setMessage(text);
            pairingDialog.close();
            NetworkPairingRunner.write(root, "quit\n");
        }
    }

    function submitPairingPrompt(accepted) {
        if (!NetworkPairingRunner.isRunning(root))
            return;
        NetworkPairingRunner.write(root, accepted ? (pairingInputRequired ? pairingPasskey : "yes") + "\n" : "no\n");
        pairingPasskey = "";
        pairingDialog.close();
    }

    function cancelPairing() {
        if (pairingCancellationPending) {
            pairingDialog.close();
            return;
        }
        pairingCancellationPending = true;
        if (NetworkPairingRunner.isRunning(root)) {
            if (notice.indexOf("timed out") < 0)
                setMessage("Pairing canceled.");
            NetworkPairingRunner.cancel(root, pairingAddress);
        }
        pairingDialog.close();
    }

    Component.onCompleted: {
        // Deferred until panel openNow() to eliminate boot-time CLI storms
    }

    Component.onDestruction: {
        const cancelledRadios = NetworkCommandRunner.cancelOwner(root);
        cancelledRadios.forEach((radio) => NetworkCenterState.cancelRadio(radio));
        if (NetworkPairingRunner.cancelOwner(root))
            NetworkCenterState.cancelRadio("bluetooth");
    }

    onVisibleChanged: {
        if (visible) {
            setMessage("");
            Qt.callLater(() => root.focusKeyboardTarget());
        } else {
            passwordDialog.close();
            if (NetworkPairingRunner.isRunning(root) && !closingWithAnimation)
                cancelPairing();
            else
                pairingDialog.close();
            forgetDialog.close();
        }
    }

    onClosingWithAnimationChanged: {
        if (!closingWithAnimation && visible)
            Qt.callLater(() => root.focusKeyboardTarget());
    }

    onActiveTabChanged: {
        setMessage("");
        if (visible) {
            if (activeTab === "wifi")
                refreshWifi();
            else
                refreshBluetooth();
        }
    }

    function handleCommandExit(radio, exitCode, stdoutText, stderrText) {
        if (radio === "wifi") {
            wifiCommandResults.push({ code: exitCode, out: stdoutText, err: stderrText });
            NetworkCenterState.wifiCommandIndex++;
        } else {
            bluetoothCommandResults.push({ code: exitCode, out: stdoutText, err: stderrText });
            NetworkCenterState.bluetoothCommandIndex++;
        }
        runNextCommand(radio);
    }

    function handlePairingExit(exitCode) {
        pairingCancellationPending = false;
        NetworkCenterState.bluetoothBusy = false;
        pairingStarted = false;
        if (exitCode !== 0 && notice.indexOf("Paired with") !== 0 && notice.indexOf("timed out") < 0)
            setMessage("Bluetooth pairing ended with an error.");
        pairingDialog.close();
        refreshBluetooth();
    }

    function handlePairingTimeout() {
        setMessage("Bluetooth pairing timed out.");
        cancelPairing();
    }

    FocusScope {
        id: panelFocusScope
        anchors.fill: parent
        focus: root.isCurrentTab
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => root.handlePanelKey(event)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Connections"; color: Colors.text; font.pixelSize: 18; font.weight: Font.DemiBold }
                            RowLayout {
                                spacing: 5
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: root.activeError ? Colors.critical : root.activeEnabled ? Colors.success : Colors.textFaint
                                    Behavior on color { ColorAnimation { duration: Motion.durationNormal; easing.type: Motion.easingStandard } }
                                }
                                Text { text: root.activeError ? "Connection issue" : root.activeStatus; color: root.activeError ? Colors.critical : Colors.textDim; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                        }

                        Rectangle {
                            implicitWidth: 32; implicitHeight: 32; radius: 10
                            color: refreshMouse.containsMouse ? Colors.hover : Colors.surfaceSoft
                            border.width: 0
                            scale: refreshMouse.pressed ? Motion.scalePress : refreshMouse.containsMouse ? Motion.scaleHover : Motion.scaleNormal
                            Behavior on scale { NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }
                            Behavior on color { ColorAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }
                            Text { id: refreshGlyph; anchors.centerIn: parent; text: root.activeSearching ? "sync" : "refresh"; color: Colors.accent; font.family: "Material Symbols Rounded"; font.pixelSize: 18; RotationAnimation on rotation { from: 0; to: 360; duration: 1100; loops: Animation.Infinite; running: root.activeSearching; onStopped: refreshGlyph.rotation = 0 } }
                            MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; enabled: !root.activeBusy && root.activeEnabled; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.activeTab === "wifi" ? root.scanWifi() : root.scanBluetooth() }
                        }

                        Rectangle {
                            implicitWidth: 32; implicitHeight: 32; radius: 10
                            color: closeMouse.containsMouse ? Colors.hover : Colors.surfaceSoft
                            border.width: 0
                            scale: closeMouse.pressed ? Motion.scalePress : closeMouse.containsMouse ? Motion.scaleHover : Motion.scaleNormal
                            Behavior on scale { NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }
                            Behavior on color { ColorAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }
                            Text { anchors.centerIn: parent; text: "close"; color: closeMouse.containsMouse ? Colors.text : Colors.textDim; font.family: "Material Symbols Rounded"; font.pixelSize: 18 }
                            MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                        }
                    }

                    NetworkCenterTabs {
                        activeTab: root.activeTab
                        onTabSelected: tab => root.setKeyboardTab(tab)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.border; border.width: 0 }
                        Text { text: root.activeTab === "wifi" ? "NETWORKS" : "DEVICES"; color: Colors.textFaint; font.pixelSize: 10; font.letterSpacing: 1.2 }
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.border; border.width: 0 }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 10
                        visible: root.activeTab === "wifi"
                        color: wifiRowToggleMouse.containsMouse ? Colors.hover : Colors.clear
                        scale: wifiRowToggleMouse.pressed ? Motion.scalePress : Motion.scaleNormal
                        Behavior on color { ColorAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }
                        Behavior on scale { NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 8
                            Text { text: "Wi‑Fi"; color: Colors.text; font.pixelSize: 13; Layout.fillWidth: true }
                            Text { text: wifiToggle.checked ? "On" : "Off"; color: wifiToggle.checked ? Colors.success : Colors.textDim; font.pixelSize: 12 }
                            Item {
                                implicitWidth: 38
                                implicitHeight: 22

                                Switch {
                                    id: wifiToggle
                                    anchors.fill: parent
                                    checked: root.wifiEnabled
                                    enabled: false
                                    focusPolicy: Qt.NoFocus
                                    indicator: Rectangle {
                                        implicitWidth: 38; implicitHeight: 22; radius: 11
                                        color: wifiToggle.checked ? Colors.accent : Colors.surfaceMuted
                                        border.width: 0
                                        Rectangle { x: wifiToggle.checked ? parent.width - width - 3 : 3; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: 8; color: wifiToggle.checked ? Colors.selectedText : Colors.text; Behavior on x { NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } } }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: wifiRowToggleMouse
                            anchors.fill: parent
                            z: 10
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWifi()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 10
                        visible: root.activeTab === "bluetooth"
                        color: btRowToggleMouse.containsMouse ? Colors.hover : Colors.clear
                        scale: btRowToggleMouse.pressed ? Motion.scalePress : Motion.scaleNormal
                        Behavior on color { ColorAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }
                        Behavior on scale { NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 8
                            Text { text: "Bluetooth"; color: Colors.text; font.pixelSize: 13; Layout.fillWidth: true }
                            Text { text: bluetoothToggle.checked ? "On" : "Off"; color: bluetoothToggle.checked ? Colors.success : Colors.textDim; font.pixelSize: 12 }
                            Item {
                                implicitWidth: 38
                                implicitHeight: 22

                                Switch {
                                    id: bluetoothToggle
                                    anchors.fill: parent
                                    checked: root.bluetoothEnabled
                                    enabled: false
                                    focusPolicy: Qt.NoFocus
                                    indicator: Rectangle {
                                        implicitWidth: 38; implicitHeight: 22; radius: 11
                                        color: bluetoothToggle.checked ? Colors.accent : Colors.surfaceMuted
                                        border.width: 0
                                        Rectangle { x: bluetoothToggle.checked ? parent.width - width - 3 : 3; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: 8; color: bluetoothToggle.checked ? Colors.selectedText : Colors.text; Behavior on x { NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingStandard } } }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: btRowToggleMouse
                            anchors.fill: parent
                            z: 10
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleBluetooth()
                        }
                    }

                    Item {
                        id: scanningBannerContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(28 * root.bannerProgress)
                        Layout.topMargin: Math.round(-12 * (1.0 - root.bannerProgress))
                        visible: root.bannerProgress > 0.01
                        clip: true
                        opacity: root.bannerProgress

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 28
                            radius: 9
                            color: Colors.accentSoft
                            border.width: 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            BusyIndicator {
                                running: root.activeSearching
                                implicitWidth: 14
                                implicitHeight: 14
                            }

                            Text {
                                text: root.activeTab === "wifi" ? "Scanning nearby networks…" : "Searching for nearby devices…"
                                color: Colors.text
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                            }

                            Text {
                                id: bannerSpinGlyph
                                text: "sync"
                                color: Colors.accent
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 1100
                                    loops: Animation.Infinite
                                    running: root.activeSearching
                                    onStopped: bannerSpinGlyph.rotation = 0
                                }
                            }
                        }
                    }
                }

                WifiNetworkList {
                    id: wifiList
                    visible: root.activeTab === "wifi"
                    networks: root.wifiNetworks
                    busy: root.wifiBusy
                    radioEnabled: root.wifiEnabled
                    loaded: root.wifiLoaded
                    searching: root.activeSearching
                    error: root.wifiError
                    keyboardFocusActive: root.keyboardNavActive
                    selectedIndex: root.keyboardSelectedIndex
                    onNetworkHovered: index => root.selectKeyboardItem(index)
                    onNetworkActivated: (index, network) => { root.selectKeyboardItem(index); root.activateWifi(network) }
                    onNetworkForgetRequested: (index, network) => {
                        root.selectKeyboardItem(index);
                        root.forgetUuid = network.savedUuid;
                        root.forgetName = network.savedName || network.ssid;
                        root.forgetKind = "wifi";
                        root.confirmingForget = true;
                        forgetDialog.open();
                    }
                }

                BluetoothDeviceList {
                    id: bluetoothList
                    visible: root.activeTab === "bluetooth"
                    devicesModel: bluetoothListModel
                    deviceCount: root.pairedDevices.length + root.nearbyDevices.length
                    busy: root.bluetoothBusy
                    radioEnabled: root.bluetoothEnabled
                    loaded: root.bluetoothLoaded
                    searching: root.activeSearching
                    error: root.bluetoothError
                    keyboardFocusActive: root.keyboardNavActive
                    selectedIndex: root.keyboardSelectedIndex
                    onDeviceHovered: index => root.selectKeyboardItem(index)
                    onDeviceAction: (index, action, address, name) => {
                        root.selectKeyboardItem(index);
                        root.bluetoothAction(action, ({ address: address, name: name }));
                    }
                    onDeviceForgetRequested: (index, address, name) => {
                        root.selectKeyboardItem(index);
                        root.forgetName = name;
                        root.forgetUuid = address;
                        root.forgetKind = "bluetooth";
                        root.confirmingForget = true;
                        forgetDialog.open();
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.notice !== ""
                    spacing: 6

                    Text {
                        text: root.noticeIsError ? "info" : "check_circle"
                        color: root.noticeIsError ? Colors.critical : Colors.success
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.notice
                        color: root.noticeIsError ? Colors.critical : Colors.text
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

    ListModel {
        id: bluetoothListModel
    }

    NetworkCenterPasswordDialog {
        id: passwordDialog
        parent: root
        networkName: root.pendingSsid
        security: root.pendingSecurity
        busy: root.wifiBusy
        onConnectRequested: password => root.connectWifiWithPassword(password)
        onDismissed: root.restoreKeyboardFocus()
    }

    NetworkCenterPairingDialog {
        id: pairingDialog
        parent: root
        deviceName: root.pairingName
        prompt: root.pairingPrompt
        passkey: root.pairingPasskey
        started: root.pairingStarted
        inputRequired: root.pairingInputRequired
        onPairRequested: root.pairWithPin()
        onPromptSubmitted: value => {
            if (root.pairingInputRequired)
                root.pairingPasskey = value;
            root.submitPairingPrompt(true);
        }
        onCancelRequested: root.cancelPairing()
        onDismissed: root.restoreKeyboardFocus()
    }

    NetworkCenterForgetDialog {
        id: forgetDialog
        parent: root
        itemKind: root.forgetKind
        itemName: root.forgetName
        onConfirmed: {
            root.confirmingForget = false;
            root.confirmRemove();
        }
        onDismissed: {
            root.confirmingForget = false;
            root.restoreKeyboardFocus();
        }
    }
}
