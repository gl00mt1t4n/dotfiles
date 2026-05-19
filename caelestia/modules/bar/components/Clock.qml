pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.normal : Tokens.padding.small
    readonly property int topOffset: Tokens.spacing.large

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + root.padding * 2 + root.topOffset

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: layout

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.topOffset / 2
        spacing: Tokens.spacing.small

        Loader {
            asynchronous: true
            anchors.horizontalCenter: parent.horizontalCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                font.pointSize: Math.round(Tokens.font.size.larger * 1.08)
                text: "calendar_month"
                color: root.colour
            }
        }

        RotatedLabel {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: Config.bar.clock.showDate

            text: Time.format("ddd d")
            fontFamily: Tokens.font.family.sans
            labelColor: root.colour
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.bar.clock.showDate
            height: visible ? 1 : 0

            width: parent.width * 0.8
            color: root.colour
            opacity: 0.2
        }

        RotatedLabel {
            anchors.horizontalCenter: parent.horizontalCenter

            text: Time.format(GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "HH:mm")
            fontFamily: Tokens.font.family.mono
            labelColor: root.colour
        }
    }

    component RotatedLabel: Item {
        id: labelRoot

        required property string text
        property string fontFamily: root.Tokens.font.family.sans
        property int pointSize: root.Tokens.font.size.smaller
        property color labelColor: root.colour

        implicitWidth: label.implicitHeight
        implicitHeight: label.implicitWidth

        StyledText {
            id: label

            anchors.centerIn: parent

            text: labelRoot.text
            horizontalAlignment: StyledText.AlignHCenter
            font.pointSize: labelRoot.pointSize
            font.family: labelRoot.fontFamily
            color: labelRoot.labelColor

            transform: [
                Rotation {
                    angle: 90
                    origin.x: label.implicitHeight / 2
                    origin.y: label.implicitHeight / 2
                }
            ]

            width: implicitHeight
            height: implicitWidth
        }
    }
}
