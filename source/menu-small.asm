namespace menu {

seek(codeCursor)

//useful routine hooks:
//jsl $ee4caa (--- number)
//jsl $ee4ddc (32-bit number)
//jsl $ee4e4e (16-bit number)
//jsl $ee5001 (window border)
//jsr $4a1e   (string literal)

namespace palette {
  enqueue pc
  seek($ee85d0)
  ds 2; dw color(31,31,28), color(15,15,15), color( 3, 5, 5)  //palette #0
  ds 2; dw color(20,20,20), color(15,15,15), color( 3, 5, 5)  //palette #1
  ds 2; dw color(17,31,17), color(15,15,15), color( 3, 5, 5)  //palette #2
  ds 2; dw color(31,31,19), color(15,15,15), color( 3, 5, 5)  //palette #3
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
//0x318-0x3f1 = 218 tiles (= 686 tiles/banks 0-3)
//0x3f2-0x3ff =  14 tiles ("Page #/#" / "No Items" text)

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
            } else if bank3 + length <= $3f1 {
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

  macro debug() {
    print  "$", hex:allocator.bank0
    print ",$", hex:allocator.bank1
    print ",$", hex:allocator.bank2
    print ",$", hex:allocator.bank3, "\n"
  }
}

namespace tilemap {
  constant modified   = $00185a  //set to request VRAM upload during NMI
  constant address    = $001860  //location to write to within tilemap
  constant attributes = $001862  //palette and flip tile attributes
  constant tilemap    = $7ec400  //location of tilemap in WRAM

  //X => starting tile#
  //Y => number of tiles to write
  //address => address + Y*2
  function write {
    phb; php; ldb #$7e; rep #$20
    txa; ora attributes
    pha; lda address; tax; pla
    cpy #$0000
  -;beq +; sta.w tilemap,x
    inc; inx #2; dey; bra -
  +;txa; sta address
    lda #$0001; sta modified
    plp; plb; rtl
  }

  macro read() {
    phx; lda tilemap.address; tax
    lda $7ec400,x; plx
  }

  macro write(variable character) {
    phx; lda tilemap.address; tax
    inc #2; sta tilemap.address
    lda.w #character
    ora tilemap.attributes
    sta $7ec400,x; plx
  }

  macro setAddress(variable address) {
    pha; lda.w #address; sta tilemap.address; pla
  }

  macro setColorNormal() {
    pha; lda #$2000; sta tilemap.attributes; pla
  }

  macro setColorShadow() {
    pha; lda #$2400; sta tilemap.attributes; pla
  }

  macro setColorHeader() {
    pha; lda #$2800; sta tilemap.attributes; pla
  }

  macro setColorYellow() {
    pha; lda #$2c00; sta tilemap.attributes; pla
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

//the original status icon rendering would print tiles for invalid status fields.
//it has been replaced with a routine that only draws valid tiles instead.
//this is done to provide consistency with the field and combat systems.
namespace statusIcons {
  enqueue pc
  seek($ee907a); jsl main; rts
  dequeue pc

  function main {
    variable(2, ailments)  //players and enemies
    variable(2, enchants)  //players only
    variable(2, affinity)  //enemies only
    variable(2, property)  //enemies only

    enter
    ldy #$0008; lda [$44],y; and.w #status.ailments.mask; sta ailments
    ldy #$000a; lda [$44],y; and.w #status.enchants.mask; sta enchants
    ldy #$000a; lda [$44],y; and.w #status.affinity.mask; sta affinity
    ldy #$0038; lda [$44],y; and.w #status.property.mask; sta property

    lda ailments; and.w #status.ailments.bunny;     beq +; tilemap.write($28); +
    lda ailments; and.w #status.ailments.sleeping;  beq +; tilemap.write($2c); +
    lda ailments; and.w #status.ailments.poisoned;  beq +; tilemap.write($2d); +
    lda ailments; and.w #status.ailments.petrified; beq +; tilemap.write($2e); +
    lda ailments; and.w #status.ailments.defeated;  beq +; tilemap.write($2f); +

    lda $0005fc; and #$00ff
    cmp #$0000;  jeq player  //players (magic and item screens)
    cmp #$0001;  jeq player  //players and dragons
    cmp #$0002;  jeq enemy   //enemies
    jmp clear

  player:
    lda enchants; and.w #status.enchants.bingo;     beq +; tilemap.write($ff); +
    jmp clear

  enemy:
    lda affinity; and.w #status.affinity.thunder;   beq +; tilemap.write($f3); +
    lda affinity; and.w #status.affinity.crystal;   beq +; tilemap.write($f4); +
    lda affinity; and.w #status.affinity.poison;    beq +; tilemap.write($f5); +
    lda affinity; and.w #status.affinity.water;     beq +; tilemap.write($f6); +
    lda affinity; and.w #status.affinity.fire;      beq +; tilemap.write($f7); +
    lda property; and.w #status.property.undead;    beq +; tilemap.write($f0); +
    jmp clear

  clear:
    //this function may be updated previous status icons.
    //for instance, using "Cleanup" to remove status ailments.
    //thus, we need to erase all remaining status icons in the tilemap here.
    tilemap.read(); and #$00ff
    cmp.w #$28; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$2c; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$2d; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$2e; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$2f; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$ff; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$f3; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$f4; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$f5; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$f6; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$f7; bne +; tilemap.write($ef); jmp clear; +
    cmp.w #$f0; bne +; tilemap.write($ef); jmp clear; +
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

function drawWindowBG3 {
  drawWindow($2000,$f8,$eb,$ec,$eb,$ec)
}

function drawWindowOverview {
  drawWindow($2000,$f8,$fd,$fe,$fd,$fe)
}

function drawWindowMagicItem {
  drawWindow($0000,$f8,$eb,$ec,$eb,$ec)
}

codeCursor = pc()

}
