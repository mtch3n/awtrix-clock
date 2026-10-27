# awtrix-clock

Scripts and settings for an Ulanzi TC002 (52×16) that runs [AWTRIX NG](https://github.com/Blueforcer/awtrix-ng).
The look is calm: the clock goes back to the time by itself, the display dims at night, and one warm
palette ("Warm paper") is used for all apps. A small Clawd-style pet brings the news.

## Apps

| Script | What it shows |
|---|---|
| `scripts/calm.be` | Background app. Goes back to the clock after 60 s, dims the display at night (22:30–07:00) and sets the corner indicators: 1 = unread mail, 2 = unread Slack, 3 = alert (internet down, or Claude Code waits for you). |
| `scripts/pet.be` | A pet that walks and blinks. It follows Claude Code (working, waiting, done), dresses for the weather (sunglasses, umbrella, snow, sweat), sleeps at night and runs in with new mail, Slack DMs and meetings. Push the knob for hearts. |
| `scripts/google-calendar.be` | The current or next event with a countdown. Turn the knob for the next events. |
| `scripts/gmail.be` | Unread mail in the inbox and the newest sender and subject. Hides itself when the inbox is read. |
| `scripts/slack.be` | Unread Slack DMs and group DMs and the newest one. Runs on the clock with a user token. |
| `scripts/network.be` | Public IP, provider, location, HTTPS time to Cloudflare and Wi-Fi signal. Turn the knob for the pages. |

Two apps come from the [AWTRIX Hub](https://awtrix.de) and are not in this repository:
[Beautiful Weather](https://awtrix.de/script/O3xYAw5TPWWp) and [Pomodoro Timer](https://awtrix.de/script/9B9ojlCGyaxL).

The apps talk to each other with `shared` values: Calendar shares the next meeting, Gmail and
Slack share the newest message, Calm shares the night state, and the pet and Calm read them.

## Settings

- `settings/display.json`: the display settings, from `GET /api/v1/settings`.
- `settings/apps.json`: the app order and the apps that are off.
- `settings/app-config.json`: the settings of each script. Secrets are not in this file.

## Put it on a clock

1. Install AWTRIX NG on the TC002 and switch on the web login.
2. Send Beautiful Weather and Pomodoro Timer from the AWTRIX Hub.
3. Run:

    ```sh
    AWTRIX_HOST=192.168.x.x AWTRIX_USER=admin AWTRIX_PASS=... python3 tools/deploy.py
    ```

4. In the web UI, under **Apps → ⚙**:
    - **Calm**: enter the web login password.
    - **Google-Calendar** and **Gmail**: enter the client ID and secret of a Google OAuth client
      (type "Web application", redirect URI `https://awtrix.de/oauth/callback`), then sign in. Use
      the scopes `calendar.readonly` and `gmail.metadata`.
    - **Slack**: create a Slack app from `slack-manifest.yaml`, install it and paste the User OAuth
      Token (`xoxp-…`).

The sign-ins and tokens are stored on the clock without encryption. Keep the web login on.

## Claude Code and the pet

The pet reads its Claude Code state from its store. A hook sends the state:

```sh
curl -s -m 1 -u "$AWTRIX_USER:$AWTRIX_PASS" -X PATCH "http://$AWTRIX_HOST/api/v1/apps/Pet/data" \
  -H 'Content-Type: application/json' -d "{\"claude\":\"working\",\"claude_at\":$(date +%s)}"
```

Use `working` on `UserPromptSubmit`, `waiting` on `Notification` and `done` on `Stop`.

## Previews

`tools/render.py` draws screens from `GET /api/v1/display/screen` as an LED panel image:

```sh
curl -s -u admin:... http://192.168.x.x/api/v1/display/screen > time.json
python3 tools/render.py preview.png "Time" time.json
```

`tools/palettes.py` recolors captured clock faces to compare palettes before you apply one.

## License

MIT. See `LICENSE`.
