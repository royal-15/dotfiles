pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.feature.bar

Scope {
    id: root

    readonly property real liveVolume: StatusBarService.volumePercent >= 0
        ? (StatusBarService.volumePercent / 100.0)
        : 0.0
    readonly property bool liveMuted: StatusBarService.volumeMuted
    readonly property string liveDeviceName: StatusBarService.activeDeviceName

    readonly property string liveDeviceIcon: {
        if (liveMuted || liveVolume <= 0)
            return "volume_off";

        const lowerDesc = liveDeviceName.toLowerCase();
        if (lowerDesc.includes("headphone") || lowerDesc.includes("headset") || lowerDesc.includes("airpods") || lowerDesc.includes("earbuds"))
            return "headphones";
        if (lowerDesc.includes("hdmi") || lowerDesc.includes("displayport") || lowerDesc.includes("tv"))
            return "tv";
        if (lowerDesc.includes("speaker"))
            return "speaker";

        if (liveVolume < 0.34)
            return "volume_mute";
        if (liveVolume < 0.67)
            return "volume_down";
        return "volume_up";
    }

    property bool volumeOsdVisible: false
    property bool isHovered: false
    property bool isInitialized: false

    Timer {
        id: startupGuardTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            root.prevLiveVolume = root.liveVolume;
            root.prevLiveMuted = root.liveMuted;
            root.isInitialized = true;
        }
    }

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: {
            if (!root.isHovered)
                root.volumeOsdVisible = false;
        }
    }

    property real prevLiveVolume: -1
    property bool prevLiveMuted: false

    onIsHoveredChanged: {
        if (!isHovered && volumeOsdVisible) {
            hideTimer.restart();
        }
    }

    onLiveVolumeChanged: {
        if (isInitialized && Math.abs(liveVolume - prevLiveVolume) > 0.005) {
            prevLiveVolume = liveVolume;
            showVolume();
        }
    }

    onLiveMutedChanged: {
        if (isInitialized && liveMuted !== prevLiveMuted) {
            prevLiveMuted = liveMuted;
            showVolume();
        }
    }

    function showVolume() {
        isInitialized = true;
        volumeOsdVisible = true;
        hideTimer.restart();
    }

    function hideVolume() {
        hideTimer.stop();
        volumeOsdVisible = false;
    }

    function setVolume(ratio) {
        const clamped = Math.max(0.0, Math.min(1.0, ratio));
        StatusBarService.setVolumePercent(clamped * 100);
        showVolume();
    }

    function changeVolume(delta) {
        StatusBarService.changeVolume(delta > 0 ? 1 : -1);
        showVolume();
    }

    function toggleMute() {
        StatusBarService.toggleMute();
        showVolume();
    }
}
