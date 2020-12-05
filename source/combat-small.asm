namespace combat {

seek(codeCursor)

namespace constants {
  constant hook        = $fe
  constant terminal    = $ff
  constant name        = 0
  constant technique   = 1
  constant item        = 2
  constant enemy       = 3
  constant dragonClass = 4
  constant string      = 5

  namespace strings {
    constant feed      = 0
    constant exit      = 1
    constant wisdom    = 2
    constant affection = 3
  }

  namespace hooks {
    feed:;      db hook,string,strings.feed,terminal
    exit:;      db hook,string,strings.exit,terminal
    wisdom:;    db hook,string,strings.wisdom,terminal
    affection:; db hook,string,strings.affection,terminal
  }
}

//available tiles:
//$01e-$029 =  12 tiles (item icons)
//$030-$0cb = 156 tiles (normal)
//$0d0-$16b = 156 tiles (active)
//$170-$17f =  16 tiles (blank)

namespace index {
  macro for3x17(define counter) {
    getTileIndex({counter}, 17)
    asl; tax; lda index.table3x17,x; tax
  }

  macro for7x4(define counter) {
    getTileIndex({counter}, 4)
    asl; tax; lda index.table7x4,x; tax
  }

  macro for3x8(define counter) {
    getTileIndex({counter}, 8)
    asl; tax; lda index.table3x8,x; tax
  }

  macro for3x16L(define counter) {
    getTileIndex({counter}, 16)
    asl; tax; lda index.table3x16L,x; tax
  }

  macro for3x16R(define counter) {
    getTileIndex({counter}, 16)
    asl; tax; lda index.table3x16R,x; tax
  }

  macro for18x1(define counter) {
    getTileIndex({counter}, 1)
    asl; tax; lda index.table18x1,x; tax
  }

  macro for4x4(define counter) {
    getTileIndex({counter}, 4)
    asl; tax; lda index.table4x4,x; tax
  }

  macro for8x2(define counter) {
    getTileIndex({counter}, 2)
    asl; tax; lda index.table8x2,x; tax
  }

  macro for9x16(define counter) {
    getTileIndex({counter}, 16)
    asl; tax; lda index.table9x16,x; tax
  }

  macro to3x17() {
    and #$00ff; asl; tax; lda index.table3x17,x; tax
  }

  macro to7x4() {
    and #$00ff; asl; tax; lda index.table7x4,x; tax
  }

  macro to3x8() {
    and #$00ff; asl; tax; lda index.table3x8,x; tax
  }

  macro to3x16L() {
    and #$00ff; asl; tax; lda index.table3x16L,x; tax
  }

  macro to3x16R() {
    and #$00ff; asl; tax; lda index.table3x16R,x; tax
  }

  macro to18x1() {
    and #$00ff; asl; tax; lda index.table18x1,x; tax
  }

  macro to4x4() {
    and #$00ff; asl; tax; lda index.table4x4,x; tax
  }

  macro to8x2() {
    and #$00ff; asl; tax; lda index.table8x2,x; tax
  }

  macro to9x16() {
    and #$00ff; asl; tax; lda index.table9x16,x; tax
  }

  macro to3x17 (variable index) {; lda.w #index; index.to3x17 (); }
  macro to7x4  (variable index) {; lda.w #index; index.to7x4  (); }
  macro to3x8  (variable index) {; lda.w #index; index.to3x8  (); }
  macro to3x16L(variable index) {; lda.w #index; index.to3x16L(); }
  macro to3x16R(variable index) {; lda.w #index; index.to3x16R(); }
  macro to18x1 (variable index) {; lda.w #index; index.to18x1 (); }
  macro to4x4  (variable index) {; lda.w #index; index.to4x4  (); }
  macro to8x2  (variable index) {; lda.w #index; index.to8x2  (); }
  macro to9x16 (variable index) {; lda.w #index; index.to9x16 (); }

  //dragon stats
  //$030-$062
  //$0d0-$102 (active mirrors)
  table3x17: {
    dw $030,$033,$036,$039,$03c,$03f
    dw $042,$045,$048,$04b,$04e,$051
    dw $054,$057,$05a,$05d,$060
  }

  //player names
  //$030-$04b
  //$0d0-$0eb (active mirrors)
  table7x4: {
    dw $0030,$0037,$003e,$0045
  }

  //player stats (HP+MP)
  //$04c-$063
  table3x8: {
    dw $04c,$04f,$052,$055
    dw $058,$05b,$05e,$061
  }

  //item counts
  //technique levels
  //$01e-$029
  //$064-$087
  table3x16L: {
    dw $01e,$021,$024,$027
    dw $064,$067,$06a,$06d
    dw $070,$073,$076,$079
    dw $07c,$07f,$082,$085
  }

  //technique costs
  //$088-$0b7
  table3x16R: {
    dw $088,$08b,$08e,$091,$094,$097,$09a,$09d
    dw $0a0,$0a3,$0a6,$0a9,$0ac,$0af,$0b2,$0b5
  }

  //dragon name - class
  //$088-$099
  table18x1: {
    dw $088
  }

  //experience
  //$088-$097
  table4x4: {
    dw $088,$08c,$090,$094
  }

  //page#
  //item#/#
  //piro
  //$09a-$0a9
  table8x2: {
    dw $09a,$0a2
  }

  //menus
  //items
  //techniques
  //$0b8-$0c9
  //$0ec-$157
  //$158-$169
  table9x16: {
    dw $0b8,$0c1
    dw $0ec,$0f5,$0fe,$107
    dw $110,$119,$122,$12b
    dw $134,$13d,$146,$14f
    dw $158,$161
  }

  //dragon stat labels
  //$16a-$16b
  //$16e-$17f
}

namespace tilemap {
  enqueue pc
  seek($c12de1); jsl main
  seek($c147e6); stub:; jsr $2e49; rtl
  dequeue pc

  variable(2, index)

  //------
  //c12de1  lda [$5e],y  ;load character
  //c12de3  cmp #$ff     ;test if it is the string terminator
  //------
  function main {
    lda [$5e],y
    cmp.b #constants.hook; beq +
    //if this is not a hook, let the original game handle the string instead
    cmp.b #constants.terminal; rtl
  +;iny; lda [$5e],y
    cmp.b #constants.name; bne +
    iny; lda [$5e],y
    jsl status.name
    iny; jmp main
  +;cmp.b #constants.technique; bne +
    iny; lda [$5e],y
    jsl technique.name
    iny; jmp main
  +;cmp.b #constants.item; bne +
    iny; lda [$5e],y
    jsl item.name
    iny; jmp main
  +;cmp.b #constants.enemy; bne +
    iny; lda [$5e],y
    jsl enemy.name
    iny; jmp main
  +;cmp.b #constants.dragonClass; bne +
    iny; lda [$5e],y
    jsl dragons.class.name
    iny; jmp main
  +;cmp.b #constants.string; bne +
    iny; lda [$5e],y
    jsl string.write
    iny; jmp main
  +;iny; jmp main
  }

  //A <= tilemap index
  function calculateIndex {
    phb; php; rep #$30; phx; phy
    jsl stub; txa
    rep #$30; ply; plx; plp; plb
    rtl
  }

  //A => tile count
  //X => target index
  //Y => source index
  function write {
    php; rep #$30
    pha; tya; ora #$3800; ply
    loop: {
      //detect if the next tile is a window right-hand border tile.
      //if so, stop writing tiles early to avoid overwriting it.
      pha; lda $7e4800,x
      cmp #$7803; bne +; pla; bra done; +  //window border
      cmp #$7809; bne +; pla; bra done; +  //window border arrow
      pla; sta $7e4800,x
      inc; inx #2
      dey; bne loop
    }
    done: {
      txa; sta tilemap.index
      plp; rtl
    }
  }
  macro write() {
    jsl tilemap.write
  }
}

namespace write {
  //A => tile count
  //X => target index
  //Y => source index
  macro bpp4(variable source) {
    enter; ldb #$00
    vsync()
    pha; tya; mul(32); ply
    add.w #source >>  0; sta $4302
    lda.w #source >> 16; adc #$0000; sta $4304
    txa; mul(32); add #$8000; lsr; sta $2116
    tya; mul(32); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave
  }

  //A => tile count
  //X => target index
  function bpp4 {
    enter; ldb #$00
    vsync(); tay
    lda.w #render.buffer >>  0; sta $4302
    lda.w #render.buffer >> 16; sta $4304
    txa; mul(32); add #$8000; lsr; sta $2116
    tya; mul(32); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave; rtl
  }
  macro bpp4() {
    jsl write.bpp4
  }
}

namespace string {
  macro write(variable address, define target) {
    seek(address)
    lda.b #constants.hooks.{target} >>  0; sta $5e
    lda.b #constants.hooks.{target} >>  8; sta $5f
    lda.b #constants.hooks.{target} >> 16; sta $60
  }

  enqueue pc

  //dragon feeding menu
  seek($c19afe); lda #$0f  //X position
  seek($c19b08); lda #$04  //window width

  //string hooks
  write($c19b26,feed)
  write($c19b39,exit)
  write($c19a78,wisdom)
  write($c19aa3,affection)

  dequeue pc

  //A => string#
  //X => tilemap index
  function write {
    enter
    cmp.w #constants.strings.feed;      bne +; jsl dragons.feed.label; leave; rtl; +
    cmp.w #constants.strings.exit;      bne +; jsl dragons.exit.label; leave; rtl; +
    cmp.w #constants.strings.wisdom;    bne +; leave; rtl; +  //handled by combat-dragons
    cmp.w #constants.strings.affection; bne +; leave; rtl; +  //handled by combat-dragons
    leave; rtl
  }
}

namespace status {
  enqueue pc
  seek($c12eff); jml hook
  seek($c138d0); jsl hp; sep #$20; nop #3
  seek($c1390a); jsl mp; sep #$20; nop #3
  seek($c138df); jsl hasMP; jmp $38ec
  dequeue pc

  //------
  //c12eff  jsr $2f18  ;write string
  //c12f02  bra $2eed  ;exit point
  //------
  //A => name
  function hook {
    enter; sep #$20
    pha; lda.b #constants.hook; sta $002180
    lda.b #constants.name; sta $002180
    pla; sta $002180
    lda.b #constants.terminal; sta $002180
    leave; jml $c12eed
  }

  //A => player name
  //X => tilemap index
  function name {
    variable(2, counter)
    variable(2, identifier)
    variable(2, type)   //0 = top status bar, 1 = name window
    variable(2, index)
    variable(2, target)
    variable(2, width)  //maximum number of tiles for name (player = 6; dragon = 8)

    enter
    and #$00ff; sta identifier

    //if this is the dragon feeding screen, do not print the name here yet.
    //the dragon feeding screen prints the name + class together at the same time.
    //test for this by checking for a full-screen 4-line status bar.
    lda $7e49c0; cmp #$b801; bne +  //test for bottom-left border
    lda $7e49fe; cmp #$f801; bne +  //test for bottom-right border
    leave; rtl; +

    lda #$0000; sta type
    lda #$ffff; sta index
    txa; sta target

    //set the maximum length of the name in tiles
    lda #$0007; sta width
    lda identifier; cmp #$0002; bcc +; cmp #$000a; bcs +
    lda #$0008; sta width
    index.to7x4(0); sta index; lda #$0001; sta type; jmp render; +

    cpx #$00c4; bne +; lda #$0000; index.to7x4(); sta index; bra render; +  //player 1 name
    cpx #$00d2; bne +; lda #$0001; index.to7x4(); sta index; bra render; +  //player 2 name
    cpx #$00e0; bne +; lda #$0002; index.to7x4(); sta index; bra render; +  //player 3 name
    cpx #$00ee; bne +; lda #$0003; index.to7x4(); sta index; bra render; +  //player 4 name
    lda index; cmp #$ffff; bne +; index.for8x2(counter); sta index; lda #$0001; sta type; +

  render:
    lda identifier
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda index; tax
    lda width; write.bpp4(names.buffer.bpo4)
    lda type; jne window
    txa; add #$00a0; tax
    lda width; write.bpp4(names.buffer.bpa4)
    txa; sub #$00a0; tay
    lda target; tax
    lda width; tilemap.write()
    leave; rtl
  static:
    mul(8); tay
    lda index; tax
    lda width; write.bpp4(lists.names.bpo4)
    lda type; jne window
    txa; add #$00a0; tax
    lda width; write.bpp4(lists.names.bpa4)
    txa; sub #$00a0; tay
    lda target; tax
    lda width; tilemap.write()
    leave; rtl

  window:
    txy; lda target; tax
    lda width; tilemap.write()
    leave; rtl
  }

  function hp {
    variable(2, value)
    variable(2, index)
    variable(2, target)

    enter
    lda $7e6425,x; sta value

    jsl tilemap.calculateIndex; sta target
    cmp #$0148; bne +; lda #$0000; bra found; +  //player 1 name
    cmp #$0156; bne +; lda #$0001; bra found; +  //player 2 name
    cmp #$0164; bne +; lda #$0002; bra found; +  //player 3 name
    cmp #$0170; bcc +; cmp #$0180; bcs +; lda #$0003; bra found; +  //player 4 or dragon name
    leave; rtl; found:; sta index

    ldx #$0000
    lda value; append.integer_4()
    lda #$0003; render.small.bpo4()
    lda index; index.to3x8()
    lda #$0003; write.bpp4()
    txy; lda target; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  function mp {
    variable(2, value)
    variable(2, index)
    variable(2, target)
    variable(2, available)

    enter
    lda $7e6429,x; sta value

    jsl tilemap.calculateIndex; sta target
    cmp #$0188; bne +; lda #$0000; bra found; +  //player 1 name
    cmp #$0196; bne +; lda #$0001; bra found; +  //player 2 name
    cmp #$01a4; bne +; lda #$0002; bra found; +  //player 3 name
    cmp #$01b0; bcc +; cmp #$01c0; bcs +; lda #$0003; bra found; +  //player 4 or dragon name
    leave; rtl; found:; add #$0004; sta index

    ldx #$0000; txy
    lda available; bne yes
    no:;  append.literal("_~~~"); bra render
    yes:; lda value; append.integer_4(); bra render
  render:
    lda #$0003; render.small.bpo4()
    lda index; index.to3x8()
    lda #$0003; write.bpp4()
    txy; lda target; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  function hasMP {
    enter
    lda $7e6460,x
    bit #$0020; beq yes
    no:;  lda #$0000; sta mp.available; leave; rtl
    yes:; lda #$0001; sta mp.available; leave; rtl
  }
}

namespace name {
  enqueue pc
  seek($c14681); jsl setPlayerWindowWidth; nop
  seek($c1398d); jsl setDragonWindowWidth; nop
  seek($c17454); jsl setDragonExperienceWindowWidth; nop
  dequeue pc

  variable(2, width)

  //------
  //c14681  lda #$08   ;width of name window
  //c14683  sta $097e  ;store width
  //------
  function setPlayerWindowWidth {
    enter
    lda $6b; and #$00ff; xba; tax
    lda $7e6431,x; and #$00ff
    jsl calculateWidth
    sep #$20; sta $097e
    lda $06; add #$08; sub width; sta $06
    leave; rtl
  }

  //------
  //c1398d  lda #$08   ;width of window
  //c1399f  sta $097c  ;store width
  //------
  function setDragonWindowWidth {
    enter
    lda $7e6431; and #$00ff
    jsl calculateWidth
    cmp #$0005; bcs +; lda #$0005; +
    sep #$20; sta $097c
    pha; lda #$1e; sub $01,s; sta $096c; pla
    leave; rtl
  }

  //------
  //c17454  lda #$08   ;width of window
  //c17456  sta $097c  ;store width
  //------
  function setDragonExperienceWindowWidth {
    enter
    lda $7e6431; and #$00ff
    jsl calculateWidth
    cmp #$0006; bcs +; lda #$0006; +
    sep #$20; sta $097c
    leave; rtl
  }

  //A => name
  function calculateWidth {
    php; rep #$30; phx; phy
    ldx #$0000; append.name()
    render.small.width(); add #$0007; div(8); sta width
    rep #$30; ply; plx; plp
    rtl
  }
}

namespace experience {
  enqueue pc
  seek($c174b8); jsl main; jmp $74c7
  dequeue pc

  function main {
    variable(2, value)
    variable(2, index)
    variable(2, target)

    enter
    lda $7e641a,x; sta value
    jsl tilemap.calculateIndex; sta target

    cmp #$014e; bne +; lda #$0000; sta index; bra render; +
    cmp #$015c; bne +; lda #$0001; sta index; bra render; +
    cmp #$016a; bne +; lda #$0002; sta index; bra render; +
    cmp #$0178; bne +; lda #$0003; sta index; bra render; +
    leave; rtl; render:

    ldx #$0000; txy
    lda value; append.alignRight(); append.integer_5()
    lda #$0004; render.small.bpo4()
    lda index; index.to4x4(); tax
    lda #$0004; write.bpp4()
    txy; lda target; sub #$0006; tax
    lda #$0004; tilemap.write()
    leave; rtl
  }
}

namespace piro {
  enqueue pc
  seek($c174f0); lda #$0c          //window width (set to match the item drop list width)
  seek($c1751c); jsl main; nop #4  //hook piro quantity write
  seek($c17532); nop #3            //disable printing of static "Piro" text ([$c1db1d] "ピロー")
  dequeue pc

  function main {
    variable(2, value)

    enter
    lda $092f; sta value
    ldx #$0000; txy
    append.alignRight(); append.integer_5(); append.literal(" Piro")
    lda #$0008; render.small.bpo4()
    index.to8x2(0); tax
    lda #$0008; write.bpp4()
    txy; jsl tilemap.calculateIndex; sub #$0008; tax
    lda #$0008; tilemap.write()
    leave; rtl
  }
}

namespace enemy {
  enqueue pc
  seek($c12f04); jml hook
  seek($c147df); jsl hp.value; jmp $4803
  seek($c1482b); jsl mp.value; jmp $4839
  seek($c14854); jsl hp.unknown; jmp $4868
  seek($c14883); jsl mp.unknown; jmp $4892
  seek($c146af); jsl setWindowWidth; nop
  seek($c147c2); jmp $47cb  //disable static "HP" text
  seek($c14817); jmp $4820  //disable static "MP" text (value)
  seek($c14872); jmp $487b  //disable static "MP" text (unknown)
  seek($c1487b); lda #$03   //static "MP" text position (unknown)
  seek($c148fd); nop #3     //disable static ":" after enemy attribute icons
  dequeue pc

  //------
  //c12f04  jsr $2f51  ;write string
  //c12f07  bra $2eed  ;exit point
  //------
  //A => enemy name ID
  function hook {
    enter; sep #$20
    pha; lda.b #constants.hook; sta $002180
    lda.b #constants.enemy; sta $002180
    pla; sta $002180
    lda.b #constants.terminal; sta $002180
    leave; jml $c12eed
  }

  variable(2, counter)
  variable(2, width)

  function setWindowWidth {
    enter
    lda $6b; and #$00ff; xba; tax
    lda $7e6431,x; and #$00ff
    jsl calculateWidth
    sep #$20; sta $097e
    leave; rtl
  }

  //A => enemy name ID
  function calculateWidth {
    php; rep #$30; phx; phy
    ldx #$0000; append.enemy()
    render.small.width(); add #$0007; div(8)
    cmp #$0008; bcc +; lda #$0008; +
    cmp #$0006; bcs +; lda #$0006; +
    sta width
    rep #$30; ply; plx; plp
    rtl
  }

  //A => enemy name ID
  //X => tilemap index
  function name {
    variable(2, index)
    variable(2, target)

    enter
    and #$00ff; mul(8); tay
    txa; sta target
    index.for9x16(counter)
    lda width; write.bpp4(lists.enemies.bpo4)
    txy; lda target; tax
    lda width; tilemap.write()
    leave; rtl
  }

  namespace hp {
    //X => enemy index
    function value {
      sep #$20
      enter
      lda $7e6425,x
      jsl write
      leave; rtl
    }

    function unknown {
      enter
      lda.w #10000  //"????"
      jsl write
      leave; rtl
    }

    function write {
      ldx #$0000; append.hpValue()
      lda #$0006; ldy #$0000; render.small.bpo4()
      index.for9x16(counter)
      lda #$0006; write.bpp4()
      txy; jsl tilemap.calculateIndex; sub #$0006; tax
      lda #$0006; tilemap.write()
      rtl
    }
  }

  namespace mp {
    //X => enemy index
    function value {
      sep #$20
      enter
      lda $7e6429,x
      jsl write
      leave; rtl
    }

    function unknown {
      sep #$20
      enter
      lda.w #1000  //"???"
      jsl write
      leave; rtl
    }

    function write {
      ldx #$0000; append.mpValue()
      lda #$0006; ldy #$0000; render.small.bpo4()
      index.for9x16(counter)
      lda #$0006; write.bpp4()
      txy; jsl tilemap.calculateIndex; sub #$0006; tax
      lda #$0006; tilemap.write()
      rtl
    }
  }
}

namespace combatMenu {
  enqueue pc
  seek($c13ac5); jsl setWindowWidth
  dequeue pc

  variable(2, width)

  function setWindowWidth {
    variable(2, index)
    variable(2, count)

    inc $67; inc $67
    enter
    lda #$0000; sta index
    lda #$0002; sta width
    lda $67; and #$00ff; sta count

    loop: {
      lda index; tax
      lda $0940,x; and #$00ff
      ldx #$0000; append.technique()
      render.small.width(); add #$0007; div(8); inc  //+1 to account for the menu cursor
      cmp width; bcc +; sta width; +
      lda index; inc; sta index
      cmp count; jcc loop
    }

    sep #$20; lda width; sta $097e
    lda $096e; add #$07; sub width; sta $096e
    leave; rtl
  }
}

namespace technique {
  enqueue pc
  seek($c12f09); jml hook; nop
  seek($c13e2c); jsl details; jmp $3e45
  seek($c13de1); lda #$0f    //window width
  seek($c13e23); nop #3      //disable 'Lv.' marker
  seek($c13e76); ldy #$000e  //# of tiles to gray when MP/SP is too low to use a technique
  dequeue pc

  //------
  //c12f09  jsr $2f6e  ;write string
  //c12f0c  bra $2eed  ;exit point
  //------
  //A => command or technique ID
  function hook {
    enter; sep #$20
    pha; lda.b #constants.hook; sta $002180
    lda.b #constants.technique; sta $002180
    pla; sta $002180
    lda.b #constants.terminal;  sta $002180
    leave; jml $c12eed
  }

  //A => command (6 tiles; 0-22) or technique (8 tiles; 23-255)
  //X => tilemap index
  function name {
    variable(2, counter)
    variable(2, index)
    variable(2, tiles)

    enter
    phx; and #$00ff; sta index
    mul(8); tay
    index.for9x16(counter)

    lda combatMenu.width; dec; sta tiles
    lda index; cmp.w #23; bcc +; lda #$0008; sta tiles; +

    lda tiles; write.bpp4(lists.techniques.bpo4)
    txy; plx; tilemap.write()
    leave; rtl
  }

  //A => level
  //X => tilemap index (pointing at "LV" tile)
  function details {
    variable(2, counterLevel)
    variable(2, counterCost)
    variable(2, level)
    variable(2, cost)
    variable(2, index)

    enter
    and #$00ff
    cmp.w #100; bcc +; lda.w #100; +  //100+ => "Lv.??"
    sta level
    tya; lda $0851,y; and #$00ff
    cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    sta cost
    txa; add #$0010; sta index

    lda level; mul(3); tay
    index.for3x16L(counterLevel)
    lda #$0003; write.bpp4(lists.levels.bpo4)
    txy; lda index; tax
    lda #$0003; tilemap.write()

    lda cost; mul(3); tay
    index.for3x16R(counterCost)

    lda name.index; cmp #$004c; bcc sp
    mp:; lda #$0003; write.bpp4(lists.costsMP.bpa4); bra wr
    sp:; lda #$0003; write.bpp4(lists.costsSP.bpa4); wr:
    txy; lda index; add #$0006; tax
    lda #$0003; tilemap.write()

    //this is needed so that subsequent lines start at the beginning of the line.
    //without it, each line prints several tiles further to the right than the previous line.
    sep #$20; lda #$01; sta $62
    leave; rtl
  }
}

namespace item {
  enqueue pc
  seek($c12f0e); jml hook; nop
  seek($c17636); jsl dropped; nop #6
  seek($c17644); nop #3  //disable printing "ko" item counter
  seek($c13fb2); jsl quantity; nop #3
  seek($c19d06); jsl use.setWindowWidth; nop
  seek($c19d43); jsl use.setCount; nop #2
  seek($c19d56); nop #3  //disable printing "/" separator
  seek($c19d5b); jsl use.setTotal; nop #2
  seek($c19d67); nop #3  //disable printing "ko" item counter
  seek($c13fde); jsl page.setIndex
  seek($c13fe8); nop #3  //disable printing "/" separator
  seek($c13ff9); jsl page.setTotal
  dequeue pc

  //------
  //c12f0e  jsr $2f8b  ;write string
  //c12f11  bra $2eed  ;exit point
  //------
  //A => item#
  function hook {
    enter; sep #$20
    pha; lda.b #constants.hook; sta $002180
    lda.b #constants.item; sta $002180
    pla; sta $002180
    lda.b #constants.terminal; sta $002180
    leave; jml $c12eed
  }

  //A => item#
  //X => tilemap index
  function name {
    variable(2, counter)

    enter
    phx; and #$007f
    mul(9); tay
    index.for9x16(counter)

    lda #$0009; write.bpp4(lists.items.bpo4)
    txy; plx; tilemap.write()
    leave; rtl
  }

  function dropped {
    variable(2, counter)
    variable(2, value)

    enter
    lda $0871,y; and #$00ff
    mul(3); tay
    index.for3x16L(counter)
    lda #$0003; write.bpp4(lists.counts.bpa4)
    txy; jsl tilemap.calculateIndex; sub #$0002; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  function quantity {
    variable(2, counter)

    enter
    lda $7ec001,x; and #$00ff
    mul(3); tay
    index.for3x16L(counter)
    lda #$0003; write.bpp4(lists.counts.bpa4)
    txy; jsl tilemap.calculateIndex; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  namespace use {
    variable(2, counter)
    variable(2, count)
    variable(2, total)

    //------
    //c19d06  lda #$09   ;window width in tiles
    //c19d08  sta $097e  ;store the value
    //------
    function setWindowWidth {
      constant item = $0969

      enter
      lda.w item; and #$00ff; tax
      lda lists.items.widths,x; and #$00ff
      sep #$20; cmp #$04; bcs +; lda #$04; +  //min(A,4) for "#/#" use
      sta $097e  //store window width
      inc $096e  //move the window one tile to the right (to avoid overlapping the dragon)
      leave; rtl
    }

    //------
    //c19d43  lda $096b  ;load count
    //c19d46  jsr $307b  ;print count
    //------
    function setCount {
      enter
      lda $096b; and #$00ff; sta count
      leave; rtl
    }

    //------
    //c19d5b  lda $096a  ;load total
    //c19d5e  jsr $307b  ;print total
    //------
    function setTotal {
      variable(2, counter)

      enter
      lda $096a; and #$00ff; sta total

      ldx #$0000; txy; append.alignRight()
      lda count; append.integer_2()
      append.literal("/")
      lda total; append.integer_2()
      lda #$0004; render.small.bpo4()
      index.for8x2(counter)
      lda #$0004; write.bpp4()
      txy; jsl tilemap.calculateIndex; sub #$000a; tax
      lda #$0004; tilemap.write()
      leave; rtl
    }
  }

  namespace page {
    variable(2, counter)
    variable(2, index)
    variable(2, total)

    //------
    //c13fdc  lda $68    ;load current page#
    //c13fde  inc        ;count from 1 for displaying
    //c13fdf  jsr $30db  ;print page# to tilemap
    //------
    //X => tilemap index
    function setIndex {
      inc
      enter
      and #$00ff; sta index
      leave; rtl
    }

    //------
    //c13ff7  lda $69    ;load total number of pages
    //c13ff9  inc        ;count from 1 for displaying
    //c13ffa  jsr $30db  ;print page# to tilemap
    //------
    //X => tilemap index
    function setTotal {
      inc
      enter
      and #$00ff; sta total

      ldx #$0000; txy
      append.styleTiny(); append.alignSkip(2)
      append.literal("Page ")
      lda index; append.integer1(); append.literal("/")
      lda total; append.integer1()
      lda #$0005; render.small.bpo4()
      index.for8x2(counter)
      lda #$0005; write.bpp4()
      txy; jsl tilemap.calculateIndex; sub #$0006; tax
      lda #$0005; tilemap.write()
      leave; rtl
    }
  }
}

//move the menu cursors down by one pixel to center them vertically with text
namespace cursors {
  enqueue pc
  seek($de462e); db $f9
  seek($de4632); db $f9
  seek($de4636); db $f9
  seek($de463a); db $f9
  seek($de463e); db $f9
  seek($de4642); db $f9
  dequeue pc
}

codeCursor = pc()

}
