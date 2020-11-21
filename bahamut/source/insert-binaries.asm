namespace hook {
  seek($c8a000); insert "../en/binaries/fonts/font-field-data.bin"
  seek($e61b40); insert "../en/binaries/fonts/font-combat-data.bin"
  seek($ee850f); dl menuFont.data
  seek($ecfe7e); dl failedFont.data
  seek($ecfaf8); dl conclusionFont.data
  seek($ecfafd); dl conclusionFont.map
  seek($ef0380); insert "../en/binaries/base56/base56-names.bin"
}

//384KB (3mbit) ROM space
//$f2-f7:0000-ffff = 384KB
array[6] cursors
namespace cursors {
  variable index = 0
  while index < array.size(cursors) {
    cursors[index] = $f20000 + index * $10000
    index = index + 1
  }
}

//DMA transfers cannot cross bank boundaries on the SNES.
//this routine tries to find a bank with enough free space to hold the entire file.
inline insert(define label, define type) {
  define name = "../en/binaries/" ~ {label} ~ "-" ~ {type} ~ ".bin"
  variable size = file.size({name})

  variable index = 0
  variable found = 0
  while index < array.size(cursors) && found == 0 {
    if cursors[index] + size <= ($f20000 + index * $10000) + $10000 {
      seek(cursors[index])
      insert {type}, {name}
      cursors[index] = cursors[index] + size
      found = 1
    }
    index = index + 1
  }

  if found == 0 {
    error "inserter exhausted all available space, cannot insert ", {name}
  }
}

namespace largeFont {
  insert("fonts/font-large", normal)
  insert("fonts/font-large", yellow)
  insert("fonts/font-large", sprite)
  insert("fonts/font-large", widths)
  insert("fonts/font-large", kernings)
}

namespace smallFont {
  insert("fonts/font-small", data)
  insert("fonts/font-small", widths)
  insert("fonts/font-small", kernings)
}

namespace menuFont {
  insert("fonts/font-menu", data)
}

namespace conclusionFont {
  insert("fonts/font-conclusion", data)
  insert("fonts/font-conclusion", map)
}

namespace failedFont {
  insert("fonts/font-failed", data)
}

namespace titleFont {
  insert("fonts/font-title", data)
}

namespace base56 {
  insert("base56/base56", products)
  insert("base56/base56", quotients)
  insert("base56/base56", remainders)
}
