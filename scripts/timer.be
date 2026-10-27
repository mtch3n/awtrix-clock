# @name    Timer
# @desc    Countdown, Pomodoro and stopwatch. Stopped: push moves the selection (mode, minutes, seconds), turn changes it. Select starts and pauses, hold resets
# @display 52x16
# @config  mode   select "First mode" default=countdown options=countdown,pomodoro,stopwatch
# @config  start  number "Countdown" default=5 min=1 max=180 unit=min group="Countdown"
# @config  step   number "Knob step" default=1 min=1 max=30 unit=min group="Countdown"
# @config  work   number "Focus" default=25 min=5 max=90 unit=min group="Pomodoro"
# @config  short  number "Short break" default=5 min=1 max=30 unit=min group="Pomodoro"
# @config  long   number "Long break" default=15 min=5 max=60 unit=min group="Pomodoro"
# @config  rounds number "Rounds before a long break" default=4 min=2 max=8 group="Pomodoro"
# @config  auto   bool   "Start the next phase by itself" default=false group="Pomodoro"
# @config  tune   select "Ring tune" default=bells options=bells,chime,pips group="Sound"
# @config  ring   number "Ring for" default=60 min=5 max=600 unit=s group="Sound"
# @config  style  select "Digit style" default=compact options=compact,airy,bold,thin group="Digits"
# @config  size   select "Digit size" default=medium options=large,medium,small help="large 6x14, medium 5x12, small 5x10" group="Digits"
# @config  spacing select "Spacing" default=airy options=airy,tight group="Digits"
# @config  color  color  "Digits" default=#F2D7B6 group="Colors"
# @config  run    color  "Running" default=#C8643C group="Colors"
import blockfont

var MODES = ["countdown", "pomodoro", "stopwatch"]
var TUNES = {"bells": "bells:d=8,o=6,b=140:e,g,e,c,4p,e,g,e,c",
             "chime": "chime:d=4,o=5,b=100:e6,c6,d6,g,2p,g,d6,e6,c6",
             "pips": "pips:d=16,o=6,b=200:c,p,c,p,c,p,c"}
var RED = 0xD0503C
var GREEN = 0x6FAF6A
var CREAM = 0xE8DCCB
var BROWN = 0x8C7B6B
var DARK = 0x3A2E26
var AMBER = 0xE0A040
var HAND = [[0, -3], [2, -2], [3, 0], [2, 2], [0, 3], [-2, 2], [-3, 0], [-2, -2]]

