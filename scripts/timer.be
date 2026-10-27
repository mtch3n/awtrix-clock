# @name    Timer
# @desc    Countdown. Turn the knob to set it, push to start or pause, hold to reset. Rings at zero until you push
# @display 52x16
# @config  start  number "Start value" default=5 min=1 max=180 unit=min
# @config  step   number "Knob step" default=1 min=1 max=30 unit=min
# @config  tune   select "Ring tune" default=bells options=bells,chime,pips
# @config  ring   number "Ring for" default=60 min=5 max=600 unit=s
# @config  color  color  "Digits" default=#F2D7B6
# @config  run    color  "Running" default=#C8643C
import blockfont

var TUNES = {"bells": "bells:d=8,o=6,b=140:e,g,e,c,4p,e,g,e,c",
             "chime": "chime:d=4,o=5,b=100:e6,c6,d6,g,2p,g,d6,e6,c6",
             "pips": "pips:d=16,o=6,b=200:c,p,c,p,c,p,c"}

class Timer
  var set_s, end_ms, left_ms, ringing, ring_until, last_tone

  def init()
    self.set_s = store.get("start", 5) * 60
    self.end_ms = 0
    self.left_ms = 0
    self.ringing = false
    self.ring_until = 0
    self.last_tone = 0
  end

  def running()
    return self.end_ms > 0
  end

  def remaining()
    if self.running() return max(self.end_ms - now_ms(), 0) end
    if self.left_ms > 0 return self.left_ms end
    return self.set_s * 1000
  end

  def loop()
    if self.running() && now_ms() >= self.end_ms
      self.end_ms = 0
      self.left_ms = 0
      self.ringing = true
      self.ring_until = now_ms() + store.get("ring", 60) * 1000
      notify({"name": "timer", "text": "Time is up", "textColor": "#E0A040", "durationMs": 6000, "wakeup": true})
      rotation.show()
      rotation.pause()
    end
    if self.ringing
      if now_ms() > self.ring_until
        self.stop_ring()
      elif now_ms() - self.last_tone > 3500
        self.last_tone = now_ms()
        sound.play({'rtttl': TUNES.find(store.get("tune", "bells"), TUNES["bells"])})
      end
    end
  end

  def stop_ring()
    self.ringing = false
    sound.stop()
    rotation.resume()
  end

  def on_knob(event)
    if self.ringing
      self.stop_ring()
      return true
    end
    var step = store.get("step", 1) * 60
    if event == "right" || event == "left"
      if self.running() return true end
      var base = self.left_ms > 0 ? (self.left_ms + 999) / 1000 : self.set_s
      base += event == "right" ? step : -step
      self.set_s = min(max(base, 60), 180 * 60)
      self.left_ms = 0
    elif event == "press"
      self.toggle()
    elif event == "long"
      self.end_ms = 0
      self.left_ms = 0
      self.set_s = store.get("start", 5) * 60
    end
    return true
  end

  def on_button(btn)
    if btn != "select" return false end
    if self.ringing
      self.stop_ring()
    else
      self.toggle()
    end
    return true
  end

  def toggle()
    if self.running()
      self.left_ms = self.remaining()
      self.end_ms = 0
      rotation.resume()
    else
      self.end_ms = now_ms() + self.remaining()
      self.left_ms = 0
    end
  end

  def draw()
    clear()
    var t = now_ms()
    var ms = self.remaining()
    var secs = (ms + 999) / 1000
    var label = secs >= 3600 ? format("%d:%02d", secs / 3600, secs % 3600 / 60) : format("%02d:%02d", secs / 60, secs % 60)
    var c = self.running() ? store.get("run", 0xC8643C) : store.get("color", 0xF2D7B6)
    if self.ringing
      c = (t / 300) % 2 == 0 ? 0xE0A040 : 0x3A2E26
      label = "00:00"
    end
    var w = blockfont.width(label)
    var x = (width() - w) / 2
    var paused = !self.running() && self.left_ms > 0
    blockfont.text(label, x, 1, c, 2, !paused || (t / 500) % 2 == 0)
    if self.running()
      var total = self.set_s * 1000
      rect_fill(x, 15, max(total - ms, 0) * w / max(total, 1), 1, 0x3A2E26)
    elif !paused && !self.ringing
      rect_fill(x, 15, w, 1, 0x3A2E26)
    end
  end
end

return Timer()
