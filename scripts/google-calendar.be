# @name    Google Calendar
# @desc    The current or next event of a Google Calendar: start time, countdown and title
# @author  mtch3n
# @version 1.0
# @display 52x16
# @oauth authorize=https://accounts.google.com/o/oauth2/v2/auth token=https://oauth2.googleapis.com/token api=www.googleapis.com scope="https://www.googleapis.com/auth/calendar.readonly" params="access_type=offline prompt=consent"
# @config  cal     text   "Calendar ID" default="primary" help="primary, or the calendar's ID from Google Calendar settings"
# @config  ahead   number "Look ahead"  default=72 min=1 max=168 unit=h
# @config  every   number "Refresh"     default=5 min=1 max=60 unit=min
# @config  allday  bool   "All-day events" default=false
# @config  tint    color  "Title color" default=#C8643C
import oauth
import json

def days_from_civil(y, m, d)
  if m <= 2 y -= 1 end
  var era = y / 400
  var yoe = y - era * 400
  var mp = (m + 9) % 12
  var doy = (153 * mp + 2) / 5 + d - 1
  var doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  return era * 146097 + doe - 719468
end

def utc_stamp(secs)
  var z = secs / 86400 + 719468
  var rest = secs % 86400
  var era = z / 146097
  var doe = z - era * 146097
  var yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  var doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  var mp = (5 * doy + 2) / 153
  var d = doy - (153 * mp + 2) / 5 + 1
  var m = mp < 10 ? mp + 3 : mp - 9
  var y = yoe + era * 400 + (m <= 2 ? 1 : 0)
  return format("%04d-%02d-%02dT%02d:%02d:%02dZ", y, m, d, rest / 3600, rest % 3600 / 60, rest % 60)
end

def parse_rfc3339(s)
  var secs = (days_from_civil(int(s[0..3]), int(s[5..6]), int(s[8..9])) * 86400
              + int(s[11..12]) * 3600 + int(s[14..15]) * 60 + int(s[17..18]))
  var i = 19
  if i < size(s) && s[i] == "."
    while i < size(s) && s[i] != "Z" && s[i] != "+" && s[i] != "-" i += 1 end
  end
  if i >= size(s) || s[i] == "Z" return secs end
  var off = int(s[i + 1 .. i + 2]) * 3600 + int(s[i + 4 .. i + 5]) * 60
  return s[i] == "+" ? secs - off : secs + off
end

def parse_date(s)
  return days_from_civil(int(s[0..3]), int(s[5..6]), int(s[8..9])) * 86400
end

def url_part(s)
  var out = ""
  for i : 0 .. size(s) - 1
    var c = s[i]
    if c == "@" out += "%40"
    elif c == "#" out += "%23"
    elif c == "+" out += "%2B"
    else out += c
    end
  end
  return out
end

