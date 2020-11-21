architecture wdc65816
include "instructions.asm"

//build the upper 4MB ROM
output "../en/rom/bahamut-hi.sfc", create
fill $400000

macro seek(variable offset) {
  origin (offset & $3fffff)
  base   (offset & $3fffff) | $400000
}

include "insert-lists.asm"

//build the lower 4MB ROM
output "../en/rom/bahamut-lo.sfc", create
insert "../jp/rom/bahamut-jp.sfc"
fill $100000
tracker enable

macro seek(variable offset) {
  origin (offset & $3fffff)
  base   (offset & $3fffff) | $c00000
}

//mark ROM for English region instead of Japanese region
seek($c0ffb5); db 'E'  //was 'J'

//expand ROM from 4MB to 8MB
seek($c0ffd5); db $35  //was $31

//expand SRAM from 8KB to 32KB
//  a0:6000-7fff: save RAM
//  a1:6000-7fff: variables
//  a2:6000-7fff: proportional font rendering buffer
//  a3:6000-7fff: pre-rendered name tiledata cache
seek($c0ffd8); db $05  //was $03

//enable the debugger
//seek($c0ffad); db $00,$ff
//include "cheats.asm"

variable codeCursor = $f00000  //$f00000-$f1ffff
variable textCursor = $f80000  //$f80000-$feffff
variable dataCursor = $ff0000  //$ff0000-$ffffff
variable sramCursor = $a16000  //$a16000-$a17fff
include "macros.asm"
include "insert-scripts.asm"
include "insert-binaries.asm"

namespace command {
  constant base  = $f0  //$f0-$ff
  constant break = $fe  //$fe-$ff

  constant name        = $f4
  constant redirect    = $f5
  constant fontNormal  = $f6
  constant fontYellow  = $f7
  constant alignCenter = $f8
  constant alignRight  = $f9
  constant skipPixels  = $fa
  constant offsetLines = $fb
  constant pause       = $fc
  constant wait        = $fd
  constant lineFeed    = $fe
  constant terminal    = $ff
}

codeCursor = $f00000
include "reset.asm"
include "character-map.asm"
include "strings.asm"
include "redirection.asm"
include "vsync.asm"
include "base56.asm"
include "render.asm"
include "text.asm"
include "names.asm"
include "dragons.asm"
include "title.asm"
include "chapter-large.asm"
include "combat-large.asm"
include "combat-small.asm"
include "combat-strings.asm"
include "combat-dragons.asm"
include "field-large.asm"
include "field-small.asm"
include "field-strings.asm"
include "field-terrain.asm"
if codeCursor > $f0ffff {
  error "code bank $f0 exhausted"
}

codeCursor = $f10000
include "menu-large.asm"
include "menu-small.asm"
include "menu-dispatcher.asm"
include "menu-saves.asm"
include "menu-names.asm"
include "menu-party.asm"
include "menu-formation.asm"
include "menu-dragons.asm"
include "menu-information.asm"
include "menu-equipment.asm"
include "menu-magic-item.asm"
include "menu-unit.asm"
include "menu-status.asm"
include "menu-shop.asm"
include "debugger.asm"
if codeCursor > $f1ffff {
  error "code bank $f1 exhausted"
}

if textCursor > $feffff {
  error "text banks $f8-fe exhausted"
}

if dataCursor > $ffffff {
  error "data bank $ff exhausted"
}

if sramCursor > $a17fff {
  error "sram bank $a1 exhausted"
}

tracker disable

//overlay the lower 4MB ROM 32KB banks onto the upper 4MB ROM
output "../en/rom/bahamut-hi.sfc", modify
variable index = 0
while index < 48 {
  variable size    = $8000
  variable address = index * $10000 + size
  origin address
  insert "../en/rom/bahamut-lo.sfc", address, size
  index = index + 1
}

//merge the lower and upper 4MB ROMs
output "../en/rom/bahamut-en.sfc", create
insert "../en/rom/bahamut-lo.sfc"; delete "../en/rom/bahamut-lo.sfc"
insert "../en/rom/bahamut-hi.sfc"; delete "../en/rom/bahamut-hi.sfc"
