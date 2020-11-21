namespace menu {

seek(codeCursor)

//useful routine hooks:
//jsl $ee4caa (--- number)
//jsl $ee4ddc (32-bit number)
//jsl $ee4e4e (16-bit number)
//jsr $4a1e   (string literal)

namespace palette {
  //add yellow text color to palette 0 entries 13-15
  enqueue pc
  //originally:  dw color( 0, 0, 0); dw color( 0, 0, 0); dw color( 0, 0, 0)
  seek($ee85ea); dw color(31,31, 0); dw color(15,15, 0); dw color( 3, 5, 5)
  dequeue pc
}

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

//0x001-0x027 =  39 tiles
//0x030-0x0e7 = 184 tiles
//0x0eb-0x0ee =   4 tiles
//0x0f1-0x0f2 =   2 tiles
//0x0f8-0x0fe =   7 tiles (= 236 tiles/bank 0)
//0x198-0x1ff = 104 tiles
//0x280-0x2ff = 128 tiles
//0x318-0x3ff = 232 tiles (= 700 tiles/banks 0-3)

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
            if bank0 + length <= $0e7 {
              dw bank0; bank0 = bank0 + length
            } else if bank1 + length <= $1ff {
              dw bank1; bank1 = bank1 + length
            } else if bank2 + length <= $2ff {
              dw bank2; bank2 = bank2 + length
            } else if bank3 + length <= $3ff {
              dw bank3; bank3 = bank3 + length
            } else {
              allocator.debug()
              error "allocator exhausted all available tiles"
            }
            amount = amount - 1
          }
        }
      }
    }
  }

  macro index(define name) {
    pha; getTileIndex(allocator.{name}.index, allocator.{name}.count)
    asl; tax; lda allocator.{name}.table,x; tax; pla
  }

  macro lookup(define name) {
    asl; tax; lda allocator.{name}.table,x; tax
  }

  macro debug() {
    print  "$", hex:allocator.bank0
    print ",$", hex:allocator.bank1
    print ",$", hex:allocator.bank2
    print ",$", hex:allocator.bank3, "\n"
  }
}

namespace tilemap {
  function write {
    phb; ldb #$7e
    txa; ora $001862
    pha; lda $001860; tax; pla
    cpy #$0000
  -;beq +
    sta $c400,x
  //stz $c3c0,x
    inc; inx #2; dey; bra -
  +;txa; sta $001860
    lda #$0001; sta $00185a
    plb; rtl
  }
}

namespace write {
  //A = tile count
  //X = target index
  //Y = source index
  macro bpp2(variable source) {
    enter; ldb #$00
    jsl vsync
    pha; tya; mul(16); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; mul(16); add #$8000; lsr; sta $2116
    tya; mul(16); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    rep #$30; jsl tilemap.write
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

  //A = tile count
  //X = target index
  //Y = source index
  macro bpp4(variable source) {
    enter; ldb #$00
    jsl vsync
    pha; tya; mul(32); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; mul(32); add #$2000; lsr; sta $2116
    tya; mul(32); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    rep #$30; jsl tilemap.write
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

//these are strings I haven't encountered in-game yet.
//they need to be located to be hooked properly.
//for now, blank the strings and keep track of them here.
namespace elusiveStrings {
  enqueue pc
  seek($ee6fab); string.skip()  //"MP"
  seek($ee6fb8); string.skip()  //"SP"
  seek($ee70a6); string.skip()  //"MP"
  seek($ee70b3); string.skip()  //"SP"
  dequeue pc
}

//many subroutines that set the Y cursor position would call jsr $2ae9 and then adc after.
//rather than attempt to locate all such instances, the multiplication function has been
//patched to clear the carry instead.
namespace multiplyCarryFix {
  enqueue pc
  seek($ee2ae9); {
  //clc; php; sep #$20
  //pha; lda $00; sta $004202
  //pla; sta $004203; nop #4
  //lda $004216; sta $04; xba
  //lda $004217; sta $05; xba
  //plp; rts
  }
  dequeue pc

  //known bugged examples:
  //------
  //eea10a  jsr $2ae9; adc #$0002  //formation and equipment overview screens
  //eea262  jsr $2ae9; adc #$0002  //formation and equipment overview screens
  //eeeda7  jsr $2ae9; adc #$0002  //inventory screen
  //------
}

//used by various routines to decode A into a dragon name index
macro getDragonName() {
  php; rep #$30; phx
  and #$00ff; mul(64); tax
  lda $7e2111,x; and #$00ff
  plx; plp
}

//this routine replaces $ee5001 in the original code to draw window borders with custom corners.
//X = width
//Y = height
//$001860 = X,Y position
//$7ec400 = tilemap address
macro drawWindow(variable line, variable topEdge, variable topLine, variable bottomEdge, variable bottomLine) {
  variable(2, count)
  variable(2, width)
  variable(2, height)

  namespace border {
    constant topLeft     = $2800|topEdge
    constant top         = $2800|topLine
    constant topRight    = $6800|topEdge
    constant left        = $2800|line
    constant right       = $6800|line
    constant bottomLeft  = $a800|bottomEdge
    constant bottom      = $a800|bottomLine
    constant bottomRight = $e800|bottomEdge
  }

  enter
  ldb #$7e
  tya; sta height
  txa; sta width
  lda $001860; tax

  lda.w #border.topLeft
  sta $c400,x; inx #2

  lda width; dec #2; tay
  lda.w #border.top
-;sta $c400,x; inx #2
  dey; bne -

  lda.w #border.topRight
  sta $c400,x

  lda $001860; add #$0040; tax
  lda height; dec #2; tay
  lda.w #border.left
-;sta $c400,x
  pha; txa; add #$0040; tax; pla
  dey; bne -
  phx

  lda $001860; add width; add width; add #$0040; dec #2; tax
  lda height; dec #2; tay
  lda.w #border.right
-;sta $c400,x
  pha; txa; add #$0040; tax; pla
  dey; bne -

  plx
  lda.w #border.bottomLeft
  sta $c400,x; inx #2

  lda width; dec #2; tay
  lda.w #border.bottom
-;sta $c400,x; inx #2
  dey; bne -

  lda.w #border.bottomRight
  sta $c400,x

  leave; rtl
}

//this routine replaces $ee5001 in the original code to draw a window border on BG2.
//this is needed because the original game didn't take BG3's VOFS HDMA writes into account.
//BG2 tiles are always 8 pixels tall; but BG3 tiles are 12 pixels tall (for (han)dakuten.)
//this routine considers the window height and uses different tiles along the bottom row.
//the result ensures an even spacing at both the top and bottom of the window.
//X = width
//Y = height (ignored)
//$00 = count (of items, spells, etc)
function drawWindowBG2 {
  variable(2, count)

  enter
  lda $00; and #$000f; sta count
  bne +; inc; sta count; +  //add one line for "No Items" string if count == 0

  dec; lsr; inc
  mul(3); pha
  lda count; dec
  and #$0001; add $01,s
  tay; pla

  lda count; and #$0001
  cmp #$0000; bne +; jsl drawBottomEven; leave; rtl; +
  cmp #$0001; bne +; jsl drawBottomOdd;  leave; rtl; +
  leave; rtl

  function drawBottomEven {
    drawWindow($f8,$fb,$fc,$f9,$fa)
  }

  function drawBottomOdd {
    drawWindow($f8,$fb,$fc,$fd,$fe)
  }
}

function drawWindowBG3 {
  drawWindow($f8,$eb,$ec,$eb,$ec)
}

function drawWindowOverview {
  drawWindow($f8,$fd,$fe,$fd,$fe)
}

codeCursor = pc()

}
