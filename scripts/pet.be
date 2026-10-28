# @name    Pet
# @desc    A small Clawd-style pet: visits now and then, does things, follows Claude Code, dresses for the weather and brings the news
# @display 52x16
# @config  visit number "Visit every" default=15 min=0 max=240 unit=min help="0 = never. Only in the day"
# @config  pop   bool   "Show me when Claude waits" default=true
# @config  news  bool   "Bring mail, Slack, alerts and meetings" default=true
# @config  hungry number "Hungry after" default=6 min=1 max=48 unit=h
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
var GLANCE = [0, 0, -1, 0, 0, 1, 0, -1]
var EVENTS = ["trip", "banana", "sneeze", "yawn", "hiccup", "butterfly"]
var EV_FOR = {"wake": 7500, "trip": 3400, "banana": 4600, "sneeze": 2400, "yawn": 3000, "hiccup": 4500, "butterfly": 5600}
var STARS = [[-4, 0], [-2, -2], [2, -2], [4, 0], [2, 1], [-2, 1]]
var FLUTTER = [0, 1, 2, 1, 0, -1, -2, -1]
var MINI = [".#######.", ".#.###.#.", "#########", ".#######."]
var MINI_LEGS_A = [1, 3, 5, 7]
var MINI_LEGS_B = [2, 4, 6, 8]
var ACTS = ["laptop", "coffee", "book", "music", "exercise", "ball", "dance", "plant", "hello"]

