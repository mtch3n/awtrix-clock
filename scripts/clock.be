# @name    Clock
# @desc    Block-digit clock with weather, alerts and many settings. Turn the knob for date, weather and alerts
# @display 52x16
# @config  layout  select "Layout" default=weather options=weather,hm,hms help="weather: weather left and HH:MM. hm: HH:MM only. hms: HH:MM:SS" group="Layout"
# @config  left    select "Left side" default=icon options=icon,both,temp help="Only for the weather layout" group="Layout"
# @config  stroke  select "Digit weight" default=bold options=bold,thin group="Digits"
# @config  hours   select "Hours" default=auto options=auto,24,12 help="auto follows the clock's 24-hour setting" group="Digits"
# @config  zero    bool   "Leading zero" default=true group="Digits"
# @config  colon   select "Colon" default=steady options=steady,blink group="Digits"
# @config  secbar  bool   "Seconds line" default=false help="A thin line on top that fills each minute" group="Digits"
# @config  bar     bool   "Weekday bar" default=true group="Extras"
# @config  overlay bool   "Weather overlay" default=false help="Rain, snow, thunder and more on the clock face" group="Extras"
# @config  mark    bool   "Alert mark" default=true help="A small triangle while Environment Canada has an alert" group="Extras"
# @config  pagesec number "Pages stay" default=8 min=3 max=60 unit=s help="After a knob turn, then back to the time" group="Extras"
# @config  color   color  "Digits" default=#F2D7B6 group="Colors"
# @config  temp    color  "Temperature" default=#E8DCCB group="Colors"
# @config  today   color  "Today" default=#C8643C group="Colors"
# @config  other   color  "Other days" default=#3A2E26 group="Colors"
# @config  sec     color  "Seconds line" default=#8C7B6B group="Colors"
import blockfont

var DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
var MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
var AMBER = 0xE0A040
var CREAM = 0xE8DCCB
var GREY = 0x9A948C
var BLUE = 0x6FA8DC

