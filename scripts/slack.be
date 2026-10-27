# @name    Slack
# @desc    Unread Slack DMs, group DMs and @mentions, and the newest one
# @display 52x16
# @config  token  text   "User OAuth Token" default="" help="xoxp-... from api.slack.com/apps > OAuth & Permissions"
# @config  hide   bool   "Hide when nothing is unread" default=true
import json

var API = "https://slack.com/api/"
var LIST_EVERY = 1800

class Slack
  var ids, idx, state, me, names, unread, latest, seen_ts, baseline, list_ticks, wait, busy, status, top, bottom
  var dms, mentions, mq, mpos, mread, mcount, mdone

  def init()
    self.ids = nil
    self.idx = 0
    self.state = {}
    self.me = nil
    self.names = {}
    self.unread = -1
    self.latest = store.get("latest", "")
    self.seen_ts = 0.0
    self.baseline = false
    self.list_ticks = 0
    self.wait = 0
    self.busy = false
    self.status = 0
    self.top = ""
    self.bottom = ""
    self.dms = 0
    self.mentions = 0
    self.mq = nil
    self.mpos = 0
    self.mread = {}
    self.mcount = 0
    self.mdone = false
  end

  def opts()
    return {'headers': {'Authorization': "Bearer " + store.get("token", "")}, 'cap': 131072}
  end

  def ok(body, status)
    self.status = status
    if status == 429 self.wait = 30 end
    if status != 200 || body == nil return nil end
    var d = json.load(body)
    if !isinstance(d, map) return nil end
    if d.find("ok") != true
      self.status = d.find("error", "error")
      return nil
    end
    self.status = 200
    return d
  end

  def loop()
    self.update_labels()
    if store.get("token", "") == "" || self.busy return end
    if self.wait > 0
      self.wait -= 1
      return
    end
    self.list_ticks -= 1
    if self.me == nil
      self.busy = true
      http.get(API + "auth.test", / b, st -> self.on_auth(b, st), self.opts())
    elif self.ids == nil || self.list_ticks <= 0
      self.busy = true
      http.get(API + "conversations.list?types=im,mpim&exclude_archived=true&limit=200", / b, st -> self.on_list(b, st), self.opts())
    elif self.mq != nil
      self.mention_step()
    elif size(self.ids) > 0
      self.busy = true
      var id = self.ids[self.idx]
      http.get(API + "conversations.info?channel=" + id, / b, st -> self.on_info(id, b, st), self.opts())
    end
  end

  def on_auth(body, status)
    self.busy = false
    var d = self.ok(body, status)
    if d != nil self.me = d.find("user_id") end
  end

  def on_list(body, status)
    self.busy = false
    var d = self.ok(body, status)
    if d == nil return end
    var ids = []
    for c : d.find("channels", [])
      if c.find("is_user_deleted") != true ids.push(c["id"]) end
    end
    self.ids = ids
    self.list_ticks = LIST_EVERY
    if self.idx >= size(ids) self.idx = 0 end
  end

  def next()
    self.busy = false
    self.wait = 1
    self.idx += 1
    if self.idx >= size(self.ids)
      self.idx = 0
      self.baseline = true
      self.busy = true
      http.get(API + "search.messages?sort=timestamp&count=20&query=%3C%40" + self.me + "%3E",
               / b, st -> self.on_search(b, st), self.opts())
    end
  end

  def on_info(id, body, status)
    var d = self.ok(body, status)
    if d == nil
      self.next()
      return
    end
    var ch = d.find("channel", {})
    if ch.find("is_im") == true
      self.record(id, ch.find("unread_count_display", 0), ch.find("latest"))
      self.next()
      return
    end
    var last_read = real(ch.find("last_read", "0"))
    http.get(API + "conversations.history?channel=" + id + "&limit=1",
             / b, st -> self.on_history(id, last_read, b, st), self.opts())
  end

  def on_history(id, last_read, body, status)
    var d = self.ok(body, status)
    if d != nil
      var msgs = d.find("messages", [])
      var lat = size(msgs) > 0 ? msgs[0] : nil
      var fresh = lat != nil && real(lat.find("ts", "0")) > last_read && lat.find("user") != self.me
      self.record(id, fresh ? 1 : 0, lat)
    end
    self.next()
  end

  def record(id, n, lat)
    self.state[id] = n
    var total = 0
    for v : self.state total += v end
    self.dms = total
    self.set_total()
    if n <= 0 || !isinstance(lat, map) || lat.find("user") == self.me return end
    var ts = real(lat.find("ts", "0"))
    if ts <= self.seen_ts return end
    self.seen_ts = ts
    var announce = self.baseline
    var user = lat.find("user", "")
    var text = lat.find("text", "")
    if self.names.find(user) != nil
      self.publish(self.names[user], text, announce)
    else
      http.get(API + "users.info?user=" + user, / b, st -> self.on_user(user, text, announce, b, st), self.opts())
    end
  end

  def set_total()
    self.unread = self.dms + self.mentions
    shared.set("unread", self.unread)
  end

  def on_search(body, status)
    self.busy = false
    var d = self.ok(body, status)
    if d == nil return end
    var list = []
    for m : d.find("messages", {}).find("matches", [])
      var ch = m.find("channel", {})
      if ch.find("is_im") != true && ch.find("is_mpim") != true && m.find("user") != self.me
        list.push(m)
      end
    end
    self.mq = list
    self.mpos = 0
    self.mread = {}
    self.mcount = 0
  end

  def mention_step()
    if self.mpos >= size(self.mq)
      self.mentions = self.mcount
      self.mq = nil
      self.mdone = true
      log("slack: " + str(self.mentions) + " unread mentions")
      self.set_total()
      return
    end
    var m = self.mq[self.mpos]
    var cid = m.find("channel", {}).find("id", "")
    if self.mread.find(cid) != nil
      self.mention_check(m, self.mread[cid])
      self.mpos += 1
      return
    end
    self.busy = true
    http.get(API + "conversations.info?channel=" + cid, / b, st -> self.on_channel(cid, b, st), self.opts())
  end

  def on_channel(cid, body, status)
    self.busy = false
    self.wait = 1
    var d = self.ok(body, status)
    if d == nil
      log("slack: mention check stopped: " + str(self.status))
      self.mq = nil
      return
    end
    self.mread[cid] = real(d.find("channel", {}).find("last_read", "0"))
  end

  def mention_check(m, last_read)
    var ts = real(m.find("ts", "0"))
    if ts <= last_read return end
    self.mcount += 1
    if ts <= self.seen_ts return end
    self.seen_ts = ts
    var chname = m.find("channel", {}).find("name", "")
    self.publish(m.find("username", "someone") + " in #" + chname, m.find("text", ""), self.mdone)
  end

  def on_user(user, text, announce, body, status)
    var d = self.ok(body, status)
    var name = user
    if d != nil
      var u = d.find("user", {})
      var p = u.find("profile", {})
      name = p.find("display_name", "")
      if name == "" name = p.find("real_name", u.find("name", user)) end
    end
    self.names[user] = name
    self.publish(name, text, announce)
  end

  def publish(name, text, announce)
    self.latest = name + ": " + text
    store.set("latest", self.latest)
    shared.set("latest", self.latest)
    if announce
      store.set("seq", store.get("seq", 0) + 1)
      shared.set("seq", store.get("seq"))
    end
  end

  def should_show()
    return !(store.get("hide", true) && self.unread == 0)
  end

  def update_labels()
    if store.get("token", "") == ""
      self.top = "SLACK"
      self.bottom = "Add the token: Apps > gear"
    elif self.status != 0 && self.status != 200 && self.status != 429
      self.top = "SLACK"
      self.bottom = "Slack answered " + str(self.status)
    elif self.unread < 0 || (!self.baseline && self.unread == 0)
      self.top = "..."
      self.bottom = "Checking..."
    elif self.unread == 0
      self.top = "none"
      self.bottom = "All read"
    else
      self.top = self.mentions > 0 ? str(self.dms) + " new @" + str(self.mentions) : str(self.unread) + " new"
      self.bottom = self.latest
    end
  end

  def draw()
    clear()
    var c = self.unread > 0 ? 0xC8643C : 0x3A2E26
    line(2, 0, 2, 6, c)
    line(5, 0, 5, 6, c)
    line(0, 2, 7, 2, c)
    line(0, 4, 7, 4, c)
    text(11, 6, self.top, 0xF2D7B6)
    scroll_text(0, 14, width(), self.bottom, 0xC8643C)
  end
end

return Slack()
