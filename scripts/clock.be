# @name    Clock
# @desc    A large block-digit clock with seconds and a weekday bar. Turn the knob for the date
# @display 52x16
# @config  secs   bool   "Seconds" default=true
# @config  blink  bool   "Blinking colon" default=false
# @config  bar    bool   "Weekday bar" default=true
# @config  color  color  "Digit color" default=#F2D7B6
# @config  today  color  "Today" default=#C8643C
# @config  other  color  "Other days" default=#3A2E26

var SEGS = {"0": "abcdef", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
            "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
var DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
var MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

class Clock
  var date_until

  def init()
    self.date_until = 0
  end

  def on_knob(event)
    if event == "left" || event == "right" || event == "press"
      self.date_until = now_ms() + 5000
      return true
    end
    return false
  end

  def digit(ch, x, y, c)
    if ch == "1"
      rect_fill(x + 2, y, 2, 14, c)
      pixel(x + 1, y + 1, c)
      rect_fill(x, y + 2, 2, 1, c)
      return
    end
    var s = SEGS[ch]
    for i : 0 .. size(s) - 1
      var g = s[i]
      if g == "a" rect_fill(x, y, 6, 2, c)
      elif g == "g" rect_fill(x, y + 6, 6, 2, c)
      elif g == "d" rect_fill(x, y + 12, 6, 2, c)
      elif g == "f" rect_fill(x, y, 2, 8, c)
      elif g == "b" rect_fill(x + 4, y, 2, 8, c)
      elif g == "e" rect_fill(x, y + 6, 2, 8, c)
      elif g == "c" rect_fill(x + 4, y + 6, 2, 8, c)
      end
    end
  end

  def line_of(s, y, c, colon_on)
    var w = 0
    for i : 0 .. size(s) - 1
      w += (s[i] == ":" ? 2 : 6) + (i > 0 ? 1 : 0)
    end
    var x = (width() - w) / 2
    for i : 0 .. size(s) - 1
      if s[i] == ":"
        if colon_on
          rect_fill(x, y + 3, 2, 2, c)
          rect_fill(x, y + 9, 2, 2, c)
        end
        x += 3
      else
        self.digit(s[i], x, y, c)
        x += 7
      end
    end
  end

  def draw()
    clear()
    var c = store.get("color", 0xF2D7B6)
    if hour() < 0
      text(1, 9, "--:--", c)
      return
    end
    if now_ms() < self.date_until
      var d = format("%02d", day())
      self.digit(d[0], 4, 1, c)
      self.digit(d[1], 11, 1, c)
      text(22, 7, DAYS[weekday()], store.get("today", 0xC8643C))
      text(22, 15, MONTHS[month() - 1], c)
      return
    end
    var h = hour()
    if settings.get("time24h") == false
      h = h % 12
      if h == 0 h = 12 end
    end
    var colon = !store.get("blink", false) || second() % 2 == 0
    var s = store.get("secs", true) ? format("%02d:%02d:%02d", h, minute(), second()) : format("%02d:%02d", h, minute())
    self.line_of(s, 1, c, colon)
    if store.get("bar", true)
      var mon = (weekday() + 6) % 7
      var x0 = (width() - 41) / 2
      for i : 0 .. 6
        rect_fill(x0 + i * 6, 15, 5, 1, i == mon ? store.get("today", 0xC8643C) : store.get("other", 0x3A2E26))
      end
    end
  end
end

return Clock()
