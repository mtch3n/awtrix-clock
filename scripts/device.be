# @name    Device
# @desc    Battery, uptime, memory and firmware of the clock. Turn the knob for the pages
# @author  mtch3n
# @version 1.0
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
var RUST = 0xC8643C
var PAGES = 4
var DICONS = {"power": [11, 12, [[1, 3, 0x968F83], [2, 3, 0xE8DCCB], [8, 3, 0xE8DCCB], [9, 3, 0x968F83], [1, 4, 0xE8DCCB], [2, 4, 0x968F83], [8, 4, 0x968F83], [9, 4, 0x958B80], [0, 5, 0x716B62], [1, 5, 0xE8DCCB], [9, 5, 0x958B80], [10, 5, 0x48433E], [0, 6, 0x968F83], [1, 6, 0xE8DCCB], [9, 6, 0x958B80], [10, 6, 0x605A53], [0, 7, 0x716B62], [1, 7, 0xE8DCCB], [9, 7, 0x958B80], [10, 7, 0x48433E], [1, 8, 0xE8DCCB], [2, 8, 0x968F83], [8, 8, 0x605A53], [9, 8, 0x958B80], [1, 9, 0x968F83], [2, 9, 0xE8DCCB], [3, 9, 0x968F83], [7, 9, 0x605A53], [8, 9, 0x958B80], [9, 9, 0x605A53], [2, 10, 0x968F83], [3, 10, 0x958B80], [4, 10, 0x958B80], [5, 10, 0x958B80], [6, 10, 0x958B80], [7, 10, 0x958B80], [8, 10, 0x605A53], [4, 11, 0x48433E], [5, 11, 0x605A53], [6, 11, 0x48433E], [5, 0, 0xF6F0E6], [5, 1, 0xF6F0E6], [5, 2, 0xF6F0E6], [5, 3, 0xF6F0E6], [5, 4, 0xE8DCCB], [5, 5, 0xE8DCCB], [5, 6, 0xE8DCCB]]], "chip": [11, 11, [[2, 2, 0x8A8278], [3, 2, 0x8A8278], [4, 2, 0x8A8278], [5, 2, 0x8A8278], [6, 2, 0x8A8278], [7, 2, 0x8A8278], [8, 2, 0x4A453F], [2, 3, 0x8A8278], [3, 3, 0x6A645D], [4, 3, 0x6A645D], [5, 3, 0x6A645D], [6, 3, 0x6A645D], [7, 3, 0x6A645D], [8, 3, 0x4A453F], [2, 4, 0x8A8278], [3, 4, 0x6A645D], [4, 4, 0x6A645D], [5, 4, 0x6A645D], [6, 4, 0x6A645D], [7, 4, 0x6A645D], [8, 4, 0x4A453F], [2, 5, 0x8A8278], [3, 5, 0x6A645D], [4, 5, 0x6A645D], [5, 5, 0x6A645D], [6, 5, 0x6A645D], [7, 5, 0x6A645D], [8, 5, 0x4A453F], [2, 6, 0x8A8278], [3, 6, 0x6A645D], [4, 6, 0x6A645D], [5, 6, 0x6A645D], [6, 6, 0x6A645D], [7, 6, 0x6A645D], [8, 6, 0x4A453F], [2, 7, 0x8A8278], [3, 7, 0x6A645D], [4, 7, 0x6A645D], [5, 7, 0x6A645D], [6, 7, 0x6A645D], [7, 7, 0x6A645D], [8, 7, 0x4A453F], [2, 8, 0x4A453F], [3, 8, 0x4A453F], [4, 8, 0x4A453F], [5, 8, 0x4A453F], [6, 8, 0x4A453F], [7, 8, 0x4A453F], [8, 8, 0x4A453F], [3, 3, 0xC8C0B6], [3, 0, 0xC8A070], [3, 1, 0xC8A070], [3, 9, 0x8C6A40], [3, 10, 0x8C6A40], [0, 3, 0xC8A070], [1, 3, 0xC8A070], [9, 3, 0x8C6A40], [10, 3, 0x8C6A40], [5, 0, 0xC8A070], [5, 1, 0xC8A070], [5, 9, 0x8C6A40], [5, 10, 0x8C6A40], [0, 5, 0xC8A070], [1, 5, 0xC8A070], [9, 5, 0x8C6A40], [10, 5, 0x8C6A40], [7, 0, 0xC8A070], [7, 1, 0xC8A070], [7, 9, 0x8C6A40], [7, 10, 0x8C6A40], [0, 7, 0xC8A070], [1, 7, 0xC8A070], [9, 7, 0x8C6A40], [10, 7, 0x8C6A40]]], "info": [11, 11, [[3, 0, 0x3E586B], [4, 0, 0x73A1C6], [5, 0, 0x7DB0D7], [6, 0, 0x73A1C6], [7, 0, 0x3E586B], [2, 1, 0x88BFEA], [3, 1, 0x8CC4F0], [4, 1, 0x8CC4F0], [6, 1, 0x8CC4F0], [7, 1, 0x5A94CC], [8, 1, 0x5790C6], [1, 2, 0x88BFEA], [2, 2, 0x8CC4F0], [3, 2, 0x8CC4F0], [4, 2, 0x8CC4F0], [5, 2, 0x8CC4F0], [6, 2, 0x5A94CC], [7, 2, 0x5A94CC], [8, 2, 0x5A94CC], [9, 2, 0x5790C6], [0, 3, 0x3E586B], [1, 3, 0x8CC4F0], [2, 3, 0x8CC4F0], [3, 3, 0x8CC4F0], [6, 3, 0x5A94CC], [7, 3, 0x5A94CC], [8, 3, 0x5A94CC], [9, 3, 0x5A94CC], [10, 3, 0x28425B], [0, 4, 0x73A1C6], [1, 4, 0x8CC4F0], [2, 4, 0x8CC4F0], [3, 4, 0x8CC4F0], [4, 4, 0x5A94CC], [6, 4, 0x5A94CC], [7, 4, 0x5A94CC], [8, 4, 0x5A94CC], [9, 4, 0x5A94CC], [10, 4, 0x33577A], [0, 5, 0x7DB0D7], [1, 5, 0x8CC4F0], [2, 5, 0x8CC4F0], [3, 5, 0x5A94CC], [4, 5, 0x5A94CC], [6, 5, 0x5A94CC], [7, 5, 0x5A94CC], [8, 5, 0x5A94CC], [9, 5, 0x3E6A94], [10, 5, 0x375F85], [0, 6, 0x73A1C6], [1, 6, 0x8CC4F0], [2, 6, 0x5A94CC], [3, 6, 0x5A94CC], [4, 6, 0x5A94CC], [6, 6, 0x5A94CC], [7, 6, 0x5A94CC], [8, 6, 0x3E6A94], [9, 6, 0x3E6A94], [10, 6, 0x33577A], [0, 7, 0x3E586B], [1, 7, 0x5A94CC], [2, 7, 0x5A94CC], [3, 7, 0x5A94CC], [7, 7, 0x3E6A94], [8, 7, 0x3E6A94], [9, 7, 0x3E6A94], [10, 7, 0x1B2F42], [1, 8, 0x5790C6], [2, 8, 0x5A94CC], [3, 8, 0x5A94CC], [4, 8, 0x5A94CC], [5, 8, 0x5A94CC], [6, 8, 0x3E6A94], [7, 8, 0x3E6A94], [8, 8, 0x3E6A94], [9, 8, 0x3C6790], [2, 9, 0x5790C6], [3, 9, 0x5A94CC], [4, 9, 0x5A94CC], [5, 9, 0x3E6A94], [6, 9, 0x3E6A94], [7, 9, 0x3E6A94], [8, 9, 0x3C6790], [3, 10, 0x28425B], [4, 10, 0x33577A], [5, 10, 0x375F85], [6, 10, 0x33577A], [7, 10, 0x1B2F42], [5, 1, 0xF6F0E6], [5, 3, 0xF6F0E6], [5, 4, 0xF6F0E6], [5, 5, 0xF6F0E6], [5, 6, 0xF6F0E6], [5, 7, 0xF6F0E6], [4, 3, 0xF6F0E6], [4, 7, 0xF6F0E6], [6, 7, 0xF6F0E6]]]}

