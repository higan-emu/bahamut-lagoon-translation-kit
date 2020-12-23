namespace field {

seek(codeCursor)

namespace command {
  constant tileBank1    = $01
  constant tileBank2    = $02
  constant paletteWhite = $03
  constant paletteGray  = $04
  constant paletteIvory = $05
}

namespace glyph {
  constant hp        = $de  //$de-$df
  constant defeated  = $f2
  constant petrified = $f1
  constant sleeping  = $ee
  constant poisoned  = $f0
  constant bunny     = $ec
  constant bingo     = $ed
}

//this code handles copying the 8-bit string at $00,x to the 16-bit WRAM tilemap.
//hooks here provide custom control codes such as bank switching and palette changes.
namespace tilemapTransfer {
  enqueue pc
  seek($c0de35); jml hook; nop #4
  seek($c0caeb); nop #2  //disable (han)dakuten support to free up $00-32 tile range
  dequeue pc

  constant read    = $c0de32
  constant write   = $c0de3d
  constant control = $c0de44

  //------
  //c0de32  lda $00,x
  //c0de34  inx
  //c0de35  cmp #$ff
  //c0de37  beq $de44
  //c0de39  cmp #$fe
  //c0de3b  beq $de44
  //c0de3d  jsr $cade  ;write 16-bit tile to tilemap
  //------
  //A => 8-bit tile
  function hook {
    constant attributes = $10  //vhopppcc

    cmp.b #command.lineFeed;     bcc +; jml control; +
    cmp.b #command.tileBank1;    bne +; lda.b attributes; and #$fc; ora #$01; sta.b attributes; jml read; +
    cmp.b #command.tileBank2;    bne +; lda.b attributes; and #$fc; ora #$02; sta.b attributes; jml read; +
    cmp.b #command.paletteWhite; bne +; lda.b attributes; and #$e3; ora #$00; sta.b attributes; jml read; +
    cmp.b #command.paletteGray;  bne +; lda.b attributes; and #$e3; ora #$04; sta.b attributes; jml read; +
    cmp.b #command.paletteIvory; bne +; lda.b attributes; and #$e3; ora #$08; sta.b attributes; jml read; +
    jml write
  }
}

namespace index {
  namespace for {
    variable(2, bpp2)
    variable(2, bpp4)
    variable(2, int3)
    variable(2, int4)
  }

  macro bpp2() {
    pha; getTileIndex(index.for.bpp2, 16)
    asl; tax; lda index.table9x16,x; tax; pla
  }

  macro bpp4() {
    pha; getTileIndex(index.for.bpp4, 16)
    asl; tax; lda index.table9x16,x; tax; pla
  }

  macro int3() {
    pha; getTileIndex(index.for.int3, 16)
    asl; tax; lda index.table3x16,x; tax; pla
  }

  macro int4() {
    pha; getTileIndex(index.for.int4, 16)
    asl; tax; lda index.table4x16,x; tax; pla
  }

  //reserved tiles (2bpp):
  //$00-$2f = graphical overlay + movement cutouts
  //$de-$e2 = static tiles ("HP") + window borders
  //$ec-$f2 = status icons + space
  //$fe-$ff = control codes

  //available tiles (2bpp):
  //$30-$dd = 174 tiles
  //$e3-$eb =   9 tiles
  //$f3-$fd =  11 tiles

  //reserved tiles (4bpp):
  //$00-$2f = large proportional font (single-line)
  //$e0-$e2 = window borders
  //$ef     = space
  //$fe-$ff = control codes

  //available tiles (4bpp):
  //$30-$bf = 144 tiles
  //$c0-$df =  32 tiles (2bpp $180-$1bf = 64 tiles)
  //$e3-$fd =  27 tiles (unused)

  //$2c0-$2dd + $2e3-$2eb + $2f3-$2fb
  table3x16: {
    dw $2c0,$2c3,$2c6,$2c9,$2cc,$2cf,$2d2,$2d5,$2d8,$2db
    dw $2e3,$2e6,$2e9
    dw $2f3,$2f6,$2f9
  }

  //$180-$1bf
  table4x16: {
    dw $180,$184,$188,$18c,$190,$194,$198,$19c
    dw $1a0,$1a4,$1a8,$1ac,$1b0,$1b4,$1b8,$1bc
  }

  //$230-$2bf
  table9x16: {
    dw $230,$239,$242,$24b,$254,$25d,$266,$26f
    dw $278,$281,$28a,$293,$29c,$2a5,$2ae,$2b7
  }
}

namespace write {
  //A => tile count
  //X => source index
  //Y => target index
  macro bpp2(variable source) {
    enter; ldb #$00
    vsync()
    pha; tya; mul(16); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; mul(16); add #$6000; lsr; sta $2116
    tya; mul(16); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave
  }
  function bpp2 {
    php; rep #$10; phy
    ldy #$0000; write.bpp2(render.buffer)
    ply; plp; rtl
  }
  macro bpp2() {
    jsl write.bpp2
  }

  //A => tile count
  //X => source index
  //Y => target index
  macro bpp4(variable source) {
    enter; ldb #$00
    vsync()
    pha; tya; mul(32); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; and #$00ff; mul(32); add #$6000; lsr; sta $2116
    tya; mul(32); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave
  }
  function bpp4 {
    php; rep #$10; phy
    ldy #$0000; write.bpp4(render.buffer)
    ply; plp; rtl
  }
  macro bpp4() {
    jsl write.bpp4
  }
}

//menus originally had two lines per item to allow for (han)dakuten.
//since these aren't used in the translation, remove the line
namespace shrinkMenuHeight {
  enqueue pc
  //move the text one line up
  seek($c0e0b5); adc #$0004  //adc #$0046
  seek($c0ead7); adc #$15    //adc #$1b
  //remove one line from the menu height
  seek($c0e1e4); jml hookCommandMenu; nop #2
  seek($c0e1c0); jml hookOptionsMenu; nop #2
  dequeue pc

  //------
  //c0e1e4  lda $b6  ;load number of menu items
  //c0e1e6  asl
  //c0e1e7  jsr $e288
  //------
  function hookCommandMenu {
    lda $b6; asl; dec
    pea $e1e9; jml $c0e288
  }

  //------
  //c0e1c0  lda $b6  ;load number of menu items
  //c0e1c2  asl
  //c0e1c3  jsr $e288
  //------
  function hookOptionsMenu {
    lda $b6; asl; dec
    pea $e1c5; jml $c0e288
  }
}

//reposition "End Phase","Temporary Save","Sound Mode" menu
namespace options {
  enqueue pc
  seek($c0e1b4); lda #$0a    //window width
  seek($c0e1b8); ldx #$0028  //window tilemap pitch
  seek($c0c933); lda #$0f    //shadow box top
  seek($c0c939); lda #$38    //shadow box height
  seek($c0c93f); lda #$50    //shadow box left
  seek($c0c945); lda #$af    //shadow box right
  seek($c0c908); lda #$4e    //X cursor offset
  seek($c0c901); ldy #$4298  //window tilemap position
  dequeue pc
}

//reposition ["Yes","No"] and ["Yes","Stop"] menus
namespace choice {
  enqueue pc
  seek($c00413); lda #$ffff  //disables the shadow box until
  seek($c00430); lda #$00    //the menu width can be determined
  seek($c0c964); jsl setWindowPosition
  dequeue pc

  //the shadow box computation must be deferred until after the menu has been built
  //------
  //c00413  lda #$efa0   ;set shadow box position to #$a0-#$ef
  //c00416  sta $7e7b1c  ;store the value
  //......
  //c00430  lda #$30     ;set shadow box height (two entries + (han)dakuten line)
  //c00432  sta $7e7b0f  ;store the value
  //......               ;(~700 instructions doing various other computations)
  //c0c95d  ldy #$42ac   ;window tilemap start position
  //......
  //c0c964  lda #$a5     ;X cursor position
  //c0c966  sta $b7      ;store the value
  //------
  //Y <= window tilemap position
  function setWindowPosition {
    php; rep #$30; pha
    jsl getMinimumMenuWidth; inc #3   //menu width in tiles + border tiles + cursor tile
    asl; pha                          //multiply by 16-bit tilemap entry size
    lda #$42c0; sub $01,s; tay; pla   //find the tilemap start from the right
    asl #2; sep #$20; pha             //now multiply width by 8x8 tile size
    lda #$ee; sub $01,s; sta $b7      //compute the cursor position from the right
    lda #$f0; sub $01,s; sta $7e7b1c  //compute the shadow position from the right
    lda #$e7; sta $7e7b1d             //always end the shadow box at the same position
    lda #$28; sta $7e7b0f             //store the shadow box height: always two entries
    pla; rep #$20                     //clean up the stack
    pla; plp; rtl
  }
}

//determines the minimum number of tiles needed to display a menu.
//does this by finding the longest item in the menu list.
function getMinimumMenuWidth {
  constant menuItems = $00
  constant menuCount = $b6
  constant menuMode  = $b0

  constant menuIndex = $09f0
  constant isTechniqueMenu = $64

  variable(2, minimumWidth)

  php; rep #$30; phx; phy

  ldx.w #menuIndex
  lda.b menuCount; and #$00ff; tay
  lda #$0001; sta minimumWidth
  loop: {
    lda $b0; and #$00ff
    cmp.w #isTechniqueMenu; beq technique

  command:
    phx; lda.b menuItems,x; inc; and #$00ff; tax
    lda lists.commands.widths,x; and #$00ff; plx; inx
    cmp minimumWidth; bcc next
    sta minimumWidth; bra next

  technique:
    phx; lda.b menuItems,x; and #$00ff; tax
    lda lists.techniques.widths,x; and #$00ff; plx; inx
    cmp minimumWidth; bcc next
    sta minimumWidth; bra next

  next:
    dey; bne loop
  }

  lda minimumWidth; inc  //include one tile on the left for the cursor
  ply; plx; plp; rtl
}

//handles window mask coordinates and X cursor position
namespace menuWidthPlacement {
  enqueue pc
  seek($c0ca1a); jsl main; rts
  dequeue pc

  constant windowMaskHeight = $7e7b06  //cutout for color add/sub background
  constant windowPositionX  = $7e7b1a  //lo = X1, hi = X2
  constant gridCursorTileX  = $92
  constant menuItemCount    = $b6
  constant menuCursorPixelX = $b7
  constant indexMode        = $b0  //#$00 = field menu; #$64 = tech menu

  constant borderTileWidth  =  2
  constant windowStartLeft  = 16
  constant windowStartRight = 16

  //Y <= window tilemap position
  function main {
    php; rep #$30; pha; phx

    lda $09,s
    cmp #$9cad; beq terrain

  menu:
    //compute the menu position as if it should appear on the left
    jsl getMinimumMenuWidth
    add.w #borderTileWidth
    asl #3; dec  //convert tile count to pixel count
    add.w #windowStartRight; xba
    add.w #windowStartLeft
    sta.l windowPositionX
    bra next

  terrain:
    jsl terrain.width
    add.w #borderTileWidth
    asl #3; dec
    add.w #windowStartRight; xba
    add.w #windowStartLeft
    sta.l windowPositionX
    bra next

  next:
    //whether the menu is placed on the left or right is based on the grid cursor:
    //#$0002-0008 places the menu on the left, #$0009-0015 places the menu on the right
    //if the menu should be on the right, swap the window position values here
    pha; lda.b gridCursorTileX; and #$00ff; cmp #$0009; pla; bcs +
    lda #$ffff; sec; sbc.l windowPositionX; xba; sta.l windowPositionX; +

    //now set the tilemap write location and menu cursor icon positions:
    and #$00ff; lsr #2; clc; adc #$4104; tay  //set tilemap write location
    sep #$20; lda.l windowPositionX; dec #2; sta.b menuCursorPixelX  //X cursor position
    lda.b menuItemCount; asl; inc; asl #3; sta.l windowMaskHeight

    rep #$30; plx; pla; plp; rtl
  }
}

//handles tilemap width and pitch
namespace menuWidthTilemap {
  enqueue pc
  seek($c0e1d8); jsl main; nop #5
  dequeue pc

  constant menuWidth = $0a
  constant menuPitch = $14
  constant indexMode = $b0

  constant lineWidth   = 64
  constant borderWidth =  2

  function main {
    enter

    lda $0f,s  //determine which parent function called this function
    cmp #$9cb1; beq terrain

  menu:
    jsl getMinimumMenuWidth
    sep #$20; sta.b menuWidth
    bra next

  terrain:
    jsl terrain.width
    sep #$20; sta.b menuWidth
    bra next

  next:
    //compute the number of tilemap bytes to skip to seek to the next menu item:
    //menuPitch <= $40 - (menuWidth + borderWidth) * 2
    lda.b #lineWidth
    sub.b menuWidth; sub.b menuWidth
    sub.b #borderWidth*2
    rep #$20; sta.b menuPitch

    leave; rtl
  }
}

namespace menu {
  enqueue pc
  seek($c0e0c5); jsl main; rts
  dequeue pc

  constant menuItems  = $00  //list of item strings at $00
  constant menuHeight = $0a  //number of items in the menu
  constant menuPitch  = $14  //tiles from end of one line to start of next line
  constant mapAddress = $16  //tilemap write location
  constant menuIndex  = $1a  //the start index into the list at $00
  constant indexMode  = $b0  //#$00 = field menu; #$64 = tech menu

  constant isTechniqueMenu = $64

  variable(2, tileIndex)
  variable(2, itemIndex)
  variable(2, itemCount)
  variable(2, menuWidth)

  function main {
    enter; ldb #$7e

    //compute the menu width based off the menu pitch
    sep #$20; lda #$40; sub.b menuPitch; lsr; dec #3
    rep #$20; and #$00ff; sta menuWidth

    //move the menu cursor offscreen while drawing the menu.
    //this prevents the cursor overlapping text when the menu width increases.
    //sprite 0 may not be a cursor, so the WRAM OAM table is checked first.
    //the cursor always uses #$30; player sprites use different values.
    lda $0803; and #$00ff; cmp #$0030; bne +
    vsync(); lda #$0000; sta $002102
    sep #$20; lda #$f0; sta $002104; sta $002104; rep #$20; +

    lda.b mapAddress; add #$0040; tay
    lda.b menuHeight; and #$00ff; sta itemCount
    lda #$0000; sta itemIndex
    loop: {
      jsl writeData
      jsl writeMap
      lda itemIndex; inc; sta itemIndex
      cmp itemCount; bcc loop
    }

    leave; rtl
  }

  function writeData {
    lda.b menuIndex; add itemIndex; tax
    lda.b menuItems,x; tay
    index.bpp4(); txa; sta tileIndex
    lda.b indexMode; and #$00ff; cmp.w #isTechniqueMenu; jeq technique
  command:
    tya; inc; and #$00ff; mul(9); tay
    lda #$0009; write.bpp4(lists.commands.bpo4); rtl
  technique:
    tya; and #$00ff; mul(8); tay
    lda #$0009; write.bpp4(lists.techniques.bpo4); rtl
  }

  function writeMap {
    lda itemIndex; mul(128); add.b mapAddress; tay
    lda menuWidth; tax
    lda tileIndex; ora #$2300  //add tile attributes to tile index
  -;sta $0040,y
    inc; iny #2
    dex; bne -
  +;rtl
  }
}

//write index into the output string
variable(2, cursor)

namespace name {
  enqueue pc
  seek($c0e051); jsl player; rts
  seek($c0dc5f); jsl dragon; rts
  seek($c0dd5e); jsl enemy; rts
  dequeue pc

  variable(2, type)
  namespace type {
    constant player = 0
    constant dragon = 1
    constant enemy  = 2
  }

  //A => player name
  function player {
    enter; ldb #$31; stz.w cursor
    pha; lda.w #type.player; sta type; pla
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; index.bpp2(); write.bpp2(names.buffer.bpp2)
    txa; sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #' '
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  static:
    mul(8); tay
    lda #$0006; index.bpp2(); write.bpp2(lists.names.bpp2)
    txa; sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #' '
    sta.w output,x; inx
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }

  //A => dragon name
  function dragon {
    enter; ldb #$31; stz.w cursor
    pha; lda.w #type.dragon; sta type; pla
    and #$00ff; mul(8); tay
    lda #$0008; index.bpp2(); write.bpp2(names.buffer.bpp2)
    txa; sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #' '
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }

  //A => enemy name
  function enemy {
    enter; ldb #$31; stz.w cursor
    pha; lda.w #type.enemy; sta type; pla
    and #$00ff; mul(8); tay
    lda #$0008; index.bpp2(); write.bpp2(lists.enemies.bpp2)
    txa; sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #' '
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }
}

namespace status {
  enqueue pc
  seek($c0e00c); jsl main; jmp $e01c  //players
  seek($c0dcc6); jsl main; rts        //dragons and enemies
  dequeue pc

  variable(2, ailments)
  variable(2, enchants)

  //Z <= icons present (0 => clear status area)
  function main {
    enter; ldb #$31
    sep #$20; ldx $18
    lda $7e0001,x; and.b #status.ailment.mask; sta ailments
    lda $7e0003,x; and.b #status.enchant.mask; sta enchants

    sep #$30; ldx.w cursor; ldy.b #0
    lda ailments; and.b #status.ailment.defeated;  beq +; lda.b #glyph.defeated;  sta.w output,x; inx; iny; +
    lda ailments; and.b #status.ailment.petrified; beq +; lda.b #glyph.petrified; sta.w output,x; inx; iny; +
    lda ailments; and.b #status.ailment.sleeping;  beq +; lda.b #glyph.sleeping;  sta.w output,x; inx; iny; +
    lda ailments; and.b #status.ailment.poisoned;  beq +; lda.b #glyph.poisoned;  sta.w output,x; inx; iny; +
    lda ailments; and.b #status.ailment.bunny;     beq +; lda.b #glyph.bunny;     sta.w output,x; inx; iny; +
    lda enchants; and.b #status.enchant.bingo;     beq +; lda.b #glyph.bingo;     sta.w output,x; inx; iny; +

    //fill remaining region with spaces (7 for dragons and enemies; 8 for players)
    lda.b #' '
  -;cpy.b #7; bcs +
    sta.w output,x; inx; iny; bra -
  +;lda name.type; cmp.b #name.type.player; bne +; lda.b #' '
    sta.w output,x; inx
  +;stx.w cursor
    leave; clz; rtl
  }
}

namespace class {
  enqueue pc
  seek($c0e027); jsl player; rts
  seek($c0dbcb); jsl dragon; nop #3
  seek($c0dcf7); jsl enemy; jmp $dd21
  dequeue pc

  //A => player class
  function player {
    enter; ldb #$31
    and #$00ff; mul(8); tay

    ldx $18
    lda $7e0001,x; and.w #status.ailment.mask; pha
    lda $7e0003,x; and.w #status.enchant.mask; ora $01,s; sta $01,s; pla
    beq +; leave; rtl; +  //skip printing class name if there are icons

    lda #$0008; index.bpp2(); write.bpp2(lists.classes.bpp2)
    txa; sep #$30; ldx.w cursor; dex #8
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }

  //A => dragon class
  function dragon {
    enter; ldb #$31; stz.w cursor
    and #$00ff; mul(8); tay
    lda #$0008; index.bpp2(); write.bpp2(lists.dragons.bpp2)
    txa; sep #$30; ldx.w cursor; pha; lda.b #' '
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }

  function enemy {
    enter; ldb #$31

    //determine whether this enemy is a boss or not
    ldx $18
    lda $7e0024,x; ora $7e001c,x
    and #$0080; bne boss; leave; rtl; +  //skip printing if this is not a boss

  boss:
    ldx #$0000; ldy.w #strings.bpp2.boss
    lda #$0003; index.bpp2(); write.bpp2(lists.strings.bpp2)
    txa; sep #$30; ldx.w cursor; dex #3; pha; lda.b #command.paletteIvory
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.paletteWhite
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }
}

namespace level {
  enqueue pc
  seek($c0deb7); jsl main; rts
  dequeue pc

  function main {
    enter; ldb #$31
    ldx $18; lda $7e0002,x; and #$00ff; min.w(100); mul(4); tay  //100+ => "??"
    lda #$0004; index.int4(); write.bpp2(lists.levels4.bpp2)
    txa; sep #$30; ldx.w cursor; pha; lda.b #command.tileBank1
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.tileBank2
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }
}

namespace hp {
  enqueue pc
  seek($c0de81); jsl main; rts
  dequeue pc

  function main {
    variable(2, counter)

    enter; ldb #$31
    ldx $18; lda $7e0005,x; ldx #$0000
    cmp.w #10000; bcs unknown; append.integer_4(); bra +
    unknown:; append.literal("^^^^"); +
    lda #$0003; render.small.bpp2()
    index.int3(); write.bpp2()
    txa; sep #$30; ldx.w cursor; pha; lda.b #glyph.hp
    sta.w output,x; inx; inc
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #' '
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }
}

namespace mp {
  enqueue pc
  seek($c0de4f); jsl main; rts
  seek($c0dd89); jsl none; rts
  seek($c0de10); nop #4  //(main) disable string terminal write to output,x
  seek($c0dd48); nop #4  //(none) disable string terminal write to output,x
  dequeue pc

  variable(2, marker)

  //A => original font marker tile
  function main {
    enter; ldb #$31

    ldx #$0000
    append.alignRight()
    and #$00ff; cmp #$00d8; beq sp  //$d7 = MP, $d8 = SP
    mp:; append.literal("MP"); append.alignSkip(2); bra +
    sp:; append.literal("SP"); append.alignSkip(3); +

    phx; ldx $18; lda $7e0009,x; plx
    cmp.w #1000; bcs unknown; append.integer_3(); bra +
    unknown:; append.literal("^^^"); +
    lda #$0004; render.small.bpp2()
    index.int4(); write.bpp2()
    txa; sep #$30; ldx.w cursor; pha; lda.b #command.tileBank1
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }

  function none {
    enter; ldb #$31

    ldx #$0000
    append.alignRight()
    append.literal("MP")
    append.alignSkip(2)
    append.literal("~~~")
    lda #$0004; render.small.bpp2()
    index.int4(); write.bpp2()
    txa; sep #$30; ldx.w cursor; pha; lda.b #command.tileBank1
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }
}

namespace dragonCommand {
  enqueue pc
  seek($c0db8f); nop #3               //disable static "Command:" text:
  seek($c0db9b); jsl main; jmp $dbb5  //render it together with current command
  dequeue pc

  //A => dragon command
  function main {
    enter; ldb #$31
    and #$00ff
    cmp.w #3; bcc +; ldx.w #21; lda.w #command.terminal; sta.w output,x; leave; rtl; +  //should never occur
    cmp.w #0; bne +; ldy.w #strings.bpp2.commandCome;   +
    cmp.w #1; bne +; ldy.w #strings.bpp2.commandGo;     +
    cmp.w #2; bne +; ldy.w #strings.bpp2.commandWait;   +
    lda #$0009; index.bpp2(); write.bpp2(lists.strings.bpp2)
    txa; sep #$30; ldx.b #21
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }
}

namespace techniqueSmall {
  enqueue pc
  seek($c05315); jsl setCursorAttributes; nop
  seek($c0d6ab); jsl main; jmp $d6b6
  seek($c0d648); ldy #$c444  //move the start of the line one tile to the left
  seek($c0d781); ldx #$062c  //move the start of MP/SP numbers one tile to the right
  seek($c0ea96); lda #$ff    //move the left-side cursor five pixels to the left
  seek($c0eaa1); lda #$77    //move the right-side cursor five pixels to the left
  dequeue pc

  //originally, the sprite cursor could only be positioned from X=0-255.
  //the technique list required an extra tile; and X=0 caused the cursor to touch the text.
  //this function hooks the routine that sets the OAM upper-table attributes,
  //so that when a sprite at position #$ff (255) is detected, it places it at #$1ff (-1) instead.
  //------
  //c0ea4f  jsr $ea94    ;call sprite subroutine
  //......
  //c05315  ora $10      ;set sprite attributes
  //c05317  sta $0a00,y  ;store in OAM upper table
  //------
  function setCursorAttributes {
    ora $10; sta $0a00,y                 //store sprite attributes into OAM upper table
    rep #$20; lda $06,s                  //determine the parent function caller of this code
    cmp #$ea51; sep #$20; beq +; rtl; +  //ensure the caller is the technique menu
    cpy #$0000; beq +; rtl; +            //the cursor always uses the first sprite slot
    lda $0800; cmp #$ff; beq +; rtl; +   //check if X=-1
    lda $0a00; ora #$40; sta $0a00; rtl  //set X.d8=1 if so (255 => -1)
  }

  //------
  //c0d6ab  lda $1a    ;load the technique name
  //c0d6ad  jsr $d6d0  ;add it to the string
  //c0d6b0  jsr $d6eb  ;print the level (if not $ff)
  //c0d6b3  jsr $d774  ;print the cost  (if not $00)
  //------
  function main {
    variable(2, palette)
    constant name  = $1a
    constant level = $19
    constant cost  = $1b

    enter; ldb #$31; stz.w cursor

    //determine which palette to use for MP/SP text
    lda.w #command.paletteIvory; sta palette    //default to ivory palette
    ldx $1e; lda $7e0011,x; and #$00ff          //check if the text will be grayed out
    cmp #$00fe; bne +                           //(eg if there is insufficient MP/SP)
    lda.w #command.paletteGray; sta palette; +  //if so, use gray palette instead

  writeName:  //write the technique name
    lda.b name; and #$00ff; mul(8); tay
    lda #$0008; index.bpp2(); write.bpp2(lists.techniques.bpp2); txa
    sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; stx.w cursor; rep #$30

  writeLevel:  //write the technique level, unless it is $ff
    lda.b level; and #$00ff; cmp #$00ff; jeq writeCost
    mul(3); tay
    phx; lda #$0003; index.int3(); write.bpp2(lists.levels.bpp2); txa; plx
    sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; stx.w cursor; rep #$30

  writeCost:  //write the technique cost, unless it is $00
    lda.b cost; and #$00ff; jeq writeTerminal
    mul(3); tay
    phx; lda #$0003; index.int4()

    //write either "## MP" or "## SP", depending on the technique
    pha; phx
    lda.b name; and #$00ff; cmp #$004c; bcc sp
    mp:; plx; pla; write.bpp2(lists.costsMP.bpp2); bra +
    sp:; plx; pla; write.bpp2(lists.costsSP.bpp2); +
    txa; plx

    sep #$30; ldx.w cursor; pha; lda palette
    sta.w output,x; inx; lda.b #command.tileBank1
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; stx.w cursor; rep #$30

  writeTerminal:
    sep #$30; ldx cursor; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }
}

namespace itemDrop {
  enqueue pc
  seek($c0626d); jsl item; nop #7
  seek($c06278); jsl quantity; nop
  seek($c061f1); jsl piro; jmp $6213
  seek($c06224); ldy #$c442  //item name line position (left)
  seek($c0623b); adc #$0020  //item name line position (right)
  seek($c06253); adc #$0060  //item name line pitch
  dequeue pc

  //print item names: unlike original game, item icons have been added
  //X => item table index
  function item {
    constant items = $0000

    enter; ldb #$31; stz.w cursor
    lda.w items,x; and #$007f
    mul(9); tay
    lda #$0009; index.bpp2(); write.bpp2(lists.items.bpp2)
    txa; sep #$30; ldx.w cursor
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #' '
    sta.w output,x; inx
    sta.w output,x; inx; stx.w cursor
    leave; rtl
  }

  function quantity {
    constant value = $1b
    constant index = $1c

    ldy.b index
    enter; ldb #$31
    lda.b value; and #$00ff; min.w(100); mul(3); tay  //100+ => "??"
    lda #$0003; index.int3(); write.bpp2(lists.counts.bpp2)
    txa; sep #$30; ldx.w cursor; pha; lda.b #command.paletteIvory
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }

  function piro {
    constant value = $0370

    enter; ldb #$31; stz cursor
    lda.w value
    ldx #$0000; append.alignRight(); append.integer_5(); append.literal(" Piro")
    lda #$0007; render.small.bpp2()
    index.bpp2(); write.bpp2()
    txa; sep #$30; ldx.w cursor; pha; lda.b #' '
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx
    sta.w output,x; inx; pla
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; inc
    sta.w output,x; inx; lda.b #command.terminal
    sta.w output,x
    leave; rtl
  }
}

codeCursor = pc()

}
