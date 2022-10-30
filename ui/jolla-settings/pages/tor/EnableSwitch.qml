/*
 * Copyright (c) 2022 Peter G. <sailfish@nephros.org>
 *
 * License: Apache-2.0
 *
 */

import QtQuick 2.1
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0

SettingsToggle {
    id: enableSwitch

    property bool activeState

    name: "Tor"
    activeText: "Tor"
    icon.source: "image://theme/icon-m-tor"

    active: activeState
    checked: activeState

    menu: ContextMenu {
        SettingsMenuItem { onClicked: enableSwitch.goToSettings() }
        MenuItem {
            text: "Open Web Console"
            onClicked: Qt.openUrlExternally("http://127.0.0.1:7070")
        }
    }

    onToggled: {
        if (busy) {
            return
        }
        busy = true
        systemdServiceIface.call(activeState ? "Stop" : "Start", ["replace"])
        systemdServiceIface.updateProperties()
    }

    Timer {
        id: checkState
        interval: 2000
        repeat: true
        onTriggered: {
            systemdServiceIface.updateProperties()
        }
    }

    DBusInterface {
        id: systemdServiceIface
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/tor_2eservice'
        iface: 'org.freedesktop.systemd1.Unit'

        signalsEnabled: true
        function updateProperties() {
            var activeProperty = systemdServiceIface.getProperty("ActiveState")
            console.log("ActiveState:", activeProperty)
            if (activeProperty === "active") {
                activeState = true
                checkState.stop()
            }
            else if (activeProperty === "inactive" || activeProperty === "failed")  {
                activeState = false
                checkState.stop()
            }
            else {
                enableSwitch.busy = false
                checkState.start()
            }
        }

        onPropertiesChanged: updateProperties()
        Component.onCompleted: updateProperties()
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/tor'
        iface: 'org.freedesktop.DBus.Properties'

        signalsEnabled: true
        onPropertiesChanged: systemdServiceIface.updateProperties()
        Component.onCompleted: systemdServiceIface.updateProperties()
    }

    /*
    DBusInterface {
        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        signal unitNew(string name)
        onUnitNew: {
            if (name == "tor.service") {
                systemdServiceIface.updateProperties()
            }
        }
    }
    */

    Component.onCompleted: systemdServiceIface.updateProperties()

}
