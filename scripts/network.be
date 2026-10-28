# @name    Network
# @desc    Public IP, provider, location, latency and Wi-Fi. Turn the knob for the pages
# @author  mtch3n
# @version 1.0
# @display 52x16
# @config  every  number "Refresh" default=10 min=1 max=120 unit=min
# @config  slow   number "Slow from" default=400 min=50 max=5000 unit=ms help="Time for one HTTPS request to Cloudflare"
import json
import string

class Network
  var page, ip, org, place, colo, rtt, up, ticks, started, turned
  var top, bottom, top_color

  def init()
    self.page = 0
    self.ip = store.get("ip", "")
    self.org = store.get("org", "")
    self.place = store.get("place", "")
    self.colo = ""
    self.rtt = -1
    self.up = nil
    self.ticks = 0
    self.started = 0
    self.turned = 0
    self.top = "NET"
    self.bottom = "Checking..."
    self.top_color = 0xF2D7B6
  end

  def loop()
    if shared.get("Calm.quiet", false) return end
    if self.ticks <= 0
      self.ticks = shared.get("Calm.eco", false) ? 3600 : store.get("every", 10) * 60
      self.check()
    end
    self.ticks -= 1
    if self.page > 0 && now_ms() - self.turned > 30000 self.page = 0 end
    self.update_labels()
  end

  def check()
    self.started = now_ms()
    http.get("https://cloudflare.com/cdn-cgi/trace", / b, st -> self.on_trace(b, st))
  end

  def on_trace(body, status)
    if status != 200 || body == nil
      self.up = false
      self.rtt = -1
      shared.set("up", false)
      return
    end
    self.rtt = now_ms() - self.started
    self.up = true
    shared.set("up", true)
    shared.set("rtt", self.rtt)
    var ip = ""
    for line : string.split(body, "\n")
      var i = string.find(line, "=")
      if i > 0
        var k = line[0 .. i - 1]
        var v = i + 1 < size(line) ? line[i + 1 .. size(line) - 1] : ""
        if k == "ip" ip = v end
        if k == "colo" self.colo = v end
      end
    end
    if ip != "" && ip != self.ip
      self.ip = ip
      store.set("ip", ip)
      shared.set("ip", ip)
      http.get("https://ipinfo.io/" + ip + "/json", / b, st -> self.on_info(b, st))
    end
  end

  def on_info(body, status)
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) return end
    var org = d.find("org", "")
    var sp = string.find(org, " ")
    if sp > 0 && org[0] == "A" && org[1] == "S" org = org[sp + 1 .. size(org) - 1] end
    self.org = org
    self.place = d.find("city", "") + ", " + d.find("region", "")
    store.set("org", self.org)
    store.set("place", self.place)
  end

  def on_show()
    self.page = 0
    self.update_labels()
  end

  def on_knob(event)
    if event == "right" self.page = (self.page + 1) % 3
    elif event == "left" self.page = (self.page + 2) % 3
    elif event == "press" self.page = 0
    else return true
    end
    self.turned = now_ms()
    self.update_labels()
    return true
  end

  def update_labels()
    self.top_color = 0xF2D7B6
    if self.up == false
      self.top = "OFFLINE"
      self.top_color = 0xD0503C
      self.bottom = self.ip == "" ? "No internet" : "Last IP " + self.ip
      return
    end
    if self.page == 0
      self.top = "IP"
      self.bottom = self.ip == "" ? "Checking..." : self.ip
    elif self.page == 1
      self.top = "ISP"
      self.bottom = self.org == "" ? "--" : self.org + " - " + self.place
    else
      var rssi = shared.get("Calm.rssi")
      self.top = self.rtt < 0 ? "WEB --" : "WEB " + str(self.rtt) + "ms"
      if self.rtt >= store.get("slow", 400) self.top_color = 0xE0A040 end
      self.bottom = (rssi == nil ? "WiFi --" : "WiFi " + str(rssi) + "dBm") + (self.colo == "" ? "" : "  CF " + self.colo)
    end
  end

  def draw()
    clear()
    text(0, 6, self.top, self.top_color)
    for i : 0 .. 2
      pixel(width() - 7 + i * 3, 2, i == self.page ? 0xF2D7B6 : 0x3A2E26)
    end
    scroll_text(0, 14, width(), self.bottom, 0xC8643C)
  end
end

return Network()
