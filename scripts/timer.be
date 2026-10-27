# @name    Timer
# @desc    Countdown, Pomodoro and stopwatch. Push to start or pause, turn to set, hold to reset, hold again to change the mode
# @display 52x16
# @config  mode   select "Start mode" default=countdown options=countdown,pomodoro,stopwatch
# @config  start  number "Countdown" default=5 min=1 max=180 unit=min group="Countdown"
# @config  step   number "Knob step" default=1 min=1 max=30 unit=min group="Countdown"
# @config  work   number "Focus" default=25 min=5 max=90 unit=min group="Pomodoro"
# @config  short  number "Short break" default=5 min=1 max=30 unit=min group="Pomodoro"
# @config  long   number "Long break" default=15 min=5 max=60 unit=min group="Pomodoro"
# @config  rounds number "Rounds before a long break" default=4 min=2 max=8 group="Pomodoro"
# @config  auto   bool   "Start the next phase by itself" default=false group="Pomodoro"
# @config  tune   select "Ring tune" default=bells options=bells,chime,pips group="Sound"
# @config  ring   number "Ring for" default=60 min=5 max=600 unit=s group="Sound"
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

class Timer
  var mode, set_s, end_ms, left_ms, started_ms, elapsed_ms, ringing, ring_until, last_tone, phase, round

  def init()
    self.mode = store.get("mode", "countdown")
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
    self.set_s = self.mode == "pomodoro" ? store.get("work", 25) * 60 : store.get("start", 5) * 60
  end

  def is_reset()
    return !self.running() && self.left_ms == 0 && self.elapsed_ms == 0 && self.phase == "work" && self.round == 1
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
    if event == "press"
      self.toggle()
    elif event == "long"
      if self.is_reset()
        self.mode = MODES[(MODES.find(self.mode) + 1) % size(MODES)]
        store.set("mode", self.mode)
      end
      self.reset()
    elif (event == "left" || event == "right") && !self.running() && self.mode != "stopwatch"
      var step = self.mode == "pomodoro" ? 60 : store.get("step", 1) * 60
      var base = self.left_ms > 0 ? (self.left_ms + 999) / 1000 : self.set_s
      self.set_s = min(max(base + (event == "right" ? step : -step), 60), 180 * 60)
      self.left_ms = 0
    end
    return true
  end

  def on_button(btn)
    if btn != "select" return false end
    if self.ringing self.stop_ring() else self.toggle() end
    return true
  end

  def hourglass(x, y, c)
    rect_fill(x, y, 9, 1, c)
    rect_fill(x, y + 10, 9, 1, c)
    line(x + 1, y + 1, x + 4, y + 5, c)
    line(x + 7, y + 1, x + 4, y + 5, c)
    line(x + 4, y + 5, x + 1, y + 9, c)
    line(x + 4, y + 5, x + 7, y + 9, c)
  end

  def tomato(x, y)
    circle_fill(x + 4, y + 6, 4, RED)
    pixel(x + 4, y + 1, GREEN)
    rect_fill(x + 2, y + 2, 5, 1, GREEN)
  end

  def cup(x, y)
    rect_fill(x, y + 4, 7, 6, CREAM)
    rect(x + 7, y + 5, 2, 3, CREAM)
    pixel(x + 2, y + 1, BROWN)
    pixel(x + 4, y + 2, BROWN)
  end

  def stopwatch(x, y, c)
    circle(x + 4, y + 6, 4, c)
    rect_fill(x + 3, y, 3, 1, c)
    pixel(x + 4, y + 1, c)
    line(x + 4, y + 6, x + 4, y + 3, AMBER)
  end

  def draw()
    clear()
    var t = now_ms()
    var label
    var progress = -1
    if self.mode == "stopwatch"
      var s = self.elapsed() / 1000
      label = s >= 6000 ? format("%d:%02d", s / 3600, s % 3600 / 60) : format("%02d:%02d", s / 60, s % 60)
      self.stopwatch(5, 2, CREAM)
    else
      var secs = (self.remaining() + 999) / 1000
      label = secs >= 6000 ? format("%d:%02d", secs / 3600, secs % 3600 / 60) : format("%02d:%02d", secs / 60, secs % 60)
      if self.running() || self.left_ms > 0 progress = (self.set_s * 1000 - self.remaining()) * 100 / max(self.set_s * 1000, 1) end
      if self.mode == "pomodoro"
        if self.phase == "work" self.tomato(5, 1) else self.cup(5, 1) end
        var n = store.get("rounds", 4)
        for i : 1 .. n
          pixel(10 - n + i * 2, 14, i < self.round || (i == self.round && self.phase != "work") ? AMBER : DARK)
        end
      else
        self.hourglass(5, 2, CREAM)
      end
    end
    var c = self.running() ? store.get("run", 0xC8643C) : store.get("color", 0xF2D7B6)
    if self.ringing
      c = (t / 300) % 2 == 0 ? AMBER : DARK
      label = "00:00"
    end
    var w = blockfont.width(label)
    var x = width() - w - 1
    var paused = !self.running() && (self.left_ms > 0 || self.elapsed_ms > 0)
    blockfont.text(label, x, 1, c, 2, !paused || (t / 500) % 2 == 0)
    if progress >= 0 rect_fill(x, 15, progress * w / 100, 1, BROWN) end
  end
end

return Timer()
