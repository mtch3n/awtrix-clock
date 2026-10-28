# @name    Calm
# @desc    Night mode, battery saving, return to the clock after a delay, and the corner indicators
# @headless true
# @config  back    number "Back to the clock after" default=60 min=0 max=3600 unit=s help="0 = never" group="Return"
# @config  home    text   "Clock app"     default="Time" group="Return"
# @config  keep    text   "Never leave"   default="Pomodoro-Timer,Timer" help="Apps that stay, separated by commas" group="Return"
# @config  quiet   bool   "Quiet time" default=true help="Display off and all apps paused" group="Quiet time"
# @config  qfrom   text   "Quiet from"    default="21:00" group="Quiet time"
# @config  qto     text   "Quiet until"   default="06:00" group="Quiet time"
# @config  qwake   number "Wake on a button for" default=3 min=1 max=30 unit=min help="A button push (LEFT or RIGHT) wakes the clock for this long" group="Quiet time"
# @config  night   bool   "Night mode"    default=true group="Night"
# @config  nfrom   text   "Night from"    default="22:30" group="Night"
# @config  nto     text   "Night until"   default="07:00" group="Night"
# @config  nmode   select "At night"      default=dim options=dim,off group="Night"
# @config  nbright number "Night brightness" default=8 min=1 max=255 group="Night"
# @config  bsave   bool   "Save battery when unplugged" default=true group="Battery"
# @config  bcap    number "Brightness on battery" default=40 min=1 max=255 group="Battery"
# @config  bwarn   number "Warn below" default=20 min=0 max=100 unit=% group="Battery"
# @config  boff    number "Display off below" default=10 min=0 max=100 unit=% group="Battery"
# @config  wover   bool   "Weather overlay on all apps" default=false help="Sets the display overlay from the weather (rain, snow, thunder...). Off: the overlay setting stays as you set it" group="Weather"
# @config  inds    bool   "Indicators"    default=true help="Mail, Slack and alerts (internet, Claude, weather) in the corners" group="Indicators"
# @config  user    text   "Web login user" default="admin" group="Web login"
# @config  pass    text   "Web login password" default="" help="Needed for the return and the indicators" group="Web login"
import json
import string

def trim(s)
  var a = 0
  var b = size(s) - 1
  while a <= b && s[a] == " " a += 1 end
  while b >= a && s[b] == " " b -= 1 end
  return a > b ? "" : s[a .. b]
end

def hhmm(s)
  var p = string.split(s, ":")
  if size(p) != 2 return -1 end
  return int(trim(p[0])) * 60 + int(trim(p[1]))
end

def b64(s)
  var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  var out = ""
  var i = 0
  var n = size(s)
  while i < n
    var b0 = string.byte(s[i])
    var b1 = i + 1 < n ? string.byte(s[i + 1]) : 0
    var b2 = i + 2 < n ? string.byte(s[i + 2]) : 0
    out += chars[b0 >> 2]
    out += chars[((b0 & 3) << 4) | (b1 >> 4)]
    out += i + 1 < n ? chars[((b1 & 15) << 2) | (b2 >> 6)] : "="
    out += i + 2 < n ? chars[b2 & 63] : "="
    i += 3
  end
  return out
end

