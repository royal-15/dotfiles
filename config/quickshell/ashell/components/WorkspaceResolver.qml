pragma Singleton

import QtQuick
import Quickshell

QtObject {
    function resolve(monitorName)
    {
        const monitorCount = Quickshell.screens.length
        let hasEdp = false

        for (let i = 0; i < Quickshell.screens.length; i++) {
            const name = Quickshell.screens[i].name ?? ""

            if (name.trim().toLowerCase() === "edp-1") {
                hasEdp = true
            }
        }

        const normalizedName = (monitorName ?? "").trim().toLowerCase()
        const isEdp = normalizedName === "edp-1"
        const isHdmi = normalizedName === "hdmi-a-2"

        if (!isEdp && !isHdmi) {
            return []
        }

        if (monitorCount === 1) {
            return [1, 2, 3]
        }

        if (isEdp && hasEdp) {
            return [4, 5, 6]
        }

        return isHdmi ? [1, 2, 3] : []
    }
}
