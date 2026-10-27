# @name    Calm
# @desc    Night mode, return to the clock after a delay, and the corner indicators
# @headless true
# @config  back    number "Back to the clock after" default=60 min=0 max=3600 unit=s help="0 = never" group="Return"
# @config  home    text   "Clock app"     default="Time" group="Return"
# @config  keep    text   "Never leave"   default="Pomodoro-Timer" help="Apps that stay, separated by commas" group="Return"
# @config  night   bool   "Night mode"    default=true group="Night"
# @config  nfrom   text   "Night from"    default="22:30" group="Night"
# @config  nto     text   "Night until"   default="07:00" group="Night"
# @config  nmode   select "At night"      default=dim options=dim,off group="Night"
# @config  nbright number "Night brightness" default=8 min=1 max=255 group="Night"
# @config  inds    bool   "Indicators"    default=true help="Mail, Slack and alerts in the corners" group="Indicators"
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
  var ticks, app, since, sent, auth

  def init()
    self.ticks = 0
    self.app = ""
    self.since = now_ms()
    self.sent = {}
    self.auth = nil
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
    self.night_mode()
    if self.auth == nil return end
    if self.ticks % 3 == 0 self.poll() end
    if self.ticks % 5 == 0 self.indicators() end
  end

  def in_night()
    if !store.get("night", true) || hour() < 0 return false end
    var a = hhmm(store.get("nfrom", "22:30"))
    var b = hhmm(store.get("nto", "07:00"))
    if a < 0 || b < 0 || a == b return false end
    var m = hour() * 60 + minute()
    return a < b ? (m >= a && m < b) : (m >= a || m < b)
  end

  def night_mode()
    var want = self.in_night()
    var was = store.get("night_on", false)
    shared.set("night", want)
    if want == was return end
    if want
      store.set("day_bright", settings.get("brightness"))
      if store.get("nmode", "dim") == "off"
        display.power(false)
      else
        settings.set("brightness", store.get("nbright", 8))
      end
    else
      display.power(true)
      var day = store.get("day_bright")
      if day != nil settings.set("brightness", day) end
    end
    store.set("night_on", want)
    log("calm: night " + (want ? "on" : "off"))
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
    var cur = d.find("currentApp", "")
    if cur != self.app
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
    http.put("http://127.0.0.1/api/v1/apps/active", json.dump({'name': home}),
             / b, st -> nil, {'headers': self.headers()})
  end

  def indicators()
    var on = store.get("inds", true) && !shared.get("Calm.night")
    var mail = shared.get("Gmail.unread")
    var slack = shared.get("Slack.unread")
    var alert = nil
    if shared.get("Network.up") == false
      alert = {'color': "#600000", 'blinkMs': 1000}
    elif shared.get("Pet.claude") == "waiting"
      alert = {'color': "#603000", 'fadeMs': 2000}
    end
    self.set_ind(1, on && mail != nil && mail > 0 ? {'color': "#001040"} : nil)
    self.set_ind(2, on && slack != nil && slack > 0 ? {'color': "#200030"} : nil)
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
