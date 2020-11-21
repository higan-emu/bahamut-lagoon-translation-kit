namespace lists {

//2432KB (19mbit) ROM space
//$00-2f:8000-ffff is unmodified to ensure compatibility with 32KB bank accesses from the original ROM
//$00-2f|40-6f:0000-7fff + $70-7d:0000-ffff is available
//$7e-7f:0000-ffff is not mapped to ROM (128KB WRAM location)
//$40-6f:0000-7fff = 1536KB
//$70-7d:0000-ffff =  896KB
array[54] cursors
namespace cursors {
  variable index = 0
  while index < array.size(cursors) {
    cursors[index] = $400000 + index * $10000
    index = index + 1
  }
}

//DMA transfers cannot cross bank boundaries on the SNES.
//this routine tries to find a bank with enough free space to hold the entire file.
inline insert(define label, define type) {
  define name = "../en/binaries/lists/" ~ {label} ~ "-" ~ {type} ~ ".bin"
  variable size = file.size({name})

  variable index = 0
  variable found = 0
  while index < array.size(cursors) && found == 0 {
    if cursors[index] + size <= ($400000 + index * $10000) + (index < 48 ? $8000 : $10000) {
      seek(cursors[index])
      insert {type}, {name}
      cursors[index] = cursors[index] + size
      found = 1
    }
    index = index + 1
  }

  if found == 0 {
    error "inserter exhaused all available space, cannot insert ", {name}
  }
}

namespace chapters {
  insert("chapters", bpp2)
  insert("chapters", bpp4)
}

namespace classes {
  insert("classes", bpp2)
  insert("classes", bpp4)
}

namespace commands {
  insert("commands", bpp2)
  insert("commands", bpo4)
  insert("commands", widths)
}

namespace costs {
  insert("costs", bpp2)
  insert("costs", bpo4)
}

namespace counts {
  insert("counts", bpp2)
  insert("counts", bpo4)
}

namespace defeats {
  insert("defeats", text)
}

namespace descriptions {
  insert("descriptions", text)
}

namespace dragons {
  insert("dragons", bpp2)
  insert("dragons", bpp4)
  insert("dragons", text)
}

namespace enemies {
  insert("enemies", bpp2)
  insert("enemies", bpo4)
  insert("enemies", text)
}

namespace field {
  insert("field", bpp2)
}

namespace items {
  insert("items", bpp2)
  insert("items", bpp4)
  insert("items", bpo4)
  insert("items", text)
  insert("items", widths)
}

namespace levels {
  insert("levels", bpp2)
  insert("levels", bpp4)
  insert("levels", bpo4)
}

namespace menu {
  insert("menu", bpp2)
}

namespace names {
  insert("names", bpp2)
  insert("names", bpp4)
  insert("names", bpo4)
  insert("names", bpa4)
  insert("names", text)
}

namespace parties {
  insert("parties", bpp2)
}

namespace saves {
  insert("saves", bpp4)
}

namespace stats {
  insert("stats", bpp2)
  insert("stats", bpp4)
  insert("stats", bpo4)
  insert("stats", bpa4)
  insert("stats", bpi4)
  insert("stats", bpd4)
}

namespace strings {
  insert("strings", bpp2)
  insert("strings", bpp4)
  insert("strings", bpo4)
}

namespace techniques {
  insert("techniques", bpp2)
  insert("techniques", bpp4)
  insert("techniques", bpo4)
  insert("techniques", text)
  insert("techniques", widths)
}

namespace terrains {
  insert("terrains", text)
}

}
