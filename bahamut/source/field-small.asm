namespace field {

seek(codeCursor)

//$00-$32 were originally treated as (han)dakuten
//reduce the range to $00-05 so that $06-1f and $30-32 can be used for tiledata
namespace expandAvailableTileRange {
  enqueue pc
  seek($c0de32); read:
  seek($c0de35); test:; cmp #$fe; bcs control; jml hook; return:
  seek($c0de44); control:
  seek($c0cae9); cmp #$06
  dequeue pc

  function hook {
    cmp #$01; bne +; lda $10; and #$fc; ora #$01; sta $10; jml read; +
    cmp #$02; bne +; lda $10; and #$fc; ora #$02; sta $10; jml read; +
    jml return
  }
}

namespace index {
  namespace for {
    variable(2, bpp2)
    variable(2, bpp4)
    variable(2, int2)
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

  macro int2() {
    pha; getTileIndex(index.for.int2, 16)
    asl; tax; lda index.table3x16a,x; tax; pla
  }

  macro int4() {
    pha; getTileIndex(index.for.int4, 16)
    asl; tax; lda index.table3x16b,x; tax; pla
  }

  //reserved tiles (2bpp):
  //$00-1f = graphical overlay
  //$20-22 = unknown (garbled tiles; may be unused)
  //$2c-2f = movement cutout
  //$f6-fc = static tiles ("LV","HP","MP","SP")

  //reserved tiles (4bpp):
  //$00-2f = large proportional font (single-line)

  //reserved tiles (2bpp and 4bpp):
  //$d9-df = element icons
  //$e0-ec = window borders and arrows
  //$ed-f5 = status icons
  //$fe-ff = control codes

  //available tiles (2bpp):
  //$23-2b =  9 tiles

  //available tiles (2bpp and 4bpp):
  //$30-d8 = 185 tiles

  //available extended tiles (2bpp):
  //$c0-d8 = 25*2 = $0180-$01b1 = 50 tiles
  //$f6-fd =  8*2 = $01ec-$01fb = 16 tiles

  //$0223-$02bf + $02c0-$02d7 + $01ec-$01fa
  table3x16a: {
    dw $0223,$0226,$0229,$02c0,$02c3,$02c6,$02c9,$02cc
    dw $02cf,$02d2,$02d5,$01ec,$01ef,$01f2,$01f5,$01f8
  }

  //$0180-$01af
  table3x16b: {
    dw $0180,$0183,$0186,$0189,$018c,$018f,$0192,$0195
    dw $0198,$019b,$019e,$01a1,$01a4,$01a7,$01aa,$01ad
  }

  //$0230-$02bf
  table9x16: {
    dw $0230,$0239,$0242,$024b,$0254,$025d,$0266,$026f
    dw $0278,$0281,$028a,$0293,$029c,$02a5,$02ae,$02b7
  }
}

namespace write {
  //A = tile count
  //X = source index
  //Y = target index
  macro bpp2(variable source) {
    enter; ldb #$00
    jsl vsync
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

  //A = tile count
  //X = source index
  //Y = target index
  macro bpp4(variable source) {
    enter; ldb #$00
    jsl vsync
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
  seek($c0e1e4); jsr $ed2b  //lda $b6; asl
  seek($c0e1c0); jsr $ed2b  //lda $b6; asl
  //there is not enough space for a jsl into the codeCursor area for these hooks.
  //instead, place this hook on top of a now-unused Japanese text string.
  seek($c0ed2b); lda $b6; asl; dec; rts
  dequeue pc
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
  define menuItems = $00
  define menuCount = $b6
  define menuMode  = $b0

  constant menuIndex = $09f0
  constant isTechniqueMenu = $64

  variable(2, minimumWidth)

  php; rep #$30; phx; phy

  ldx.w #menuIndex
  lda {menuCount}; and #$00ff; tay
  lda #$0001; sta minimumWidth
  loop: {
    lda $b0; and #$00ff
    cmp.w #isTechniqueMenu; beq technique

  command:
    phx; lda {menuItems},x; inc; and #$00ff; tax
    lda lists.commands.widths,x; and #$00ff; plx; inx
    cmp minimumWidth; bcc next
    sta minimumWidth; bra next

  technique:
    phx; lda {menuItems},x; and #$00ff; tax
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

  define windowMaskHeight = $7e7b06  //cutout for color add/sub background
  define windowPositionX  = $7e7b1a  //lo = X1, hi = X2
  define gridCursorTileX  = $92
  define menuItemCount    = $b6
  define menuCursorPixelX = $b7
  define indexMode        = $b0  //#$00 = field menu; #$64 = tech menu

  constant borderTileWidth  =  2
  constant windowStartLeft  = 16
  constant windowStartRight = 16

  function main {  //return: y = window tilemap position
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
    sta {windowPositionX}
    bra next

  terrain:
    jsl terrain.width
    add.w #borderTileWidth
    asl #3; dec
    add.w #windowStartRight; xba
    add.w #windowStartLeft
    sta {windowPositionX}
    bra next

  next:
    //whether the menu is placed on the left or right is based on the grid cursor:
    //#$0002-0008 places the menu on the left, #$0009-0015 places the menu on the right
    //if the menu should be on the right, swap the window position values here
    pha; lda {gridCursorTileX}; and #$00ff; cmp #$0009; pla; bcs +
    lda #$ffff; sec; sbc {windowPositionX}; xba; sta {windowPositionX}; +

    //now set the tilemap write location and menu cursor icon positions:
    and #$00ff; lsr #2; clc; adc #$4104; tay  //set tilemap write location
    sep #$20; lda {windowPositionX}; dec #2; sta {menuCursorPixelX}  //X cursor position
    lda {menuItemCount}; asl; inc; asl #3; sta {windowMaskHeight}

    rep #$30; plx; pla; plp; rtl
  }
}

//handles tilemap width and pitch
namespace menuWidthTilemap {
  enqueue pc
  seek($c0e1d8); jsl main; nop #5
  dequeue pc

  define menuWidth = $0a
  define menuPitch = $14
  define indexMode = $b0

  constant lineWidth   = 64
  constant borderWidth =  2

  function main {
    enter

    lda $0f,s  //determine which parent function called this function
    cmp #$9cb1; beq terrain

  menu:
    jsl getMinimumMenuWidth
    sep #$20; sta {menuWidth}
    bra next

  terrain:
    jsl terrain.width
    sep #$20; sta {menuWidth}
    bra next

  next:
    //compute the number of tilemap bytes to skip to seek to the next menu item:
    //menuPitch = $40 - (menuWidth + borderWidth) * 2
    lda.b #lineWidth
    sub {menuWidth}; sub {menuWidth}
    sub.b #borderWidth*2
    rep #$20; sta {menuPitch}

    leave; rtl
  }
}

namespace menu {
  enqueue pc
  seek($c0e0c5); jsl main; rts
  dequeue pc

  define menuItems  = $00  //list of item strings at $00
  define menuHeight = $0a  //number of items in the menu
  define menuPitch  = $14  //tiles from end of one line to start of next line
  define mapAddress = $16  //tilemap write location
  define menuIndex  = $1a  //the start index into the list at $00
  define indexMode  = $b0  //#$00 = field menu; #$64 = tech menu

  constant isTechniqueMenu = $64

  variable(2, tileIndex)
  variable(2, itemIndex)
  variable(2, itemCount)
  variable(2, menuWidth)

  function main {
    enter; ldb #$7e

    //compute the menu width based off the menu pitch
    sep #$20; lda #$40; sub {menuPitch}; lsr; dec #3
    rep #$20; and #$00ff; sta menuWidth

    //move the menu cursor offscreen while drawing the menu.
    //this prevents the cursor overlapping text when the menu width increases.
    //sprite 0 may not be a cursor, so the WRAM OAM table is checked first.
    //the cursor always uses #$30; player sprites use different values.
    lda $0803; and #$00ff; cmp #$0030; bne +
    jsl vsync; lda #$0000; sta $002102
    sep #$20; lda #$f0; sta $002104; sta $002104; rep #$20; +

    lda {mapAddress}; add #$0040; tay
    lda {menuHeight}; and #$00ff; sta itemCount
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
    lda {menuIndex}; add itemIndex; tax
    lda {menuItems},x; tay
    index.bpp4(); txa; sta tileIndex
    lda {indexMode}; and #$00ff; cmp.w #isTechniqueMenu; jeq technique
  command:
    tya; inc; and #$00ff; mul(9); tay
    lda #$0009; write.bpp4(lists.commands.bpo4); rtl
  technique:
    tya; and #$00ff; mul(8); tay
    lda #$0009; write.bpp4(lists.techniques.bpo4); rtl
  }

  function writeMap {
    lda itemIndex; mul(128); add {mapAddress}; tay
    lda menuWidth; tax
    lda tileIndex; ora #$2300  //add tile attributes to tile index
  -;sta $0040,y
    inc; iny #2
    dex; bne -
  +;rtl
  }
}

function playerName {
  enqueue pc
  seek($c0e051); jsl main; rts
  dequeue pc

  //A = player name
  function main {
    ldx #$0628
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; index.bpp2(); write.bpp2(names.buffer.bpp2)
    sep #$20;  txa
    sta $0720; inc
    sta $0721; inc
    sta $0722; inc
    sta $0723; inc
    sta $0724; inc
    sta $0725; inc
    sta $0726; lda #$ef
    sta $0727
    leave; rtl
  static:
    mul(8); tay
    lda #$0006; index.bpp2(); write.bpp2(lists.names.bpp2)
    sep #$20;  txa
    sta $0720; inc
    sta $0721; inc
    sta $0722; inc
    sta $0723; inc
    sta $0724; inc
    sta $0725; lda #$ef
    sta $0726
    sta $0727
    leave; rtl
  }
}

namespace dragonName {
  enqueue pc
  seek($c0dc5f); jsl main; rts
  dequeue pc

  //A = dragon name
  function main {
    ldx #$0631
    enter
    and #$00ff; mul(8); tay
    lda #$0008; index.bpp2(); write.bpp2(lists.names.bpp2)
    sep #$20;  txa
    sta $0720; inc
    sta $0721; inc
    sta $0722; inc
    sta $0723; inc
    sta $0724; inc
    sta $0725; inc
    sta $0726; inc
    sta $0727; lda #$ef
    sta $0728
    sta $0729
    sta $072a
    sta $072b
    sta $072c
    sta $072d
    sta $072e
    sta $072f
    sta $0730
    leave; rtl
  }
}

namespace playerClass {
  enqueue pc
  seek($c0e027); jsl main; rts

  //when a player is defeated, a flag icon is drawn instead of the class name.
  //because the LV/HP/MP is shorter after being made proportional, the clear
  //width for the flag drawing routine must be increased by 1 to clear up to
  //the new position of the LV text.
  seek($c0df87); lda #$0a  //was lda #$09
  dequeue pc

  function main {
    ldx #$0631
    enter
    and #$00ff; mul(8); tay
    lda #$0008; index.bpp2(); write.bpp2(lists.classes.bpp2)
    txa; sep #$20
    sta $0728; inc
    sta $0729; inc
    sta $072a; inc
    sta $072b; inc
    sta $072c; inc
    sta $072d; inc
    sta $072e; inc
    sta $072f; lda #$ef
    sta $0730
    leave; rtl
  }
}

namespace dragonClass {
  enqueue pc
  seek($c0dbcb); jsl main; nop #3
  dequeue pc

  function main {
    ldx #$062b
    enter
    and #$00ff; mul(9); tay
    lda #$0009; index.bpp2(); write.bpp2(lists.dragons.bpp2)
    sep #$20;  lda #$ef
    sta $0720; txa
    sta $0721; inc
    sta $0722; inc
    sta $0723; inc
    sta $0724; inc
    sta $0725; inc
    sta $0726; inc
    sta $0727; inc
    sta $0728; inc
    sta $0729; lda #$ff
    sta $072b
    leave; rtl
  }
}

namespace dragonCommand {
  enqueue pc
  seek($c0db8f); nop #3               //disable static "Command:" text:
  seek($c0db9b); jsl main; jmp $dbb5  //render it together with current command
  dequeue pc

  function main {
    ldx #$063f
    enter
    and #$00ff; mul(9); tay
    lda #$0009; index.bpp2(); write.bpp2(lists.field.bpp2)
    sep #$20;  txa
    sta $0735; inc
    sta $0736; inc
    sta $0737; inc
    sta $0738; inc
    sta $0739; inc
    sta $073a; inc
    sta $073b; inc
    sta $073c; inc
    sta $073d; lda #$ff
    sta $073e
    leave; rtl
  }
}

namespace enemyName {
  enqueue pc
  seek($c0dd5e); jsl main; rts
  dequeue pc

  function main {
    ldx #$0631
    enter
    and #$00ff; mul(9); tay
    lda #$0009; index.bpp2(); write.bpp2(lists.enemies.bpp2)
    txa; sep #$20
    sta $0720; inc
    sta $0721; inc
    sta $0722; inc
    sta $0723; inc
    sta $0724; inc
    sta $0725; inc
    sta $0726; inc
    sta $0727; inc
    sta $0728; lda #$ef
    sta $0729
    sta $072a
    sta $072b
    sta $072c
    sta $072d
    sta $072e
    sta $072f
    sta $0730
    leave; rtl
  }
}

namespace level {
  enqueue pc
  seek($c0deb7); jsl main; rts
  dequeue pc

  function main {
    ldx #$0636
    enter
    ldx $18; lda $7e0002,x
    and #$00ff; mul(3); tay
    lda #$0003; index.int2(); write.bpp2(lists.levels.bpp2)
    txa; sep #$20; xba
    sta $0731; xba
    sta $0732; inc
    sta $0733; inc
    sta $0734; lda #$02
    sta $0735
    leave; rtl
  }
}

namespace hp {
  enqueue pc
  seek($c0de81); jsl main; rts
  dequeue pc

  function main {
    variable(2, counter)

    ldx #$063d
    enter
    ldx $18; lda $7e0005,x
    ldx #$0000
    cmp.w #10000; bcc _1; append.literal("^^^^"); bra _2; _1:
    append.integer_4(); _2:
    lda #$0003; render.small.bpp2()
    index.int4(); jsl write.bpp2
    sep #$20;  lda #$f7
    sta $0736; inc
    sta $0737; lda #$01
    sta $0738; txa
    sta $0739; inc
    sta $073a; inc
    sta $073b; lda #$02
    sta $073c
    leave; rtl
  }
}

namespace mp {
  enqueue pc
  seek($c0de4f); jsl main; rts
  seek($c0dd89); jsl none; rts
  dequeue pc

  variable(2, marker)

  function main {
    ldx #$0644
    enter
    sta marker
    ldx $18; lda $7e0009,x
    ldx #$0000
    cmp.w #1000; bcc _1; append.literal("_^^^"); bra _2; _1:
    append.integer_4(); _2:
    lda #$0003; render.small.bpp2()
    index.int4(); jsl write.bpp2
    sep #$20; jsl getMarker
    sta $073d; inc
    sta $073e; lda #$01
    sta $073f; txa
    sta $0740; inc
    sta $0741; inc
    sta $0742; lda #$02
    sta $0743
    leave; rtl
  }

  function getMarker {
    lda marker
    cmp #$d8; beq +
    lda #$f9; rtl  //"MP"
  +;lda #$fb; rtl  //"SP"
  }

  function none {
    ldx #$0644
    enter
    ldx #$0000; txy
    append.literal("_~~~")
    lda #$0003; render.small.bpp2()
    index.int4(); jsl write.bpp2
    sep #$20;  lda #$f9  //"MP"
    sta $073d; inc
    sta $073e; lda #$01
    sta $073f; txa
    sta $0740; inc
    sta $0741; inc
    sta $0742; lda #$02
    sta $0743
    leave; rtl
  }
}

//replace fixed-width 'Boss' indicator with new pre-rendered version
namespace bossIndicator {
  enqueue pc
  seek($c0dd05); jsl main; jmp $dd19
  dequeue pc

  function main {
    ldx #$062d
    enter
    ldx #$0000; append.literal("Boss")
    lda #$0003; render.small.bpp2()
    index.bpp2(); jsl write.bpp2
    sep #$20;  lda #$ef
    sta $0729; txa
    sta $072a; inc
    sta $072b; inc
    sta $072c
    leave; rtl
  }
}

namespace techniqueSmall {
  enqueue pc
  seek($c0d6ab); jsl main; jmp $d6b6
  seek($c0d648); ldy #$c444  //move the start of the line one tile to the left
  seek($c0d781); ldx #$062c  //move the start of MP/SP numbers one tile to the right
  seek($c0ea96); lda #$ff    //move the left-side cursor five pixels to the left
  seek($c0eaa1); lda #$77    //move the right-side cursor five pixels to the left
  seek($c0eb0e); jml setCursorAttributes; nop
  dequeue pc

  //originally, the sprite cursor could only be positioned from X=0-255.
  //the technique list required an extra tile; and X=0 caused the cursor to touch the text.
  //this function hooks the routine that sets the OAM upper-table attributes,
  //so that when a sprite at position #$ff (255) is detected, it places it at #$1ff (-1) instead.
  //because this routine is shared by other sprite handling code,
  //a few extra checks are performed to guarantee this only affects the cursor sprite.
  //------
  //c0ea96  lda #$00     ;X position of left-hand sprite cursor in the technique menu
  //c0ea98  sta $0800,y  ;store position in sprite table
  //......
  //c0eb0b  iny
  //c0eb0c  iny
  //c0eb0d  iny          ;increment sprite index to the attributes location
  //c0eb0e  lda #$80     ;set OAM upper-table attributes for sprite in d6-d7
  //c0eb10  jsr $5300    ;function to write to the OAM upper-table
  //......
  //c05317  sta $0a00,y  ;store OAM upper-table attributes for sprite (after shifting into place)
  //------
  function setCursorAttributes {
    constant oamTableAddress = $0800-3  //location of WRAM copy of the sprite table ($0220 bytes)
    constant baseCursorY     = $a7

    cpy #$0003; bne normal          //the cursor is always the first sprite in the table
    lda.w oamTableAddress+0,y       //get X position
    cmp #$ff; bne normal            //it will only ever be placed at -1 by us
    lda.w oamTableAddress+1,y       //get Y position
    cmp.b #baseCursorY+ 0; beq +    //make sure it's at one of the four possible locations
    cmp.b #baseCursorY+12; beq +
    cmp.b #baseCursorY+24; beq +
    cmp.b #baseCursorY+36; beq +
    bra normal
  +;lda.w oamTableAddress+2,y       //get character#
    and #$f8; cmp #$e0; bne normal  //ensure it's one of the eight sprite animation tiles
    lda.w oamTableAddress+3,y       //get lower-table attributes
    cmp #$30; bne return            //final check

    //this is the sprite cursor trying to be placed at X=-1, set the extended attribute bit
    modify: {
      lda #$c0; bra return
    }

    //this is not the sprite cursor trying to be placed at -1; don't set X.d8
    normal: {
      lda #$80; bra return
    }

    return: {
      pea $eb12
      jml $c05300
    }
  }

  //------
  //c0d6ab  lda $1a    ;load the technique name
  //c0d6ad  jsr $d6d0  ;add it to the string
  //c0d6b0  jsr $d6eb  ;print the level (if not #$ff)
  //c0d6b3  jsr $d774  ;print the cost  (if not #$00)
  //------
  function main {
    constant name  = $1a
    constant level = $19
    constant cost  = $1b

    enter
    ldx #$0000

    lda.b name; and #$00ff; mul(8); tay
    phx; lda #$0008; index.bpp2(); write.bpp2(lists.techniques.bpp2); txa; plx
    sep #$20  //write eight tiles
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; rep #$20

    lda.b level; and #$00ff; cmp #$00ff; jeq +
    mul(3); tay
    phx; lda #$0003; index.int2(); write.bpp2(lists.levels.bpp2); txa; plx
    sep #$20; xba  //write three tiles + bank switching code + space
    sta $0720,x; inx; xba
    sta $0720,x; inx; inc
    sta $0720,x; inx; inc
    sta $0720,x; inx; lda #$02
    sta $0720,x; inx; lda #$ef
    sta $0720,x; inx; rep #$20

  +;lda.b cost; and #$00ff; jeq +
    mul(2); tay
    phx; lda #$0002; index.int4(); write.bpp2(lists.costs.bpp2); txa; plx
    sep #$20; xba  //write two tiles + bank switching code
    sta $0720,x; inx; xba
    sta $0720,x; inx; inc
    sta $0720,x; inx; rep #$20

  +;sep #$20; lda #$ff  //write terminal
    sta $0720,x

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
  function item {
    define index = $0000,x

    enter
    lda {index}; and #$007f
    mul(9); tay
    lda #$0009; index.bpp2(); write.bpp2(lists.items.bpp2)
    txa; sep #$20
    sta $0720; inc
    sta $0721; inc
    sta $0722; inc
    sta $0723; inc
    sta $0724; inc
    sta $0725; inc
    sta $0726; inc
    sta $0727; inc
    sta $0728; lda #$ef
    sta $0729
    sta $072a
    leave
    ldx #$062b; rtl
  }

  function quantity {
    define value = $1b

    ldx #$0631
    ldy $1c
    enter
    lda {value}; and #$00ff; mul(3); tay
    lda #$0003; index.int2(); write.bpp2(lists.counts.bpp2)
    txa; sep #$20; xba
    sta $072b; xba
    sta $072c; inc
    sta $072d; inc
    sta $072e; lda #$02
    sta $072f; lda #$ff
    sta $0730
    leave; rtl
  }

  function piro {
    constant value = $0370

    ldx #$063d
    enter
    lda.w value
    ldx #$0000; append.alignLeft(6); append.integer_5(); append.literal(" Piro")
    lda #$0007; render.small.bpp2()
    index.bpp2(); jsl write.bpp2
    sep #$20; lda #$ef
    sta $0720
    sta $0721
    sta $0722
    sta $0723
    sta $0724
    sta $0725
    sta $0726
    sta $0727
    sta $0728
    sta $0729
    sta $072a
    sta $072b
    sta $072c
    sta $072d
    sta $072e
    sta $072f
    sta $0730
    sta $0731
    sta $0732
    sta $0733
    sta $0734; txa
    sta $0735; inc
    sta $0736; inc
    sta $0737; inc
    sta $0738; inc
    sta $0739; inc
    sta $073a; inc
    sta $073b; lda #$ff
    sta $073c
    leave; rtl
  }
}

codeCursor = pc()

}
