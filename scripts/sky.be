# @name    Sky
# @desc    Weather from Open-Meteo and Environment Canada alerts for one place, shared with the other apps
# @headless true
# @config  lat    number "Latitude"  default=43.6532 min=-90 max=90 step=0.0001
# @config  lon    number "Longitude" default=-79.3832 min=-180 max=180 step=0.0001
# @config  alerts bool   "Environment Canada alerts" default=true
# @config  note   select "Notify for" default=advisory options=statement,advisory,watch,warning,none help="The lowest alert type that shows a notification"
# @config  windy  number "Storm overlay from" default=50 min=20 max=150 unit=km/h
import json

var LEVELS = ["statement", "advisory", "watch", "warning"]
var COLORS = {"red": 0xD0503C, "orange": 0xE08040, "yellow": 0xE0C040}

def level_of(t)
  var i = LEVELS.find(t)
  return i == nil ? 0 : i
end

class Sky
  var wx_ticks, alert_ticks, seq

  def init()
    self.wx_ticks = 0
    self.alert_ticks = 5
    self.seq = 0
  end

  def setup()
    shared.set("seq", 0)
  end

  def loop()
    self.wx_ticks -= 1
    self.alert_ticks -= 1
    if self.wx_ticks <= 0
      self.wx_ticks = shared.get("Calm.eco", false) ? 1800 : 600
      self.fetch_weather()
    end
    if self.alert_ticks <= 0
      self.alert_ticks = shared.get("Calm.eco", false) ? 900 : 300
      if store.get("alerts", true) self.fetch_alerts() end
    end
  end

  def fetch_weather()
    var url = format("https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m",
                     store.get("lat", 43.6532), store.get("lon", -79.3832))
    http.get(url, / b, st -> self.on_weather(b, st))
  end

  def on_weather(body, status)
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) || !isinstance(d.find("current"), map) return end
    var cur = d["current"]
    var code = cur.find("weather_code", 0)
    var wind = cur.find("wind_speed_10m", 0)
    shared.set("temp", cur.find("temperature_2m"))
    shared.set("feels", cur.find("apparent_temperature"))
    shared.set("code", code)
    shared.set("day", cur.find("is_day", 1))
    shared.set("wind", wind)
    shared.set("overlay", self.overlay_for(code, wind))
  end

  def overlay_for(code, wind)
    if code >= 95 return "thunder" end
    if code == 56 || code == 57 || code == 66 || code == 67 return "frost" end
    if code >= 51 && code <= 55 return "drizzle" end
    if (code >= 61 && code <= 65) || (code >= 80 && code <= 82) return "rain" end
    if (code >= 71 && code <= 77) || code == 85 || code == 86 return "snow" end
    if wind >= store.get("windy", 50) return "storm" end
    return nil
  end

  def fetch_alerts()
    var lat = store.get("lat", 43.6532)
    var lon = store.get("lon", -79.3832)
    var url = format("https://api.weather.gc.ca/collections/weather-alerts/items?f=json&lang=en&skipGeometry=true&bbox=%.4f,%.4f,%.4f,%.4f&properties=alert_short_name_en,alert_name_en,alert_type,risk_colour_en",
                     lon - 0.02, lat - 0.02, lon + 0.02, lat + 0.02)
    http.get(url, / b, st -> self.on_alerts(b, st), {'cap': 32768})
  end

  def on_alerts(body, status)
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) return end
    var top = nil
    var seen = store.get("seen", [])
    var fresh = []
    for f : d.find("features", [])
      var p = f.find("properties", {})
      var a = {"id": f.find("id", ""), "name": p.find("alert_short_name_en", "Weather alert"),
               "type": p.find("alert_type", "statement"), "colour": p.find("risk_colour_en")}
      if top == nil || level_of(a["type"]) > level_of(top["type"]) top = a end
      if seen.find(a["id"]) == nil
        fresh.push(a)
        seen.push(a["id"])
      end
    end
    while size(seen) > 30 seen.remove(0) end
    store.set("seen", seen)
    shared.set("alert", top == nil ? nil : top["name"])
    shared.set("alert_type", top == nil ? nil : top["type"])
    shared.set("alert_color", top == nil ? nil : COLORS.find(top["colour"], 0xE8DCCB))
    var min_level = store.get("note", "advisory")
    if min_level == "none" return end
    for a : fresh
      if level_of(a["type"]) >= level_of(min_level)
        var label = a["name"] + " " + a["type"]
        notify({"name": "eccc", "text": label, "textColor": format("#%06X", COLORS.find(a["colour"], 0xE8DCCB)), "durationMs": 10000})
        shared.set("latest", label)
        self.seq += 1
        shared.set("seq", self.seq)
      end
    end
  end

  def draw() end
end

return Sky()
