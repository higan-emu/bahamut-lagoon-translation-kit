//2048KB (16mbit) ROM space
//$40-6f:0000-7fff = 1536KB (48 banks)
//$f7-ff:0000-ffff =  576KB ( 9 banks)
array[57] cursors
namespace cursors {
  variable index = 0
  while index < array.size(cursors) {
    if index < 48 {
      cursors[index] = $400000 + (index -  0) * $10000
    } else {
      cursors[index] = $f70000 + (index - 48) * $10000
    }
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
    variable bounds = 0
    if index < 48 {
      bounds = $400000 + (index -  0) * $10000 +  $8000
    } else {
      bounds = $f70000 + (index - 48) * $10000 + $10000
    }
    if cursors[index] + size <= bounds {
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

namespace script {
  seek(textCursor)
  insert "../en/binaries/script/script.bin"
  textCursor = pc()
}

namespace hook {
  seek($c8a000); insert "../en/binaries/fonts/font-field-data.bin"
  seek($e61b40); insert "../en/binaries/fonts/font-combat-data.bin"
  seek($ee850f); dl menuFont.data
  seek($c2feb7); dl failedFont.data  //combat
  seek($ecfe7e); dl failedFont.data  //field
  seek($ecfaf8); dl conclusionFont.data
  seek($ecfafd); dl conclusionFont.map
  seek($ef0380); insert "../en/binaries/base56/base56-names.bin"
}

namespace chapter {
  macro insert(id) {
    variable index   = ${id}
    variable address = 0
    address = address | read($1a8000 + index * 3) <<  0
    address = address | read($1a8001 + index * 3) <<  8
    address = address | read($1a8002 + index * 3) << 16
    seek(address); insert "../en/binaries/chapters/chapter-{id}.bin"
  }
  insert(00);insert(01);insert(02);insert(03);insert(04);insert(05);insert(06);insert(07)
  insert(08);insert(09);insert(0a);insert(0b);insert(0c);insert(0d);insert(0e);insert(0f)
  insert(10);insert(11);insert(12);insert(13);insert(14);insert(1e);insert(1f);insert(23)
  insert(25);insert(27);insert(28);insert(29);insert(2a);insert(2c);insert(2d);insert(2e)
  insert(2f);insert(30);insert(31);insert(32);insert(33);insert(3e);insert(3f);insert(40)
  insert(41);insert(42);insert(43);insert(44);insert(46);insert(48);insert(49);insert(4b)
  insert(4c);insert(4d);insert(4e);insert(50);insert(d0);insert(d1);insert(d2);insert(d3)
  insert(d4);insert(d5);insert(d6);insert(d7);insert(f3);insert(f4);insert(f5);insert(f6)
  insert(f7)
}

namespace field {
  macro insert(id) {
    variable index   = ${id}
    variable address = 0
    address = address | read($07140f + index * 3) <<  0
    address = address | read($071410 + index * 3) <<  8
    address = address | read($071411 + index * 3) << 16
    seek(address); insert "../en/binaries/fields/field-{id}.bin"
  }
  insert(00);insert(01);insert(02);insert(03);insert(04);insert(05);insert(06);insert(07)
  insert(08);insert(09);insert(0a);insert(0b);insert(0c);insert(0d);insert(0e);insert(0f)
  insert(10);insert(11);insert(12);insert(13);insert(14);insert(15);insert(16);insert(17)
  insert(18);insert(19);insert(1a);insert(1b);insert(1c);insert(1d);insert(1e);insert(1f)
}

namespace largeFont {
  insert("fonts/font-large", normal)
  insert("fonts/font-large", yellow)
  insert("fonts/font-large", shadow)
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

namespace lists {

namespace chapters {
  insert("lists/chapters", bpp2)
  insert("lists/chapters", bpp4)
  insert("lists/chapters", bph4)
}

namespace classes {
  insert("lists/classes", bpp2)
  insert("lists/classes", bpp4)
}

namespace combat {
  insert("lists/combat", text)
}

namespace commands {
  insert("lists/commands", bpp2)
  insert("lists/commands", bpo4)
  insert("lists/commands", widths)
}

namespace costsMP {
  insert("lists/costsMP", bpp2)
  insert("lists/costsMP", bpa4)
  insert("lists/costsMP", bpb4)
  insert("lists/costsMP", bpi4)
}

namespace costsSP {
  insert("lists/costsSP", bpp2)
  insert("lists/costsSP", bpa4)
  insert("lists/costsSP", bpb4)
}

namespace counts {
  insert("lists/counts", bpp2)
  insert("lists/counts", bpa4)
  insert("lists/counts", bpb4)
}

namespace defeats {
  insert("lists/defeats", text)
}

namespace descriptions {
  insert("lists/descriptions", text)
}

namespace dragons {
  insert("lists/dragons", bpp2)
  insert("lists/dragons", bpp4)
  insert("lists/dragons", text)
}

namespace enemies {
  insert("lists/enemies", bpp2)
  insert("lists/enemies", bpo4)
  insert("lists/enemies", text)
}

namespace items {
  insert("lists/items", bpp2)
  insert("lists/items", bpp4)
  insert("lists/items", bpo4)
  insert("lists/items", text)
  insert("lists/items", widths)
}

namespace levels {
  insert("lists/levels", bpp2)
  insert("lists/levels", bpp4)
  insert("lists/levels", bpo4)
}

namespace names {
  insert("lists/names", bpp2)
  insert("lists/names", bpp4)
  insert("lists/names", bpo4)
  insert("lists/names", bpa4)
  insert("lists/names", text)
}

namespace parties {
  insert("lists/parties", bpp2)
}

namespace quantities {
  insert("lists/quantities", bpp2)
}

namespace stats {
  insert("lists/stats", bpp2)
  insert("lists/stats", bpp4)
  insert("lists/stats", bpo4)
  insert("lists/stats", bpa4)
  insert("lists/stats", bpi4)
  insert("lists/stats", bpd4)
}

namespace strings {
  insert("lists/strings", bpp2)
  insert("lists/strings", bpp4)
  insert("lists/strings", bpo4)
  insert("lists/strings", bph4)
}

namespace techniques {
  insert("lists/techniques", bpp2)
  insert("lists/techniques", bpp4)
  insert("lists/techniques", bpo4)
  insert("lists/techniques", text)
  insert("lists/techniques", widths)
}

namespace terrains {
  insert("lists/terrains", text)
}

namespace triggers {
  insert("lists/triggers", text)
}

}
