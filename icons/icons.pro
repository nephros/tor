TEMPLATE = aux
# Configures svg to png
THEMENAME=sailfish-default
CONFIG += sailfish-svg2png
INSTALLS += svg

# also install SVG:
svg.path = /usr/share/icons/hicolor/scalable/apps
svg.files = \
    svgs/icon-m-tor.svg \
