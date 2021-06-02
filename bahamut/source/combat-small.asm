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

namespace glyph {
  constant undead    = $18
  constant fire      = $13
  constant water     = $14
  constant thunder   = $17
  constant earth     = $16
  constant poison    = $15
  constant defeated  = $2b
  constant petrified = $2c
  constant sleeping  = $2d
  constant poisoned  = $2e
  constant bunny     = $2f
  constant bingo     = $ca
}

//available tiles:
//$01e-$029 =  12 tiles (item icons)
//$030-$0cb = 156 tiles (normal)
//$0cf-$169 = 155 tiles (active)

//reserved tiles:
//$000-$01d = window borders + affinity icons + HP/MP/SP labels
//$02a-$02f = ailment icons
//$0ca-$0ce = bingo icon + potion icon + level up text
//$16a-$16b = dragon stats labels
//$16c-$16d = EXP label
//$16e-$17f = dragon stats labels

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
  //$0ec-$169
  table9x16: {
    dw $0b8,$0c1
    dw $0ec,$0f5,$0fe,$107
    dw $110,$119,$122,$12b
    dw $134,$13d,$146,$14f
    dw $158,$161
  }
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
    jsl player.name
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

  macro write(variable character) {
    php; rep #$30; pha
    lda.w #$3800|character; sta $7e4800,x; inx #2
    pla; plp
  }
}

namespace write {
  //A => tile count
  //X => target index
  //Y => source index
  macro bpp4(variable source) {
    enter; vsync(); ldb #$00
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
  function bpp4 {
    php; rep #$10; phy
    ldy #$0000; write.bpp4(render.buffer)
    ply; plp; rtl
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
    cmp.w #constants.strings.feed;      bne +; jsl dragons.feed; leave; rtl; +
    cmp.w #constants.strings.exit;      bne +; jsl dragons.exit; leave; rtl; +
    cmp.w #constants.strings.wisdom;    bne +; leave; rtl; +  //handled by combat-dragons
    cmp.w #constants.strings.affection; bne +; leave; rtl; +  //handled by combat-dragons
    leave; rtl
  }
}

namespace player {
  enqueue pc
  seek($c12eff); jml hook
  seek($c138a0); jsl status; nop
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

  //------
  //c138a0  inc #63
  //c138a2  jsr $3919
  //------
  //X => character table index
  function status {
    constant ailments = $7e6421
    constant enchants = $7e6423

    inc $63
    enter; ldb #$7e
    txy; jsl tilemap.calculateIndex; tax
    lda ailments,y; and.w #status.ailment.defeated;  beq +; tilemap.write(glyph.defeated ); +
    lda ailments,y; and.w #status.ailment.petrified; beq +; tilemap.write(glyph.petrified); +
    lda ailments,y; and.w #status.ailment.sleeping;  beq +; tilemap.write(glyph.sleeping ); +
    lda ailments,y; and.w #status.ailment.poisoned;  beq +; tilemap.write(glyph.poisoned ); +
    lda ailments,y; and.w #status.ailment.bunny;     beq +; tilemap.write(glyph.bunny    ); +
    lda enchants,y; and.w #status.enchant.bingo;     beq +; tilemap.write(glyph.bingo    ); +
    leave; rtl
  }

