import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root

  readonly property var nightlightService: bar?.shell?.firstPartyServiceFor("omarchy.nightlight")
  readonly property int nightTemperature: nightlightService ? nightlightService.nightTemperature : 4000
  readonly property bool active: nightlightService ? nightlightService.enabled : false
  readonly property var modeOptions: ["daylight", "nightlight", "sunset"]
  readonly property string mode: nightlightService && nightlightService.scheduled
    ? "sunset"
    : (root.active ? "nightlight" : "daylight")
  property string indicatorBlock: "single"
  property var indicatorHost: null
  property var activeOverride: null
  readonly property bool fixedPosition: true
  property int cursorIndex: 0

  ipcTarget: "nightlight.panel"
  manageIpc: true
  implicitWidth: indicator.implicitWidth
  implicitHeight: indicator.implicitHeight
  visible: indicator.visible

  function toggleTemperature() {
    if (root.nightlightService) root.nightlightService.setNightlight(!root.active)
  }

  function triggerPress(button) {
    if (button === Qt.RightButton) root.toggle()
    else indicator.triggerPress(button)
  }

  function openSettings() {
    Qt.callLater(function() { root.toggle() })
  }

  function selectMode(mode) {
    if (!root.nightlightService) return
    if (mode === "sunset") root.nightlightService.setScheduleEnabled(true)
    else root.nightlightService.setNightlight(mode === "nightlight")
  }

  function moveCursor(delta) {
    cursorIndex = Math.max(0, Math.min(modeOptions.length - 1, cursorIndex + delta))
  }

  onOpenedChanged: {
    if (opened) cursorIndex = Math.max(0, modeOptions.indexOf(mode))
  }

  BarIndicator {
    id: indicator

    anchors.fill: parent
    bar: root.bar
    moduleName: root.moduleName
    settings: root.settings
    indicatorBlock: root.indicatorBlock
    indicatorHost: root.indicatorHost
    activeOverride: root.opened ? null : root.activeOverride
    alwaysRevealInactive: true
    active: root.active
    activeText: "󰔎"
    inactiveText: "󰔎"
    activeTooltipText: "Night Light · Right-click for modes"
    inactiveTooltipText: "Night Light · Right-click for modes"

    onPressed: function(button) {
      if (button === Qt.RightButton) root.toggle()
      else root.toggleTemperature()
    }
  }

  MouseArea {
    anchors.fill: indicator
    acceptedButtons: Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: root.openSettings()
  }

  KeyboardPanel {
    id: panel
    anchorItem: indicator
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: tempInput.activeFocus
      onMoveRequested: function(dx, dy) { root.moveCursor(dx !== 0 ? dx : dy) }
      onActivateRequested: root.selectMode(root.modeOptions[root.cursorIndex])
      onCloseRequested: root.close()

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(14)

        PanelHero {
          title: "Night Light"
          meta: root.mode === "sunset"
            ? ("Follows sunset and sunrise · " + root.nightTemperature + "K")
            : (root.mode === "nightlight" ? ("Warm display · " + root.nightTemperature + "K") : "Daylight display · 6500K")
          detail: root.mode === "sunset" && root.nightlightService
            ? root.nightlightService.scheduleTimezone
            : ""
          foreground: root.barForeground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          iconComponent: Component {
            Text {
              text: "󰔎"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
            }
          }
        }

        PanelSeparator {
          foreground: root.barForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "MODE"
            foreground: root.barForeground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          ButtonGroup {
            options: [
              { value: "daylight", label: "Daylight" },
              { value: "nightlight", label: "Night Light" },
              { value: "sunset", label: "Sunset" }
            ]
            value: root.mode
            cursorIndex: root.cursorIndex
            foreground: root.barForeground
            background: Color.popups.background
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            focusable: false
            onChanged: function(value) { root.selectMode(value) }
            onHovered: function(index, hovered) { if (hovered) root.cursorIndex = index }
          }
        }

        Text {
          visible: root.mode === "sunset" && root.nightlightService && root.nightlightService.nextEventAt !== ""
          width: parent.width
          textFormat: Text.PlainText
          text: root.nightlightService
            ? "Next: " + root.nightlightService.nextEvent + " · " + Qt.formatDateTime(new Date(root.nightlightService.nextEventAt), "ddd h:mm AP")
            : ""
          color: Qt.darker(root.barForeground, 1.4)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
        }

        PanelSeparator {
          foreground: root.barForeground
        }

        // Warmth / Temperature Slider Section
        Column {
          width: parent.width
          spacing: Style.space(8)

          Item {
            width: parent.width
            height: Math.max(header.implicitHeight, valueRow.implicitHeight)

            PanelSectionHeader {
              id: header
              text: "WARMTH"
              foreground: root.barForeground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Row {
              id: valueRow
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(4)

              TextField {
                id: tempInput
                width: Style.space(56)
                horizontalPadding: Style.space(4)
                verticalPadding: Style.space(2)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                color: Color.accent
                horizontalAlignment: TextInput.AlignRight
                inputMethodHints: Qt.ImhDigitsOnly
                text: String(root.nightTemperature)

                // Sync text when slider moves (if not actively editing)
                Connections {
                  target: warmthSlider
                  function onDraggingChanged() {
                    if (warmthSlider.dragging && !tempInput.activeFocus) {
                      tempInput.text = String(Math.round(warmthSlider.liveValue))
                    }
                  }
                  function onLiveValueChanged() {
                    if (warmthSlider.dragging && !tempInput.activeFocus) {
                      tempInput.text = String(Math.round(warmthSlider.liveValue))
                    }
                  }
                }

                // Sync text when nightTemperature changes externally
                Connections {
                  target: root
                  function onNightTemperatureChanged() {
                    if (!tempInput.activeFocus && !warmthSlider.dragging) {
                      tempInput.text = String(root.nightTemperature)
                    }
                  }
                }

                function commitValue() {
                  var val = parseInt(tempInput.text.trim(), 10)
                  if (isNaN(val)) val = root.nightTemperature
                  val = Math.max(1000, Math.min(val, 6500))
                  if (root.nightlightService) {
                    root.nightlightService.setTemperature(val)
                  }
                  tempInput.text = String(val)
                }

                onAccepted: {
                  commitValue()
                  keyCatcher.forceActiveFocus()
                }

                onEditingFinished: {
                  commitValue()
                }

                onActiveFocusChanged: {
                  if (activeFocus) {
                    selectAll()
                  }
                }

                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Escape) {
                    tempInput.text = String(root.nightTemperature)
                    keyCatcher.forceActiveFocus()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Up) {
                    var vUp = Math.min(6500, Math.round(parseInt(tempInput.text, 10) / 100) * 100 + 100)
                    tempInput.text = String(vUp)
                    commitValue()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Down) {
                    var vDown = Math.max(1000, Math.round(parseInt(tempInput.text, 10) / 100) * 100 - 100)
                    tempInput.text = String(vDown)
                    commitValue()
                    event.accepted = true
                  }
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "K"
                color: Color.accent
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }
          }

          PanelSlider {
            id: warmthSlider
            width: parent.width
            bar: root.bar
            minimum: 1500
            maximum: 5000
            step: 100
            integer: true
            value: root.nightTemperature

            onMoved: function(v) {
              if (root.nightlightService && (root.mode === "nightlight" || (root.mode === "sunset" && root.nightlightService.isNight))) {
                root.nightlightService.applyTemperature(Math.round(v))
              }
            }

            onReleased: function(v) {
              if (root.nightlightService) {
                root.nightlightService.setTemperature(Math.round(v))
              }
            }
          }

          Item {
            width: parent.width
            height: leftLabel.implicitHeight

            Text {
              id: leftLabel
              anchors.left: parent.left
              text: "1500K Candle"
              color: Qt.darker(root.barForeground, 1.6)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              anchors.right: parent.right
              text: "5000K Soft"
              color: Qt.darker(root.barForeground, 1.6)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}
