namespace menu {

seek(codeCursor)

namespace dragons {
  enqueue pc

  seek($eec783); jsl deployedName
  seek($eec7a8); jsl reservedName
  seek($eecb86); jsl playerName
  seek($eecbb8); string.hook(reservedDragon)
  seek($eecb2a); jsl drawWindowOverview
  seek($eec67f); jsl properties.main; plp; rts

  //cursor positions
  seek($eec8e2); {
    dw $0e,$15  //party 1
    dw $5e,$15  //party 2
    dw $ae,$15  //party 3
    dw $0e,$45  //party 4
    dw $5e,$45  //party 5
    dw $ae,$45  //party 6
    dw $0e,$75  //reserve
  }

  //name positions
  seek($eec7c4); lda #$0144  //party 1
  seek($eec7cb); lda #$0158  //party 2
  seek($eec7d2); lda #$016c  //party 3
  seek($eec7d9); lda #$02c4  //party 4
  seek($eec7e0); lda #$02d8  //party 5
  seek($eec7e7); lda #$02ec  //party 6
  seek($eec790); lda #$0444  //reserve

  //player sprite X,Y positions
  seek($eec952); db $0e; ds 3; db $0b  //party 1
  seek($eec95a); db $5e; ds 3; db $0b  //party 2
  seek($eec962); db $ae; ds 3; db $0b  //party 3
  seek($eec96a); db $0e; ds 3; db $3b  //party 4
  seek($eec972); db $5e; ds 3; db $3b  //party 5
  seek($eec97a); db $ae; ds 3; db $3b  //party 6

  //dragon sprite X,Y positions
  seek($eeca11); db $04; ds 3; db $01  //party 1
  seek($eeca19); db $0e; ds 3; db $01  //party 2
  seek($eeca21); db $18; ds 3; db $01  //party 3
  seek($eeca29); db $04; ds 3; db $07  //party 4
  seek($eeca31); db $0e; ds 3; db $07  //party 5
  seek($eeca39); db $18; ds 3; db $07  //party 6
  seek($eeca41); db $02; ds 3; db $0d  //reserve

  //party overview window
  seek($eecb07); lda #$0354  //window clear position
  seek($eecb0d); ldx #$0015  //window clear width
  seek($eecb10); ldy #$000c  //window clear height
  seek($eecb1e); lda #$0354  //window write position
  seek($eecb24); ldx #$0015  //window write width
  seek($eecb27); ldy #$000c  //window write height
  seek($eec608); lda #$87    //sprite X position
  seek($eec60d); lda #$68    //sprite Y position
  seek($eecb5e); lda #$0456  //player name list position
  seek($eecb46); lda #$03a6  //technique list position
  seek($eecbb2); lda #$04da  //"Reserved Dragon" position

  //dragon stats window
  seek($eec67b); nop #4      //disable clearing stats when changing dragons

  //replace the BG3VOFS HDMA table
  seek($eecbff); ldx.w #hdmaTable
  seek($eecc05); lda.w #hdmaTable.size
  seek($eecc08); mvn $7e=hdmaTable>>16

  dequeue pc

  allocator.bpp4()
  allocator.create( 8,12,deployedName)
  allocator.create( 8, 4,reservedName)
  allocator.bpp2()
  allocator.create( 5, 2,party)
  allocator.create( 7, 8,playerName)
  allocator.create(15, 2,reservedDragon)
  allocator.create( 8, 2,selectedDragon)
  allocator.create( 6,15,labels)
  allocator.create( 3,30,values)

  //this table produces 8x10 lines of text for the party and dragon stats areas.
  //in the original game, the party window was 8x12, and the stats area was 8x8.
  //the extra space this produces allows four lines of stats with a window frame.
  function hdmaTable {
    db $68,$06,$00
    db $0a,$0e,$00
    db $0a,$14,$00
    db $0a,$1a,$00
    db $0a,$20,$00
    db $11,$26,$00

    db $02,$2a,$00
    db $0a,$3a,$00
    db $0a,$40,$00
    db $0a,$46,$00
    db $0a,$4c,$00
    db $0a,$52,$00
    db $00
    constant size = pc() - hdmaTable
  }

  //A = dragon name
  function deployedName {
    enter
    getDragonName(); mul(8); tay
    lda #$0008; allocator.index(deployedName); write.bpp4(names.buffer.bpp4)
    leave; rtl
  }

  //A = dragon name
  function reservedName {
    enter
    getDragonName(); mul(8); tay
    lda #$0008; allocator.index(reservedName); write.bpp4(names.buffer.bpp4)
    leave; rtl
  }

  //A = party#
  function party {
    enter
    mul(5); tay
    lda #$03d6; sta $001860
    lda #$0005; allocator.index(party); write.bpp2(lists.parties.bpp2)
    leave; rtl
  }

  //A = player name
  function playerName {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; allocator.index(playerName); write.bpp2(names.buffer.bpp2)
    leave; rtl
  static:
    mul(8); tay
    lda #$0007; allocator.index(playerName); write.bpp2(lists.names.bpp2)
    leave; rtl
  }

