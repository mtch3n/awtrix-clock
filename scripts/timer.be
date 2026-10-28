# @name    Timer
# @desc    Countdown, Pomodoro and stopwatch. Stopped: push moves the selection (mode, minutes, seconds), turn changes it. Select starts and pauses, hold resets
# @display 52x16
# @config  mode   select "First mode" default=countdown options=countdown,pomodoro,stopwatch
# @config  start  number "Countdown" default=5 min=1 max=180 unit=min group="Countdown"
# @config  step   number "Knob step" default=1 min=1 max=30 unit=min group="Countdown"
# @config  work   number "Focus" default=25 min=5 max=90 unit=min group="Pomodoro"
# @config  short  number "Short break" default=5 min=1 max=30 unit=min group="Pomodoro"
# @config  long   number "Long break" default=15 min=5 max=60 unit=min group="Pomodoro"
# @config  focus  select "Focus icon" default=tomato options=tomato,target,flame,bulb,sprout group="Pomodoro"
# @config  rounds number "Rounds before a long break" default=4 min=2 max=8 group="Pomodoro"
# @config  auto   bool   "Start the next phase by itself" default=false group="Pomodoro"
# @config  tune   select "Ring tune" default=bells options=bells,chime,pips group="Sound"
# @config  ring   number "Ring for" default=60 min=5 max=600 unit=s group="Sound"
# @config  style  select "Digit style" default=compact options=compact,airy,bold,thin group="Digits"
# @config  size   select "Digit size" default=medium options=large,medium,small help="large 6x14, medium 5x12, small 5x10" group="Digits"
# @config  spacing select "Spacing" default=airy options=airy,tight group="Digits"
# @config  color  color  "Digits" default=#F2D7B6 group="Colors"
# @config  run    color  "Running" default=#C8643C group="Colors"
import blockfont

var MODES = ["countdown", "pomodoro", "stopwatch"]
var TUNES = {"bells": "bells:d=8,o=6,b=140:e,g,e,c,4p,e,g,e,c",
             "chime": "chime:d=4,o=5,b=100:e6,c6,d6,g,2p,g,d6,e6,c6",
             "pips": "pips:d=16,o=6,b=200:c,p,c,p,c,p,c"}
