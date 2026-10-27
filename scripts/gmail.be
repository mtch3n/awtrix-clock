# @name    Gmail
# @desc    Unread mail in the inbox, the newest sender and subject, and a quiet note for new mail
# @display 52x16
# @oauth authorize=https://accounts.google.com/o/oauth2/v2/auth token=https://oauth2.googleapis.com/token api=gmail.googleapis.com scope="https://www.googleapis.com/auth/gmail.metadata" params="access_type=offline prompt=consent"
# @config  every  number "Refresh" default=2 min=1 max=60 unit=min
# @config  note   bool   "Note for new mail" default=false help="The pet brings new mail. Turn this on for a plain notification as well"
# @config  sound  bool   "Sound for new mail" default=false
# @config  hide   bool   "Hide when no unread mail" default=true
import oauth
import json
import string

var API = "https://gmail.googleapis.com/gmail/v1/users/me/"

def sender_name(from)
  var lt = string.find(from, " <")
  var name = lt > 0 ? from[0 .. lt - 1] : from
  if size(name) > 1 && name[0] == "\"" && name[size(name) - 1] == "\"" name = name[1 .. size(name) - 2] end
  return name
end

class Gmail
  var unread, latest, status, ticks, top, bottom

  def init()
    self.unread = store.get("unread", -1)
    self.latest = store.get("latest", "")
    self.status = 0
    self.ticks = 0
    self.top = ""
    self.bottom = ""
  end

  def loop()
    if oauth.ready()
      if self.ticks <= 0
        self.ticks = store.get("every", 2) * 60
        oauth.get(API + "labels/INBOX", / b, st -> self.on_label(b, st))
      end
      self.ticks -= 1
    end
    self.update_labels()
  end

  def on_label(body, status)
    self.status = status
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) return end
    self.unread = d.find("messagesUnread", 0)
    store.set("unread", self.unread)
    shared.set("unread", self.unread)
    shared.set("seq", store.get("seq", 0))
    if self.unread > 0
      oauth.get(API + "messages?labelIds=INBOX&labelIds=UNREAD&maxResults=1", / b, st -> self.on_list(b, st))
    end
  end

  def on_list(body, status)
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) return end
    var msgs = d.find("messages", [])
    if size(msgs) == 0 return end
    var id = msgs[0].find("id", "")
    if id == "" || id == store.get("last_id", "") return end
    var first = store.get("last_id") == nil
    store.set("last_id", id)
    oauth.get(API + "messages/" + id + "?format=metadata&metadataHeaders=From&metadataHeaders=Subject",
              / b, st -> self.on_message(b, st, !first))
  end

  def on_message(body, status, announce)
    if status != 200 || body == nil return end
    var d = json.load(body)
    if !isinstance(d, map) return end
    var from = ""
    var subject = ""
    for h : d.find("payload", {}).find("headers", [])
      if h.find("name") == "From" from = sender_name(h.find("value", "")) end
      if h.find("name") == "Subject" subject = h.find("value", "") end
    end
    self.latest = from + ": " + (subject == "" ? "(no subject)" : subject)
    store.set("latest", self.latest)
    shared.set("latest", self.latest)
    if announce
      store.set("seq", store.get("seq", 0) + 1)
      shared.set("seq", store.get("seq"))
    end
    if announce && store.get("note", false) && !shared.get("Calm.night", false)
      var n = {"name": "gmail", "text": self.latest, "textColor": "#F2D7B6", "durationMs": 9000,
               "scroll": {"mode": "wrap", "speed": 70}}
      if store.get("sound", false) n["sound"] = {"rtttl": "mail:d=16,o=6,b=140:e,g"} end
      notify(n)
    end
  end

  def should_show()
    return !(store.get("hide", true) && self.unread == 0)
  end

  def update_labels()
    if !oauth.ready()
      self.top = "MAIL"
      self.bottom = "Sign in: Apps > gear > Sign in"
    elif self.status == 401
      self.top = "MAIL"
      self.bottom = "Sign in again"
    elif self.status != 0 && self.status != 200
      self.top = "E" + str(self.status)
      self.bottom = "Gmail answered " + str(self.status)
    elif self.unread < 0
      self.top = "..."
      self.bottom = "Loading..."
    else
      self.top = self.unread == 0 ? "none" : str(self.unread) + " new"
      self.bottom = self.unread == 0 ? "Inbox is read" : self.latest
    end
  end

  def draw()
    clear()
    var c = self.unread > 0 ? 0xC8643C : 0x3A2E26
    rect(0, 0, 9, 7, c)
    line(1, 1, 4, 4, c)
    line(7, 1, 4, 4, c)
    text(11, 6, self.top, 0xF2D7B6)
    scroll_text(0, 14, width(), self.bottom, 0xC8643C)
  end
end

return Gmail()
