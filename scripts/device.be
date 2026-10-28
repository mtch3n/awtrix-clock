# @name    Device
# @desc    Battery and system state of the clock. Turn the knob for the pages
# @display 52x16
import blockfont

var CREAM = 0xE8DCCB
var LIGHT = 0xF6F0E6
var SHADE = 0x958B80
var DARK = 0x3A2E26
var AMBER = 0xE0A040
var GREEN = 0x6FAF6A
var RED = 0xD0503C
var BOLT = 0xF6D86A

class Device
  var page, turned

  def init()
    self.page = 0
    self.turned = 0
  end

  def on_show()
    self.page = 0
  end

  def on_knob(event)
    if event == "right" || event == "left" self.page = 1 - self.page
    elif event == "press" self.page = 0
    else return false
    end
    self.turned = now_ms()
    return true
  end

  def battery_icon(x, y, pct, charging, t)
    rect_fill(x, y, 13, 1, LIGHT)
    rect_fill(x, y + 1, 1, 7, LIGHT)
    rect_fill(x + 1, y + 7, 12, 1, SHADE)
    rect_fill(x + 12, y + 1, 1, 7, SHADE)
    rect_fill(x + 13, y + 2, 2, 4, SHADE)
    var c = pct > 50 ? GREEN : (pct >= 20 ? AMBER : RED)
    var w = pct * 11 / 100
    if charging && pct < 100 && (t / 600) % 2 == 0 w = min(w + 1, 11) end
    if w > 0
      rect_fill(x + 1, y + 1, w, 6, c)
      rect_fill(x + 1, y + 1, w, 1, ((c >> 1) & 0x7F7F7F) + 0x404040)
    end
    if charging
      pixel(x + 7, y + 1, BOLT)
      pixel(x + 6, y + 2, BOLT)
      rect_fill(x + 5, y + 3, 4, 1, BOLT)
      pixel(x + 6, y + 4, BOLT)
      pixel(x + 5, y + 5, BOLT)
      pixel(x + 4, y + 6, BOLT)
    end
  end

  def draw_battery(t)
    var pct = shared.get("Calm.battery")
    var usb = shared.get("Calm.usb", false)
    if pct == nil
      text(2, 10, "no data", SHADE)
      return
    end
    self.battery_icon(1, 4, pct, usb, t)
    var s = str(pct)
    var w = blockfont.width(s, 5, 2)
    var x = width() - w - 8
    blockfont.text(s, x, 2, CREAM, 2, 2, true, 5, 12, 2)
    text(width() - 6, 13, "%", SHADE)
    if usb text(width() - 6, 6, "+", BOLT) end
  end

  def uptime_text()
    var u = shared.get("Calm.uptime", 0)
    if u >= 86400 return format("%dd%dh", u / 86400, u % 86400 / 3600) end
    if u >= 3600 return format("%dh%02dm", u / 3600, u % 3600 / 60) end
    return format("%dm", u / 60)
  end

  def draw_system(t)
    text(0, 6, "UP " + self.uptime_text(), CREAM)
    var heap = shared.get("Calm.heap", 0)
    var v = shared.get("Calm.volts")
    var info = "fw " + str(shared.get("Calm.version", "?")) + "   mem " + format("%.1fMB", heap / 1048576.0)
    info += "   " + (v == nil ? "" : format("%.2fV", v)) + "   reset " + str(shared.get("Calm.reset", "?"))
    scroll_text(0, 14, width(), info, 0xC8643C)
  end

  def draw()
    clear()
    var t = now_ms()
    if self.page == 1 && t - self.turned > 15000 self.page = 0 end
    if self.page == 0 self.draw_battery(t) else self.draw_system(t) end
    for i : 0 .. 1
      pixel(width() - 6 + i * 2, 0, i == self.page ? 0xF2D7B6 : DARK)
    end
  end
end

return Device()
