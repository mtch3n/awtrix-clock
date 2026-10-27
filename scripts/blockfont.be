# @module
# @desc  Block digits 6 wide and 14 high, with a 2 or 1 pixel stroke, for Clock and Timer

var blockfont = module("blockfont")

var SEGS = {"0": "abcdef", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
            "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}

blockfont.digit = def (ch, x, y, c, s)
  if ch == "1"
    rect_fill(x + 4 - s, y, s, 14, c)
    if s == 2
      pixel(x + 1, y + 1, c)
      rect_fill(x, y + 2, 2, 1, c)
    else
      pixel(x + 2, y + 1, c)
    end
    return
  end
  if ch == "-"
    rect_fill(x, y + 6, 6, s, c)
    return
  end
  var segs = SEGS.find(ch, "")
  for i : 0 .. size(segs) - 1
    var g = segs[i]
    if g == "a" rect_fill(x, y, 6, s, c)
    elif g == "g" rect_fill(x, y + 6, 6, s, c)
    elif g == "d" rect_fill(x, y + 14 - s, 6, s, c)
    elif g == "f" rect_fill(x, y, s, 8, c)
    elif g == "b" rect_fill(x + 6 - s, y, s, 8, c)
    elif g == "e" rect_fill(x, y + 6, s, 8, c)
    elif g == "c" rect_fill(x + 6 - s, y + 6, s, 8, c)
    end
  end
end

blockfont.width = def (str)
  var w = 0
  for i : 0 .. size(str) - 1
    w += (str[i] == ":" ? 2 : 6) + (i > 0 ? 1 : 0)
  end
  return w
end

blockfont.text = def (str, x, y, c, s, colon_on)
  for i : 0 .. size(str) - 1
    if str[i] == ":"
      if colon_on
        rect_fill(x, y + 3, 2, 2, c)
        rect_fill(x, y + 9, 2, 2, c)
      end
      x += 3
    else
      blockfont.digit(str[i], x, y, c, s)
      x += 7
    end
  end
end

return blockfont
