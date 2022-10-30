import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0

Page {
    id: page

    property bool activeState

    onActiveStateChanged: {
        if (activeState) { daemonInfo.refreshInfo() }
    }

    Timer {
        id: checkState
        interval: 2000
        repeat: true
        running: Qt.application.state == Qt.ApplicationActive
        onTriggered: {
            systemdServiceIface.updateProperties()
        }
    }

    Timer {
        id: refreshTimer
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: activeState && Qt.application.state == Qt.ApplicationActive
        onTriggered: {
            daemonInfo.refreshInfo()
        }
    }

    DBusInterface {
        // qdbus --system org.freedesktop.systemd1 /org/freedesktop/systemd1/unit/tor_2eservice org.freedesktop.systemd1.Unit.ActiveState
        // valuse: "active", "reloading", "inactive", "failed", "activating", and "deactivating"
        id: systemdServiceIface
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/tor_2eservice'
        iface: 'org.freedesktop.systemd1.Unit'

        signalsEnabled: true
        function updateProperties() {
            var activeProperty = systemdServiceIface.getProperty("ActiveState")
            //var enabledProperty = systemdServiceIface.getProperty("UnitFileState")
            console.debug("ActiveState:", activeProperty)
            if (activeProperty === "active") {
                activeState = true
                startstopSwitch.busy = false
            }
            else if (activeProperty === "inactive" || activeProperty === "failed") {
                activeState = false
                startstopSwitch.busy = false
            } else {
                startstopSwitch.busy = true
            }
            /*
            if (enabledProperty === "enabled") {
                enabledState = true
            } else {
                enabledState = false
            }
            */
        }

        onPropertiesChanged: updateProperties()
        Component.onCompleted: updateProperties()
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/tor_2eservice'
        iface: 'org.freedesktop.DBus.Properties'

        signalsEnabled: true
        onPropertiesChanged: { console.log("updating properties"); systemdServiceIface.updateProperties()}
        Component.onCompleted: systemdServiceIface.updateProperties()
    }

    /*
    DBusInterface {
        id: systemdManagerIface
        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        signal unitNew(string name)
        onUnitNew: {
            if (name == "tor.service") {
                console.debug("A wild unit appeared!", name);
                systemdServiceIface.updateProperties()
            }
        }
    }
    */

    SilicaFlickable { id: flick
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Tor Proxy") }

            ListItem {
                id: enableItem

                contentHeight: startstopSwitch.height
                _backgroundColor: "transparent"

                highlighted: startstopSwitch.down || menuOpen

                showMenuOnPressAndHold: false
                menu: Component { FavoriteMenu { } }

                TextSwitch {
                    id: startstopSwitch

                    automaticCheck: false
                    checked: activeState
                    text: "Tor Service" + " " + ( activeState ? "active" : "inactive" )
                    description: activeState ? qsTr("Stopping may take some time.") : ""

                    onClicked: {
                        if (startstopSwitch.busy) {
                            return
                        }
                        systemdServiceIface.call(activeState ? "Stop" : "Start", ["replace"])
                        systemdServiceIface.updateProperties()
                        startstopSwitch.busy = true
                    }
                }
            }
        }
    }
}
