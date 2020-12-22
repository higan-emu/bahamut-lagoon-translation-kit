namespace menu {

seek(codeCursor)

//useful routine hooks:
//jsl $ee4caa (--- number)
//jsl $ee4ddc (32-bit number)
//jsl $ee4e4e (16-bit number)
//jsl $ee5001 (window border)
//jsr $4a1e   (string literal)

namespace reconfigureVRAM {
  //the game originally transferred far more tilemap data than was necessary.
  //tilemaps can be 256x256 - 512x512 in size, but only 256x224 is visible.
  //by reducing the tilemap transfer lengths, more VRAM can be freed up for tiledata.
  enqueue pc

  //$9000-$997f: BG3 tilemap (frees $01a0-$01ff)
  seek($eefdc1); dw $9000>>1,$0a00  //was $4800,$1000
  seek($eefea6); dw $9000>>1,$0a00  //was $4800,$1000

  //$a000-$a7ff: BG2 tilemap (upper region) (unchanged)
  seek($eefd8b); dw $a000>>1,$0800  //was $5000,$0800
  seek($eefe38); dw $a000>>1,$0800  //was $5000,$0800

  //$b000-$b17f: BG2 tilemap (lower region) (frees $0318-$037f)
  seek($eefd96); dw $b000>>1,$0180  //was $5800,$0800
  seek($eefe43); dw $b000>>1,$0180  //was $5800,$0800

  dequeue pc
}

//BG3 available tiles:
//$030-$0e7 = 184 tiles
//$1a0-$1ff =  96 tiles
//$280-$2ff = 128 tiles
//$318-$3f3 = 224 tiles (= 632 tiles/banks 0-3)

//BG2 available tiles:
//$030-$0e7 = 184 tiles
//$100-$1ff = 256 tiles (= 440 tiles/banks 0-1)

//BG3 + BG2 reserved tiles:
//$000      = blank
//$001-$00a = '0'-'9' single-digit tiles (for technique multipliers)
//$00b-$015 = "Equipment Summary" text
//$016-$027 = "Item Explanation" / "Dragon Keeper's Item Explanation" text
//$028-$02f = ailments icon ($28,$2a-$2f) / "|" separator ($29)
//$0e8-$0ec = window borders
//$0ed      = 'x' technique multiplier
//$0ee      = unused
//$0ef      = space
//$0f0      = property icon
//$0f1-$0f2 = increase / decrease arrows
//$0f3-$0f7 = affinity icons
//$0f8-$0fe = window borders
//$0ff      = enchant icon

//BG3 reserved tiles:
//$100-$19f = BG3 tilemap
//$200-$27f = BG2 tilemap (upper region)
//$300-$317 = BG2 tilemap (lower region)
//$3f4-$3ff = "Page ##/##" / "No Items" text

//BG2 reserved tiles:
//$200-$3ff = unnecessary

namespace allocator {
  inline bpp2() {
    namespace allocator {
      variable bank0 = $030
      variable bank1 = $1a0
      variable bank2 = $280
      variable bank3 = $318
    }
  }

  inline bpp4() {
    namespace allocator {
      variable bank0 = $030
      variable bank1 = $100
      variable bank2 = $300  //unused
      variable bank3 = $400  //unused
    }
  }

  inline create(variable length, variable amount, define name) {
    namespace allocator {
      namespace {name} {
        constant count = amount
        variable(2, index)
        table: {
          while amount > 0 {
            if bank0 + length <= $0e8 {
              dw bank0; bank0 = bank0 + length
            } else if bank1 + length <= $200 {
              dw bank1; bank1 = bank1 + length
            } else if bank2 + length <= $300 {
              dw bank2; bank2 = bank2 + length
            } else if bank3 + length <= $3f4 {
              dw bank3; bank3 = bank3 + length
            } else {
              error "allocator exhausted all available tiles"
            }
            amount = amount - 1
          }
        }
      }
    }
  }

  //hint that tiles are reserved because they are shared with another namespace
  inline shared(variable length, variable amount, define name) {
    allocator.create(length, amount, {name})
  }

  macro index(define name) {
    pha; getTileIndex(allocator.{name}.index, allocator.{name}.count)
    asl; tax; lda allocator.{name}.table,x; tax; pla
  }

  macro lookup(define name) {
    asl; tax; lda allocator.{name}.table,x; tax
  }
}

namespace palette {
  constant white = $2000
  constant gray  = $2400
  constant green = $2800
  constant ivory = $2c00
}

namespace glyph {
  constant numbers       = $01  //$01-$0a = '0'-'9'
  constant multiplier    = $ed
  constant arrowIncrease = $f1
  constant arrowDecrease = $f2
  constant space         = $ef
  constant undead        = $f0
  constant fire          = $f7
  constant water         = $f6
  constant thunder       = $f3
  constant earth         = $f4
  constant poison        = $f5
  constant defeated      = $2f
  constant petrified     = $2e
  constant sleeping      = $2c
  constant poisoned      = $2d
  constant bunny         = $28
  constant bingo         = $ff
}

namespace tilemap {
  constant address     = $001860  //location to write to within tilemap
  constant baseAddress = $001864  //base address added to tilemap address
  constant attributes  = $001862  //palette and flip tile attributes
  constant transfer    = $00185a  //must be set to 1 to transfer tilemap to VRAM for some screens
  constant location    = $7ec400  //location of tilemap in WRAM

  //X => starting tile#
  //Y => number of tiles to write
  //address => address + Y*2
  function write {
    phb; php; ldb #$7e; rep #$20
    txa; ora attributes
    pha; lda address; tax; pla
    cpy #$0000
  -;beq +; sta.w location,x
    inc; inx #2; dey; bra -
  +;txa; sta address
    lda #$0001; sta transfer
    plp; plb; rtl
  }

  macro read() {
    phx; lda tilemap.address; tax
    lda tilemap.location,x; plx
  }

  macro write(variable character) {
    phx; lda tilemap.address; tax
    inc #2; sta tilemap.address
    lda.w #character
    ora tilemap.attributes
    sta tilemap.location,x; plx
    lda #$0001; sta tilemap.transfer
  }

  macro incrementAddress(variable amount) {
    pha; lda.w tilemap.address; add.w #amount; sta tilemap.address; pla
  }

  macro decrementAddress(variable amount) {
    pha; lda.w tilemap.address; sub.w #amount; sta tilemap.address; pla
  }

  macro setAddress(variable address) {
    pha; lda.w #address; sta tilemap.address; pla
  }

  macro setBaseAddress(variable baseAddress) {
    pha; lda.w #baseAddress; sta tilemap.baseAddress; pla
  }

  macro setColorPalette(variable index) {
    pha; lda.w #$2000+(index&7)*$400; sta tilemap.attributes; pla
  }

  macro setColorWhite() {
    tilemap.setColorPalette(0)
  }

  macro setColorGray() {
    tilemap.setColorPalette(1)
  }

  macro setColorGreen() {
    tilemap.setColorPalette(2)
  }

  macro setColorIvory() {
    tilemap.setColorPalette(3)
  }
}

namespace write {
  //A => tile count
  //X => target index
  //Y => source index
  macro bpp2(variable source) {
    enter; ldb #$00
    vsync()
    pha; tya; mul(16); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; mul(16); add #$8000; lsr; sta $2116
    tya; mul(16); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    jsl tilemap.write
    leave
  }
  function bpp2 {
    php; rep #$30; phy
    ldy #$0000; write.bpp2(render.buffer)
    ply; plp; rtl
  }
  macro bpp2() {
    jsl write.bpp2
  }

  //A => tile count
  //X => target index
  //Y => source index
  macro bpp4(variable source) {
    enter; ldb #$00
    vsync()
    pha; tya; mul(32); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; mul(32); add #$2000; lsr; sta $2116
    tya; mul(32); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    jsl tilemap.write
    leave
  }
  function bpp4 {
    php; rep #$30; phy
    ldy #$0000; write.bpp4(render.buffer)
    ply; plp; rtl
  }
  macro bpp4() {
    jsl write.bpp4
  }
}

//the original status icon rendering would print tiles for invalid status fields.
//it has been replaced with a routine that only draws valid tiles instead.
//this is done to provide consistency with the field and combat systems.
namespace status {
  enqueue pc
  seek($ee907a); jsl main; rts
  dequeue pc

  function main {
    variable(2, property)  //enemies only
    variable(2, affinity)  //enemies only
    variable(2, ailments)  //players and enemies
    variable(2, enchants)  //players only

    enter
    ldy #$0038; lda [$44],y; and.w #status.property.mask; sta property
    ldy #$000a; lda [$44],y; and.w #status.affinity.mask; sta affinity
    ldy #$0008; lda [$44],y; and.w #status.ailment.mask;  sta ailments
    ldy #$000a; lda [$44],y; and.w #status.enchant.mask;  sta enchants

    lda $0005fc; and #$00ff  //0 = players, 1 = dragons, 2 = enemies
    cmp #$0002; jne writeAilments

  writeProperties:
    lda property; and.w #status.property.undead;   beq +; tilemap.write(glyph.undead   ); +

  writeAffinities:
    lda affinity; and.w #status.affinity.fire;     beq +; tilemap.write(glyph.fire     ); +
    lda affinity; and.w #status.affinity.water;    beq +; tilemap.write(glyph.water    ); +
    lda affinity; and.w #status.affinity.thunder;  beq +; tilemap.write(glyph.thunder  ); +
    lda affinity; and.w #status.affinity.earth;    beq +; tilemap.write(glyph.earth    ); +
    lda affinity; and.w #status.affinity.poison;   beq +; tilemap.write(glyph.poison   ); +

  writeAilments:
    lda ailments; and.w #status.ailment.defeated;  beq +; tilemap.write(glyph.defeated ); +
    lda ailments; and.w #status.ailment.petrified; beq +; tilemap.write(glyph.petrified); +
    lda ailments; and.w #status.ailment.sleeping;  beq +; tilemap.write(glyph.sleeping ); +
    lda ailments; and.w #status.ailment.poisoned;  beq +; tilemap.write(glyph.poisoned ); +
    lda ailments; and.w #status.ailment.bunny;     beq +; tilemap.write(glyph.bunny    ); +

  writeEnchants:
    lda enchants; and.w #status.enchant.bingo;     beq +; tilemap.write(glyph.bingo    ); +

    lda $0005fc; and #$00ff
    cmp #$0000;  jeq clear  //players (magic and item screens)
    cmp #$0001;  jeq clear  //players and dragons
    cmp #$0002;  jeq enemy  //enemies
    jmp clear

  enemy:
    jmp clear

  clear:
    //this function may have updated previous status icons.
    //for instance, using "Cleanup" to remove status ailments.
    //thus, we need to erase all remaining status icons in the tilemap here.
    tilemap.read(); and #$00ff
    cmp.w #glyph.undead;    bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.fire;      bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.water;     bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.thunder;   bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.earth;     bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.poison;    bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.defeated;  bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.petrified; bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.sleeping;  bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.poisoned;  bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.bunny;     bne +; tilemap.write(glyph.space); jmp clear; +
    cmp.w #glyph.bingo;     bne +; tilemap.write(glyph.space); jmp clear; +
    leave; rtl
  }
}

namespace string {
  variable found = 0
  variable index = 0

  //the menu system embedded shift-JIS strings inline with code, like so:
  //jsr $4a1e; dw shiftJIS; ...  ;code
  //the $ee4a1e subroutine would pull the return address from the stack,
  //treat it as a text pointer, render the text, and then update the stack return address.
  //scan() will scan the ROM from the current file location to find the end of the string.
  //skip() will skip over the text; and hook() will insert a jsl hook and then skip over the text.
  macro scan() {
    string.found = 0
    string.index = 0

    //the longest string is 42 bytes; but add a bounds check anyway for good measure
    while string.found == 0 && string.index < 64 {
      variable byte = read(origin() + string.index)
      if string.found == 0 && byte == $ff {
        //strings always end with $ffff; but the terminal marker is just $ff
        string.found = origin() + string.index + 2 | base()
      }
      string.index = string.index + 1
    }

    //ensure origin points at a "jsr $4a1e" instruction
    if read(origin() + 0) != $20 {; string.found = 0; }
    if read(origin() + 1) != $1e {; string.found = 0; }
    if read(origin() + 2) != $4a {; string.found = 0; }
  }

  macro skip() {
    string.scan()
    if string.found == 0 || string.index < 4 {
      error "string.skip() failed"
    }
    jmp string.found
  }

  macro hook(target) {
    string.scan()
    if string.found == 0 || string.index < 7 {
      error "string.hook() failed"
    }
    jsl {target}
    jmp string.found
  }
}

//these strings exist as leftover code that is inaccessible in the ROM.
//they are skipped here for the sake of completeness and documentation.
namespace unusedStrings {
  enqueue pc

  seek($ee6f89); rtl            //subroutine entry point
  seek($ee6fab); string.skip()  //"MP"
  seek($ee6fb8); string.skip()  //"SP"

  seek($ee7087); rtl            //subroutine entry point
  seek($ee70a6); string.skip()  //"MP"
  seek($ee70b3); string.skip()  //"SP"

  dequeue pc
}

//used by various routines to decode A into a dragon name index
//A => encoded dragon index
//A <= decoded dragon index
macro getDragonName() {
  php; rep #$30; phx
  and #$00ff; mul(64); tax
  lda $7e2111,x; and #$00ff
  plx; plp
}

//this routine replaces $ee5001 in the original code to draw window borders with custom corners.
//X => width
//Y => height
//$001860 => X,Y position
//$7ec400 => tilemap address
macro drawWindow(variable priority, variable line, variable topEdge, variable topLine, variable bottomEdge, variable bottomLine) {
  variable(2, count)
  variable(2, width)
  variable(2, height)

  namespace border {
    constant topLeft     = $2000|topEdge
    constant top         = $2000|topLine
    constant topRight    = $6000|topEdge
    constant left        = $0000|line|priority
    constant right       = $6000|line
    constant bottomLeft  = $a000|bottomEdge
    constant bottom      = $a000|bottomLine
    constant bottomRight = $e000|bottomEdge
  }

  enter; ldb #$7e
  tya; sta height
  txa; sta width
  lda.w tilemap.address; tax

  lda.w #border.topLeft
  sta.w tilemap.location,x; inx #2

  lda width; dec #2; tay
  lda.w #border.top
-;sta.w tilemap.location,x; inx #2
  dey; bne -

  lda.w #border.topRight
  sta.w tilemap.location,x

  lda.w tilemap.address; add #$0040; tax
  lda height; dec #2; tay
  lda.w #border.left
-;sta.w tilemap.location,x
  pha; txa; add #$0040; tax; pla
  dey; bne -
  phx

  lda.w tilemap.address; add width; add width; add #$0040; dec #2; tax
  lda height; dec #2; tay
  lda.w #border.right
-;sta.w tilemap.location,x
  pha; txa; add #$0040; tax; pla
  dey; bne -

  plx
  lda.w #border.bottomLeft
  sta.w tilemap.location,x; inx #2

  lda width; dec #2; tay
  lda.w #border.bottom
-;sta.w tilemap.location,x; inx #2
  dey; bne -

  lda.w #border.bottomRight
  sta.w tilemap.location,x

  leave; rtl
}

function drawWindowBG3 {
  drawWindow($2000,$f8,$eb,$ec,$eb,$ec)
}

function drawWindowOverview {
  drawWindow($2000,$f8,$fd,$fe,$fd,$fe)
}

function drawWindowPaged {
  drawWindow($2000,$f8,$fd,$fe,$fb,$fc)
}

function drawWindowMagicItem {
  drawWindow($0000,$f8,$eb,$ec,$eb,$ec)
}

codeCursor = pc()

}