  //X => character table index
  function hp {
    constant hpValues = $7e6425

    variable(2, value)
    variable(2, index)
    variable(2, target)

    enter
    lda.l hpValues,x; sta value

    jsl tilemap.calculateIndex; sta target
    cmp #$0148; bne +; lda #$0000; bra found; +  //player 1 name
    cmp #$0156; bne +; lda #$0001; bra found; +  //player 2 name
    cmp #$0164; bne +; lda #$0002; bra found; +  //player 3 name
    cmp #$0170; bcc +; cmp #$0180; bcs +; lda #$0003; bra found; +  //player 4 or dragon name
    leave; rtl; found:; sta index

    ldx #$0000
    lda value; cmp.w #10000; bcs above
    below:; append.integer_4();     bra render  //"####"
    above:; append.literal("^^^^"); bra render  //"????"
  render:
    lda #$0003; render.small.bpo4()
    lda index; index.to3x8()
    lda #$0003; write.bpp4()
    txy; lda target; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  //X => character table index
  function mp {
    constant mpValues = $7e6429

    variable(2, value)
    variable(2, index)
    variable(2, target)
    variable(2, available)

    enter
    lda.l mpValues,x; sta value

    jsl tilemap.calculateIndex; sta target
    cmp #$0188; bne +; lda #$0000; bra found; +  //player 1 name
    cmp #$0196; bne +; lda #$0001; bra found; +  //player 2 name
    cmp #$01a4; bne +; lda #$0002; bra found; +  //player 3 name
    cmp #$01b0; bcc +; cmp #$01c0; bcs +; lda #$0003; bra found; +  //player 4 or dragon name
    leave; rtl; found:; add #$0004; sta index

    ldx #$0000; txy
    lda available; beq none
    lda value; cmp.w #1000; bcs above
    below:; append.integer_4();     bra render  //" ###"
    above:; append.literal("_^^^"); bra render  //" ???"
    none:;  append.literal("_~~~"); bra render  //" ---"
  render:
    lda #$0003; render.small.bpo4()
    lda index; index.to3x8()
    lda #$0003; write.bpp4()
    txy; lda target; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  //X => character table index
  function hasMP {
    constant attributes = $7e6460

    enter
    lda.l attributes,x; bit #$0020; beq yes
    no:;  lda #$0000; sta mp.available; leave; rtl
    yes:; lda #$0001; sta mp.available; leave; rtl
  }
}

namespace name {
  enqueue pc
  seek($c14681); jsl setPlayerNameWindowWidth; nop
  seek($c1398d); jsl setDragonStatsWindowWidth; nop
  seek($c17454); jsl setDragonExperienceWindowWidth; nop
  dequeue pc

  constant nameIndex = $7e6431

  variable(2, width)

  //------
  //c14681  lda #$08   ;width of name window
  //c14683  sta $097e  ;store width
  //------
  //X => player#
  function setPlayerNameWindowWidth {
    constant playerIndex  = $6b
    constant windowOffset = $06
    constant windowWidth  = $097e

    enter
    lda.b playerIndex; and #$00ff; xba; tax
    lda.l nameIndex,x; and #$00ff
    jsl calculateWidth; max.w(1)  //cannot be zero
    sep #$20; sta.w windowWidth
    lda.b windowOffset; add #$08; sub width; sta.b windowOffset
    leave; rtl
  }

  //------
  //c1398d  lda #$08   ;width of window
  //c1399f  sta $097c  ;store width
  //------
  function setDragonStatsWindowWidth {
    constant windowOffset = $096c
    constant windowWidth  = $097c

    enter
    lda.l nameIndex; and #$00ff
    jsl calculateWidth; max.w(5)  //"HP/MP ####" length
    sep #$20; sta.w windowWidth
    pha; lda #$1e; sub $01,s; sta.w windowOffset; pla
    leave; rtl
  }

  //------
  //c17454  lda #$08   ;width of window
  //c17456  sta $097c  ;store width
  //------
  function setDragonExperienceWindowWidth {
    constant windowWidth = $097c

    enter
    lda.l nameIndex; and #$00ff
    jsl calculateWidth; max.w(5)  //"EXP" + "Lv. Up" length
    sep #$20; sta.w windowWidth
    leave; rtl
  }

  //A => name index
  //A <= name width (in tiles)
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
  seek($c1766a); lda #$02  //"Lv. Up" text position
  dequeue pc

  //X => character table index
  function main {
    constant experienceTable = $7e641a

    variable(2, value)
    variable(2, index)
    variable(2, target)

    enter
    lda.l experienceTable,x; sta value
    jsl tilemap.calculateIndex; sta target

    cmp #$014e; bne +; lda #$0000; sta index; bra render; +
    cmp #$015c; bne +; lda #$0001; sta index; bra render; +
    cmp #$016a; bne +; lda #$0002; sta index; bra render; +
    cmp #$0178; bne +; lda #$0003; sta index; bra render; +
    leave; rtl; render:

    ldx #$0000
    lda value; append.alignRight(); append.integer_5()
    lda #$0004; render.small.bpo4()
    lda index; index.to4x4(); tax
    lda #$0004; write.bpp4()
    txy; lda target; sub #$0008; tax
    lda #$0004; tilemap.write()
    leave; rtl
  }
}

namespace piro {
  enqueue pc
  seek($c174f0); lda #$0c          //window width (set to match the item drop list window width)
  seek($c1751c); jsl main; nop #4  //hook piro quantity write
  seek($c17532); nop #3            //disable printing of static "Piro" text ([$c1db1d] "ピロー")
  dequeue pc

  function main {
    constant piro = $092f

    variable(2, value)

    enter
    lda.w piro; sta value
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
  seek($c148ad); jsl status; rts
  seek($c147df); jsl hp.value; jmp $4803
  seek($c1482b); jsl mp.value; jmp $4839
  seek($c14854); jsl hp.unknown; jmp $4868
  seek($c14883); jsl mp.unknown; jmp $4892
  seek($c146af); jsl setWindowWidth; nop
  seek($c147c2); jmp $47cb  //disable static "HP" text
  seek($c14817); jmp $4820  //disable static "MP" text (value)
  seek($c14872); jmp $487b  //disable static "MP" text (unknown)
  seek($c1487b); lda #$03   //static "MP" text position (unknown)
  seek($c147b5); nop #3     //disable ailments+enchants printing (handled by status)
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

  constant enemy      =     $6b
  constant names      = $7e6431
  constant properties = $7e6444
  constant affinities = $7e6434
  constant ailments   = $7e6421

  function setWindowWidth {
    constant windowWidth = $097e

    enter
    lda.b enemy; and #$00ff; xba; tax
    lda.l names,x; and #$00ff
    jsl calculateWidth
    sep #$20; lda width; sta.w windowWidth

    ldy #$0000
    lda properties,x; and.b #status.property.undead;   beq +; iny; +
    lda affinities,x; and.b #status.affinity.fire;     beq +; iny; +
    lda affinities,x; and.b #status.affinity.water;    beq +; iny; +
    lda affinities,x; and.b #status.affinity.thunder;  beq +; iny; +
    lda affinities,x; and.b #status.affinity.earth;    beq +; iny; +
    lda affinities,x; and.b #status.affinity.poison;   beq +; iny; +
    lda ailments,x;   and.b #status.ailment.defeated;  beq +; iny; +
    lda ailments,x;   and.b #status.ailment.petrified; beq +; iny; +
    lda ailments,x;   and.b #status.ailment.sleeping;  beq +; iny; +
    lda ailments,x;   and.b #status.ailment.poisoned;  beq +; iny; +
    lda ailments,x;   and.b #status.ailment.bunny;     beq +; iny; +

    //windowWidth <= max(windowWidth, iconCount)
    phy; lda width; cmp $01,s; bcs +
    lda $01,s; sta.w windowWidth; +; ply

    leave; rtl
  }

  //A => enemy name ID
  function calculateWidth {
    enter
    ldx #$0000; append.enemy()
    render.small.width(); add #$0007; div(8)
    clamp.w(5,8); sta width
    leave; rtl
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

  function status {
    lda #$00
    enter; ldb #$7e

    txy; jsl tilemap.calculateIndex; tax
    lda properties,y; and.w #status.property.undead;   beq +; tilemap.write(glyph.undead   ); +
    lda affinities,y; and.w #status.affinity.fire;     beq +; tilemap.write(glyph.fire     ); +
    lda affinities,y; and.w #status.affinity.water;    beq +; tilemap.write(glyph.water    ); +
    lda affinities,y; and.w #status.affinity.thunder;  beq +; tilemap.write(glyph.thunder  ); +
    lda affinities,y; and.w #status.affinity.earth;    beq +; tilemap.write(glyph.earth    ); +
    lda affinities,y; and.w #status.affinity.poison;   beq +; tilemap.write(glyph.poison   ); +
    lda ailments,y;   and.w #status.ailment.defeated;  beq +; tilemap.write(glyph.defeated ); +
    lda ailments,y;   and.w #status.ailment.petrified; beq +; tilemap.write(glyph.petrified); +
    lda ailments,y;   and.w #status.ailment.sleeping;  beq +; tilemap.write(glyph.sleeping ); +
    lda ailments,y;   and.w #status.ailment.poisoned;  beq +; tilemap.write(glyph.poisoned ); +
    lda ailments,y;   and.w #status.ailment.bunny;     beq +; tilemap.write(glyph.bunny    ); +

    leave; rtl
  }

  namespace hp {
    //X => enemy index
    function value {
      constant hpValues = $7e6425

      sep #$20
      enter
      lda.l hpValues,x
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
      lda #$0005; ldy #$0000; render.small.bpo4()
      index.for9x16(counter)
      lda #$0005; write.bpp4()
      txy; jsl tilemap.calculateIndex; sub #$0006; tax
      lda #$0005; tilemap.write()
      rtl
    }
  }

  namespace mp {
    //X => enemy index
    function value {
      constant mpValues = $7e6429

      sep #$20
      enter
      lda.l mpValues,x
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
      lda #$0005; ldy #$0000; render.small.bpo4()
      index.for9x16(counter)
      lda #$0005; write.bpp4()
      txy; jsl tilemap.calculateIndex; sub #$0006; tax
      lda #$0005; tilemap.write()
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
    constant windowOffset = $096e
    constant windowWidth  = $097e

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

    sep #$20; lda width; sta.w windowWidth
    lda.w windowOffset; add #$07; sub width; sta.w windowOffset
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
  //Y => costs index
  function details {
    constant costs = $0851

    variable(2, counterLevel)
    variable(2, counterCost)
    variable(2, level)
    variable(2, cost)
    variable(2, index)

    enter
    and #$00ff; min.w(100); sta level  //100+ => "Lv.??"
    lda.w costs,y; and #$00ff; min.w(100); sta cost  //100+ => "??"
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
  seek($c13fb2); jsl quantity; nop #3
  seek($c19d06); jsl use.setWindowWidth; nop
  seek($c19d43); jsl use.setCount; nop #2
  seek($c19d5b); jsl use.setTotal; nop #2
  seek($c13fde); jsl page.setIndex
  seek($c13ff9); jsl page.setTotal
  seek($c17644); nop #3   //disable printing "ko" item counter
  seek($c19d56); nop #3   //disable printing "/" separator
  seek($c19d67); nop #3   //disable printing "ko" item counter
  seek($c13fe8); nop #13  //disable printing "/" separator + attribute modification
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

  //Y => item list index
  function dropped {
    constant counts = $0871

    variable(2, counter)
    variable(2, value)

    enter
    lda.w counts,y; and #$00ff
    mul(3); tay
    index.for3x16L(counter)
    lda #$0003; write.bpp4(lists.counts.bpa4)
    txy; jsl tilemap.calculateIndex; sub #$0002; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  //X => item list index
  function quantity {
    constant counts = $7ec001

    variable(2, counter)

    enter
    lda.l counts,x; and #$00ff
    mul(3); tay
    index.for3x16L(counter)
    lda #$0003; write.bpp4(lists.counts.bpa4)
    txy; jsl tilemap.calculateIndex; tax
    lda #$0003; tilemap.write()
    leave; rtl
  }

  namespace use {
    constant item         = $0969
    constant itemCount    = $096b
    constant itemTotal    = $096a
    constant windowOffset = $096e
    constant windowWidth  = $097e

    variable(2, counter)
    variable(2, count)
    variable(2, total)

    //------
    //c19d06  lda #$09   ;window width in tiles
    //c19d08  sta $097e  ;store the value
    //------
    function setWindowWidth {
      enter
      lda.w item; and #$00ff; tax
      lda lists.items.widths,x; and #$00ff
      sep #$20; pha
      lda.w itemTotal; cmp.b #10; bcs total_2
      total_1:; pla; max.b(4); bra store  //9 + 18 => 27 pixels => 4 tiles
      total_2:; pla; max.b(5); bra store  //9 + 30 => 39 pixels => 5 tiles
    store:
      sta.w windowWidth
      inc.w windowOffset  //move the window one tile to the right (to avoid overlapping the dragon)
      leave; rtl
    }

    //------
    //c19d43  lda $096b  ;load count
    //c19d46  jsr $307b  ;print count
    //------
    function setCount {
      enter
      lda.w itemCount; and #$00ff; sta count
      leave; rtl
    }

    //------
    //c19d5b  lda $096a  ;load total
    //c19d5e  jsr $307b  ;print total
    //------
    function setTotal {
      variable(2, counter)

      enter
      ldx #$0000; txy
      append.alignSkip(1)
      lda.w itemTotal; and #$00ff; sta total
      cmp.w #10; jcs total_2

      total_1: {
        lda count; append.integer1()
        append.literal("/")
        lda total; append.integer1()
        jmp render
      }

      total_2: {
        lda count; append.integer_2()
        append.literal("/")
        lda total; append.integer_2()
        jmp render
      }

      render: {
        lda #$0004; render.small.bpo4(); render.small.bpo4.to.bpa4()
        index.for8x2(counter)
        lda #$0004; write.bpp4()
        txy; jsl tilemap.calculateIndex; sub #$0008; tax
        lda #$0004; tilemap.write()
        leave; rtl
      }
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
      append.byte(map.windowBorder)
      append.styleTiny()
      append.alignSkip(1)
      append.literal("Page")
      lda total; cmp.w #10; jcs total_2

      total_1: {
        append.alignLeft()
        append.alignSkip(24)
        lda index; append.integer1(); append.literal("/")
        lda total; append.integer1()
        append.styleNormal()
        append.byte(map.windowBorder)
        lda #$0005; render.small.bpo4()
        index.for8x2(counter)
        lda #$0005; write.bpp4()
        txy; jsl tilemap.calculateIndex; sub #$0006; tax
        lda #$0005; tilemap.write()
        leave; rtl
      }

      total_2: {
        append.alignLeft()
        append.alignSkip(23)
        lda index; append.integer_2(); append.literal("/")
        append.alignLeft()
        append.alignSkip(37)
        lda total; append.integer_2()
        append.styleNormal()
        append.byte(map.windowBorder)
        lda #$0006; render.small.bpo4()
        index.for8x2(counter)
        lda #$0006; write.bpp4()
        txy; jsl tilemap.calculateIndex; sub #$0008; tax
        lda #$0006; tilemap.write()
        leave; rtl
      }
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
