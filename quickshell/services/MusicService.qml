pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    // Reference to current active player
    readonly property MprisPlayer activePlayer: {
        var count = Mpris.players.values.length;
        if (count === 0) return null;

        // First look for any playing player
        for (var i = 0; i < count; i++) {
            var p = Mpris.players.values[i];
            if (p && p.isPlaying) {
                return p;
            }
        }
        // Fall back to first available player
        return Mpris.players.values[0];
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string title: (activePlayer && activePlayer.trackTitle) ? activePlayer.trackTitle : "No media playing"
    readonly property string artist: (activePlayer && activePlayer.trackArtist) ? activePlayer.trackArtist : "Idle"
    readonly property string album: (activePlayer && activePlayer.trackAlbum) ? activePlayer.trackAlbum : ""
    readonly property string artUrl: (activePlayer && activePlayer.trackArtUrl) ? activePlayer.trackArtUrl : ""
    readonly property string identity: (activePlayer && activePlayer.identity) ? activePlayer.identity : ""

    function togglePlay() {
        if (activePlayer) {
            activePlayer.togglePlaying();
        }
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next();
        }
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous();
        }
    }
}
