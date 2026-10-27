# @name    Pet
# @desc    A small Clawd-style pet: follows Claude Code, dresses for the weather and brings new mail and meetings
# @display 52x16
# @config  pop   bool   "Show me when Claude waits" default=true
# @config  news  bool   "Bring mail, Slack and meetings" default=true
# @config  lat   number "Latitude"  default=43.6532 min=-90 max=90 step=0.0001 group="Weather"
# @config  lon   number "Longitude" default=-79.3832 min=-180 max=180 step=0.0001 group="Weather"
# @config  color color  "Color" default=#D77757
import math
import json

var BODY = [[[3, 14]], [[3, 14]], [[3, 4], [6, 11], [13, 14]], [[3, 4], [6, 11], [13, 14]],
            [[1, 16]], [[1, 16]], [[3, 14]], [[3, 14]]]
var LEGS_A = [4, 6, 11, 13]
var LEGS_B = [3, 5, 12, 14]
var HEART = [".#.#.", "#####", ".###.", "..#.."]
var ZED = ["###", ".#.", "###"]
var STALE = 1800
var DONE_FOR = 60
var NEWS_FOR = 20000
var CREAM = 0xE8DCCB
var BROWN = 0x8C7B6B
var AMBER = 0xE0A040

class Pet
  var x, target, rest_until, last_step, moving, hearts_until, mood, popped
  var wx, wx_ticks, news, seen

  def init()
    self.x = 17
    self.target = 17
    self.rest_until = 0
    self.last_step = 0
    self.moving = false
    self.hearts_until = 0
    self.mood = "idle"
    self.wx = store.get("wx")
    self.wx_ticks = 0
    self.news = nil
    self.seen = {}
  end

  def setup()
    self.mood = self.claude_mood()
    shared.set("claude", self.mood == "idle" ? nil : self.mood)
    self.popped = false
  end

  def claude_mood()
    var state = store.get("claude", "idle")
    var age = int(epoch_ms() / 1000) - store.get("claude_at", 0)
    if state == "done" return age < DONE_FOR ? "done" : "idle" end
    if state == "working" || state == "waiting" return age < STALE ? state : "idle" end
    return "idle"
  end

  def loop()
    var night = shared.get("Calm.night", false)
    if !self.popped
      self.popped = true
      var fresh = int(epoch_ms() / 1000) - store.get("claude_at", 0) < 15
      if fresh && store.get("pop", true) && !night
        if self.mood == "waiting" || self.mood == "done" rotation.show() end
      end
    end
    var m = self.claude_mood()
    if m != self.mood
      self.mood = m
      shared.set("claude", m == "idle" ? nil : m)
    end
    if self.wx_ticks <= 0
      self.wx_ticks = 900
      self.fetch_weather()
    end
    self.wx_ticks -= 1
    self.check_news(night)
  end

  def fetch_weather()
    var url = format("https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m,weather_code,is_day",
                     store.get("lat", 43.6532), store.get("lon", -79.3832))
    http.get(url, / b, st -> self.on_weather(b, st))
  end

  def on_weather(body, status)
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) return end
    var cur = d.find("current")
    if !isinstance(cur, map) return end
    self.wx = {"temp": cur.find("temperature_2m", 10), "code": cur.find("weather_code", 0), "day": cur.find("is_day", 1)}
    store.set("wx", self.wx)
  end

  def wx_kind()
    if self.wx == nil return "" end
    var code = self.wx["code"]
    var temp = self.wx["temp"]
    if (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95 return "rain" end
    if (code >= 71 && code <= 77) || code == 85 || code == 86 return "snow" end
    if temp < 0 return "cold" end
    if temp >= 28 return "hot" end
    if code <= 1 && self.wx["day"] == 1 return "sun" end
    return ""
  end

  def check_news(night)
    for src : [["Gmail", "mail"], ["Slack", "slack"]]
      var seq = shared.get(src[0] + ".seq")
      if seq != nil
        var before = self.seen.find(src[0])
        self.seen[src[0]] = seq
        if before != nil && seq > before && !night
          self.start_news(src[1], shared.get(src[0] + ".latest", "New message"))
        end
      end
    end
    var mins = shared.get("Google-Calendar.next_min")
    var at = shared.get("Google-Calendar.next_at")
    if mins != nil && at != nil && mins >= 0 && mins <= 5 && at != store.get("meet_seen")
      store.set("meet_seen", at)
      var title = shared.get("Google-Calendar.next_title", "Meeting")
      if !night self.start_news("meet", title + (mins == 0 ? " now" : " in " + str(mins) + "m")) end
    end
    if self.news != nil && now_ms() > self.news["until"]
      self.news = nil
      self.rest_until = now_ms() + 3000
    end
  end

  def start_news(kind, label)
    if !store.get("news", true) return end
    self.news = {"kind": kind, "text": label, "until": now_ms() + NEWS_FOR}
    self.x = -18
    self.target = 4
    rotation.show()
  end

  def on_knob(event)
    if event == "left" self.x = max(self.x - 3, 0)
    elif event == "right" self.x = min(self.x + 3, width() - 18)
    elif event == "press"
      self.hearts_until = now_ms() + 3000
      self.news = nil
    else return true
    end
    self.target = self.x
    self.rest_until = now_ms() + 8000
    return true
  end

  def walk(t, fast)
    if self.news != nil
      fast = true
    elif self.mood != "idle" && !fast
      self.moving = false
      return
    elif t < self.rest_until
      self.moving = false
      return
    end
    if self.x == self.target
      if self.news == nil
        self.target = math.rand() % (width() - 17)
        self.rest_until = t + 2000 + math.rand() % 5000
      end
      self.moving = false
      return
    end
    if t - self.last_step >= (fast ? 90 : 260)
      self.last_step = t
      self.x += self.target > self.x ? 1 : -1
    end
    self.moving = true
  end

  def sprite(x, y, c, t, eyes_closed, wave)
    var r = 0
    for spans : BODY
      if (r == 2 || r == 3) && (eyes_closed || (t % 4200) < 150)
        if !(eyes_closed && r == 3)
          rect_fill(x + 3, y + r, 12, 1, c)
          r += 1
          continue
        end
      end
      for s : spans
        var a = s[0]
        var b = s[1]
        if wave && (r == 4 || r == 5) b = 14 end
        rect_fill(x + a, y + r, b - a + 1, 1, c)
      end
      r += 1
    end
    if wave
      var up = (t / 400) % 2 == 0 ? 0 : 1
      rect_fill(x + 15, y + 2 + up, 2, 2, c)
    end
    var legs = self.moving && (t / 260) % 2 == 1 ? LEGS_B : LEGS_A
    for lx : legs
      rect_fill(x + lx, y + 8, 1, 2, c)
    end
  end

  def bitmap(rows, x, y, c)
    var r = 0
    for row : rows
      for i : 0 .. size(row) - 1
        if row[i] == "#" pixel(x + i, y + r, c) end
      end
      r += 1
    end
  end

  def envelope(x, y, c)
    rect(x, y, 7, 5, c)
    line(x + 1, y + 1, x + 3, y + 2, c)
    line(x + 5, y + 1, x + 3, y + 2, c)
  end

  def bubble(x, y, c)
    rect(x, y, 8, 5, c)
    pixel(x + 1, y + 5, c)
    pixel(x + 2, y + 2, AMBER)
    pixel(x + 4, y + 2, AMBER)
    pixel(x + 6, y + 2, AMBER)
  end

  def weather_back(kind, t)
    if kind == "rain"
      for i : 0 .. 7
        var dx = (i * 7 + 3) % width()
        var dy = ((t / 70) + i * 5) % 18 - 2
        pixel(dx, dy, 0x4E6178)
        pixel(dx, dy + 1, 0x2C3644)
      end
    elif kind == "snow"
      for i : 0 .. 8
        var dx = (i * 6 + 2 + ((t / 700 + i) % 3) - 1) % width()
        var dy = ((t / 220) + i * 3) % 17 - 1
        pixel(dx, dy, i % 2 == 0 ? CREAM : 0x6E6A64)
      end
    end
  end

  def weather_front(kind, x, y, t)
    if kind == "rain"
      rect_fill(x + 6, 1, 6, 1, CREAM)
      rect_fill(x + 4, 2, 10, 1, CREAM)
      rect_fill(x + 3, 3, 12, 1, CREAM)
      pixel(x + 9, 4, BROWN)
      pixel(x + 9, 5, BROWN)
    elif kind == "sun"
      rect_fill(x + 4, y + 2, 3, 2, 0)
      rect_fill(x + 11, y + 2, 3, 2, 0)
      rect_fill(x + 7, y + 2, 4, 1, 0)
      pixel(x + 4, y + 2, BROWN)
      pixel(x + 11, y + 2, BROWN)
    elif kind == "hot" && (t / 600) % 2 == 0
      pixel(x + 16, y + 1, 0x6FA8DC)
      pixel(x + 16, y + 2, 0x4E6178)
    end
  end

  def draw()
    clear()
    var t = now_ms()
    var c = store.get("color", 0xD77757)
    var night = shared.get("Calm.night", false)
    var next = shared.get("Google-Calendar.next_min")
    var soon = next != nil && next >= 0 && next <= 5
    var mail = shared.get("Gmail.unread", 0)
    self.walk(t, soon && !night)
    var y = 6
    if night
      self.sprite(self.x, y, 0x6A3A2C, t, true, false)
      var drift = (t / 600) % 4
      self.bitmap(ZED, self.x + 17, 3 - drift / 2, 0x3050A0)
      if drift >= 2 self.bitmap(ZED, self.x + 20, 0, 0x203070) end
      return
    end
    var kind = self.wx_kind()
    self.weather_back(kind, t)
    var x = self.x
    if (kind == "cold" || kind == "snow") && !self.moving x += (t / 90) % 2 end
    if self.news == nil && self.mood == "working"
      y = 6 - ((t / 180) % 2)
      var sx = x + 19
      var on = (t / 250) % 2 == 0
      pixel(sx + 1, 1, 0xF0A060)
      pixel(sx, 2, on ? 0xF0A060 : 0)
      pixel(sx + 2, 2, on ? 0xF0A060 : 0)
      pixel(sx + 1, 3, 0xF0A060)
      pixel(sx + 1, 2, 0xFFE0C0)
      pixel(x - 2, 2 + (t / 300) % 3, 0x804020)
    elif self.news == nil && self.mood == "done"
      var jump = (t / 120) % 12
      y = jump < 3 ? 6 - jump : (jump < 6 ? jump + 1 : 6)
      self.bitmap(HEART, x + 6, 0, 0xE06A6A)
    end
    self.sprite(x, y, c, t, false, self.news == nil && self.mood == "waiting")
    if self.news == nil || kind != "rain" self.weather_front(kind, x, y, t) end
    if self.news != nil
      if self.news["kind"] == "mail"
        self.envelope(x + 17, y + 3, CREAM)
      elif self.news["kind"] == "slack"
        self.bubble(x + 17, y + 2, CREAM)
      else
        circle(x + 20, y + 5, 3, CREAM)
        line(x + 20, y + 5, x + 20, y + 3, AMBER)
        line(x + 20, y + 5, x + 21, y + 5, AMBER)
      end
      scroll_text(0, 6, width(), self.news["text"], 0xF2D7B6)
      return
    end
    if self.mood == "waiting" && (t / 500) % 2 == 0
      rect_fill(x + 19, 6, 1, 5, AMBER)
      pixel(x + 19, 12, AMBER)
    end
    if t < self.hearts_until
      var rise = (self.hearts_until - t) / 500
      self.bitmap(HEART, x + 13, rise - 2, 0xE06A6A)
      self.bitmap(HEART, x, rise - 4, 0xE89A90)
    end
    if mail > 0
      self.envelope(self.x < 26 ? 44 : 1, 10, CREAM)
    end
    if soon
      var label = str(next) + "m"
      text(width() - text_width(label), 6, label, AMBER)
    end
  end
end

return Pet()
