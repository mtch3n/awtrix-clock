# @name    Clock
# @desc    Block-digit clock with weather, alerts and many settings. Turn the knob for date, weather and alerts
# @display 52x16
# @config  layout  select "Layout" default=weather options=weather,hm,hms help="weather: weather left and HH:MM. hm: HH:MM only. hms: HH:MM:SS" group="Layout"
# @config  left    select "Left side" default=icon options=icon,both,temp help="Only for the weather layout" group="Layout"
# @config  size    select "Digit size" default=medium options=large,medium,small help="large 6x14, medium 5x12, small 5x10" group="Digits"
# @config  spacing select "Spacing" default=airy options=airy,tight group="Digits"
# @config  style   select "Digit style" default=compact options=compact,airy,bold,thin help="airy: thin sides, bold bars. compact: 5 wide" group="Digits"
# @config  hours   select "Hours" default=auto options=auto,24,12 help="auto follows the clock's 24-hour setting" group="Digits"
# @config  zero    bool   "Leading zero" default=true group="Digits"
# @config  colon   select "Colon" default=steady options=steady,blink group="Digits"
# @config  secbar  bool   "Seconds line" default=false help="A thin line on top that fills each minute" group="Digits"
# @config  bar     bool   "Weekday bar" default=true group="Extras"
# @config  overlay bool   "Weather overlay" default=false help="Rain, snow, thunder and more on the clock face" group="Extras"
# @config  mark    bool   "Alert mark" default=true help="A small triangle while Environment Canada has an alert" group="Extras"
# @config  pagesec number "Pages stay" default=8 min=3 max=60 unit=s help="After a knob turn, then back to the time" group="Extras"
# @config  retro   select "Retro" default=off options=off,nixie,vfd,crt help="nixie: orange glow. vfd: cyan glow and ghost segments. crt: amber glow and scan lines" group="Retro"
# @config  glow    slider "Glow" default=25 min=0 max=60 unit=% group="Retro"
# @config  color   color  "Digits" default=#F2D7B6 group="Colors"
# @config  temp    color  "Temperature" default=#E8DCCB group="Colors"
# @config  today   color  "Today" default=#C8643C group="Colors"
# @config  other   color  "Other days" default=#3A2E26 group="Colors"
# @config  sec     color  "Seconds line" default=#8C7B6B group="Colors"
import blockfont

var DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
var MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
var AMBER = 0xE0A040
var WICONS = {"sun": [13, 13, [[4, 3, 0x937E49], [5, 3, 0xF6D27A], [6, 3, 0xF6D27A], [7, 3, 0xF6D27A], [8, 3, 0x866026], [3, 4, 0x937E49], [4, 4, 0xF6D27A], [5, 4, 0xF6D27A], [6, 4, 0xF6D27A], [7, 4, 0xE0A040], [8, 4, 0xE0A040], [9, 4, 0x866026], [3, 5, 0xF6D27A], [4, 5, 0xF6D27A], [5, 5, 0xF6D27A], [6, 5, 0xE0A040], [7, 5, 0xE0A040], [8, 5, 0xE0A040], [9, 5, 0xE0A040], [3, 6, 0xF6D27A], [4, 6, 0xF6D27A], [5, 6, 0xE0A040], [6, 6, 0xE0A040], [7, 6, 0xE0A040], [8, 6, 0xE0A040], [9, 6, 0xB8742A], [3, 7, 0xF6D27A], [4, 7, 0xE0A040], [5, 7, 0xE0A040], [6, 7, 0xE0A040], [7, 7, 0xE0A040], [8, 7, 0xB8742A], [9, 7, 0xB8742A], [3, 8, 0x866026], [4, 8, 0xE0A040], [5, 8, 0xE0A040], [6, 8, 0xE0A040], [7, 8, 0xB8742A], [8, 8, 0xB8742A], [9, 8, 0x6E4519], [4, 9, 0x866026], [5, 9, 0xE0A040], [6, 9, 0xB8742A], [7, 9, 0xB8742A], [8, 9, 0x6E4519], [6, 1, 0xE0A040], [6, 0, 0xB8742A], [11, 6, 0xE0A040], [12, 6, 0xB8742A], [6, 11, 0xE0A040], [6, 12, 0xB8742A], [1, 6, 0xE0A040], [0, 6, 0xB8742A], [10, 2, 0xE0A040], [11, 1, 0xB8742A], [10, 10, 0xE0A040], [11, 11, 0xB8742A], [2, 10, 0xE0A040], [1, 11, 0xB8742A], [2, 2, 0xE0A040], [1, 1, 0xB8742A]]], "moon": [10, 11, [[4, 0, 0x635F58], [2, 1, 0x9E998D], [3, 1, 0xF4ECDA], [4, 1, 0x4F4C46], [1, 2, 0x9E998D], [2, 2, 0xF4ECDA], [3, 2, 0xF4ECDA], [1, 3, 0xF4ECDA], [2, 3, 0xF4ECDA], [3, 3, 0xEDE6D4], [0, 4, 0x76736A], [1, 4, 0xF4ECDA], [2, 4, 0xF4ECDA], [3, 4, 0xEDE6D4], [0, 5, 0x9E998D], [1, 5, 0xF4ECDA], [2, 5, 0xF4ECDA], [3, 5, 0xF4ECDA], [0, 6, 0x76736A], [1, 6, 0xF4ECDA], [2, 6, 0xF4ECDA], [3, 6, 0xF4ECDA], [4, 6, 0xDAD2C2], [1, 7, 0xF4ECDA], [2, 7, 0xF4ECDA], [3, 7, 0xF4ECDA], [4, 7, 0xF4ECDA], [5, 7, 0xD2C6B1], [1, 8, 0x9E998D], [2, 8, 0xF4ECDA], [3, 8, 0xF4ECDA], [4, 8, 0xD8CCB6], [5, 8, 0xD8CCB6], [6, 8, 0xD8CCB6], [7, 8, 0xD8CCB6], [8, 8, 0xD8CCB6], [9, 8, 0x8C8476], [2, 9, 0x9E998D], [3, 9, 0xD8CCB6], [4, 9, 0xD8CCB6], [5, 9, 0xD8CCB6], [6, 9, 0xD8CCB6], [7, 9, 0xD8CCB6], [8, 9, 0x8C8476], [4, 10, 0x696358], [5, 10, 0x8C8476], [6, 10, 0x696358]]], "partly": [12, 8, [[8, 0, 0xF6D27A], [9, 0, 0xF6D27A], [10, 0, 0xE0A040], [7, 1, 0xF6D27A], [8, 1, 0xF6D27A], [9, 1, 0xE0A040], [10, 1, 0xE0A040], [11, 1, 0xB8742A], [4, 2, 0xF6F0E6], [5, 2, 0xF6F0E6], [6, 2, 0xF6F0E6], [7, 2, 0xF6F0E6], [8, 2, 0xE0A040], [9, 2, 0xE0A040], [10, 2, 0xB8742A], [11, 2, 0xB8742A], [2, 3, 0xF6F0E6], [3, 3, 0xF6F0E6], [4, 3, 0xE0D6C6], [5, 3, 0xE0D6C6], [6, 3, 0xE0D6C6], [7, 3, 0xE0D6C6], [8, 3, 0xF6F0E6], [9, 3, 0xF6F0E6], [10, 3, 0xB8742A], [1, 4, 0xF6F0E6], [2, 4, 0xE0D6C6], [3, 4, 0xE0D6C6], [4, 4, 0xE0D6C6], [5, 4, 0xE0D6C6], [6, 4, 0xE0D6C6], [7, 4, 0xE0D6C6], [8, 4, 0xE0D6C6], [9, 4, 0xE0D6C6], [10, 4, 0x958B80], [0, 5, 0xF6F0E6], [1, 5, 0xE0D6C6], [2, 5, 0xE0D6C6], [3, 5, 0xE0D6C6], [4, 5, 0xE0D6C6], [5, 5, 0xE0D6C6], [6, 5, 0xE0D6C6], [7, 5, 0xE0D6C6], [8, 5, 0xE0D6C6], [9, 5, 0xE0D6C6], [10, 5, 0x958B80], [11, 5, 0x958B80], [0, 6, 0xE0D6C6], [1, 6, 0xE0D6C6], [2, 6, 0xE0D6C6], [3, 6, 0xE0D6C6], [4, 6, 0xE0D6C6], [5, 6, 0xE0D6C6], [6, 6, 0xE0D6C6], [7, 6, 0xE0D6C6], [8, 6, 0xE0D6C6], [9, 6, 0xE0D6C6], [10, 6, 0xE0D6C6], [11, 6, 0x958B80], [1, 7, 0x958B80], [2, 7, 0x958B80], [3, 7, 0x958B80], [4, 7, 0x958B80], [5, 7, 0x958B80], [6, 7, 0x958B80], [7, 7, 0x958B80], [8, 7, 0x958B80], [9, 7, 0x958B80], [10, 7, 0x958B80]]], "cloud": [12, 6, [[4, 0, 0xF6F0E6], [5, 0, 0xF6F0E6], [6, 0, 0xF6F0E6], [7, 0, 0xF6F0E6], [2, 1, 0xF6F0E6], [3, 1, 0xF6F0E6], [4, 1, 0xE0D6C6], [5, 1, 0xE0D6C6], [6, 1, 0xE0D6C6], [7, 1, 0xE0D6C6], [8, 1, 0xF6F0E6], [9, 1, 0xF6F0E6], [1, 2, 0xF6F0E6], [2, 2, 0xE0D6C6], [3, 2, 0xE0D6C6], [4, 2, 0xE0D6C6], [5, 2, 0xE0D6C6], [6, 2, 0xE0D6C6], [7, 2, 0xE0D6C6], [8, 2, 0xE0D6C6], [9, 2, 0xE0D6C6], [10, 2, 0x958B80], [0, 3, 0xF6F0E6], [1, 3, 0xE0D6C6], [2, 3, 0xE0D6C6], [3, 3, 0xE0D6C6], [4, 3, 0xE0D6C6], [5, 3, 0xE0D6C6], [6, 3, 0xE0D6C6], [7, 3, 0xE0D6C6], [8, 3, 0xE0D6C6], [9, 3, 0xE0D6C6], [10, 3, 0x958B80], [11, 3, 0x958B80], [0, 4, 0xE0D6C6], [1, 4, 0xE0D6C6], [2, 4, 0xE0D6C6], [3, 4, 0xE0D6C6], [4, 4, 0xE0D6C6], [5, 4, 0xE0D6C6], [6, 4, 0xE0D6C6], [7, 4, 0xE0D6C6], [8, 4, 0xE0D6C6], [9, 4, 0xE0D6C6], [10, 4, 0xE0D6C6], [11, 4, 0x958B80], [1, 5, 0x958B80], [2, 5, 0x958B80], [3, 5, 0x958B80], [4, 5, 0x958B80], [5, 5, 0x958B80], [6, 5, 0x958B80], [7, 5, 0x958B80], [8, 5, 0x958B80], [9, 5, 0x958B80], [10, 5, 0x958B80]]], "rain": [12, 10, [[4, 0, 0xC8C0B6], [5, 0, 0xC8C0B6], [6, 0, 0xC8C0B6], [7, 0, 0xC8C0B6], [2, 1, 0xC8C0B6], [3, 1, 0xC8C0B6], [4, 1, 0xA49C92], [5, 1, 0xA49C92], [6, 1, 0xA49C92], [7, 1, 0xA49C92], [8, 1, 0xC8C0B6], [9, 1, 0xC8C0B6], [1, 2, 0xC8C0B6], [2, 2, 0xA49C92], [3, 2, 0xA49C92], [4, 2, 0xA49C92], [5, 2, 0xA49C92], [6, 2, 0xA49C92], [7, 2, 0xA49C92], [8, 2, 0xA49C92], [9, 2, 0xA49C92], [10, 2, 0x6A645D], [0, 3, 0xC8C0B6], [1, 3, 0xA49C92], [2, 3, 0xA49C92], [3, 3, 0xA49C92], [4, 3, 0xA49C92], [5, 3, 0xA49C92], [6, 3, 0xA49C92], [7, 3, 0xA49C92], [8, 3, 0xA49C92], [9, 3, 0xA49C92], [10, 3, 0x6A645D], [11, 3, 0x6A645D], [0, 4, 0xA49C92], [1, 4, 0xA49C92], [2, 4, 0xA49C92], [3, 4, 0xA49C92], [4, 4, 0xA49C92], [5, 4, 0xA49C92], [6, 4, 0xA49C92], [7, 4, 0xA49C92], [8, 4, 0xA49C92], [9, 4, 0xA49C92], [10, 4, 0xA49C92], [11, 4, 0x6A645D], [1, 5, 0x6A645D], [2, 5, 0x6A645D], [3, 5, 0x6A645D], [4, 5, 0x6A645D], [5, 5, 0x6A645D], [6, 5, 0x6A645D], [7, 5, 0x6A645D], [8, 5, 0x6A645D], [9, 5, 0x6A645D], [10, 5, 0x6A645D], [2, 7, 0x8CC4F0], [6, 7, 0x8CC4F0], [10, 7, 0x8CC4F0], [1, 8, 0x8CC4F0], [2, 8, 0x3E6A94], [5, 8, 0x8CC4F0], [6, 8, 0x3E6A94], [9, 8, 0x8CC4F0], [10, 8, 0x3E6A94], [1, 9, 0x3E6A94], [5, 9, 0x3E6A94], [9, 9, 0x3E6A94]]], "snow": [12, 12, [[4, 0, 0xF6F0E6], [5, 0, 0xF6F0E6], [6, 0, 0xF6F0E6], [7, 0, 0xF6F0E6], [2, 1, 0xF6F0E6], [3, 1, 0xF6F0E6], [4, 1, 0xE0D6C6], [5, 1, 0xE0D6C6], [6, 1, 0xE0D6C6], [7, 1, 0xE0D6C6], [8, 1, 0xF6F0E6], [9, 1, 0xF6F0E6], [1, 2, 0xF6F0E6], [2, 2, 0xE0D6C6], [3, 2, 0xE0D6C6], [4, 2, 0xE0D6C6], [5, 2, 0xE0D6C6], [6, 2, 0xE0D6C6], [7, 2, 0xE0D6C6], [8, 2, 0xE0D6C6], [9, 2, 0xE0D6C6], [10, 2, 0x958B80], [0, 3, 0xF6F0E6], [1, 3, 0xE0D6C6], [2, 3, 0xE0D6C6], [3, 3, 0xE0D6C6], [4, 3, 0xE0D6C6], [5, 3, 0xE0D6C6], [6, 3, 0xE0D6C6], [7, 3, 0xE0D6C6], [8, 3, 0xE0D6C6], [9, 3, 0xE0D6C6], [10, 3, 0x958B80], [11, 3, 0x958B80], [0, 4, 0xE0D6C6], [1, 4, 0xE0D6C6], [2, 4, 0xE0D6C6], [3, 4, 0xE0D6C6], [4, 4, 0xE0D6C6], [5, 4, 0xE0D6C6], [6, 4, 0xE0D6C6], [7, 4, 0xE0D6C6], [8, 4, 0xE0D6C6], [9, 4, 0xE0D6C6], [10, 4, 0xE0D6C6], [11, 4, 0x958B80], [1, 5, 0x958B80], [2, 5, 0x958B80], [3, 5, 0x958B80], [4, 5, 0x958B80], [5, 5, 0x958B80], [6, 5, 0x958B80], [7, 5, 0x958B80], [8, 5, 0x958B80], [9, 5, 0x958B80], [10, 5, 0x958B80], [2, 7, 0xE0D6C6], [9, 7, 0xE0D6C6], [1, 8, 0xE0D6C6], [2, 8, 0xFFFFFF], [3, 8, 0xE0D6C6], [8, 8, 0xE0D6C6], [9, 8, 0xFFFFFF], [10, 8, 0xE0D6C6], [2, 9, 0xE0D6C6], [6, 9, 0xE0D6C6], [9, 9, 0xE0D6C6], [5, 10, 0xE0D6C6], [6, 10, 0xFFFFFF], [7, 10, 0xE0D6C6], [6, 11, 0xE0D6C6]]], "thunder": [12, 12, [[4, 0, 0xC8C0B6], [5, 0, 0xC8C0B6], [6, 0, 0xC8C0B6], [7, 0, 0xC8C0B6], [2, 1, 0xC8C0B6], [3, 1, 0xC8C0B6], [4, 1, 0xA49C92], [5, 1, 0xA49C92], [6, 1, 0xA49C92], [7, 1, 0xA49C92], [8, 1, 0xC8C0B6], [9, 1, 0xC8C0B6], [1, 2, 0xC8C0B6], [2, 2, 0xA49C92], [3, 2, 0xA49C92], [4, 2, 0xA49C92], [5, 2, 0xA49C92], [6, 2, 0xA49C92], [7, 2, 0xA49C92], [8, 2, 0xA49C92], [9, 2, 0xA49C92], [10, 2, 0x6A645D], [0, 3, 0xC8C0B6], [1, 3, 0xA49C92], [2, 3, 0xA49C92], [3, 3, 0xA49C92], [4, 3, 0xA49C92], [5, 3, 0xA49C92], [6, 3, 0xA49C92], [7, 3, 0xA49C92], [8, 3, 0xA49C92], [9, 3, 0xA49C92], [10, 3, 0x6A645D], [11, 3, 0x6A645D], [0, 4, 0xA49C92], [1, 4, 0xA49C92], [2, 4, 0xA49C92], [3, 4, 0xA49C92], [4, 4, 0xA49C92], [5, 4, 0xA49C92], [6, 4, 0xA49C92], [7, 4, 0xA49C92], [8, 4, 0xA49C92], [9, 4, 0xA49C92], [10, 4, 0xA49C92], [11, 4, 0x6A645D], [1, 5, 0x6A645D], [2, 5, 0x6A645D], [3, 5, 0x6A645D], [4, 5, 0x6A645D], [5, 5, 0x6A645D], [6, 5, 0x6A645D], [7, 5, 0xF6D86A], [8, 5, 0xF6D86A], [9, 5, 0x6A645D], [10, 5, 0x6A645D], [7, 6, 0xF6D86A], [8, 6, 0xF6D86A], [6, 7, 0xF6D86A], [7, 7, 0xF6D86A], [8, 7, 0xC08A30], [5, 8, 0xF6D86A], [6, 8, 0xF6D86A], [7, 8, 0xF6D86A], [8, 8, 0xF6D86A], [9, 8, 0xC08A30], [7, 9, 0xF6D86A], [8, 9, 0xC08A30], [6, 10, 0xF6D86A], [7, 10, 0xC08A30], [6, 11, 0xC08A30]]], "fog": [12, 7, [[0, 0, 0xB4ACA2], [1, 0, 0xB4ACA2], [2, 0, 0xB4ACA2], [3, 0, 0xB4ACA2], [4, 0, 0xB4ACA2], [5, 0, 0xB4ACA2], [6, 0, 0xB4ACA2], [7, 0, 0xB4ACA2], [8, 0, 0xB4ACA2], [9, 0, 0xB4ACA2], [2, 2, 0x6E6862], [3, 2, 0xB4ACA2], [4, 2, 0xB4ACA2], [5, 2, 0xB4ACA2], [6, 2, 0xB4ACA2], [7, 2, 0xB4ACA2], [8, 2, 0xB4ACA2], [9, 2, 0xB4ACA2], [10, 2, 0xB4ACA2], [11, 2, 0xB4ACA2], [0, 4, 0xB4ACA2], [1, 4, 0xB4ACA2], [2, 4, 0xB4ACA2], [3, 4, 0xB4ACA2], [4, 4, 0xB4ACA2], [5, 4, 0xB4ACA2], [6, 4, 0xB4ACA2], [7, 4, 0xB4ACA2], [8, 4, 0xB4ACA2], [9, 4, 0x6E6862], [2, 6, 0x6E6862], [3, 6, 0xB4ACA2], [4, 6, 0xB4ACA2], [5, 6, 0xB4ACA2], [6, 6, 0xB4ACA2], [7, 6, 0xB4ACA2], [8, 6, 0xB4ACA2], [9, 6, 0xB4ACA2]]], "alert": [9, 9, [[4, 0, 0xF6D86A], [3, 1, 0xF6D86A], [4, 1, 0xF6D86A], [5, 1, 0xC08A30], [3, 2, 0xF6D86A], [4, 2, 0x3A2E26], [5, 2, 0xF6D86A], [2, 3, 0xF6D86A], [3, 3, 0xF6D86A], [4, 3, 0x3A2E26], [5, 3, 0xF6D86A], [6, 3, 0xC08A30], [2, 4, 0xF6D86A], [3, 4, 0xF6D86A], [4, 4, 0x3A2E26], [5, 4, 0xF6D86A], [6, 4, 0xC08A30], [1, 5, 0xF6D86A], [2, 5, 0xF6D86A], [3, 5, 0xF6D86A], [4, 5, 0xF6D86A], [5, 5, 0xF6D86A], [6, 5, 0xF6D86A], [7, 5, 0xC08A30], [1, 6, 0xF6D86A], [2, 6, 0xF6D86A], [3, 6, 0xF6D86A], [4, 6, 0x3A2E26], [5, 6, 0xF6D86A], [6, 6, 0xF6D86A], [7, 6, 0xC08A30], [0, 7, 0xF6D86A], [1, 7, 0xF6D86A], [2, 7, 0xF6D86A], [3, 7, 0xF6D86A], [4, 7, 0xF6D86A], [5, 7, 0xF6D86A], [6, 7, 0xF6D86A], [7, 7, 0xF6D86A], [8, 7, 0xC08A30], [0, 8, 0xC08A30], [1, 8, 0xC08A30], [2, 8, 0xC08A30], [3, 8, 0xC08A30], [4, 8, 0xC08A30], [5, 8, 0xC08A30], [6, 8, 0xC08A30], [7, 8, 0xC08A30], [8, 8, 0xC08A30]]]}
var CREAM = 0xE8DCCB
var GREY = 0x9A948C
var BLUE = 0x6FA8DC

