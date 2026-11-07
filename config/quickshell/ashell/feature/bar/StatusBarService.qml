pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs
import qs.components

Scope {
    id: root

    function format12HourTime() {
        const d = new Date();
        let hours = d.getHours() % 12;
        if (hours === 0)
            hours = 12;
        const minutes = d.getMinutes().toString().padStart(2, "0");
        return `${hours}:${minutes}`;
    }

    property string clockValue: format12HourTime()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const formatted = root.format12HourTime();
            if (root.clockValue !== formatted)
                root.clockValue = formatted;
        }
    }

    readonly property string cpuTemperature: cpuTempPoller.value
    readonly property string volumeReading: volumePoller.value
    readonly property var volumeState: volumeReading.split("|")
    readonly property int volumePercent: numericValue(volumeState[0])
    readonly property bool volumeMuted: volumeState.length > 1 && volumeState[1] === "muted"
    readonly property string activeDeviceName: volumeState.length > 2 && volumeState[2] !== "" ? volumeState[2] : "Audio Output"

    readonly property var battDev: UPower.displayDevice
    readonly property bool hasUPowerBattery: battDev !== null && battDev !== undefined && battDev.ready && battDev.isPresent

    readonly property string powerReading: powerPoller.value
    readonly property var powerState: powerReading.split("|")
    readonly property string fallbackAcOnline: powerState.length > 0 ? powerState[0] : ""
    readonly property string fallbackBatteryStatus: powerState.length > 1 ? powerState[1] : ""
    readonly property string fallbackBatteryCapacity: powerState.length > 2 ? powerState[2] : ""

    readonly property bool hasBattery: {
        if (hasUPowerBattery)
            return battDev.isLaptopBattery || battDev.type === UPowerDeviceType.Battery;
        return fallbackBatteryCapacity !== "" || fallbackBatteryStatus !== "";
    }

    readonly property string batteryPercent: {
        if (hasUPowerBattery) {
            const raw = battDev.percentage;
            if (raw > 0) {
                const pct = raw <= 1.0 ? Math.round(raw * 100) : Math.round(raw);
                return String(pct);
            }
        }
        return fallbackBatteryCapacity;
    }

    readonly property bool isAcConnected: {
        if (hasUPowerBattery) {
            if (battDev.state === UPowerDeviceState.Charging || battDev.state === UPowerDeviceState.FullyCharged)
                return true;
            if (battDev.state === UPowerDeviceState.Discharging)
                return false;
            return !UPower.onBattery;
        }
        if (fallbackAcOnline === "1")
            return true;
        if (fallbackAcOnline === "0")
            return false;
        if (fallbackBatteryStatus === "Charging")
            return true;
        if (fallbackBatteryStatus === "Discharging")
            return false;
        return true;
    }

    readonly property bool isCharging: {
        if (hasUPowerBattery) {
            return battDev.state === UPowerDeviceState.Charging || battDev.state === UPowerDeviceState.PendingCharge;
        }
        return fallbackBatteryStatus === "Charging";
    }

    readonly property bool isBatteryFull: {
        if (hasUPowerBattery) {
            return battDev.state === UPowerDeviceState.FullyCharged || (numericValue(batteryPercent) >= 100 && isAcConnected);
        }
        return fallbackBatteryStatus === "Full" || (numericValue(batteryPercent) >= 100 && isAcConnected);
    }

    readonly property string batteryStatus: {
        if (hasUPowerBattery) {
            if (battDev.state === UPowerDeviceState.Charging) return "Charging";
            if (battDev.state === UPowerDeviceState.Discharging) return "Discharging";
            if (battDev.state === UPowerDeviceState.FullyCharged) return "Full";
            if (battDev.state === UPowerDeviceState.PendingCharge) return "Charging";
        }
        if (fallbackBatteryStatus !== "")
            return fallbackBatteryStatus;
        if (isAcConnected)
            return isBatteryFull ? "Full" : "Not charging";
        return hasBattery ? "Discharging" : "";
    }

    function refreshPower() {
        powerPoller.trigger();
    }

    readonly property string powerProfile: powerProfilePoller.value
    readonly property string activeConnection: activeConnectionPoller.value
    readonly property string wifiState: wifiStatePoller.value
    readonly property string bluetoothState: bluetoothStatePoller.value
    readonly property var wifiReading: wifiState.split("|")
    readonly property int wifiSignal: numericValue(wifiReading[1])
    readonly property bool wifiRadioEnabled: (wifiReading.length > 0 && wifiReading[0] !== "")
        ? (wifiReading[0] === "enabled")
        : NetworkCenterState.wifiEnabled
    readonly property bool wifiConnected: wifiRadioEnabled && activeConnection !== "" && wifiSignal > 0
    readonly property var bluetoothReading: bluetoothState.split("|")
    readonly property bool bluetoothPowered: bluetoothReading.length > 0 && bluetoothReading[0] === "yes"
    readonly property int bluetoothConnectedCount: bluetoothReading.length > 1 ? Math.max(0, numericValue(bluetoothReading[1])) : 0
    readonly property string bluetoothDeviceName: bluetoothReading.length > 2 ? bluetoothReading[2] : ""

    signal networkStatusEvent(string icon, string label)

    property string lastActiveConnection: ""
    property bool lastWifiRadioEnabled: true
    property int lastBtConnectedCount: 0
    property string lastBtDeviceName: ""
    property bool lastBtPowered: true
    property bool networkEventsInitialized: false

    Timer {
        id: startupGraceTimer
        interval: 3500
        running: true
        repeat: false
        onTriggered: {
            root.lastActiveConnection = root.activeConnection;
            root.lastWifiRadioEnabled = root.wifiRadioEnabled;
            root.lastBtConnectedCount = root.bluetoothConnectedCount;
            root.lastBtDeviceName = root.bluetoothDeviceName;
            root.lastBtPowered = root.bluetoothPowered;
            root.networkEventsInitialized = true;
        }
    }

    function checkNetworkEvents() {
        if (!networkEventsInitialized || startupGraceTimer.running) {
            lastActiveConnection = activeConnection;
            lastWifiRadioEnabled = wifiRadioEnabled;
            lastBtConnectedCount = bluetoothConnectedCount;
            lastBtDeviceName = bluetoothDeviceName;
            lastBtPowered = bluetoothPowered;
            return;
        }

        if (activeConnection !== lastActiveConnection) {
            if (activeConnection !== "") {
                networkStatusEvent("wifi", activeConnection);
            } else if (lastActiveConnection !== "" && wifiRadioEnabled) {
                networkStatusEvent("wifi_find", "Wi-Fi Disconnected");
            }
            lastActiveConnection = activeConnection;
        }

        if (wifiRadioEnabled !== lastWifiRadioEnabled) {
            if (!wifiRadioEnabled) {
                networkStatusEvent("wifi_off", "Wi-Fi Off");
            } else {
                networkStatusEvent("wifi", "Wi-Fi On");
            }
            lastWifiRadioEnabled = wifiRadioEnabled;
        }

        if (bluetoothConnectedCount !== lastBtConnectedCount || bluetoothDeviceName !== lastBtDeviceName) {
            if (bluetoothConnectedCount > lastBtConnectedCount) {
                const name = bluetoothDeviceName !== "" ? bluetoothDeviceName : "Bluetooth Connected";
                networkStatusEvent("bluetooth_connected", name);
            } else if (bluetoothConnectedCount < lastBtConnectedCount) {
                networkStatusEvent("bluetooth", "Device Disconnected");
            }
            lastBtConnectedCount = bluetoothConnectedCount;
            lastBtDeviceName = bluetoothDeviceName;
        }

        if (bluetoothPowered !== lastBtPowered) {
            if (!bluetoothPowered) {
                networkStatusEvent("bluetooth_disabled", "Bluetooth Off");
            } else {
                networkStatusEvent("bluetooth", "Bluetooth On");
            }
            lastBtPowered = bluetoothPowered;
        }
    }

    onActiveConnectionChanged: checkNetworkEvents()
    onWifiRadioEnabledChanged: checkNetworkEvents()
    onBluetoothConnectedCountChanged: checkNetworkEvents()
    onBluetoothDeviceNameChanged: checkNetworkEvents()
    onBluetoothPoweredChanged: checkNetworkEvents()

    Connections {
        target: NetworkCenterState
        function onGlobalNoticeChanged() {
            if (NetworkCenterState.globalNotice !== "") {
                root.networkStatusEvent("info", NetworkCenterState.globalNotice);
            }
        }
    }

    function numericValue(value) {
        const reading = parseFloat(value);
        return isFinite(reading) ? reading : -1;
    }

    function statusColor(value, minValue, maxValue, reverse = false) {
        const reading = parseFloat(value);
        if (!isFinite(reading))
            return Colors.text;

        const ratio = Math.max(0, Math.min(1, (reading - minValue) / (maxValue - minValue)));
        const progress = reverse ? 1 - ratio : ratio;
        if (progress < 0.6)
            return Colors.success;
        if (progress < 0.85)
            return Colors.warning;
        return Colors.critical;
    }

    function volumeIcon() {
        if (volumeMuted || volumePercent <= 0)
            return "volume_off";
        if (volumePercent < 34)
            return "volume_mute";
        if (volumePercent < 67)
            return "volume_down";
        return "volume_up";
    }

    function wifiIcon() {
        if (!wifiRadioEnabled)
            return "wifi_off";
        if (!wifiConnected || wifiSignal <= 0)
            return "wifi_find";
        if (wifiSignal < 35)
            return "wifi_1_bar";
        if (wifiSignal < 70)
            return "wifi_2_bar";
        return "wifi";
    }

    function powerProfileIcon() {
        if (powerProfile === "power-saver")
            return "energy_savings_leaf";
        if (powerProfile === "performance")
            return "bolt";
        if (powerProfile === "balanced")
            return "speed";
        return "bolt";
    }

    function batteryIcon() {
        if (!hasBattery)
            return powerProfileIcon();

        const pct = numericValue(batteryPercent);

        if (isAcConnected || isCharging) {
            if (pct >= 95 || isCharged)
                return "battery_charging_full";
            if (pct >= 85)
                return "battery_charging_90";
            if (pct >= 70)
                return "battery_charging_80";
            if (pct >= 55)
                return "battery_charging_60";
            if (pct >= 40)
                return "battery_charging_50";
            if (pct >= 25)
                return "battery_charging_30";
            return "battery_charging_20";
        }

        if (pct >= 90)
            return "battery_full";
        if (pct >= 65)
            return "battery_horiz_075";
        if (pct >= 30)
            return "battery_horiz_050";
        if (pct > 15)
            return "battery_horiz_000";
        return "battery_alert";
    }

    function batteryColor() {
        if (isAcConnected || isCharging)
            return Colors.accent;
        const pct = numericValue(batteryPercent);
        if (pct > 0 && pct <= 15)
            return Colors.critical;
        if (pct > 0 && pct <= 25)
            return Colors.warning;
        return Colors.text;
    }

    Process {
        id: volumeActionProcess
        onExited: volumePoller.trigger()
    }

    function refreshVolume() {
        volumePoller.trigger();
    }

    function changeVolume(delta) {
        volumeActionProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta > 0 ? "5%+" : "5%-"];
        volumeActionProcess.running = true;
    }

    function toggleMute() {
        volumeActionProcess.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        volumeActionProcess.running = true;
    }

    function setVolumePercent(pct) {
        const clamped = Math.max(0, Math.min(100, Math.round(pct)));
        volumeActionProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${clamped}%`];
        volumeActionProcess.running = true;
    }

    Process {
        id: volumeEventWatcher
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("sink") || line.includes("server")) {
                    volumePoller.trigger();
                }
            }
        }
    }

    Poller {
        id: volumePoller
        command: "$HOME/.config/quickshell/ashell/feature/bar/get_volume.sh"
        interval: 2000
    }
    Process {
        id: powerEventWatcher
        command: ["udevadm", "monitor", "-s", "power_supply"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                powerDebounceTimer.restart();
            }
        }
    }

    Timer {
        id: powerDebounceTimer
        interval: 100
        repeat: false
        onTriggered: powerPoller.trigger()
    }

    Connections {
        target: UPower
        ignoreUnknownSignals: true
        function onOnBatteryChanged() {
            powerPoller.trigger();
        }
    }

    Connections {
        target: root.battDev ? root.battDev : null
        ignoreUnknownSignals: true
        function onStateChanged() {
            powerPoller.trigger();
        }
        function onPercentageChanged() {
            powerPoller.trigger();
        }
        function onIsPresentChanged() {
            powerPoller.trigger();
        }
    }

    Poller {
        id: powerPoller
        command: "$HOME/.config/quickshell/ashell/feature/bar/get_power.sh"
        interval: 5000
    }
    Poller {
        id: cpuTempPoller
        command: `sensors 2>/dev/null | awk '
        /Package id 0:/ { print $4; exit }
        /Tctl:/ { print $2; exit }
        /Tdie:/ { print $2; exit }'`
        interval: 5000
    }
    Poller { id: powerProfilePoller; command: "powerprofilesctl get 2>/dev/null"; interval: 5000 }
    Poller { id: activeConnectionPoller; command: "nmcli -t -f NAME connection show --active | head -n1"; interval: 5000 }
    Poller {
        id: wifiStatePoller
        command: "printf '%s|' \"$(nmcli -t radio wifi 2>/dev/null)\"; nmcli -t -f IN-USE,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: '$1 == \"*\" {print $2; found=1; exit} END {if (!found) print 0}'"
        interval: 5000
    }
    Poller {
        id: bluetoothStatePoller
        command: "powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}'); connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l); devName=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d ' ' -f 3-); printf '%s|%s|%s' \"${powered:-unknown}\" \"$connected\" \"$devName\""
        interval: 5000
    }
}
