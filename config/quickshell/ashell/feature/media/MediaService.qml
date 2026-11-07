pragma Singleton

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Mpris
import qs

Scope {
    id: root

    property var lastActivePlayer: null
    property string lastTrackKey: ""
    property int trackRevision: 0
    signal trackChanged(string title, string artist)

    // Feedback Message State (unified across expanded MediaCard and compact Dynamic Island)
    property bool feedbackActive: false
    property string feedbackIcon: ""
    property string feedbackText: ""
    property bool feedbackIsError: false
    signal feedbackTriggered(string icon, string text, bool isError)

    Timer {
        id: feedbackTimer
        interval: 2200
        repeat: false
        onTriggered: {
            root.feedbackActive = false;
        }
    }

    function showFeedback(icon, text, isError = false) {
        if (!text || text === "")
            return;
        root.feedbackIcon = icon || "info";
        root.feedbackText = text;
        root.feedbackIsError = Boolean(isError);
        root.feedbackActive = true;
        feedbackTimer.restart();
        root.feedbackTriggered(root.feedbackIcon, root.feedbackText, root.feedbackIsError);
    }

    property var activePlayer: null

    function recalculateActivePlayer() {
        const players = Mpris.players.values || [];
        if (players.length === 0) {
            if (root.activePlayer !== null)
                root.activePlayer = null;
            return;
        }

        // 1. Prefer actively playing player
        const playing = players.find(p => p && p.isPlaying);
        if (playing) {
            root.lastActivePlayer = playing;
            if (root.activePlayer !== playing)
                root.activePlayer = playing;
            return;
        }

        // 2. If last active player is still available in the list, persist it
        if (root.lastActivePlayer && players.some(p => p === root.lastActivePlayer)) {
            if (root.activePlayer !== root.lastActivePlayer)
                root.activePlayer = root.lastActivePlayer;
            return;
        }

        // 3. Fallback to first available player
        const fallback = players[0] || null;
        if (root.activePlayer !== fallback)
            root.activePlayer = fallback;
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.recalculateActivePlayer();
        }
    }

    // Watch playback state transitions across all players dynamically
    Instantiator {
        model: Mpris.players.values
        onObjectAdded: root.recalculateActivePlayer()
        onObjectRemoved: root.recalculateActivePlayer()
        delegate: QtObject {
            readonly property var targetPlayer: modelData
            readonly property Connections conn: Connections {
                target: targetPlayer
                ignoreUnknownSignals: true
                function onIsPlayingChanged() {
                    root.recalculateActivePlayer();
                }
                function onPlaybackStateChanged() {
                    root.recalculateActivePlayer();
                }
            }
        }
    }

    Component.onCompleted: {
        root.recalculateActivePlayer();
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: !!(activePlayer && activePlayer.isPlaying)
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "Unknown Track") : ""
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || activePlayer.trackArtists || "Unknown Artist") : ""
    readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string trackArtUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property real trackLength: (activePlayer && activePlayer.lengthSupported && activePlayer.length > 0) ? activePlayer.length : 0
    property real currentPosition: (activePlayer && activePlayer.positionSupported) ? activePlayer.position : 0

    readonly property bool shuffle: !!(activePlayer && activePlayer.shuffleSupported && activePlayer.shuffle)
    readonly property bool canGoPrevious: !!(activePlayer && activePlayer.canGoPrevious)
    readonly property bool canGoNext: !!(activePlayer && activePlayer.canGoNext)
    readonly property bool canTogglePlaying: !!(activePlayer && activePlayer.canTogglePlaying)
    readonly property bool canSeek: !!(activePlayer && activePlayer.canSeek && trackLength > 0)

    // Track Change Detection
    readonly property string currentTrackKey: `${trackTitle}|${trackArtist}`

    onCurrentTrackKeyChanged: {
        if (!hasPlayer || currentTrackKey === "|")
            return;

        if (root.lastTrackKey !== "" && root.lastTrackKey !== currentTrackKey) {
            root.trackRevision++;
            root.trackChanged(root.trackTitle, root.trackArtist);
        }
        root.lastTrackKey = currentTrackKey;
    }

    // Position ticker: periodically poll and advance position when playing
    Timer {
        id: positionTimer
        interval: 500
        repeat: true
        running: root.isPlaying && (root.activePlayer ? root.activePlayer.positionSupported : false)
        onTriggered: {
            if (root.activePlayer && root.activePlayer.positionSupported) {
                root.currentPosition = root.activePlayer.position;
            }
        }
    }

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onPositionChanged() {
            if (root.activePlayer && root.activePlayer.positionSupported) {
                root.currentPosition = root.activePlayer.position;
            }
        }
        function onTrackChanged() {
            if (root.activePlayer) {
                const key = `${root.trackTitle}|${root.trackArtist}`;
                if (key !== "" && key !== "|" && key !== root.lastTrackKey) {
                    root.lastTrackKey = key;
                    root.trackRevision++;
                    root.trackChanged(root.trackTitle, root.trackArtist);
                }
            }
        }
    }

    function togglePlaying() {
        if (!activePlayer) {
            showFeedback("music_off", "No media player", true);
            return;
        }
        if (!canTogglePlaying) {
            showFeedback("info", "Play/Pause unsupported", true);
            return;
        }
        const willPlay = !isPlaying;
        activePlayer.togglePlaying();
        showFeedback(willPlay ? "play_arrow" : "pause", willPlay ? "Playing" : "Paused");
    }

    function next() {
        if (!activePlayer) {
            showFeedback("music_off", "No media player", true);
            return;
        }
        if (!canGoNext) {
            showFeedback("info", "End of queue", true);
            return;
        }
        activePlayer.next();
        showFeedback("skip_next", "Next track");
    }

    function previous() {
        if (!activePlayer) {
            showFeedback("music_off", "No media player", true);
            return;
        }
        if (!canGoPrevious) {
            showFeedback("info", "Start of queue", true);
            return;
        }
        activePlayer.previous();
        showFeedback("skip_previous", "Previous track");
    }

    function toggleShuffle() {
        if (!activePlayer || !activePlayer.shuffleSupported) {
            showFeedback("info", "Shuffle unsupported", true);
            return;
        }
        const nextState = !activePlayer.shuffle;
        activePlayer.shuffle = nextState;
        showFeedback("shuffle", nextState ? "Shuffle On" : "Shuffle Off");
    }

    function seekBy(deltaSeconds) {
        if (!activePlayer) {
            showFeedback("music_off", "No media player", true);
            return;
        }
        if (!canSeek) {
            showFeedback("info", "Seeking unsupported", true);
            return;
        }
        const target = Math.max(0, Math.min(trackLength, currentPosition + deltaSeconds));
        seekTo(target, false);
        const icon = deltaSeconds >= 0 ? "fast_forward" : "fast_rewind";
        const sign = deltaSeconds >= 0 ? `+${Math.round(deltaSeconds)}s` : `${Math.round(deltaSeconds)}s`;
        showFeedback(icon, `Seek ${sign} (${formatTime(target)})`);
    }

    function seekTo(targetSeconds, showNotice = false) {
        if (!activePlayer || !canSeek)
            return;
        const bounded = Math.max(0, Math.min(trackLength, targetSeconds));
        activePlayer.position = bounded;
        root.currentPosition = bounded;
        if (showNotice) {
            showFeedback("fast_forward", `Seeked to ${formatTime(bounded)}`);
        }
    }

    function formatTime(totalSeconds) {
        if (isNaN(totalSeconds) || totalSeconds < 0)
            return "0:00";
        const sec = Math.floor(totalSeconds % 60);
        const min = Math.floor((totalSeconds / 60) % 60);
        const hrs = Math.floor(totalSeconds / 3600);
        const secStr = sec.toString().padStart(2, "0");

        if (hrs > 0) {
            const minStr = min.toString().padStart(2, "0");
            return `${hrs}:${minStr}:${secStr}`;
        }
        return `${min}:${secStr}`;
    }
}
