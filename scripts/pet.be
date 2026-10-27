# @name    Pet
# @desc    A small Clawd-style pet: visits now and then, does things, follows Claude Code, dresses for the weather and brings the news
# @display 52x16
# @config  visit number "Visit every" default=20 min=0 max=240 unit=min help="0 = never. Only in the day"
# @config  pop   bool   "Show me when Claude waits" default=true
# @config  news  bool   "Bring mail, Slack and meetings" default=true
# @config  hungry number "Hungry after" default=6 min=1 max=48 unit=h
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
var NOTE = [".##", ".#.", "##."]
var COOKIE = [".##.", "#.##", "##.#", ".##."]
var STALE = 1800
var DONE_FOR = 60
var NEWS_FOR = 20000
var ACT_FOR = 18000
var CREAM = 0xE8DCCB
var BROWN = 0x8C7B6B
var DARK = 0x3A2E26
var AMBER = 0xE0A040
var RUST = 0xC8643C
var BLUE = 0x6FA8DC
var PINK = 0xE06A6A
var GREEN = 0x6FAF6A
var BOUNCE = [0, 2, 3, 2, 0]
var ACTS = ["laptop", "coffee", "book", "music", "exercise", "ball", "dance", "plant", "hello"]

class Pet
  var x, target, rest_until, last_step, moving, hearts_until, mood, popped
  var wx, wx_ticks, news, seen
  var act, act_start, act_until, ball_x, ball_dx, ball_t, last_visit, idle_since, eat_until, away_until

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
    self.act = nil
    self.act_start = 0
    self.act_until = 0
    self.ball_x = 0
    self.ball_dx = 1
    self.ball_t = 0
    self.last_visit = int(epoch_ms() / 1000)
    self.idle_since = now_ms()
    self.eat_until = 0
    self.away_until = 0
  end

  def setup()
    math.srand(int(epoch_ms() % 100000))
    self.mood = self.claude_mood()
    shared.set("claude", self.mood == "idle" ? nil : self.mood)
    self.popped = false
    if store.get("fed_at") == nil store.set("fed_at", int(epoch_ms() / 1000)) end
  end

  def claude_mood()
    var state = store.get("claude", "idle")
    var age = int(epoch_ms() / 1000) - store.get("claude_at", 0)
    if state == "done" return age < DONE_FOR ? "done" : "idle" end
    if state == "working" || state == "waiting" return age < STALE ? state : "idle" end
    return "idle"
  end

  def hungry()
    return int(epoch_ms() / 1000) - store.get("fed_at", 0) > store.get("hungry", 6) * 3600
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
    self.check_visit(night)
    if self.act != nil && now_ms() > self.act_until
      self.act = nil
      self.idle_since = now_ms()
      self.rest_until = now_ms() + 2000
    end
  end

  def check_visit(night)
    var every = store.get("visit", 20)
    var now = int(epoch_ms() / 1000)
    if night || every <= 0 || self.news != nil || self.mood != "idle" || hour() < 0 return end
    if now - self.last_visit < every * 60 return end
    self.last_visit = now
    self.start_act(self.pick_act())
    rotation.show()
  end

  def pick_act()
    var h = hour()
    if h >= 6 && h < 10 && math.rand() % 3 == 0 return "coffee" end
    if h >= 19 && math.rand() % 3 == 0 return "book" end
    return ACTS[math.rand() % size(ACTS)]
  end

  def offscreen()
    return self.x <= -18 || self.x >= width()
  end

  def start_act(name)
    if self.offscreen() self.x = self.x < 0 ? 0 : width() - 18 end
    self.away_until = 0
    self.act = name
    self.act_start = now_ms()
    self.act_until = now_ms() + ACT_FOR
    if name == "ball"
      self.ball_x = self.x < 26 ? width() - 4 : 1
      self.ball_dx = self.x < 26 ? -1 : 1
    end
    if name == "laptop" || name == "coffee" || name == "book" || name == "plant"
      self.target = min(max(self.x, 0), width() - 30)
      self.x = self.target
    end
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
    self.act = nil
    self.news = {"kind": kind, "text": label, "until": now_ms() + NEWS_FOR}
    self.x = -18
    self.target = 4
    rotation.show()
  end

  def on_show()
    self.idle_since = now_ms()
    if self.away_until > now_ms() + 1500 self.away_until = now_ms() + 1500 end
  end

  def on_knob(event)
    if event == "left"
      self.x = max(self.x - 3, 0)
    elif event == "right"
      self.x = min(self.x + 3, width() - 18)
    elif event == "press"
      self.hearts_until = now_ms() + 3000
      self.news = nil
    elif event == "long"
      self.act = "eat"
      self.act_start = now_ms()
      self.act_until = now_ms() + 6000
      self.eat_until = now_ms() + 6000
      store.set("fed_at", int(epoch_ms() / 1000))
    else
      return true
    end
    self.target = self.x
    self.rest_until = now_ms() + 8000
    self.idle_since = now_ms()
    return true
  end

  def on_button(btn)
    if btn != "select" return false end
    self.news = nil
    self.start_act("ball")
    return true
  end

  def walk(t, fast)
    var called = self.mood != "idle" || self.act != nil || fast
    if self.news == nil && called && (self.x < 0 || self.x > width() - 18)
      self.target = self.x < 0 ? 2 : width() - 20
      self.away_until = 0
      fast = true
    elif self.news != nil
      fast = true
    elif self.act == "ball"
      self.target = self.ball_dx > 0 ? self.ball_x - 19 : self.ball_x + 4
      self.target = min(max(self.target, 0), width() - 18)
      fast = true
    elif self.act != nil || (self.mood != "idle" && !fast)
      self.moving = false
      return
    elif t < self.rest_until
      self.moving = false
      return
    end
    if self.x == self.target && self.news == nil && self.act == nil && self.offscreen()
      self.moving = false
      if self.away_until == 0
        self.away_until = t + 5000 + math.rand() % 15000
      elif t >= self.away_until
        self.away_until = 0
        var left = math.rand() % 2 == 0
        self.x = left ? -18 : width()
        self.target = math.rand() % 3 == 0 ? (left ? -9 : width() - 9) : math.rand() % (width() - 17)
        self.rest_until = t + 2500
      end
      return
    end
    if self.x == self.target
      if self.news == nil && self.act == nil
        self.target = math.rand() % 7 == 0 ? (math.rand() % 2 == 0 ? -18 : width()) : math.rand() % (width() - 17)
        self.rest_until = t + 2000 + math.rand() % 5000
        if t - self.idle_since > 15000 && self.mood == "idle" && math.rand() % 3 == 0
          self.start_act(self.pick_act())
        end
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

  def arms_up(x, y, c, left_up, right_up)
    if left_up
      rect_fill(x + 1, y + 4, 2, 2, 0)
      rect_fill(x + 1, y + 1, 2, 3, c)
    end
    if right_up
      rect_fill(x + 15, y + 4, 2, 2, 0)
      rect_fill(x + 15, y + 1, 2, 3, c)
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
      pixel(x + 16, y + 1, BLUE)
      pixel(x + 16, y + 2, 0x4E6178)
    end
  end

  def draw_laptop(x, y, t)
    rect(x + 20, y, 9, 7, BROWN)
    for i : 0 .. 2
      var w = (t / 300 + i * 3) % 6 + 1
      rect_fill(x + 21, y + 1 + i * 2, w, 1, i == 1 ? AMBER : BLUE)
    end
    rect_fill(x + 18, y + 7, 12, 1, CREAM)
    var tap = (t / 150) % 2
    pixel(x + 17, y + 6 - tap, store.get("color", 0xD77757))
  end

  def draw_coffee(x, y, t)
    var sip = (t / 2500) % 3 == 0
    var my = sip ? y + 1 : y + 4
    rect_fill(x + 18, my, 4, 4, CREAM)
    pixel(x + 22, my + 1, CREAM)
    pixel(x + 22, my + 2, CREAM)
    if !sip
      for i : 0 .. 1
        var s = (t / 250 + i * 2) % 4
        pixel(x + 19 + i * 2 + (s % 2), my - 1 - s, 0x6E6A64)
      end
    end
  end

  def draw_book(x, y, t)
    rect_fill(x + 17, y + 3, 5, 5, CREAM)
    rect_fill(x + 23, y + 3, 5, 5, CREAM)
    rect_fill(x + 22, y + 3, 1, 5, BROWN)
    for i : 0 .. 1
      rect_fill(x + 18, y + 4 + i * 2, 3, 1, DARK)
      rect_fill(x + 24, y + 4 + i * 2, 3, 1, DARK)
    end
    var flip = (t / 150) % 20
    if flip < 5 rect_fill(x + 23 - flip, y + 2, 1, 6, 0xF2D7B6) end
  end

  def draw_music(x, y, t)
    rect_fill(x + 3, y - 1, 12, 1, BROWN)
    pixel(x + 2, y, BROWN)
    pixel(x + 15, y, BROWN)
    rect_fill(x + 1, y + 1, 2, 3, CREAM)
    rect_fill(x + 15, y + 1, 2, 3, CREAM)
    for i : 0 .. 1
      var rise = (t / 120 + i * 7) % 14
      self.bitmap(NOTE, x + 18 + i * 5, 10 - rise, i == 0 ? AMBER : CREAM)
    end
  end

  def draw_plant(x, y, t)
    var age = (t - self.act_start) / 1500
    rect_fill(x + 22, y + 6, 5, 4, BROWN)
    var h = min(age, 6)
    if h > 0 rect_fill(x + 24, y + 6 - h, 1, h, GREEN) end
    if h >= 3
      pixel(x + 23, y + 4, GREEN)
      pixel(x + 25, y + 3, GREEN)
    end
    if h >= 6
      pixel(x + 24, y - 1, PINK)
      pixel(x + 23, y, PINK)
      pixel(x + 25, y, PINK)
    end
    if age < 6
      rect_fill(x + 17, y + 2, 3, 3, BLUE)
      var d = (t / 120) % 4
      pixel(x + 21, y + 3 + d, BLUE)
    end
  end

  def draw_eat(x, y, t)
    var k = t - self.act_start
    if k < 1500
      self.bitmap(COOKIE, x + 7, k / 150 - 4, AMBER)
    elif k < 4500
      var bite = (k / 300) % 2
      self.bitmap(COOKIE, x + 7, y - 4, bite == 0 ? AMBER : 0x8A6030)
      pixel(x + 5 + (k / 200) % 8, y + 9, 0x8A6030)
    else
      self.bitmap(HEART, x + 6, 0, PINK)
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
      if self.offscreen() || self.x < 0 || self.x > width() - 18
        self.x = 17
        self.target = 17
      end
      self.sprite(self.x, y, 0x6A3A2C, t, true, false)
      var drift = (t / 600) % 4
      self.bitmap(ZED, self.x + 17, 3 - drift / 2, 0x3050A0)
      if drift >= 2 self.bitmap(ZED, self.x + 20, 0, 0x203070) end
      return
    end
    var kind = self.wx_kind()
    self.weather_back(kind, t)
    var x = self.x
    var act = self.news == nil ? self.act : nil
    if act == nil && self.news == nil && self.mood == "working" act = "laptop" end
    if (kind == "cold" || kind == "snow") && !self.moving && act == nil x += (t / 90) % 2 end
    var eyes_closed = false
    var wave = self.news == nil && act == nil && self.mood == "waiting"
    if act == "music" || act == "dance" y = 6 - ((t / 250) % 2)
    elif act == "exercise" y = 6 - ((t / 300) % 2) * 2
    elif act == "ball" && self.moving y = 6 - ((t / 200) % 2)
    elif act == "eat" eyes_closed = (t - self.act_start) > 1500 && (t - self.act_start) < 4500 && (t / 300) % 2 == 0
    elif act == "hello" wave = true
    elif act == nil && self.news == nil && self.mood == "done"
      var jump = (t / 120) % 12
      y = jump < 3 ? 6 - jump : (jump < 6 ? jump + 1 : 6)
      self.bitmap(HEART, x + 6, 0, PINK)
    end
    if act == "dance" x += ((t / 250) % 2) * 2 - 1 end
    self.sprite(x, y, c, t, eyes_closed, wave)
    if act == "exercise" self.arms_up(x, y, c, (t / 300) % 2 == 0, (t / 300) % 2 == 0)
    elif act == "dance" self.arms_up(x, y, c, (t / 250) % 2 == 0, (t / 250) % 2 == 1)
    end
    if self.news == nil || kind != "rain"
      if !(act == "music" && kind == "rain") self.weather_front(kind, x, y, t) end
    end
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
    if act == "laptop" self.draw_laptop(x, y, t)
    elif act == "coffee" self.draw_coffee(x, y, t)
    elif act == "book" self.draw_book(x, y, t)
    elif act == "music" self.draw_music(x, y, t)
    elif act == "plant" self.draw_plant(x, y, t)
    elif act == "eat" self.draw_eat(x, y, t)
    elif act == "hello" text(x + 19, 6, "hi!", 0xF2D7B6)
    elif act == "dance"
      for i : 0 .. 2
        if (t / 200 + i) % 3 == 0 pixel((t / 37 + i * 17) % width(), (t / 53 + i * 5) % 6, AMBER) end
      end
    elif act == "ball"
      if t - self.ball_t >= 70
        self.ball_t = t
        self.ball_x += self.ball_dx
        if self.ball_x <= 0 || self.ball_x >= width() - 3 self.ball_dx = -self.ball_dx end
      end
      var by = 12 - BOUNCE[(t / 90) % 5]
      rect_fill(self.ball_x, by, 3, 3, AMBER)
      pixel(self.ball_x + 1, by + 1, CREAM)
    end
    if self.mood == "waiting" && act == nil && (t / 500) % 2 == 0
      rect_fill(x + 19, 6, 1, 5, AMBER)
      pixel(x + 19, 12, AMBER)
    end
    if act == nil && self.hungry() && (t / 4000) % 3 == 0
      pixel(x + 16, y - 1, CREAM)
      pixel(x + 18, y - 3, CREAM)
      rect(x + 19, 0, 7, 6, CREAM)
      self.bitmap(COOKIE, x + 20, 1, AMBER)
    end
    if t < self.hearts_until
      var rise = (self.hearts_until - t) / 500
      self.bitmap(HEART, x + 13, rise - 2, PINK)
      self.bitmap(HEART, x, rise - 4, 0xE89A90)
    end
    if mail > 0 && act == nil
      self.envelope(self.x < 26 ? 44 : 1, 10, CREAM)
    end
    if soon
      var label = str(next) + "m"
      text(width() - text_width(label), 6, label, AMBER)
    end
  end
end

return Pet()