class Clock
  var page, turned

  def init()
    self.page = 0
    self.turned = 0
  end

  def pages()
    return shared.get("Sky.alert") != nil ? 4 : 3
  end

  def on_show()
    self.page = 0
  end

  def on_knob(event)
    if event == "right" self.page = (self.page + 1) % self.pages()
    elif event == "left" self.page = (self.page + self.pages() - 1) % self.pages()
    elif event == "press" self.page = 0
    else return false
    end
    self.turned = now_ms()
    return true
  end

  def rounded(v)
    return v >= 0 ? int(v + 0.5) : -int(-v + 0.5)
  end

  def cloud(cx, cy, c)
    circle_fill(cx - 3, cy + 1, 2, c)
    circle_fill(cx + 1, cy - 1, 3, c)
    circle_fill(cx + 4, cy + 1, 2, c)
    rect_fill(cx - 5, cy + 1, 11, 3, c)
  end

  def sun(cx, cy, r)
    circle_fill(cx, cy, r, AMBER)
    var d = r + 2
    pixel(cx, cy - d, AMBER)
    pixel(cx, cy + d, AMBER)
    pixel(cx - d, cy, AMBER)
    pixel(cx + d, cy, AMBER)
    pixel(cx - d + 1, cy - d + 1, AMBER)
    pixel(cx + d - 1, cy - d + 1, AMBER)
    pixel(cx - d + 1, cy + d - 1, AMBER)
    pixel(cx + d - 1, cy + d - 1, AMBER)
  end

  def moon(cx, cy, r)
    circle_fill(cx, cy, r, CREAM)
    circle_fill(cx + 2, cy - 1, r - 1, 0)
  end

  def icon(cx, cy)
    var code = shared.get("Sky.code")
    var day = shared.get("Sky.day", 1) == 1
    if code == nil
      rect_fill(cx - 3, cy, 7, 1, GREY)
      return
    end
    if code <= 1
      if day self.sun(cx, cy, 3) else self.moon(cx, cy, 4) end
    elif code == 2
      if day self.sun(cx + 3, cy - 2, 2) else self.moon(cx + 3, cy - 2, 2) end
      self.cloud(cx - 1, cy + 1, CREAM)
    elif code == 3
      self.cloud(cx, cy, CREAM)
    elif code == 45 || code == 48
      for i : 0 .. 2
        rect_fill(cx - 5 + (i % 2), cy - 2 + i * 3, 10, 1, GREY)
      end
    elif (code >= 71 && code <= 77) || code == 85 || code == 86
      self.cloud(cx, cy - 1, CREAM)
      for i : 0 .. 2
        pixel(cx - 3 + i * 3, cy + 4 + i % 2, CREAM)
      end
    elif code >= 95
      self.cloud(cx, cy - 1, GREY)
      line(cx + 1, cy + 3, cx - 1, cy + 5, AMBER)
      line(cx - 1, cy + 5, cx + 1, cy + 5, AMBER)
    else
      self.cloud(cx, cy - 1, GREY)
      for i : 0 .. 2
        pixel(cx - 3 + i * 3, cy + 3 + (i * 2) % 3, BLUE)
      end
    end
  end

  def temp_text(cx, y, top)
    var v = shared.get("Sky.temp")
    if v == nil return end
    var s = str(self.rounded(v))
    var w = text_width(s) + 4
    var x = cx - w / 2
    text(x, y, s, store.get("temp", CREAM))
    rect(x + text_width(s) + 1, top, 3, 3, store.get("temp", CREAM))
  end

  def mark(x, y, t)
    var col = shared.get("Sky.alert_color")
    if col == nil || (t / 700) % 4 == 0 return end
    pixel(x + 2, y, col)
    rect_fill(x + 1, y + 1, 3, 1, col)
    rect_fill(x, y + 2, 5, 1, col)
  end

  def hour_text()
    var h = hour()
    var mode = store.get("hours", "auto")
    var twelve = mode == "12" || (mode == "auto" && settings.get("time24h") == false)
    if twelve
      h = h % 12
      if h == 0 h = 12 end
    end
    if h < 10 && !store.get("zero", true) return " " + str(h) end
    return format("%02d", h)
  end

  def weekday_bar(x, w)
    var seg = (w + 1) / 7
    var mon = (weekday() + 6) % 7
    for i : 0 .. 6
      rect_fill(x + i * seg, 15, seg - 1, 1, i == mon ? store.get("today", 0xC8643C) : store.get("other", 0x3A2E26))
    end
  end

  def draw_time(t)
    var layout = store.get("layout", "weather")
    var s = store.get("stroke", "bold") == "bold" ? 2 : 1
    var c = store.get("color", 0xF2D7B6)
    var colon = store.get("colon", "steady") == "steady" || second() % 2 == 0
    var str_t = self.hour_text() + ":" + format("%02d", minute())
    if layout == "hms" str_t += ":" + format("%02d", second()) end
    var w = blockfont.width(str_t)
    var x = layout == "weather" ? width() - w - 1 : (width() - w) / 2
    blockfont.text(str_t, x, 1, c, s, colon)
    if store.get("bar", true) self.weekday_bar(x, w) end
    if store.get("secbar", false) rect_fill(x, 0, second() * w / 59, 1, store.get("sec", 0x8C7B6B)) end
    if layout == "weather"
      var left = store.get("left", "both")
      if left == "temp"
        font("large")
        self.temp_text(9, 11, 4)
      else
        self.icon(9, left == "icon" ? 7 : 4)
        if left == "both" self.temp_text(9, 15, 10) end
      end
      if store.get("mark", true) self.mark(15, 0, t) end
    elif store.get("mark", true)
      self.mark(0, 0, t)
    end
  end

  def draw_date()
    var c = store.get("color", 0xF2D7B6)
    var d = format("%02d", day())
    blockfont.text(d, 3, 1, c, store.get("stroke", "bold") == "bold" ? 2 : 1, true)
    text(22, 7, DAYS[weekday()], store.get("today", 0xC8643C))
    text(22, 15, MONTHS[month() - 1] + " " + str(year() % 100), c)
  end

  def draw_weather(t)
    self.icon(9, 5)
    var v = shared.get("Sky.temp")
    var f = shared.get("Sky.feels")
    var wind = shared.get("Sky.wind")
    if v == nil
      text(21, 9, "no data", GREY)
      return
    end
    text(21, 7, str(self.rounded(v)) + "C feels " + str(self.rounded(f == nil ? v : f)), store.get("color", 0xF2D7B6))
    text(21, 15, "wind " + str(self.rounded(wind == nil ? 0 : wind)) + "km/h", GREY)
  end

  def draw_alert(t)
    var col = shared.get("Sky.alert_color", CREAM)
    self.mark(1, 2, 0)
    text(8, 7, shared.get("Sky.alert_type", "alert"), col)
    scroll_text(0, 15, width(), shared.get("Sky.alert", ""), col)
  end

  def draw()
    clear()
    var t = now_ms()
    if hour() < 0
      text(1, 9, "--:--", store.get("color", 0xF2D7B6))
      return
    end
    if self.page != 0 && t - self.turned > store.get("pagesec", 8) * 1000 self.page = 0 end
    if self.page == 1 self.draw_date()
    elif self.page == 2 self.draw_weather(t)
    elif self.page == 3 self.draw_alert(t)
    else self.draw_time(t)
    end
    var ov = shared.get("Sky.overlay")
    if store.get("overlay", true) && ov != nil overlay(ov) end
  end
end

return Clock()