var RED = 0xD0503C
var GREEN = 0x6FAF6A
var CREAM = 0xE8DCCB
var BROWN = 0x8C7B6B
var DARK = 0x3A2E26
var AMBER = 0xE0A040
var TICONS = {"target": [11, 11, [[3, 0, 0xE0604A], [4, 0, 0xE0604A], [5, 0, 0xE0604A], [6, 0, 0xE0604A], [7, 0, 0xE0604A], [1, 1, 0xE0604A], [2, 1, 0xE0604A], [8, 1, 0xE0604A], [9, 1, 0xE0604A], [1, 2, 0xE0604A], [9, 2, 0x9A3424], [0, 3, 0xE0604A], [4, 3, 0xE8DCCB], [5, 3, 0xE8DCCB], [6, 3, 0xE8DCCB], [10, 3, 0x9A3424], [0, 4, 0xE0604A], [3, 4, 0xE8DCCB], [4, 4, 0xE0604A], [5, 4, 0xE0604A], [6, 4, 0xE0604A], [7, 4, 0xE8DCCB], [10, 4, 0x9A3424], [0, 5, 0xE0604A], [3, 5, 0xE8DCCB], [4, 5, 0xE0604A], [5, 5, 0xF09A80], [6, 5, 0xE0604A], [7, 5, 0xE8DCCB], [10, 5, 0x9A3424], [0, 6, 0xE0604A], [3, 6, 0xE8DCCB], [4, 6, 0xE0604A], [5, 6, 0xE0604A], [6, 6, 0xE0604A], [7, 6, 0xE8DCCB], [10, 6, 0x9A3424], [0, 7, 0xE0604A], [4, 7, 0xE8DCCB], [5, 7, 0xE8DCCB], [6, 7, 0xE8DCCB], [10, 7, 0x9A3424], [1, 8, 0xE0604A], [9, 8, 0x9A3424], [1, 9, 0x9A3424], [2, 9, 0xE0604A], [8, 9, 0x9A3424], [9, 9, 0x9A3424], [3, 10, 0x9A3424], [4, 10, 0x9A3424], [5, 10, 0x9A3424], [6, 10, 0x9A3424], [7, 10, 0x9A3424]]], "flame": [10, 12, [[4, 0, 0xE07030], [3, 1, 0xE07030], [4, 1, 0xE07030], [3, 2, 0xE07030], [4, 2, 0xE07030], [5, 2, 0xE07030], [2, 3, 0xE07030], [3, 3, 0xE07030], [4, 3, 0xE07030], [5, 3, 0xE07030], [7, 3, 0xE07030], [2, 4, 0xE07030], [3, 4, 0xE07030], [4, 4, 0xE07030], [5, 4, 0xE07030], [6, 4, 0xE07030], [7, 4, 0xE07030], [8, 4, 0xE07030], [1, 5, 0xE07030], [2, 5, 0xE07030], [3, 5, 0xE07030], [4, 5, 0xF0D070], [5, 5, 0xF0D070], [6, 5, 0xE07030], [7, 5, 0xE07030], [8, 5, 0x9A5426], [1, 6, 0xE07030], [2, 6, 0xE07030], [3, 6, 0xF0D070], [4, 6, 0xFFF4C0], [5, 6, 0xFFF4C0], [6, 6, 0xF0D070], [7, 6, 0xE07030], [8, 6, 0x9A5426], [0, 7, 0xE07030], [1, 7, 0xE07030], [2, 7, 0xE07030], [3, 7, 0xF0D070], [4, 7, 0xFFF4C0], [5, 7, 0xFFF4C0], [6, 7, 0xF0D070], [7, 7, 0xE07030], [8, 7, 0xE07030], [9, 7, 0x9A5426], [0, 8, 0xE07030], [1, 8, 0xE07030], [2, 8, 0xF0D070], [3, 8, 0xFFF4C0], [4, 8, 0xFFF4C0], [5, 8, 0xFFF4C0], [6, 8, 0xFFF4C0], [7, 8, 0xF0D070], [8, 8, 0xE07030], [9, 8, 0x9A5426], [0, 9, 0xE07030], [1, 9, 0xE07030], [2, 9, 0xF0D070], [3, 9, 0xFFF4C0], [4, 9, 0xFFF4C0], [5, 9, 0xFFF4C0], [6, 9, 0xFFF4C0], [7, 9, 0xF0D070], [8, 9, 0xE07030], [9, 9, 0x9A5426], [1, 10, 0x9A5426], [2, 10, 0xE07030], [3, 10, 0xF0D070], [4, 10, 0xFFF4C0], [5, 10, 0xFFF4C0], [6, 10, 0xF0D070], [7, 10, 0xE07030], [8, 10, 0x9A5426], [2, 11, 0x9A5426], [3, 11, 0x9A5426], [4, 11, 0x9A5426], [5, 11, 0x9A5426], [6, 11, 0x9A5426], [7, 11, 0x9A5426]]], "bulb": [9, 12, [[2, 0, 0xF0D070], [3, 0, 0xF0D070], [4, 0, 0xF0D070], [5, 0, 0xF0D070], [6, 0, 0xF0D070], [1, 1, 0xF0D070], [2, 1, 0xFFFFFF], [3, 1, 0xFFF4C0], [4, 1, 0xF0D070], [5, 1, 0xF0D070], [6, 1, 0xF0D070], [7, 1, 0xE0A040], [0, 2, 0xF0D070], [1, 2, 0xFFFFFF], [2, 2, 0xFFF4C0], [3, 2, 0xF0D070], [4, 2, 0xF0D070], [5, 2, 0xF0D070], [6, 2, 0xF0D070], [7, 2, 0xF0D070], [8, 2, 0xE0A040], [0, 3, 0xF0D070], [1, 3, 0xFFF4C0], [2, 3, 0xF0D070], [3, 3, 0xF0D070], [4, 3, 0xE0A040], [5, 3, 0xE0A040], [6, 3, 0xF0D070], [7, 3, 0xF0D070], [8, 3, 0xE0A040], [0, 4, 0xF0D070], [1, 4, 0xF0D070], [2, 4, 0xF0D070], [3, 4, 0xE0A040], [4, 4, 0xF0D070], [5, 4, 0xF0D070], [6, 4, 0xE0A040], [7, 4, 0xF0D070], [8, 4, 0xE0A040], [0, 5, 0xF0D070], [1, 5, 0xF0D070], [2, 5, 0xF0D070], [3, 5, 0xF0D070], [4, 5, 0xE0A040], [5, 5, 0xE0A040], [6, 5, 0xF0D070], [7, 5, 0xF0D070], [8, 5, 0xE0A040], [1, 6, 0xF0D070], [2, 6, 0xF0D070], [3, 6, 0xF0D070], [4, 6, 0xF0D070], [5, 6, 0xF0D070], [6, 6, 0xF0D070], [7, 6, 0xE0A040], [2, 7, 0xF0D070], [3, 7, 0xF0D070], [4, 7, 0xF0D070], [5, 7, 0xF0D070], [6, 7, 0xE0A040], [2, 8, 0xE8DCCB], [3, 8, 0xE8DCCB], [4, 8, 0xE8DCCB], [5, 8, 0xE8DCCB], [6, 8, 0x8A8074], [2, 9, 0x8A8074], [3, 9, 0x8A8074], [4, 9, 0x8A8074], [5, 9, 0x8A8074], [6, 9, 0x8A8074], [2, 10, 0xE8DCCB], [3, 10, 0xE8DCCB], [4, 10, 0xE8DCCB], [5, 10, 0xE8DCCB], [6, 10, 0x8A8074], [3, 11, 0x8A8074], [4, 11, 0x8A8074], [5, 11, 0x8A8074]]], "sprout": [9, 11, [[1, 0, 0x8ACF7A], [2, 0, 0x8ACF7A], [6, 0, 0x8ACF7A], [7, 0, 0x8ACF7A], [0, 1, 0x8ACF7A], [1, 1, 0x8ACF7A], [2, 1, 0x8ACF7A], [3, 1, 0x4F8F42], [5, 1, 0x8ACF7A], [6, 1, 0x8ACF7A], [7, 1, 0x8ACF7A], [8, 1, 0x4F8F42], [0, 2, 0x8ACF7A], [1, 2, 0x8ACF7A], [2, 2, 0x4F8F42], [3, 2, 0x4F8F42], [4, 2, 0x2F5F2A], [5, 2, 0x4F8F42], [6, 2, 0x4F8F42], [7, 2, 0x4F8F42], [8, 2, 0x2F5F2A], [1, 3, 0x4F8F42], [2, 3, 0x4F8F42], [3, 3, 0x2F5F2A], [4, 3, 0x2F5F2A], [5, 3, 0x2F5F2A], [6, 3, 0x4F8F42], [7, 3, 0x4F8F42], [4, 4, 0x2F5F2A], [4, 5, 0x2F5F2A], [0, 6, 0xE08A50], [1, 6, 0xE08A50], [2, 6, 0xE08A50], [3, 6, 0xE08A50], [4, 6, 0xE08A50], [5, 6, 0xE08A50], [6, 6, 0xE08A50], [7, 6, 0xE08A50], [8, 6, 0x9A5426], [0, 7, 0xE08A50], [1, 7, 0xE08A50], [2, 7, 0xE08A50], [3, 7, 0xE08A50], [4, 7, 0xE08A50], [5, 7, 0xE08A50], [6, 7, 0xE08A50], [7, 7, 0xE08A50], [8, 7, 0x9A5426], [1, 8, 0xE08A50], [2, 8, 0xE08A50], [3, 8, 0xE08A50], [4, 8, 0xE08A50], [5, 8, 0xE08A50], [6, 8, 0xE08A50], [7, 8, 0x9A5426], [1, 9, 0xE08A50], [2, 9, 0xE08A50], [3, 9, 0xE08A50], [4, 9, 0xE08A50], [5, 9, 0xE08A50], [6, 9, 0x9A5426], [7, 9, 0x9A5426], [2, 10, 0x9A5426], [3, 10, 0x9A5426], [4, 10, 0x9A5426], [5, 10, 0x9A5426], [6, 10, 0x9A5426]]], "cup": [9, 11, [[2, 0, 0x8A8074], [5, 0, 0x8A8074], [3, 1, 0x8A8074], [6, 1, 0x8A8074], [2, 2, 0x8A8074], [5, 2, 0x8A8074], [0, 4, 0xF6F0E6], [1, 4, 0xE0D6C6], [2, 4, 0xE0D6C6], [3, 4, 0xE0D6C6], [4, 4, 0xE0D6C6], [5, 4, 0xE0D6C6], [6, 4, 0x958B80], [0, 5, 0xF6F0E6], [1, 5, 0xE0D6C6], [2, 5, 0xE0D6C6], [3, 5, 0xE0D6C6], [4, 5, 0xE0D6C6], [5, 5, 0xE0D6C6], [6, 5, 0x958B80], [7, 5, 0x958B80], [8, 5, 0x958B80], [0, 6, 0xF6F0E6], [1, 6, 0xE0D6C6], [2, 6, 0xE0D6C6], [3, 6, 0xE0D6C6], [4, 6, 0xE0D6C6], [5, 6, 0xE0D6C6], [6, 6, 0x958B80], [8, 6, 0x958B80], [0, 7, 0xF6F0E6], [1, 7, 0xE0D6C6], [2, 7, 0xE0D6C6], [3, 7, 0xE0D6C6], [4, 7, 0xE0D6C6], [5, 7, 0xE0D6C6], [6, 7, 0x958B80], [8, 7, 0x958B80], [0, 8, 0xF6F0E6], [1, 8, 0xE0D6C6], [2, 8, 0xE0D6C6], [3, 8, 0xE0D6C6], [4, 8, 0xE0D6C6], [5, 8, 0xE0D6C6], [6, 8, 0x958B80], [7, 8, 0x958B80], [8, 8, 0x958B80], [0, 9, 0xF6F0E6], [1, 9, 0xE0D6C6], [2, 9, 0xE0D6C6], [3, 9, 0xE0D6C6], [4, 9, 0xE0D6C6], [5, 9, 0xE0D6C6], [6, 9, 0x958B80], [1, 10, 0x958B80], [2, 10, 0x958B80], [3, 10, 0x958B80], [4, 10, 0x958B80], [5, 10, 0x958B80]]]}
var DIAL = [[0, -5, 0, 0, 100], [0, -4, 0, 1, 100], [0, -3, 0, 1, 100], [0, -2, 0, 1, 100], [0, -1, 0, 1, 100], [0, 0, 0, 1, 100], [1, -5, 11, 0, 89], [1, -4, 14, 1, 100], [1, -3, 18, 1, 100], [2, -5, 21, 0, 60], [2, -4, 26, 1, 100], [1, -2, 26, 1, 100], [2, -3, 33, 1, 100], [3, -4, 36, 0, 100], [4, -4, 45, 0, 22], [3, -3, 45, 1, 100], [2, -2, 45, 1, 100], [1, -1, 45, 1, 100], [4, -3, 53, 0, 100], [3, -2, 56, 1, 100], [4, -2, 63, 1, 100], [2, -1, 63, 1, 100], [5, -2, 68, 0, 60], [3, -1, 71, 1, 100], [4, -1, 75, 1, 100], [5, -1, 78, 0, 89], [1, 0, 90, 1, 100], [2, 0, 90, 1, 100], [3, 0, 90, 1, 100], [4, 0, 90, 1, 100], [5, 0, 90, 0, 100], [5, 1, 101, 0, 89], [4, 1, 104, 1, 100], [3, 1, 108, 1, 100], [5, 2, 111, 0, 60], [2, 1, 116, 1, 100], [4, 2, 116, 1, 100], [3, 2, 123, 1, 100], [4, 3, 126, 0, 100], [1, 1, 135, 1, 100], [2, 2, 135, 1, 100], [3, 3, 135, 1, 100], [4, 4, 135, 0, 22], [3, 4, 143, 0, 100], [2, 3, 146, 1, 100], [1, 2, 153, 1, 100], [2, 4, 153, 1, 100], [2, 5, 158, 0, 60], [1, 3, 161, 1, 100], [1, 4, 165, 1, 100], [1, 5, 168, 0, 89], [0, 1, 180, 1, 100], [0, 2, 180, 1, 100], [0, 3, 180, 1, 100], [0, 4, 180, 1, 100], [0, 5, 180, 0, 100], [-1, 5, 191, 0, 89], [-1, 4, 194, 1, 100], [-1, 3, 198, 1, 100], [-2, 5, 201, 0, 60], [-1, 2, 206, 1, 100], [-2, 4, 206, 1, 100], [-2, 3, 213, 1, 100], [-3, 4, 216, 0, 100], [-1, 1, 225, 1, 100], [-2, 2, 225, 1, 100], [-3, 3, 225, 1, 100], [-4, 4, 225, 0, 22], [-4, 3, 233, 0, 100], [-3, 2, 236, 1, 100], [-2, 1, 243, 1, 100], [-4, 2, 243, 1, 100], [-5, 2, 248, 0, 60], [-3, 1, 251, 1, 100], [-4, 1, 255, 1, 100], [-5, 1, 258, 0, 89], [-5, 0, 270, 0, 100], [-4, 0, 270, 1, 100], [-3, 0, 270, 1, 100], [-2, 0, 270, 1, 100], [-1, 0, 270, 1, 100], [-5, -1, 281, 0, 89], [-4, -1, 284, 1, 100], [-3, -1, 288, 1, 100], [-5, -2, 291, 0, 60], [-4, -2, 296, 1, 100], [-2, -1, 296, 1, 100], [-3, -2, 303, 1, 100], [-4, -3, 306, 0, 100], [-4, -4, 315, 0, 22], [-3, -3, 315, 1, 100], [-2, -2, 315, 1, 100], [-1, -1, 315, 1, 100], [-3, -4, 323, 0, 100], [-2, -3, 326, 1, 100], [-2, -4, 333, 1, 100], [-1, -2, 333, 1, 100], [-2, -5, 338, 0, 60], [-1, -3, 341, 1, 100], [-1, -4, 345, 1, 100], [-1, -5, 348, 0, 89]]
var TOMATO = [[-2, -5, 0x905143], [-1, -5, 0xD77A64], [0, -5, 0xF08870], [1, -5, 0xBB4835], [2, -5, 0x7C3024], [-4, -4, 0x351E19], [-3, -4, 0xF08870], [-2, -4, 0xF08870], [-1, -4, 0xF08870], [0, -4, 0xD0503C], [1, -4, 0xD0503C], [2, -4, 0xD0503C], [3, -4, 0xD0503C], [4, -4, 0x2E120D], [-4, -3, 0xF08870], [-3, -3, 0xF08870], [-2, -3, 0xF08870], [-1, -3, 0xD0503C], [0, -3, 0xD0503C], [1, -3, 0xD0503C], [2, -3, 0xD0503C], [3, -3, 0xD0503C], [4, -3, 0xD0503C], [-5, -2, 0x905143], [-4, -2, 0xF08870], [-3, -2, 0xF08870], [-2, -2, 0xD0503C], [-1, -2, 0xD0503C], [0, -2, 0xD0503C], [1, -2, 0xD0503C], [2, -2, 0xD0503C], [3, -2, 0xD0503C], [4, -2, 0xD0503C], [5, -2, 0x7C3024], [-5, -1, 0xD77A64], [-4, -1, 0xF08870], [-3, -1, 0xD0503C], [-2, -1, 0xD0503C], [-1, -1, 0xD0503C], [0, -1, 0xD0503C], [1, -1, 0xD0503C], [2, -1, 0xD0503C], [3, -1, 0xD0503C], [4, -1, 0xD0503C], [5, -1, 0xBB4835], [-5, 0, 0xF08870], [-4, 0, 0xD0503C], [-3, 0, 0xD0503C], [-2, 0, 0xD0503C], [-1, 0, 0xD0503C], [0, 0, 0xD0503C], [1, 0, 0xD0503C], [2, 0, 0xD0503C], [3, 0, 0xD0503C], [4, 0, 0xD0503C], [5, 0, 0x9A3424], [-5, 1, 0xBB4835], [-4, 1, 0xD0503C], [-3, 1, 0xD0503C], [-2, 1, 0xD0503C], [-1, 1, 0xD0503C], [0, 1, 0xD0503C], [1, 1, 0xD0503C], [2, 1, 0xD0503C], [3, 1, 0xD0503C], [4, 1, 0x9A3424], [5, 1, 0x8A2E20], [-5, 2, 0x7C3024], [-4, 2, 0xD0503C], [-3, 2, 0xD0503C], [-2, 2, 0xD0503C], [-1, 2, 0xD0503C], [0, 2, 0xD0503C], [1, 2, 0xD0503C], [2, 2, 0xD0503C], [3, 2, 0x9A3424], [4, 2, 0x9A3424], [5, 2, 0x5C1F15], [-4, 3, 0xD0503C], [-3, 3, 0xD0503C], [-2, 3, 0xD0503C], [-1, 3, 0xD0503C], [0, 3, 0xD0503C], [1, 3, 0xD0503C], [2, 3, 0x9A3424], [3, 3, 0x9A3424], [4, 3, 0x9A3424], [-4, 4, 0x2E120D], [-3, 4, 0xD0503C], [-2, 4, 0xD0503C], [-1, 4, 0xD0503C], [0, 4, 0xD0503C], [1, 4, 0x9A3424], [2, 4, 0x9A3424], [3, 4, 0x9A3424], [4, 4, 0x220B08], [-2, 5, 0x7C3024], [-1, 5, 0xBB4835], [0, 5, 0x9A3424], [1, 5, 0x8A2E20], [2, 5, 0x5C1F15]]

