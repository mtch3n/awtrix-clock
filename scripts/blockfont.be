# @module
# @desc  Block digits in any size (w wide, h high) with a 2 or 1 pixel stroke, for Clock and Timer

var blockfont = module("blockfont")

var SEGS = {"0": "abcdef", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
            "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}

blockfont.digit = def (ch, x, y, c, s, w, h)
  var mid = (h - s) / 2
  if ch == "1"
    var stem = x + w - 2 - s + (w < 6 ? 1 : 0)
    rect_fill(stem, y, s, h, c)
    pixel(stem - 1, y + 1, c)
    if s == 2 rect_fill(stem - 2, y + 2, 2, 1, c) end
    return
  end
  if ch == "-"
    rect_fill(x, y + mid, w, s, c)
    return
  end
  var segs = SEGS.find(ch, "")
  for i : 0 .. size(segs) - 1
    var g = segs[i]
    if g == "a" rect_fill(x, y, w, s, c)
    elif g == "g" rect_fill(x, y + mid, w, s, c)
    elif g == "d" rect_fill(x, y + h - s, w, s, c)
    elif g == "f" rect_fill(x, y, s, mid + s, c)
    elif g == "b" rect_fill(x + w - s, y, s, mid + s, c)
    elif g == "e" rect_fill(x, y + mid, s, h - mid, c)
    elif g == "c" rect_fill(x + w - s, y + mid, s, h - mid, c)
    end
  end
end

blockfont.width = def (str, w, gap)
  var total = 0
  for i : 0 .. size(str) - 1
    total += (str[i] == ":" ? 2 : w) + (i > 0 ? gap : 0)
  end
  return total
end

blockfont.text = def (str, x, y, c, s, colon_on, w, h, gap)
  for i : 0 .. size(str) - 1
    if str[i] == ":"
      if colon_on
        rect_fill(x, y + h / 2 - 4, 2, 2, c)
        rect_fill(x, y + h / 2 + 2, 2, 2, c)
      end
      x += 2 + gap
    else
      blockfont.digit(str[i], x, y, c, s, w, h)
      x += w + gap
    end
  end
end

return blockfont
