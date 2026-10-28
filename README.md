# awtrix-clock

Scripts and settings for an Ulanzi TC002 (52×16) that runs [AWTRIX NG](https://github.com/Blueforcer/awtrix-ng).
The look is calm: the clock goes back to the time by itself, the display dims at night, and one warm
palette ("Warm paper") is used for all apps. A small Clawd-style pet brings the news.

## Apps

| Script | What it shows |
|---|---|
| `scripts/clock.be` | The home screen: block digits with a static weather icon on the left and `HH:MM`, a weekday bar and an alert mark. Turn the knob for the date, the weather and the active alert. Many settings: layout (weather, `HH:MM`, `HH:MM:SS`), left side (icon, temperature, both), digit style (compact, airy, bold, thin), size and spacing, 12/24 h, leading zero, colon, seconds line, weather overlay, a retro glow mode (nixie, VFD with ghost segments, CRT with scan lines) and all colors. It replaces the built-in Time app. |
| `scripts/timer.be` | Countdown, Pomodoro and stopwatch in one app. While stopped, a knob push moves the selection (Countdown: mode, minutes, seconds; Pomodoro: mode, focus, break, long break) and a turn changes it. Select starts and pauses (a knob push too while it runs), hold resets. Animated icons; it rings at zero and comes to the display. |
| `scripts/sky.be` | Background app. Weather from Open-Meteo every 10 minutes and Environment Canada alerts (GeoMet `weather-alerts`) every 5 minutes for one place. Shares them with Clock, Pet and Calm, and shows one notification for each new alert. |
| `scripts/blockfont.be` | Module. The block digits that Clock and Timer use. Install it first. |
| `scripts/calm.be` | Background app. Goes back to the clock after 60 s, has a quiet time (21:00–06:00: display off and all apps paused; a LEFT or RIGHT push wakes it for 3 minutes), dims the display at night (22:30–07:00), saves the battery when unplugged (brightness limit, display off at night, and an eco mode in which every app polls less often and the pet does not visit; it also estimates the time left) and sets the corner indicators: 1 = unread mail, 2 = unread Slack, 3 = alert (internet down, Claude Code waits for you, or a weather watch or warning). |
| `scripts/pet.be` | A pet that wakes up on the display after each start of the clock (sleeps, stretches, yawns, waves "morning!", "hi!" or "evening!"), walks, looks around and visits every 15 minutes. It does activities (laptop, coffee, book, music, exercise, ball, dance, plant), has small accidents (trips, slips on a banana, sneezes, hiccups, chases a butterfly), hides past the edges of the frame (side, under, upside down from the top) for hide-and-seek, walks far away (small) or comes close (big), follows Claude Code, dresses for the weather, sleeps at night and brings new mail, Slack DMs and meetings. Knob: push for hearts, hold to feed, turn to find it. Select: play ball. |
| `scripts/google-calendar.be` | The current or next event with a countdown. Turn the knob for the next events. |
| `scripts/gmail.be` | Unread mail in the inbox and the newest sender and subject. Hides itself when the inbox is read. |
| `scripts/slack.be` | Unread Slack DMs and group DMs and the newest one. Runs on the clock with a user token. |
| `scripts/device.be` | Four pages, one big value each: battery (a shaded battery that fills, a bolt while it charges), uptime, free memory, and firmware with voltage and the last restart reason. Turn the knob for the pages. Calm shares the values. |
| `scripts/network.be` | Public IP, provider, location, HTTPS time to Cloudflare and Wi-Fi signal. Turn the knob for the pages. |


The apps talk to each other with `shared` values: Calendar shares the next meeting, Gmail and
Slack share the newest message, Calm shares the night state, and the pet and Calm read them.

## Settings

- `settings/display.json`: the display settings, from `GET /api/v1/settings`.
- `settings/apps.json`: the app order and the apps that are off.
- `settings/app-config.json`: the settings of each script. Secrets are not in this file.

## Put it on a clock

1. Install AWTRIX NG on the TC002 and switch on the web login.
2. Run:

    ```sh
    AWTRIX_HOST=192.168.x.x AWTRIX_USER=admin AWTRIX_PASS=... python3 tools/deploy.py
    ```

3. In the web UI, under **Apps → ⚙**:
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