class Timer
  var mode, set_s, end_ms, left_ms, started_ms, elapsed_ms, ringing, ring_until, last_tone, phase, round, field

  def init()
    self.mode = store.get("last_mode", store.get("mode", "countdown"))
    self.ringing = false
    self.ring_until = 0
    self.last_tone = 0
    self.reset()
  end

  def reset()
    self.end_ms = 0
    self.left_ms = 0
    self.started_ms = 0
    self.elapsed_ms = 0
    self.phase = "work"
    self.round = 1
    self.field = self.mode == "countdown" ? "min" : "mode"
    self.set_s = self.mode == "pomodoro" ? store.get("work", 25) * 60 : store.get("start", 5) * 60
  end

  def running()
    return self.end_ms > 0 || self.started_ms > 0
  end

  def remaining()
    if self.end_ms > 0 return max(self.end_ms - now_ms(), 0) end
    if self.left_ms > 0 return self.left_ms end
    return self.set_s * 1000
  end

  def elapsed()
    return self.elapsed_ms + (self.started_ms > 0 ? now_ms() - self.started_ms : 0)
  end

  def phase_len()
    if self.phase == "work" return store.get("work", 25) * 60 end
    if self.phase == "long" return store.get("long", 15) * 60 end
    return store.get("short", 5) * 60
  end

  def loop()
    if self.end_ms > 0 && now_ms() >= self.end_ms self.finish() end
    if self.ringing
      if now_ms() > self.ring_until
        self.stop_ring()
      elif now_ms() - self.last_tone > 3500
        self.last_tone = now_ms()
        sound.play({'rtttl': TUNES.find(store.get("tune", "bells"), TUNES["bells"])})
      end
    end
  end

  def finish()
    self.end_ms = 0
    self.left_ms = 0
    if self.mode == "pomodoro"
      var was = self.phase
      if was == "work"
        self.phase = self.round >= store.get("rounds", 4) ? "long" : "short"
      else
        self.phase = "work"
        self.round = was == "long" ? 1 : self.round + 1
      end
      self.set_s = self.phase_len()
      notify({"name": "timer", "text": self.phase == "work" ? "Back to focus" : "Time for a break", "textColor": "#E0A040", "durationMs": 5000, "wakeup": true})
      if store.get("auto", false)
        sound.play({'rtttl': TUNES["chime"]})
        self.end_ms = now_ms() + self.set_s * 1000
        rotation.show()
        return
      end
    else
      notify({"name": "timer", "text": "Time is up", "textColor": "#E0A040", "durationMs": 6000, "wakeup": true})
    end
    self.ringing = true
    self.ring_until = now_ms() + store.get("ring", 60) * 1000
    rotation.show()
    rotation.pause()
  end

  def stop_ring()
    self.ringing = false
    sound.stop()
    rotation.resume()
  end

  def toggle()
    if self.mode == "stopwatch"
      if self.started_ms > 0
        self.elapsed_ms = self.elapsed()
        self.started_ms = 0
      else
        self.started_ms = now_ms()
      end
      return
    end
    if self.end_ms > 0
      self.left_ms = self.remaining()
      self.end_ms = 0
    else
      self.end_ms = now_ms() + self.remaining()
      self.left_ms = 0
    end
  end

  def on_knob(event)
    if self.ringing
      self.stop_ring()
      return true
    end
    var editing = !self.running() && self.left_ms == 0 && self.elapsed_ms == 0
    var fields = self.mode == "countdown" ? ["mode", "min", "sec"] : (self.mode == "pomodoro" ? ["mode", "min", "brk", "long"] : ["mode"])
    if event == "press" && editing
      self.field = fields[((fields.find(self.field) == nil ? 0 : fields.find(self.field)) + 1) % size(fields)]
    elif event == "press"
      self.toggle()
    elif (event == "left" || event == "right") && editing && self.field == "mode"
      var i = MODES.find(self.mode)
      self.mode = MODES[(i + (event == "right" ? 1 : 2)) % 3]
      store.set("last_mode", self.mode)
      self.reset()
      self.field = "mode"
    elif event == "long"
      self.reset()
      self.field = "mode"
    elif (event == "left" || event == "right") && editing && self.mode == "pomodoro" && (self.field == "brk" || self.field == "long")
      var key = self.field == "brk" ? "short" : "long"
      var v = store.get(key, self.field == "brk" ? 5 : 15) + (event == "right" ? 1 : -1)
      store.set(key, min(max(v, 1), 60))
    elif (event == "left" || event == "right") && editing && self.mode == "pomodoro" && self.field == "min"
      var v = store.get("work", 25) + (event == "right" ? 1 : -1)
      store.set("work", min(max(v, 5), 90))
      self.set_s = store.get("work") * 60
    elif (event == "left" || event == "right") && editing && self.field == "sec" && self.mode == "countdown"
      var m = self.set_s / 60
      var sec = (self.set_s % 60 + (event == "right" ? 1 : 59)) % 60
      self.set_s = max(m * 60 + sec, 5)
    elif (event == "left" || event == "right") && !self.running() && self.mode != "stopwatch"
      var step = self.mode == "pomodoro" ? 60 : store.get("step", 1) * 60
      var base = self.left_ms > 0 ? (self.left_ms + 999) / 1000 : self.set_s
      self.set_s = min(max(base + (event == "right" ? step : -step), self.mode == "pomodoro" ? 60 : 5), 180 * 60)
      self.left_ms = 0
    end
    return true
  end

  def on_button(btn)
    if btn != "select" return false end
    if self.ringing self.stop_ring() else self.toggle() end
    return true
  end

  def hourglass(x, y, c, left, t, running)
    rect_fill(x, y, 9, 1, c)
    rect_fill(x, y + 10, 9, 1, c)
    line(x + 1, y + 1, x + 4, y + 5, c)
    line(x + 7, y + 1, x + 4, y + 5, c)
    line(x + 4, y + 5, x + 1, y + 9, c)
    line(x + 4, y + 5, x + 7, y + 9, c)
    var done = 100 - left
    if left > 0 pixel(x + 4, y + 3, AMBER) end
    if left > 33 rect_fill(x + 3, y + 2, 3, 1, AMBER) end
    if left > 66 rect_fill(x + 2, y + 1, 5, 1, AMBER) end
    if done > 5 rect_fill(x + 2, y + 9, 5, 1, AMBER) end
    if done > 40 rect_fill(x + 3, y + 8, 3, 1, AMBER) end
    if done > 75 pixel(x + 4, y + 7, AMBER) end
    if running && left > 0 pixel(x + 4, y + 5 + (t / 150) % 3, AMBER) end
  end

  def tomato(x, y, t, running)
    circle_fill(x + 4, y + 6, 4, RED)
    var sway = running ? ((t / 500) % 2) : 0
    pixel(x + 4, y + 1, GREEN)
    rect_fill(x + 2 + sway, y + 2, 5 - sway, 1, GREEN)
    if running && sway == 1 pixel(x + 7, y + 1, GREEN) end
  end

  def cup(x, y, t, running)
    rect_fill(x, y + 4, 7, 6, CREAM)
    rect(x + 7, y + 5, 2, 3, CREAM)
    if running
      for i : 0 .. 1
        var k = (t / 250 + i * 2) % 4
        pixel(x + 2 + i * 2 + k % 2, y + 3 - k, BROWN)
      end
    else
      pixel(x + 2, y + 1, BROWN)
      pixel(x + 4, y + 2, BROWN)
    end
  end

  def stopwatch(x, y, c, ms)
    circle(x + 4, y + 6, 4, c)
    rect_fill(x + 3, y, 3, 1, c)
    pixel(x + 4, y + 1, c)
    var h = HAND[(ms / 7500) % size(HAND)]
    line(x + 4, y + 6, x + 4 + h[0], y + 6 + h[1], AMBER)
  end

  def draw()
    clear()
    var t = now_ms()
    var label
    var progress = -1
    if self.mode == "stopwatch"
      var s = self.elapsed() / 1000
      label = s >= 6000 ? format("%d:%02d", s / 3600, s % 3600 / 60) : format("%02d:%02d", s / 60, s % 60)
      self.stopwatch(3, 2, CREAM, self.elapsed())
    else
      var secs = (self.remaining() + 999) / 1000
      label = secs >= 6000 ? format("%d:%02d", secs / 3600, secs % 3600 / 60) : format("%02d:%02d", secs / 60, secs % 60)
      if self.running() || self.left_ms > 0 progress = (self.set_s * 1000 - self.remaining()) * 100 / max(self.set_s * 1000, 1) end
      if self.mode == "pomodoro"
        var edit_brk = !self.running() && self.left_ms == 0 && (self.field == "brk" || self.field == "long")
        if edit_brk
          secs = store.get(self.field == "brk" ? "short" : "long", 5) * 60
          label = format("%02d:00", secs / 60)
        end
        if self.phase == "work" && !edit_brk self.tomato(3, 1, t, self.running()) else self.cup(3, 1, t, self.running()) end
        var n = store.get("rounds", 4)
        for i : 1 .. n
          var lit = i < self.round || (i == self.round && self.phase != "work") || (edit_brk && self.field == "long")
          pixel(8 - n + i * 2, 14, lit ? AMBER : DARK)
        end
      else
        self.hourglass(3, 2, CREAM, self.remaining() * 100 / max(self.set_s * 1000, 1), t, self.running())
      end
    end
    var c = self.running() ? store.get("run", 0xC8643C) : store.get("color", 0xF2D7B6)
    if self.ringing
      c = (t / 300) % 2 == 0 ? AMBER : DARK
      label = "00:00"
    end
    var dsize = store.get("size", "medium")
    var dh = dsize == "large" ? 14 : (dsize == "small" ? 10 : 12)
    var st = blockfont.style(store.get("style", "compact"))
    var dw = st[0]
    var gap = store.get("spacing", "airy") == "airy" ? 2 : 1
    var w = blockfont.width(label, dw, gap)
    var x = width() - w - 2
    var paused = !self.running() && (self.left_ms > 0 || self.elapsed_ms > 0)
    blockfont.text(label, x, (16 - dh) / 2, c, st[1], st[2], !paused || (t / 500) % 2 == 0, dw, dh, gap)
    if progress >= 0 rect_fill(x, 15, progress * w / 100, 1, BROWN) end
    if !self.running() && self.left_ms == 0 && self.elapsed_ms == 0 && !self.ringing
      var on = (t / 400) % 3 == 0 ? DARK : 0xF2D7B6
      if self.field == "mode"
        rect_fill(2, 15, 11, 1, on)
      elif size(label) == 5 && self.mode != "stopwatch"
        rect_fill(self.field == "sec" ? x + 2 * dw + 3 * gap + 2 : x, 15, 2 * dw + gap, 1, on)
      end
    end
  end
end

return Timer()
