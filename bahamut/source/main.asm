architecture wdc65816
include "instructions.asm"

variable codeCursor = $f00000  //$f00000-$f1ffff
variable textCursor = $f20000  //$f20000-$f6ffff
variable sramCursor = $316000  //$316000-$317fff

output "../en/rom/bahamut-en.sfc", create
insert "../jp/rom/bahamut-jp.sfc"; fill $500000
tracker enable

macro seek(variable offset) {
  if offset & 0xc00000 == 0x400000 {
    origin (offset & $3fffff) | $400000
    base   (offset & $3fffff) | $400000
  }
  if offset & 0xc00000 == 0xc00000 {
    origin (offset & $3fffff) | $000000
    base   (offset & $3fffff) | $c00000
  }
}

//mark ROM for North American region instead of Japanese region
seek($c0ffb5); db 'E'  //was 'J'

//modify mapper from HiROM to ExHiROM
seek($c0ffd5); db $35  //was $31

//expand ROM from 4MB to 8MB
seek($c0ffd7); db $0d  //was $0c

//expand SRAM from 8KB to 32KB
//  $30:6000-7fff: save RAM
//  $31:6000-7fff: variables
//  $32:6000-7fff: proportional font rendering buffer
//  $33:6000-7fff: pre-rendered name tiledata cache
seek($c0ffd8); db $05  //was $03

//change region from Japan to North America
seek($c0ffd9); db $01  //was $00

//change revision from 1.0 to 1.2
seek($c0ffdb); db $02  //was $00

//erase the ROM checksum
seek($c0ffdc); dw $ffff,$0000

//enable the debugger
if 0 {
  notice "debugger enabled"
  seek($c0ffad); db $00,$ff
  include "cheats.asm"
}

include "macros.asm"
include "insert.asm"
include "constants.asm"

codeCursor = $f00000
include "reset.asm"
include "character-map.asm"
include "strings.asm"
include "palettes.asm"
include "redirection.asm"
include "vsync.asm"
include "base56.asm"
include "render.asm"
include "text.asm"
include "names.asm"
include "title.asm"
include "chapter-large.asm"
include "chapter-credits.asm"
include "chapter-debugger.asm"
include "combat-hdma.asm"
include "combat-large.asm"
include "combat-small.asm"
include "combat-strings.asm"
include "combat-dragons.asm"
include "field-large.asm"
include "field-small.asm"
include "field-strings.asm"
include "field-terrain.asm"
include "field-debugger.asm"
if codeCursor > $f10000 {
  error "code bank $f0 exhausted"
}

codeCursor = $f10000
include "menu-large.asm"
include "menu-small.asm"
include "menu-dispatcher.asm"
include "menu-saves.asm"
include "menu-names.asm"
include "menu-party.asm"
include "menu-dragons.asm"
include "menu-information.asm"
include "menu-equipment.asm"
include "menu-magic-item.asm"
include "menu-overviews.asm"
include "menu-unit.asm"
include "menu-status.asm"
include "menu-shop.asm"
if codeCursor > $f20000 {
  error "code bank $f1 exhausted"
}

if textCursor > $f70000 {
  error "text banks $f2-$f6 exhausted"
}

if sramCursor > $318000 {
  error "sram bank $31 exhausted"
}

//mirror $80-af:8000-ffff to $00-2f:8000-ffff
variable index = 0
while index < 48 {
  copy $008000 + index * $10000, $408000 + index * $10000, $8000
  index = index + 1
}