class Timer
  var mode, set_s, end_ms, left_ms, started_ms, elapsed_ms, ringing, ring_until, last_tone, phase, round, field

  def init()
    self.mode = store.get("last_mode", store.get("mode", "countdown"))
    self.ringing = false
    self.ring_until = 0
    self.last_tone = 0
    self.reset()
  end

  def reset()
    self.end_ms = 0
    self.left_ms = 0
    self.started_ms = 0
    self.elapsed_ms = 0
    self.phase = "work"
    self.round = 1
    self.field = self.mode == "countdown" ? "min" : "mode"
    self.set_s = self.mode == "pomodoro" ? store.get("work", 25) * 60 : store.get("start", 5) * 60
  end

  def running()
    return self.end_ms > 0 || self.started_ms > 0
  end

  def remaining()
    if self.end_ms > 0 return max(self.end_ms - now_ms(), 0) end
    if self.left_ms > 0 return self.left_ms end
    return self.set_s * 1000
  end

  def elapsed()
    return self.elapsed_ms + (self.started_ms > 0 ? now_ms() - self.started_ms : 0)
  end

  def phase_len()
    if self.phase == "work" return store.get("work", 25) * 60 end
    if self.phase == "long" return store.get("long", 15) * 60 end
    return store.get("short", 5) * 60
  end

  def loop()
    if self.end_ms > 0 && now_ms() >= self.end_ms self.finish() end
    if self.ringing
      if now_ms() > self.ring_until
        self.stop_ring()
      elif now_ms() - self.last_tone > 3500
        self.last_tone = now_ms()
        sound.play({'rtttl': TUNES.find(store.get("tune", "bells"), TUNES["bells"])})
      end
    end
  end

  def finish()
    self.end_ms = 0
    self.left_ms = 0
    if self.mode == "pomodoro"
      var was = self.phase
      if was == "work"
        self.phase = self.round >= store.get("rounds", 4) ? "long" : "short"
      else
        self.phase = "work"
        self.round = was == "long" ? 1 : self.round + 1
      end
      self.set_s = self.phase_len()
      notify({"name": "timer", "text": self.phase == "work" ? "Back to focus" : "Time for a break", "textColor": "#E0A040", "durationMs": 5000, "wakeup": true})
      if store.get("auto", false)
        sound.play({'rtttl': TUNES["chime"]})
        self.end_ms = now_ms() + self.set_s * 1000
        rotation.show()
        return
      end
    else
      notify({"name": "timer", "text": "Time is up", "textColor": "#E0A040", "durationMs": 6000, "wakeup": true})
    end
    self.ringing = true
    self.ring_until = now_ms() + store.get("ring", 60) * 1000
    rotation.show()
    rotation.pause()
  end

  def stop_ring()
    self.ringing = false
    sound.stop()
    rotation.resume()
  end

  def toggle()
    if self.mode == "stopwatch"
      if self.started_ms > 0
        self.elapsed_ms = self.elapsed()
        self.started_ms = 0
      else
        self.started_ms = now_ms()
      end
      return
    end
    if self.end_ms > 0
      self.left_ms = self.remaining()
      self.end_ms = 0
    else
      self.end_ms = now_ms() + self.remaining()
      self.left_ms = 0
    end
  end

  def on_knob(event)
    if self.ringing
      self.stop_ring()
      return true
    end
    var editing = !self.running() && self.left_ms == 0 && self.elapsed_ms == 0
    var fields = self.mode == "countdown" ? ["mode", "min", "sec"] : (self.mode == "pomodoro" ? ["mode", "min", "brk", "long"] : ["mode"])
    if event == "press" && editing
      self.field = fields[((fields.find(self.field) == nil ? 0 : fields.find(self.field)) + 1) % size(fields)]
    elif event == "press"
      self.toggle()
    elif (event == "left" || event == "right") && editing && self.field == "mode"
      var i = MODES.find(self.mode)
      self.mode = MODES[(i + (event == "right" ? 1 : 2)) % 3]
      store.set("last_mode", self.mode)
      self.reset()
      self.field = "mode"
    elif event == "long"
      self.reset()
      self.field = "mode"
    elif (event == "left" || event == "right") && editing && self.mode == "pomodoro" && (self.field == "brk" || self.field == "long")
      var key = self.field == "brk" ? "short" : "long"
      var v = store.get(key, self.field == "brk" ? 5 : 15) + (event == "right" ? 1 : -1)
      store.set(key, min(max(v, 1), 60))
    elif (event == "left" || event == "right") && editing && self.mode == "pomodoro" && self.field == "min"
      var v = store.get("work", 25) + (event == "right" ? 1 : -1)
      store.set("work", min(max(v, 5), 90))
      self.set_s = store.get("work") * 60
    elif (event == "left" || event == "right") && editing && self.field == "sec" && self.mode == "countdown"
      var m = self.set_s / 60
      var sec = (self.set_s % 60 + (event == "right" ? 1 : 59)) % 60
      self.set_s = max(m * 60 + sec, 5)
    elif (event == "left" || event == "right") && !self.running() && self.mode != "stopwatch"
      var step = self.mode == "pomodoro" ? 60 : store.get("step", 1) * 60
      var base = self.left_ms > 0 ? (self.left_ms + 999) / 1000 : self.set_s
      self.set_s = min(max(base + (event == "right" ? step : -step), self.mode == "pomodoro" ? 60 : 5), 180 * 60)
      self.left_ms = 0
    end
    return true
  end

  def on_button(btn)
    if btn != "select" return false end
    if self.ringing self.stop_ring() else self.toggle() end
    return true
  end

  def hourglass(x, y, h, c, left, t, running)
    var m = y + h / 2
    rect_fill(x, y, 9, 1, 0xC8A070)
    rect_fill(x, y + h - 1, 9, 1, 0x7A5A34)
    line(x + 1, y + 1, x + 4, m, 0x8A8074)
    line(x + 7, y + 1, x + 4, m, 0x8A8074)
    line(x + 4, m, x + 1, y + h - 2, 0x8A8074)
    line(x + 4, m, x + 7, y + h - 2, 0x8A8074)
    var top = m - y - 1
    var bot = y + h - 2 - m
    var n = (left * top + 99) / 100
    for i : 0 .. n - 1
      var r = m - 1 - i
      var wl = x + 1 + (r - y - 1) * 3 / max(top, 1)
      if wl + 1 <= 2 * (x + 4) - wl - 1 rect_fill(wl + 1, r, 2 * (x + 4) - 2 * wl - 1, 1, AMBER) end
    end
    var nb = ((100 - left) * bot) / 100
    for i : 0 .. nb - 1
      var r = y + h - 2 - i
      var wl = x + 4 - (r - m) * 3 / max(bot, 1)
      if wl + 1 <= 2 * (x + 4) - wl - 1 rect_fill(wl + 1, r, 2 * (x + 4) - 2 * wl - 1, 1, AMBER) end
    end
    if running && left > 0 pixel(x + 4, m + (t / 150) % 3, AMBER) end
  end

  def scaled(c, k)
    return ((((c >> 16) & 255) * k / 100) << 16) | ((((c >> 8) & 255) * k / 100) << 8) | ((c & 255) * k / 100)
  end

  def ticon(name, x, y)
    var ic = TICONS[name]
    for p : ic[2]
      pixel(x + p[0], y + p[1], p[2])
    end
  end

  def focus_icon(x, y, h, t, running)
    var name = store.get("focus", "tomato")
    var top = y + (h - 12) / 2
    if name == "tomato"
      for cell : TOMATO
        pixel(x + 5 + cell[0], top + 6 + cell[1], cell[2])
      end
      var sway = running && (t / 500) % 2 == 1 ? 1 : 0
      pixel(x + 5 + sway, top, 0x6FAF6A)
      rect_fill(x + 3 + sway, top + 1, 5, 1, 0x6FAF6A)
      pixel(x + 5, top + 1, 0x3F7F3A)
      return
    end
    if !TICONS.contains(name) name = "target" end
    var ic = TICONS[name]
    var bob = running && (t / 500) % 2 == 1 ? 1 : 0
    self.ticon(name, x + (11 - ic[0]) / 2, top + 12 - ic[1] - bob)
  end

  def cup(x, y, h, t, running)
    var ic = TICONS["cup"]
    var top = y + h - ic[1]
    self.ticon("cup", x + 1, top)
    if running
      for i : 0 .. 1
        var k = (t / 250 + i * 2) % 3
        pixel(x + 3 + i * 3 + k % 2, top + 2 - k, 0)
      end
    end
  end

  def stopwatch(x, y, h, c, ms)
    var top = y + (h - 12) / 2
    rect_fill(x + 4, top, 3, 1, CREAM)
    pixel(x + 5, top + 1, 0x958B80)
    pixel(x + 9, top + 2, 0x958B80)
    var deg = ms > 0 ? (ms % 60000) * 360 / 60000 : -1
    for cell : DIAL
      var col = 0x958B80
      if cell[3] == 1
        col = cell[2] <= deg ? AMBER : (cell[0] + cell[1] < 3 ? CREAM : 0xCFC3B2)
      end
      pixel(x + 5 + cell[0], top + 7 + cell[1], self.scaled(col, cell[4]))
    end
  end

  def draw()
    clear()
    var t = now_ms()
    var dsize = store.get("size", "medium")
    var dh = dsize == "large" ? 14 : (dsize == "small" ? 10 : 12)
    var dy = (16 - dh) / 2
    var hide_icon = self.field == "mode" && !self.running() && self.left_ms == 0 && self.elapsed_ms == 0 && !self.ringing && (t / 400) % 3 == 0
    var label
    var progress = -1
    if self.mode == "stopwatch"
      var s = self.elapsed() / 1000
      label = s >= 6000 ? format("%d:%02d", s / 3600, s % 3600 / 60) : format("%02d:%02d", s / 60, s % 60)
      if !hide_icon self.stopwatch(2, dy, dh, CREAM, self.elapsed()) end
    else
      var secs = (self.remaining() + 999) / 1000
      label = secs >= 6000 ? format("%d:%02d", secs / 3600, secs % 3600 / 60) : format("%02d:%02d", secs / 60, secs % 60)
      if self.running() || self.left_ms > 0 progress = (self.set_s * 1000 - self.remaining()) * 100 / max(self.set_s * 1000, 1) end
      if self.mode == "pomodoro"
        var edit_brk = !self.running() && self.left_ms == 0 && (self.field == "brk" || self.field == "long")
        if edit_brk
          secs = store.get(self.field == "brk" ? "short" : "long", 5) * 60
          label = format("%02d:00", secs / 60)
        end
        if hide_icon
        elif self.phase == "work" && !edit_brk self.focus_icon(2, dy, dh, t, self.running())
        else self.cup(3, dy, dh, t, self.running())
        end
        var n = store.get("rounds", 4)
        for i : 1 .. n
          var lit = i < self.round || (i == self.round && self.phase != "work") || (edit_brk && self.field == "long")
          pixel(8 - n + i * 2, 15, lit ? AMBER : DARK)
        end
      else
        if !hide_icon self.hourglass(3, dy, dh, CREAM, self.remaining() * 100 / max(self.set_s * 1000, 1), t, self.running()) end
      end
    end
    var c = self.running() ? store.get("run", 0xC8643C) : store.get("color", 0xF2D7B6)
    if self.ringing
      c = (t / 300) % 2 == 0 ? AMBER : DARK
      label = "00:00"
    end
    var st = blockfont.style(store.get("style", "compact"))
    var dw = st[0]
    var gap = store.get("spacing", "airy") == "airy" ? 2 : 1
    var w = blockfont.width(label, dw, gap)
    var x = width() - w - 2
    var paused = !self.running() && (self.left_ms > 0 || self.elapsed_ms > 0)
    blockfont.text(label, x, (16 - dh) / 2, c, st[1], st[2], !paused || (t / 500) % 2 == 0, dw, dh, gap)
    if progress >= 0 rect_fill(x, 15, progress * w / 100, 1, BROWN) end
    if !self.running() && self.left_ms == 0 && self.elapsed_ms == 0 && !self.ringing
      var on = (t / 400) % 3 == 0 ? DARK : 0xF2D7B6
      if self.field != "mode" && size(label) == 5 && self.mode != "stopwatch"
        rect_fill(self.field == "sec" ? x + 2 * dw + 3 * gap + 2 : x, 15, 2 * dw + gap, 1, on)
      end
    end
  end
end

return Timer()