  function reservedDragon {
    enter
    lda #$000f; ldy.w #strings.menu.reserveDragon
    allocator.index(reservedDragon); write.bpp2(lists.menu.bpp2)
    leave; rtl
  }

  namespace properties {
    namespace constants {
      constant strength     =  6
      constant vitality     =  7
      constant dexterity    =  8
      constant intelligence =  9
      constant fire         = 10
      constant water        = 11
      constant thunder      = 12
      constant earth        =  0  //min(fire,water,thunder)
      constant recovery     = 13
      constant poison       = 14
      constant corruption   = 15
      constant timidity     = 16
      constant wisdom       = 17
      constant aggression   = 18
      constant mutation     = 19
      constant affection    = 20
    }

    macro label(variable index, define name) {
      ldy.w #strings.menu.{name}
      if index / 5 == 0 {; lda.w #$0704+(index%5)*$80; }
      if index / 5 == 1 {; lda.w #$0716+(index%5)*$80; }
      if index / 5 == 2 {; lda.w #$072a+(index%5)*$80; }
      sta $001860
      lda #$0006; ldy.w #strings.menu.{name}
      allocator.index(labels); jsl writeLabel
    }

    macro value(variable index, define name) {
      if index / 5 == 0 {; lda.w #$070e+(index%5)*$80; }
      if index / 5 == 1 {; lda.w #$0722+(index%5)*$80; }
      if index / 5 == 2 {; lda.w #$0736+(index%5)*$80; }
      sta $001860
      ldy.w #dragons.stats.{name}-dragons.stats.base
      lda [$12],y; and #$00ff
      mul(3); tay; lda #$0003
      allocator.index(values); jsl writeValue
    }

    macro divider(variable index) {
      index = (index == 0 ? $cb14 : $cb28)
      lda #$2829
      sta.w index+$000; sta.w index+$040; sta.w index+$080
      sta.w index+$0c0; sta.w index+$100; sta.w index+$140
      sta.w index+$180; sta.w index+$1c0; sta.w index+$200
    }

    function main {
      enter; ldb #$7e

      //the window border and labels only need to be rendered once.
      //check if the first tile of "Strength" is blank to see if it's needed.
      lda $ca42; cmp #$0000; jne +; {
        //draw a window around the dragon stats area
        lda #$0642   //X,Y offset
        ldx #$001e   //width
        ldy #$000d   //height
        sta $001860  //store target
        jsl drawWindowOverview

        //draw two vertical dividers between each stat column
        divider(0)
        divider(1)

        //render the stat labels
        label( 0,fire)
        label( 1,water)
        label( 2,thunder)
        label( 3,recovery)
        label( 4,poison)

        label( 5,strength)
        label( 6,vitality)
        label( 7,dexterity)
        label( 8,intelligence)
        label( 9,wisdom)

        label(10,aggression)
        label(11,affection)
        label(12,timidity)
        label(13,corruption)
        label(14,mutation)
      };+

      //the stats always need to be refreshed
      value( 0,fire)
      value( 1,water)
      value( 2,thunder)
      value( 3,recovery)
      value( 4,poison)

      value( 5,strength)
      value( 6,vitality)
      value( 7,dexterity)
      value( 8,intelligence)
      value( 9,wisdom)

      value(10,aggression)
      value(11,affection)
      value(12,timidity)
      value(13,corruption)
      value(14,mutation)

      leave; rtl
    }

    //A = tile count
    //X = target index
    //Y = source index
    function writeLabel {
      enter
      jsl vsync
      pha; tya; mul(16); ply
      add.w #lists.menu.bpp2 >>  0; sta $004302
      lda.w #lists.menu.bpp2 >> 16; adc #$0000; sta $004304
      txa; mul(16); add #$8000; lsr; sta $002116
      tya; mul(16); sta $004305; sep #$20
      lda #$80; sta $002115
      lda #$01; sta $004300
      lda #$18; sta $004301
      lda #$01; sta $00420b
      jsl writeTilemap
      leave; rtl
    }

    //A = tile count
    //X = target index
    //Y = source index
    function writeValue {
      enter
      jsl vsync
      pha; tya; mul(16); ply
      add.w #lists.stats.bpp2 >>  0; sta $004302
      lda.w #lists.stats.bpp2 >> 16; adc #$0000; sta $004304
      txa; mul(16); add #$8000; lsr; sta $002116
      tya; mul(16); sta $004305; sep #$20
      lda #$80; sta $002115
      lda #$01; sta $004300
      lda #$18; sta $004301
      lda #$01; sta $00420b
      jsl writeTilemap
      leave; rtl
    }

    //custom tilemap write routine needed to not (han)dakuten line
    //A = tile count
    //X = target index
    function writeTilemap {
      enter; ldb #$7e
      txa; ora $001862
      pha; lda $001860; tax; pla
      cpy #$0000
    -;beq +
      sta $c400,x
      inc; inx #2; dey; bra -
    +;txa; sta $001860
      lda #$0001; sta $00185a
      leave; rtl
    }
  }
}

codeCursor = pc()

}