class GoogleCalendar
  var events, status, fetched, ticks, idx, turned
  var when_label, left_label, title, left_color

  def init()
    self.events = []
    self.status = 0
    self.fetched = false
    self.ticks = 0
    self.idx = 0
    self.turned = 0
    self.when_label = ""
    self.left_label = ""
    self.title = ""
    self.left_color = 0xF2D7B6
  end

  def now_s()
    return int(epoch_ms() / 1000)
  end

  def local_offset_s(now)
    var diff = (hour() * 60 + minute()) - (now % 86400) / 60
    if diff > 720 diff -= 1440 end
    if diff < -720 diff += 1440 end
    return diff * 60
  end

  def loop()
    if hour() < 0 || !oauth.ready() || shared.get("Calm.quiet", false)
      self.update_labels()
      return
    end
    if !self.fetched || self.ticks <= 0
      self.ticks = shared.get("Calm.eco", false) ? 900 : store.get("every", 5) * 60
      self.fetch()
    end
    self.ticks -= 1
    self.update_labels()
  end

  def fetch()
    var now = self.now_s()
    var url = "https://www.googleapis.com/calendar/v3/calendars/" + url_part(store.get("cal", "primary"))
    url += "/events?singleEvents=true&orderBy=startTime&maxResults=10"
    url += "&timeMin=" + utc_stamp(now - 86400)
    url += "&timeMax=" + utc_stamp(now + store.get("ahead", 12) * 3600)
    url += "&fields=items(summary,status,start,end,attendees(self,responseStatus))"
    oauth.get(url, / body, status -> self.on_events(body, status), {'cap': 32768})
  end

  def on_events(body, status)
    self.fetched = true
    self.status = status
    if status != 200 || body == nil return end
    var data = json.load(body)
    if !isinstance(data, map) return end
    var list = []
    var allday = store.get("allday", false)
    for item : data.find("items", [])
      if item.find("status") == "cancelled" continue end
      var declined = false
      for a : item.find("attendees", [])
        if a.find("self") == true && a.find("responseStatus") == "declined" declined = true end
      end
      if declined continue end
      var st = item.find("start", {})
      var en = item.find("end", {})
      var ev = nil
      if st.find("dateTime") != nil
        ev = {"start": parse_rfc3339(st["dateTime"]), "end": parse_rfc3339(en.find("dateTime", st["dateTime"])), "allday": false}
      elif allday && st.find("date") != nil
        ev = {"start": parse_date(st["date"]), "end": parse_date(en.find("date", st["date"])), "allday": true}
      end
      if ev != nil
        ev["title"] = item.find("summary", "(no title)")
        list.push(ev)
      end
    end
    self.events = list
    log("calendar: " + str(size(list)) + " events")
  end

  def upcoming(now)
    var off = self.local_offset_s(now)
    var out = []
    for ev : self.events
      var s = ev["start"]
      var e = ev["end"]
      if ev["allday"]
        s -= off
        e -= off
      end
      if e > now out.push([ev, s, e]) end
    end
    return out
  end

  def on_show()
    self.idx = 0
    self.update_labels()
  end

  def on_knob(event)
    if event == "right" self.idx += 1
    elif event == "left" self.idx = max(self.idx - 1, 0)
    elif event == "press" self.idx = 0
    else return true
    end
    self.turned = now_ms()
    self.update_labels()
    return true
  end

  def span(secs)
    var mins = (secs + 59) / 60
    if mins < 60 return str(mins) + "m" end
    var h = mins / 60
    if h < 24 return format("%dh%02d", h, mins % 60) end
    return str(h / 24) + "d"
  end

  def update_labels()
    self.left_color = 0xF2D7B6
    if hour() < 0
      self.when_label = "CAL"
      self.left_label = ""
      self.title = "Waiting for the time"
      return
    end
    if !oauth.ready()
      self.when_label = "CAL"
      self.left_label = ""
      self.title = "Sign in: Apps > gear > Sign in"
      return
    end
    if self.status != 0 && self.status != 200
      self.when_label = "CAL"
      self.left_label = "E" + str(self.status)
      self.left_color = 0xD0503C
      self.title = self.status == 401 ? "Sign in again" : "Google answered " + str(self.status)
      return
    end
    if !self.fetched
      self.when_label = "CAL"
      self.left_label = ""
      self.title = "Loading..."
      return
    end
    var now = self.now_s()
    if self.idx > 0 && now_ms() - self.turned > 30000 self.idx = 0 end
    var list = self.upcoming(now)
    var first = nil
    for h : list
      if !h[0]["allday"]
        first = h
        break
      end
    end
    shared.set("next_min", first == nil ? nil : (first[1] - now) / 60)
    shared.set("next_at", first == nil ? nil : first[1])
    shared.set("next_title", first == nil ? nil : first[0]["title"])
    if size(list) == 0
      self.idx = 0
      self.when_label = "FREE"
      self.left_label = ""
      self.left_color = 0x8C7B6B
      self.title = "Nothing in the next " + str(store.get("ahead", 72)) + "h"
      return
    end
    if self.idx >= size(list) self.idx = size(list) - 1 end
    var hit = list[self.idx]
    var ev = hit[0]
    var off = self.local_offset_s(now)
    var today = (now + off) / 86400
    var local = hit[1] + off
    var day = local / 86400
    var names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    var prefix = day == today ? "" : (day == today + 1 ? "TMR " : names[(day + 4) % 7] + " ")
    self.title = ev["title"]
    if ev["allday"]
      self.when_label = day <= today ? "TODAY" : prefix + "ALL"
    elif prefix == ""
      self.when_label = format("%02d:%02d", local % 86400 / 3600, local % 3600 / 60)
    else
      self.when_label = prefix + format("%d:%02d", local % 86400 / 3600, local % 3600 / 60)
    end
    if hit[1] <= now
      self.left_label = ev["allday"] ? "" : "NOW " + self.span(hit[2] - now)
      self.left_color = 0xD0503C
    elif prefix == ""
      var wait = hit[1] - now
      self.left_label = "in " + self.span(wait)
      self.left_color = wait <= 300 ? 0xE0A040 : 0xF2D7B6
    else
      self.left_label = str(self.idx + 1) + "|" + str(size(list))
      self.left_color = 0x8C7B6B
    end
  end

  def draw()
    clear()
    text(0, 6, self.when_label, 0xF2D7B6)
    text(width() - text_width(self.left_label), 6, self.left_label, self.left_color)
    scroll_text(0, 14, width(), self.title, store.get("tint", 0xC8643C))
  end
end

return GoogleCalendar()