class Clock
  var page, turned

  def init()
    self.page = 0
    self.turned = 0
  end

  def pages()
    return shared.get("Sky.alert") != nil ? 4 : 3
  end

  def on_show()
    self.page = 0
  end

  def on_knob(event)
    if event == "right" self.page = (self.page + 1) % self.pages()
    elif event == "left" self.page = (self.page + self.pages() - 1) % self.pages()
    elif event == "press" self.page = 0
    else return false
    end
    self.turned = now_ms()
    return true
  end

  def rounded(v)
    return v >= 0 ? int(v + 0.5) : -int(-v + 0.5)
  end

  def wicon(name, cx, cy)
    var ic = WICONS[name]
    var x0 = cx - ic[0] / 2
    var y0 = cy - ic[1] / 2
    for p : ic[2]
      pixel(x0 + p[0], y0 + p[1], p[2])
    end
  end

  def icon(cx, cy)
    var code = shared.get("Sky.code")
    var day = shared.get("Sky.day", 1) == 1
    if code == nil
      rect_fill(cx - 3, cy, 7, 1, GREY)
      return
    end
    var name = "rain"
    if code <= 1 name = day ? "sun" : "moon"
    elif code == 2 name = day ? "partly" : "moon"
    elif code == 3 name = "cloud"
    elif code == 45 || code == 48 name = "fog"
    elif (code >= 71 && code <= 77) || code == 85 || code == 86 name = "snow"
    elif code >= 95 name = "thunder"
    end
    self.wicon(name, cx, cy)
  end

  def temp_text(cx, y, top)
    var v = shared.get("Sky.temp")
    if v == nil return end
    var s = str(self.rounded(v))
    var w = text_width(s) + 4
    var x = cx - w / 2
    text(x, y, s, store.get("temp", CREAM))
    rect(x + text_width(s) + 1, top, 3, 3, store.get("temp", CREAM))
  end

  def mark(x, y, t)
    var col = shared.get("Sky.alert_color")
    if col == nil || (t / 700) % 4 == 0 return end
    pixel(x + 2, y, col)
    rect_fill(x + 1, y + 1, 3, 1, col)
    rect_fill(x, y + 2, 5, 1, col)
  end

  def hour_text()
    var h = hour()
    var mode = store.get("hours", "auto")
    var twelve = mode == "12" || (mode == "auto" && settings.get("time24h") == false)
    if twelve
      h = h % 12
      if h == 0 h = 12 end
    end
    if h < 10 && !store.get("zero", true) return " " + str(h) end
    return format("%02d", h)
  end

  def weekday_bar(x, w)
    var seg = (w + 1) / 7
    var mon = (weekday() + 6) % 7
    for i : 0 .. 6
      rect_fill(x + i * seg, 15, seg - 1, 1, i == mon ? store.get("today", 0xC8643C) : store.get("other", 0x3A2E26))
    end
  end

  def dims()
    var dsize = store.get("size", "medium")
    var st = blockfont.style(store.get("style", "compact"))
    var h = dsize == "large" ? 14 : (dsize == "small" ? 10 : 12)
    var gap = store.get("spacing", "airy") == "airy" ? 2 : 1
    return [st[0], h, gap, st[1], st[2]]
  end

  def dimmed(c, k)
    return ((((c >> 16) & 255) * k / 100) << 16) | ((((c >> 8) & 255) * k / 100) << 8) | ((c & 255) * k / 100)
  end

  def retro_text(s, x, y, c, colon, dm)
    var mode = store.get("retro", "off")
    if mode == "off"
      blockfont.text(s, x, y, c, dm[3], dm[4], colon, dm[0], dm[1], dm[2])
      return
    end
    var col = mode == "nixie" ? 0xFF7A2A : (mode == "vfd" ? 0x5CF0D0 : 0xFFB030)
    var g = store.get("glow", 25)
    if mode == "vfd"
      var ghost = ""
      for i : 0 .. size(s) - 1 ghost += s[i] == ":" || s[i] == " " ? s[i] : "8" end
      blockfont.text(ghost, x, y, self.dimmed(col, 7), dm[3], dm[4], true, dm[0], dm[1], dm[2])
    end
    if g > 0
      for d : [[-1, 0], [1, 0], [0, -1], [0, 1]]
        blockfont.text(s, x + d[0], y + d[1], self.dimmed(col, g), dm[3], dm[4], colon, dm[0], dm[1], dm[2])
      end
    end
    if mode == "crt"
      blockfont.parity = 1
      blockfont.text(s, x, y, self.dimmed(col, 70), dm[3], dm[4], colon, dm[0], dm[1], dm[2])
      blockfont.parity = 0
      blockfont.text(s, x, y, col, dm[3], dm[4], colon, dm[0], dm[1], dm[2])
      blockfont.parity = -1
    else
      blockfont.text(s, x, y, col, dm[3], dm[4], colon, dm[0], dm[1], dm[2])
    end
  end

  def draw_time(t)
    var layout = store.get("layout", "weather")
    var dm = self.dims()
    var c = store.get("color", 0xF2D7B6)
    var colon = store.get("colon", "steady") == "steady" || second() % 2 == 0
    var str_t = self.hour_text() + ":" + format("%02d", minute())
    if layout == "hms" str_t += ":" + format("%02d", second()) end
    var w = blockfont.width(str_t, dm[0], dm[2])
    var x = layout == "weather" ? width() - w - 2 : (width() - w) / 2
    var y = (16 - dm[1]) / 2
    self.retro_text(str_t, x, y, c, colon, dm)
    if store.get("bar", true) self.weekday_bar(x, w) end
    if store.get("secbar", false) rect_fill(x, 0, second() * w / 59, 1, store.get("sec", 0x8C7B6B)) end
    if layout == "weather"
      var left = store.get("left", "both")
      if left == "temp"
        font("large")
        self.temp_text(9, 11, 4)
      else
        self.icon(9, left == "icon" ? 8 : 5)
        if left == "both" self.temp_text(9, 15, 10) end
      end
      if store.get("mark", true) self.mark(15, 0, t) end
    elif store.get("mark", true)
      self.mark(0, 0, t)
    end
  end

  def draw_date()
    var c = store.get("color", 0xF2D7B6)
    var d = format("%02d", day())
    var dm = self.dims()
    blockfont.text(d, 3, (16 - dm[1]) / 2, c, dm[3], dm[4], true, dm[0], dm[1], dm[2])
    text(22, 7, DAYS[weekday()], store.get("today", 0xC8643C))
    text(22, 15, MONTHS[month() - 1] + " " + str(year() % 100), c)
  end

  def draw_weather(t)
    self.icon(9, 8)
    var v = shared.get("Sky.temp")
    var f = shared.get("Sky.feels")
    var wind = shared.get("Sky.wind")
    if v == nil
      text(21, 9, "no data", GREY)
      return
    end
    text(21, 7, str(self.rounded(v)) + "C feels " + str(self.rounded(f == nil ? v : f)), store.get("color", 0xF2D7B6))
    text(21, 15, "wind " + str(self.rounded(wind == nil ? 0 : wind)) + "km/h", GREY)
  end

  def draw_alert(t)
    var col = shared.get("Sky.alert_color", CREAM)
    self.wicon("alert", 5, 5)
    text(12, 7, shared.get("Sky.alert_type", "alert"), col)
    scroll_text(0, 15, width(), shared.get("Sky.alert", ""), col)
  end

  def knob_dots(cur, n)
    var x0 = width() - 4 - n * 2
    for i : 0 .. n - 1
      pixel(x0 + i * 2, 0, i == cur ? 0xF2D7B6 : 0x3A2E26)
    end
  end

  def draw()
    clear()
    var t = now_ms()
    if hour() < 0
      text(1, 9, "--:--", store.get("color", 0xF2D7B6))
      return
    end
    if self.page != 0 && t - self.turned > store.get("pagesec", 8) * 1000 self.page = 0 end
    if self.page == 1 self.draw_date()
    elif self.page == 2 self.draw_weather(t)
    elif self.page == 3 self.draw_alert(t)
    else self.draw_time(t)
    end
    self.knob_dots(self.page, self.pages())
    var ov = shared.get("Sky.overlay")
    if store.get("overlay", true) && ov != nil overlay(ov) end
  end
end

return Clock()
