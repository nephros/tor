TEMPLATE = aux

settings-entry.path = /usr/share/jolla-settings/entries
settings-entry.files = ./entries/tor.json

settings-ui.path = /usr/share/jolla-settings/pages/tor
settings-ui.files = \
    pages/tor/mainpage.qml \
    pages/tor/EnableSwitch.qml

INSTALLS += settings-ui settings-entry