class Pet
  var x, target, rest_until, last_step, moving, hearts_until, mood, popped
  var news, seen
  var act, act_start, act_until, ball_x, ball_dx, ball_t, last_visit, idle_since, eat_until, away_until
  var hide, hide_until, pending_hide, yoff, yoff_target, yoff_t, look, say, say_until, duck_until, jump_until, hang
  var ev, ev_start, ev_x, flip_now, land_until
  var depth, depth_start, depth_until, far_x, far_target, far_step

  def init()
    self.x = 17
    self.target = 17
    self.rest_until = 0
    self.last_step = 0
    self.moving = false
    self.hearts_until = 0
    self.mood = "idle"
    self.news = nil
    self.seen = {}
    self.act = nil
    self.act_start = 0
    self.act_until = 0
    self.ball_x = 0
    self.ball_dx = 1
    self.ball_t = 0
    self.last_visit = store.get("last_visit", int(epoch_ms() / 1000))
    self.idle_since = now_ms()
    self.eat_until = 0
    self.away_until = 0
    self.hide = nil
    self.hide_until = 0
    self.pending_hide = nil
    self.yoff = 0
    self.yoff_target = 0
    self.yoff_t = 0
    self.look = 0
    self.say = nil
    self.say_until = 0
    self.duck_until = 0
    self.jump_until = 0
    self.hang = 11
    self.ev = nil
    self.ev_start = 0
    self.ev_x = 0
    self.flip_now = false
    self.land_until = 0
    self.depth = nil
    self.depth_start = 0
    self.depth_until = 0
    self.far_x = 0
    self.far_target = 0
    self.far_step = 0
  end

  def start_depth(kind)
    self.depth = kind
    self.depth_start = now_ms()
    self.depth_until = now_ms() + (kind == "far" ? 10000 + math.rand() % 10000 : 5000 + math.rand() % 3000)
    self.far_x = min(max(self.x + 4, 0), width() - 9)
    self.far_target = self.far_x
  end

  def end_depth()
    if self.depth == "far" self.x = min(max(self.far_x - 4, 0), width() - 18) end
    self.target = self.x
    self.depth = nil
    self.rest_until = now_ms() + 1500
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
      if now_ms() < 90000 && !night && hour() >= 0
        self.x = 17
        self.target = 17
        self.start_ev("wake")
        rotation.show()
      end
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
    self.check_news(night)
    self.check_visit(night)
    if self.ev != nil && now_ms() - self.ev_start > EV_FOR[self.ev] self.end_ev() end
    if self.act != nil && now_ms() > self.act_until
      self.act = nil
      self.idle_since = now_ms()
      self.rest_until = now_ms() + 2000
    end
  end

  def check_visit(night)
    var every = store.get("visit", 20)
    var now = int(epoch_ms() / 1000)
    if night || every <= 0 || shared.get("Calm.eco", false) || self.news != nil || self.mood != "idle" || hour() < 0 return end
    if now - self.last_visit < every * 60 return end
    self.last_visit = now
    store.set("last_visit", now)
    self.start_act(self.pick_act())
    rotation.show()
  end

  def pick_act()
    var h = hour()
    if h >= 6 && h < 10 && math.rand() % 3 == 0 return "coffee" end
    if h >= 19 && math.rand() % 3 == 0 return "book" end
    return ACTS[math.rand() % size(ACTS)]
  end

  def start_ev(name)
    if name == "banana" && self.x > width() - 28 name = "sneeze" end
    self.ev = name
    self.ev_start = now_ms()
    self.ev_x = self.x + 24
    self.target = self.x
  end

  def end_ev()
    self.ev = nil
    self.flip_now = false
    self.rest_until = now_ms() + 1500
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

  def wx_kind()
    var code = shared.get("Sky.code")
    var temp = shared.get("Sky.temp")
    if code == nil || temp == nil return "" end
    if (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95 return "rain" end
    if (code >= 71 && code <= 77) || code == 85 || code == 86 return "snow" end
    if temp < 0 return "cold" end
    if temp >= 28 return "hot" end
    if code <= 1 && shared.get("Sky.day", 1) == 1 return "sun" end
    return ""
  end

  def check_news(night)
    for src : [["Gmail", "mail"], ["Slack", "slack"], ["Sky", "alert"]]
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

  def end_hide()
    if self.hide == "top"
      self.yoff = -16
      self.target = self.x
    end
    self.hide = nil
    self.pending_hide = nil
    self.yoff_target = 0
    self.duck_until = 0
  end

  def talk(words, ms)
    self.say = words
    self.say_until = now_ms() + ms
  end

  def seek(event)
    var t = now_ms()
    if event == "press"
      self.duck_until = t + 1500
      self.hide_until = max(self.hide_until, t + 4000)
      return
    end
    if event != "left" && event != "right" return end
    var hit = self.hide != "side" || (event == "left") == (self.x < 0)
    if hit
      store.set("found", store.get("found", 0) + 1)
      self.talk("found! " + str(store.get("found")), 2500)
      self.end_hide()
      self.target = min(max(self.x, 0), width() - 18)
      self.x = self.target
      self.hearts_until = t + 2500
      self.jump_until = t + 700
      self.rest_until = t + 5000
    else
      self.talk("hehe", 1500)
      self.hide_until = max(self.hide_until, t + 3000)
    end
  end

  def on_knob(event)
    if self.depth == "near" && event == "press"
      self.hearts_until = now_ms() + 3000
      self.depth_until = max(self.depth_until, now_ms() + 3000)
      return true
    end
    if self.depth != nil
      self.end_depth()
      return true
    end
    if self.hide != nil
      self.seek(event)
      return true
    end
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
    var called = self.mood != "idle" || self.act != nil || fast || self.news != nil
    if self.depth != nil
      if called || t >= self.depth_until
        self.end_depth()
      else
        if self.depth == "far"
          if self.far_x == self.far_target
            if t - self.far_step > 2500 self.far_target = math.rand() % (width() - 8) end
          elif t - self.far_step >= 420
            self.far_step = t
            self.far_x += self.far_target > self.far_x ? 1 : -1
          end
        end
        self.moving = false
        return
      end
    end
    if self.hide != nil
      if called || t >= self.hide_until
        var side = self.hide == "side"
        self.end_hide()
        if side self.target = min(max(self.x, 2), width() - 20) end
        self.rest_until = called ? 0 : t + 1500
      else
        self.moving = false
        return
      end
    end
    if self.ev != nil
      if called
        self.end_ev()
      else
        var k = t - self.ev_start
        var speed = 200
        if self.ev == "banana" && k < 1600
          self.target = self.ev_x - 15
        elif self.ev == "butterfly"
          self.target = min(max(k / 80 - 6 - 12, 0), width() - 18)
          speed = 90
        else
          self.target = self.x
        end
        if self.x != self.target && t - self.last_step >= speed
          self.last_step = t
          self.x += self.target > self.x ? 1 : -1
        end
        self.moving = self.x != self.target
        return
      end
    end
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
        var how = math.rand() % 4
        if how == 3
          self.x = math.rand() % (width() - 17)
          self.target = self.x
          self.yoff = -16
          self.yoff_target = 0
          self.rest_until = t + 2000
          return
        end
        if how == 2 && self.mood == "idle"
          self.x = math.rand() % (width() - 17)
          self.target = self.x
          self.hide = "top"
          self.hang = 11
          self.hide_until = t + 6000 + math.rand() % 10000
          return
        end
        if how == 0
          self.target = left ? -9 : width() - 9
          self.pending_hide = "side"
        else
          self.target = math.rand() % (width() - 17)
        end
        self.rest_until = t + 2500
      end
      return
    end
    if self.x == self.target
      if self.news == nil && self.act == nil && self.pending_hide != nil
        self.hide = self.pending_hide
        self.pending_hide = nil
        self.hide_until = t + 6000 + math.rand() % 10000
        self.moving = false
        return
      end
      if self.news == nil && self.act == nil && self.mood == "idle" && self.x >= 0 && self.x <= width() - 18 && math.rand() % 5 == 0
        self.start_ev(EVENTS[math.rand() % size(EVENTS)])
        self.moving = false
        return
      end
      if self.news == nil && self.act == nil
        var pick = math.rand() % 9
        if pick == 0
          self.target = math.rand() % 2 == 0 ? -18 : width()
        elif pick == 1
          self.target = math.rand() % 2 == 0 ? -9 : width() - 9
          self.pending_hide = "side"
        elif pick == 3 && self.mood == "idle"
          self.start_depth("far")
          self.moving = false
          return
        elif pick == 4 && self.mood == "idle"
          self.start_depth("near")
          self.moving = false
          return
        elif pick == 2 && self.mood == "idle"
          self.hide = "under"
          self.yoff_target = 6
          self.hide_until = t + 6000 + math.rand() % 10000
          self.moving = false
          return
        else
          self.target = math.rand() % (width() - 17)
        end
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
      if !fast && self.mood == "idle" && self.act == nil && self.x >= 0 && self.x <= width() - 18 && math.rand() % 300 == 0
        self.start_ev("trip")
      end
    end
    self.moving = true
  end

  def tint(c, k)
    var r = min(((c >> 16) & 255) * k / 100, 255)
    var g = min(((c >> 8) & 255) * k / 100, 255)
    var b = min((c & 255) * k / 100, 255)
    return (r << 16) | (g << 8) | b
  end

  def run(x, y, a, b, r, c, flip)
    if b < a return end
    rect_fill(flip ? x + 17 - b : x + a, flip ? y + 9 - r : y + r, b - a + 1, 1, c)
  end

  def sprite(x, y, c, t, eyes_closed, wave)
    var flip = self.hide == "top" || self.flip_now
    var blink = (t % 4200) < 150
    var lc = self.tint(c, 122)
    var sc = self.tint(c, 76)
    var dc = self.tint(c, 56)
    var r = 0
    for spans : BODY
      for s : spans
        var a = s[0]
        var b = s[1]
        if wave && !flip && (r == 4 || r == 5) b = min(b, 14) end
        self.run(x, y, a, b, r, c, flip)
      end
      r += 1
    end
    self.run(x, y, 3, 12, 0, lc, flip)
    for rr : 1 .. 3 self.run(x, y, 3, 3, rr, lc, flip) end
    self.run(x, y, 3, 14, 7, sc, flip)
    for rr : 0 .. 3 self.run(x, y, 13, 14, rr, sc, flip) end
    self.run(x, y, 13, 14, 6, sc, flip)
    self.run(x, y, 1, 2, 5, sc, flip)
    if !(wave && !flip) self.run(x, y, 15, 16, 5, sc, flip) end
    for rr : 2 .. 3
      var ry = flip ? y + 9 - rr : y + rr
      if !blink && (!eyes_closed || rr == 3)
        var e1 = 5 + self.look
        var e2 = 12 + self.look
        pixel(flip ? x + 17 - e1 : x + e1, ry, 0)
        pixel(flip ? x + 17 - e2 : x + e2, ry, 0)
      end
    end
    if wave && !flip
      var up = (t / 400) % 2 == 0 ? 0 : 1
      rect_fill(x + 15, y + 2 + up, 1, 2, lc)
      rect_fill(x + 16, y + 2 + up, 1, 2, c)
    end
    var legs = self.moving && (t / 260) % 2 == 1 ? LEGS_B : LEGS_A
    for lx : legs
      var lx2 = flip ? x + 17 - lx : x + lx
      pixel(lx2, flip ? y + 1 : y + 8, sc)
      pixel(lx2, flip ? y : y + 9, dc)
    end
  end

  def draw_depth(c, t)
    var k = t - self.depth_start
    var left = self.depth_until - t
    if self.depth == "far"
      if k < 450 || left < 450
        var p = k < 450 ? k : left
        self.sprite(self.x, 6 - p / 110, c, t, false, false)
        return
      end
      var y = 5
      var moving = self.far_x != self.far_target
      var blink = (t % 4200) < 150
      var dim = ((c >> 1) & 0x7F7F7F)
      var r = 0
      for row : MINI
        for i : 0 .. 8
          if row[i] == "#" pixel(self.far_x + i, y + r, dim) end
        end
        r += 1
      end
      if blink
        pixel(self.far_x + 2, y + 1, dim)
        pixel(self.far_x + 6, y + 1, dim)
      end
      for lx : (moving && (t / 420) % 2 == 1 ? MINI_LEGS_B : MINI_LEGS_A)
        pixel(self.far_x + lx, y + 4, dim)
      end
      return
    end
    var rise = k < 600 ? k / 50 : (left < 600 ? (600 - left) / 50 : 0)
    var x = (width() - 36) / 2
    var y = 2 + (k < 600 ? 12 - rise : rise)
    var r = 0
    for spans : BODY
      if r == 2 || r == 3
        rect_fill(x + 6, y + r * 2, 24, 2, c)
        if (t % 4200) >= 150
          var look = GLANCE[(t / 900) % size(GLANCE)] * 2
          rect_fill(x + 10 + look, y + r * 2, 2, 2, 0)
          rect_fill(x + 24 + look, y + r * 2, 2, 2, 0)
        end
      else
        for sp : spans
          rect_fill(x + sp[0] * 2, y + r * 2, (sp[1] - sp[0] + 1) * 2, 2, c)
        end
      end
      r += 1
    end
    if t < self.hearts_until
      var up = (self.hearts_until - t) / 400
      self.bitmap(HEART, x - 2, up - 3, PINK)
      self.bitmap(HEART, x + 33, up - 5, 0xE89A90)
    end
  end

  def pancake(x, c, t)
    rect_fill(x + 3, 12, 12, 1, c)
    rect_fill(x + 1, 13, 16, 2, c)
    var d = (t / 200) % 2
    pixel(x + 6, 13 + d, 0)
    pixel(x + 11, 14 - d, 0)
    pixel(x, 15, c)
    pixel(x + 17, 15, c)
    pixel(x + 5, 15, c)
    pixel(x + 12, 15, c)
  end

  def stars(cx, cy, t)
    for i : 0 .. 2
      var p = STARS[(t / 120 + i * 2) % size(STARS)]
      pixel(cx + p[0], cy + p[1], AMBER)
    end
  end

  def draw_event(x, y, c, t)
    var k = t - self.ev_start
    var e = self.ev
    if e == "wake"
      if k < 2000
        self.sprite(x, y, c, t, true, false)
        var drift = (t / 600) % 4
        self.bitmap(ZED, x + 17, 3 - drift / 2, 0x3050A0)
      elif k < 3600
        self.sprite(x, y - (k < 2600 ? 0 : 1), c, t, true, false)
        self.arms_up(x, y - (k < 2600 ? 0 : 1), c, true, true)
        rect_fill(x + 8, y + 5, 2, 2, 0)
      elif k < 4600
        self.look = GLANCE[(k / 250) % size(GLANCE)]
        self.sprite(x, y, c, t, k > 3900 && k < 4050, false)
      else
        self.sprite(x, y, c, t, false, true)
        var h = hour()
        var hello = h < 12 ? "morning!" : (h < 18 ? "hi!" : "evening!")
        text(min(x + 19, width() - text_width(hello)), 6, hello, 0xF2D7B6)
      end
    elif e == "trip"
      if k < 400
        self.sprite(x + 1, y + 1, c, t, false, false)
      elif k < 2600
        self.pancake(x, c, t)
        self.stars(x + 9, 9, t)
      else
        self.sprite(x, y - ((k / 200) % 2), c, t, false, false)
      end
    elif e == "banana"
      if k < 1600
        rect_fill(self.ev_x, 14, 1, 1, 0xE8C840)
        rect_fill(self.ev_x + 1, 15, 2, 1, 0xE8C840)
        pixel(self.ev_x + 3, 14, 0xE8C840)
        self.sprite(x, y, c, t, false, false)
      elif k < 3800
        self.flip_now = true
        self.moving = (t / 200) % 2 == 0
        self.sprite(x, k < 2000 ? y - 3 : y, c, t, false, false)
        self.flip_now = false
        if k < 2600 pixel(self.ev_x + (k - 1600) / 40, 12 - (k - 1600) / 60, 0xE8C840) end
        if k >= 2000 self.stars(x + 9, 3, t) end
      else
        self.sprite(x, y - ((k / 200) % 2), c, t, false, false)
      end
    elif e == "sneeze"
      if k < 1400
        self.sprite(x, k > 700 ? y - 1 : y, c, t, k > 700, false)
      else
        self.sprite(x - 2, y, c, t, true, false)
        for i : 0 .. 4
          pixel(x + 17 + (k - 1400) / 50 + i * 2, y + 2 + (i % 3) - 1, 0x9A948C)
        end
        text(min(x + 17, width() - text_width("achoo")), 6, "achoo", 0xF2D7B6)
      end
    elif e == "yawn"
      self.sprite(x, y, c, t, true, false)
      self.arms_up(x, y, c, true, true)
      rect_fill(x + 8, y + 5, 2, 2, 0)
    elif e == "hiccup"
      var hic = k % 900 < 160
      self.sprite(x, hic ? y - 2 : y, c, t, false, false)
      if k % 900 < 500 text(min(x + 17, width() - text_width("hic")), 6, "hic", 0xF2D7B6) end
    elif e == "butterfly"
      var bx = k / 80 - 6
      var by = 3 + FLUTTER[(k / 120) % size(FLUTTER)]
      var near = (x + 9 - bx) < 4 && (bx - x - 9) < 4
      self.sprite(x, near && (k / 250) % 2 == 0 ? y - 2 : y, c, t, false, false)
      var up = (k / 150) % 2
      pixel(bx, by, DARK)
      pixel(bx - 1, by - up, PINK)
      pixel(bx + 1, by - up, PINK)
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
      if self.hide != nil self.end_hide() end
      self.yoff = 0
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
    if self.depth != nil
      self.draw_depth(c, t)
      return
    end
    var x = self.x
    if self.hide == "top"
      var want = t < self.duck_until ? 11 : 4
      if self.hang != want && t - self.yoff_t >= 70
        self.yoff_t = t
        self.hang += want > self.hang ? 1 : -1
      end
      self.look = GLANCE[(t / 700) % size(GLANCE)]
      self.sprite(x, -self.hang, store.get("color", 0xD77757), t, false, false)
      if self.say != nil && t < self.say_until text(min(max(x, 0), width() - text_width(self.say)), 14, self.say, 0xF2D7B6) end
      return
    end
    var goal = t < self.duck_until ? 11 : self.yoff_target
    if self.yoff != goal && t - self.yoff_t >= (self.yoff < 0 ? 35 : 70)
      self.yoff_t = t
      var falling = self.yoff < 0
      self.yoff += goal > self.yoff ? 1 : -1
      if falling && self.yoff == 0 self.land_until = t + 400 end
    end
    if self.moving
      self.look = self.target > self.x ? 1 : -1
    elif self.hide == "side"
      self.look = self.x < 0 ? 1 : -1
    elif self.act == "ball"
      self.look = self.ball_x > self.x + 8 ? 1 : -1
    else
      self.look = GLANCE[(t / (self.hide == "under" ? 700 : 1300)) % size(GLANCE)]
    end
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
    y += self.yoff
    if t < self.jump_until y -= 2 end
    if self.say != nil
      if t < self.say_until
        text(min(max(x, 0), width() - text_width(self.say)), 6, self.say, 0xF2D7B6)
      else
        self.say = nil
      end
    end
    if self.ev != nil && self.news == nil
      self.draw_event(x, y, c, t)
      return
    end
    if t < self.land_until
      y += 1
      pixel(x - 1, 15, 0x6E6A64)
      pixel(x - 2, 14, 0x6E6A64)
      pixel(x + 18, 15, 0x6E6A64)
      pixel(x + 19, 14, 0x6E6A64)
    end
    self.sprite(x, y, c, t, eyes_closed, wave)
    if act == "exercise" self.arms_up(x, y, c, (t / 300) % 2 == 0, (t / 300) % 2 == 0)
    elif act == "dance" self.arms_up(x, y, c, (t / 250) % 2 == 0, (t / 250) % 2 == 1)
    end
    if (self.news == nil || kind != "rain") && self.yoff < 3
      if !(act == "music" && kind == "rain") self.weather_front(kind, x, y, t) end
    end
    if self.news != nil
      if self.news["kind"] == "mail"
        self.envelope(x + 17, y + 3, CREAM)
      elif self.news["kind"] == "slack"
        self.bubble(x + 17, y + 2, CREAM)
      elif self.news["kind"] == "alert"
        var ac = shared.get("Sky.alert_color", AMBER)
        line(x + 21, y + 1, x + 17, y + 7, ac)
        line(x + 21, y + 1, x + 25, y + 7, ac)
        line(x + 17, y + 7, x + 25, y + 7, ac)
        pixel(x + 21, y + 3, ac)
        pixel(x + 21, y + 4, ac)
        pixel(x + 21, y + 6, ac)
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
    if act == nil && self.hide == nil && self.say == nil && self.hungry() && (t / 4000) % 3 == 0
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