class Device
  var page, turned, pct_s, left_s, up_v, up_u, mem_s, fw_s, info_s

  def init()
    self.page = 0
    self.turned = 0
  end

  def loop()
    var pct = shared.get("Calm.battery")
    self.pct_s = pct == nil ? nil : str(pct)
    var left = shared.get("Calm.left_h")
    self.left_s = left == nil ? nil : (left >= 1 ? format("~%dh", int(left)) : format("~%dm", int(left * 60)))
    var u = shared.get("Calm.uptime", 0)
    if u >= 86400
      self.up_v = str(u / 86400)
      self.up_u = "d"
    elif u >= 36000
      self.up_v = str(u / 3600)
      self.up_u = "h"
    else
      self.up_v = format("%d:%02d", u / 3600, u % 3600 / 60)
      self.up_u = "h"
    end
    self.mem_s = str(shared.get("Calm.heap", 0) / 1048576)
    self.fw_s = "fw " + str(shared.get("Calm.version", "?"))
    var v = shared.get("Calm.volts")
    self.info_s = (v == nil ? "" : format("%.2fV  ", v)) + "reset " + str(shared.get("Calm.reset", "?"))
  end

  def on_show()
    self.page = 0
  end

  def on_knob(event)
    if event == "right" self.page = (self.page + 1) % PAGES
    elif event == "left" self.page = (self.page + PAGES - 1) % PAGES
    elif event == "press" self.page = 0
    else return false
    end
    self.turned = now_ms()
    return true
  end

  def icon(name, cx, cy)
    var ic = DICONS[name]
    var x0 = cx - ic[0] / 2
    var y0 = cy - ic[1] / 2
    for p : ic[2]
      pixel(x0 + p[0], y0 + p[1], p[2])
    end
  end

  def big(value, unit, color)
    var uw = unit == "%" ? 5 : text_width(unit)
    var w = blockfont.width(value, 5, 2)
    var x = width() - w - uw - 3
    blockfont.text(value, x, 2, color, 2, 2, true, 5, 12, 2)
    if unit == "%"
      var ux = width() - 6
      pixel(ux, 9, SHADE)
      pixel(ux + 4, 9, SHADE)
      line(ux + 3, 10, ux + 1, 12, SHADE)
      pixel(ux, 13, SHADE)
      pixel(ux + 4, 13, SHADE)
    else
      text(width() - uw - 1, 14, unit, SHADE)
    end
  end

  def battery_icon(x, y, pct, charging, t)
    rect_fill(x, y, 13, 1, LIGHT)
    rect_fill(x, y + 1, 1, 7, LIGHT)
    rect_fill(x + 1, y + 8, 12, 1, SHADE)
    rect_fill(x + 12, y + 1, 1, 8, SHADE)
    rect_fill(x + 13, y + 3, 2, 3, SHADE)
    var c = pct > 50 ? GREEN : (pct >= 20 ? AMBER : RED)
    var w = pct * 11 / 100
    if charging && pct < 100 && (t / 600) % 2 == 0 w = min(w + 1, 11) end
    if w > 0
      rect_fill(x + 1, y + 1, w, 7, c)
      rect_fill(x + 1, y + 1, w, 1, ((c >> 1) & 0x7F7F7F) + 0x404040)
      rect_fill(x + 1, y + 7, w, 1, (c >> 1) & 0x7F7F7F)
    end
    if charging
      pixel(x + 7, y + 1, BOLT)
      pixel(x + 6, y + 2, BOLT)
      rect_fill(x + 4, y + 3, 5, 1, BOLT)
      rect_fill(x + 4, y + 4, 4, 1, BOLT)
      pixel(x + 6, y + 5, BOLT)
      pixel(x + 5, y + 6, BOLT)
      pixel(x + 4, y + 7, 0xC08A30)
    end
  end

  def draw_battery(t)
    var pct = shared.get("Calm.battery")
    if pct == nil || self.pct_s == nil
      text(2, 10, "waiting...", SHADE)
      return
    end
    var usb = shared.get("Calm.usb", false)
    self.battery_icon(1, 4, pct, usb, t)
    self.big(self.pct_s, "%", pct >= 20 ? CREAM : RED)
    if !usb && self.left_s != nil text(18, 15, self.left_s, SHADE) end
  end

  def draw_uptime()
    self.icon("power", 8, 8)
    if self.up_v != nil self.big(self.up_v, self.up_u, CREAM) end
  end

  def draw_memory()
    self.icon("chip", 8, 8)
    if self.mem_s != nil self.big(self.mem_s, "MB", CREAM) end
  end

  def draw_info()
    self.icon("info", 7, 8)
    if self.fw_s == nil return end
    text(15, 7, self.fw_s, CREAM)
    scroll_text(15, 15, width() - 15, self.info_s, RUST)
  end

  def draw()
    clear()
    var t = now_ms()
    if self.page != 0 && t - self.turned > 20000 self.page = 0 end
    if self.page == 0 self.draw_battery(t)
    elif self.page == 1 self.draw_uptime()
    elif self.page == 2 self.draw_memory()
    else self.draw_info()
    end
    for i : 0 .. PAGES - 1
      pixel(width() - 2 - (PAGES - 1 - i) * 2, 0, i == self.page ? 0xF2D7B6 : DARK)
    end
  end
end

return Device()
