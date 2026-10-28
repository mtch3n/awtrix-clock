# @module
# @desc  Block digits in any size (w wide, h high) with separate side (sv) and bar (sh) strokes, for Clock and Timer
# @author  mtch3n
# @version 1.0

var blockfont = module("blockfont")

blockfont.parity = -1

blockfont.box = def (x, y, w, h, c)
  if blockfont.parity < 0
    rect_fill(x, y, w, h, c)
    return
  end
  for yy : y .. y + h - 1
    if yy % 2 == blockfont.parity rect_fill(x, yy, w, 1, c) end
  end
end

var SEGS = {"0": "abcdef", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
            "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}

blockfont.digit = def (ch, x, y, c, sv, sh, w, h)
  var mid = (h - sh) / 2
  if ch == "1"
    var stem = x + w - sv - 1
    blockfont.box(stem, y, sv, h, c)
    blockfont.box(stem - 1, y + 1, 1, 1, c)
    if sv == 2 blockfont.box(stem - 2, y + 2, 2, 1, c) end
    return
  end
  if ch == "-"
    blockfont.box(x, y + mid, w, sh, c)
    return
  end
  var segs = SEGS.find(ch, "")
  for i : 0 .. size(segs) - 1
    var g = segs[i]
    if g == "a" blockfont.box(x, y, w, sh, c)
    elif g == "g" blockfont.box(x, y + mid, w, sh, c)
    elif g == "d" blockfont.box(x, y + h - sh, w, sh, c)
    elif g == "f" blockfont.box(x, y, sv, mid + sh, c)
    elif g == "b" blockfont.box(x + w - sv, y, sv, mid + sh, c)
    elif g == "e" blockfont.box(x, y + mid, sv, h - mid, c)
    elif g == "c" blockfont.box(x + w - sv, y + mid, sv, h - mid, c)
    end
  end
end

var STYLES = {"bold": [6, 2, 2], "thin": [6, 1, 1], "compact": [5, 2, 2], "airy": [6, 1, 2]}

blockfont.style = def (name)
  return STYLES.find(name, STYLES["airy"])
end

blockfont.width = def (str, w, gap)
  var total = 0
  for i : 0 .. size(str) - 1
    total += (str[i] == ":" ? 2 : w) + (i > 0 ? gap : 0)
  end
  return total
end

blockfont.text = def (str, x, y, c, sv, sh, colon_on, w, h, gap)
  for i : 0 .. size(str) - 1
    if str[i] == ":"
      if colon_on
        blockfont.box(x, y + h / 2 - 4, 2, 2, c)
        blockfont.box(x, y + h / 2 + 2, 2, 2, c)
      end
      x += 2 + gap
    else
      blockfont.digit(str[i], x, y, c, sv, sh, w, h)
      x += w + gap
    end
  end
end

return blockfont