class Calm
  var ticks, app, since, sent, auth, usb, pct, wake_until

  def init()
    self.ticks = 0
    self.app = ""
    self.since = now_ms()
    self.sent = {}
    self.auth = nil
    self.usb = true
    self.pct = 100
    self.wake_until = 0
  end

  def setup()
    var pass = store.get("pass", "")
    if pass != "" self.auth = "Basic " + b64(store.get("user", "admin") + ":" + pass) end
  end

  def headers()
    return {'Authorization': self.auth, 'Content-Type': "application/json"}
  end

  def loop()
    self.ticks += 1
    self.power_mode()
    if self.auth == nil return end
    if self.ticks % (shared.get("eco", false) && !shared.get("quiet", false) ? 10 : 3) == 0 self.poll() end
    if self.ticks % 5 == 0 self.indicators() end
    if self.ticks % 30 == 0 && store.get("wover", false) self.weather_overlay() end
  end

  def in_window(from, to)
    if hour() < 0 return false end
    var a = hhmm(from)
    var b = hhmm(to)
    if a < 0 || b < 0 || a == b return false end
    var m = hour() * 60 + minute()
    return a < b ? (m >= a && m < b) : (m >= a || m < b)
  end

  def in_quiet()
    if !store.get("quiet", true) || !self.in_window(store.get("qfrom", "21:00"), store.get("qto", "06:00")) return false end
    return now_ms() > self.wake_until
  end

  def wake()
    self.wake_until = now_ms() + store.get("qwake", 3) * 60000
  end

  def in_night()
    if !store.get("night", true) || hour() < 0 return false end
    var a = hhmm(store.get("nfrom", "22:30"))
    var b = hhmm(store.get("nto", "07:00"))
    if a < 0 || b < 0 || a == b return false end
    var m = hour() * 60 + minute()
    return a < b ? (m >= a && m < b) : (m >= a || m < b)
  end

  def wanted_mode()
    var night = self.in_night()
    var battery = store.get("bsave", true) && !self.usb
    if self.in_quiet() return "off" end
    if battery && self.pct < store.get("boff", 10) return "off" end
    if night && (battery || store.get("nmode", "dim") == "off") return "off" end
    if night return "dim" end
    if battery return "save" end
    return "normal"
  end

  def power_mode()
    shared.set("night", self.in_night() || self.in_quiet())
    shared.set("quiet", self.in_quiet())
    var want = self.wanted_mode()
    var was = store.get("pmode", "normal")
    if want == was return end
    if was == "normal" store.set("day_bright", settings.get("brightness")) end
    var day = store.get("day_bright", settings.get("brightness"))
    display.power(want != "off")
    if want == "dim" settings.set("brightness", store.get("nbright", 8)) end
    if want == "save" settings.set("brightness", min(day, store.get("bcap", 40))) end
    if want == "normal" settings.set("brightness", day) end
    store.set("pmode", want)
    log("calm: power " + want)
  end

  def battery(d)
    var pct = d.find("batteryPercent")
    var usb = d.find("usbPower")
    if pct == nil || usb == nil return end
    var warn = store.get("bwarn", 20)
    if !usb && pct < warn && self.pct >= warn
      notify({"name": "battery", "text": "Battery " + str(pct) + "% - please charge", "textColor": "#E0A040", "durationMs": 8000})
    end
    self.pct = pct
    self.usb = usb
    shared.set("eco", !usb && store.get("bsave", true))
    self.battery_log(pct, usb)
    shared.set("battery", pct)
    shared.set("usb", usb)
    shared.set("volts", d.find("batteryVoltage"))
    shared.set("uptime", d.find("uptimeSeconds"))
    shared.set("heap", d.find("freeHeapBytes"))
    shared.set("version", d.find("version"))
    shared.set("reset", d.find("resetReason"))
  end

  def battery_log(pct, usb)
    var now = int(epoch_ms() / 1000)
    var logv = store.get("blog", [])
    if usb
      if size(logv) > 0 store.set("blog", []) end
      shared.set("left_h", nil)
      return
    end
    if size(logv) > 0 && now - logv[-1][0] < 600 return end
    logv.push([now, pct])
    while size(logv) > 18 logv.remove(0) end
    store.set("blog", logv)
    var first = logv[0]
    var hours = (now - first[0]) / 3600.0
    var drop = first[1] - pct
    shared.set("left_h", hours >= 0.3 && drop > 0 ? pct * hours / drop : nil)
  end

  def poll()
    http.get("http://127.0.0.1/api/v1/device", / b, st -> self.on_device(b, st), {'headers': self.headers()})
  end

  def on_device(body, status)
    if status != 200 || body == nil
      log("calm: device answered " + str(status))
      return
    end
    var d = json.load(body)
    if !isinstance(d, map) return end
    shared.set("rssi", d.find("wifiRssi"))
    self.battery(d)
    var cur = d.find("currentApp", "")
    if cur != self.app
      if self.app != "" && store.get("quiet", true) && self.in_window(store.get("qfrom", "21:00"), store.get("qto", "06:00")) self.wake() end
      self.app = cur
      self.since = now_ms()
      return
    end
    var back = store.get("back", 60)
    var home = store.get("home", "Time")
    if back <= 0 || cur == "" || cur == home return end
    for k : string.split(store.get("keep", ""), ",")
      if trim(k) == cur return end
    end
    if now_ms() - self.since < back * 1000 return end
    self.since = now_ms()
    self.app = home
    http.put("http://127.0.0.1/api/v1/apps/active", json.dump({'name': home}),
             / b, st -> nil, {'headers': self.headers()})
  end

  def weather_overlay()
    var want = shared.get("Calm.night", false) ? nil : shared.get("Sky.overlay")
    var key = want == nil ? "none" : want
    if self.sent.find("overlay") == key return end
    self.sent["overlay"] = key
    http.patch("http://127.0.0.1/api/v1/display", json.dump({'overlay': want}), / b, st -> nil, {'headers': self.headers()})
  end

  def indicators()
    var on = store.get("inds", true) && !shared.get("Calm.night")
    var mail = shared.get("Gmail.unread")
    var slack = shared.get("Slack.unread")
    var alert = nil
    if shared.get("Network.up") == false
      alert = {'color': "#D0503C", 'blinkMs': 1000}
    elif shared.get("Pet.claude") == "waiting"
      alert = {'color': "#E08040", 'fadeMs': 2000}
    elif shared.get("Sky.alert_type") == "warning" || shared.get("Sky.alert_type") == "watch"
      alert = {'color': format("#%06X", shared.get("Sky.alert_color", 0xE0C040)), 'fadeMs': 3000}
    end
    self.set_ind(1, on && mail != nil && mail > 0 ? {'color': "#4A80D0", 'fadeMs': 4000} : nil)
    self.set_ind(2, on && slack != nil && slack > 0 ? {'color': "#A060D0", 'fadeMs': 4000} : nil)
    self.set_ind(3, on ? alert : nil)
  end

  def set_ind(id, want)
    var key = json.dump(want)
    if self.sent.find(id) == key return end
    self.sent[id] = key
    var url = "http://127.0.0.1/api/v1/indicators/" + str(id)
    if want == nil
      http.delete(url, / b, st -> nil, {'headers': self.headers()})
    else
      http.put(url, json.dump(want), / b, st -> nil, {'headers': self.headers()})
    end
  end

  def draw() end
end

return Calm()
