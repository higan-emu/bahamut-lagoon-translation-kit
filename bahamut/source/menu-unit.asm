namespace menu {

seek(codeCursor)

namespace unit {
  enqueue pc

  seek($eeada3); jsl name
  seek($eeadbc); jsl enemy
  seek($eeac42); string.hook(enemy.unknown)
  seek($eeadf0); jsl level
  seek($eeae29); jsl hp.setCurrent
  seek($eeae47); jsl hp.setMaximum
  seek($eeaea1); jsl mp.setCurrent
  seek($eeaebf); jsl mp.setMaximum
  seek($eeaed8); jsl mp.setCurrentUnavailable
  seek($eeaef5); jsl mp.setMaximumUnavailable
  seek($eeaf06); string.hook(attack.label)
  seek($eeaf38); string.hook(defense.label)
  seek($eeaf6a); string.hook(speed.label)
  seek($eeaf9c); string.hook(magic.label)
  seek($eeaf27); jsl attack.value
  seek($eeaf59); jsl defense.value
  seek($eeaf8b); jsl speed.value
  seek($eeafbd); jsl magic.value
  seek($eeaffe); jsl stats; jmp $affb

  //the "LV" text was moved up onto the name line.
  //the status icons have been moved to the start of the second line.
  seek($eeadd3); string.skip()  //"LV" text
  seek($eeade3); lda #$0060     //"LV" position
  seek($eeadf4); lda #$00d0     //status icon(s) position
  seek($eeae0a); string.skip()  //"HP" text
  seek($eeae33); string.skip()  //"HP" separator
  seek($eeae3a); lda #$0150     //"HP" position
  seek($eeae76); string.hook(mp.setTypeMP)  //"MP" text

  seek($eeaf1a); lda #$0074  //"Attack#"  position
  seek($eeaf4c); lda #$00f4  //"Defense#" position
  seek($eeaf7e); lda #$0174  //"Speed#"   position
  seek($eeafb0); lda #$01f4  //"Magic#"   position

  //player and dragon statistics
  seek($ee7065); string.skip()  //disable "-" separator (with MP/SP)
  seek($ee7020); string.skip()  //disable "-" separator (without MP/SP)
  seek($ee705f); nop #2         //position numeric offset (dash)
  seek($ee7071); adc #$0000     //position numeric offset (maximum)

  //dragon statistics (most stat strings are shared with the item explanation screen)
  seek($eeb03b); string.skip()  //"Timidity" text
  seek($eeb04c); string.skip()  //"Wisdom" text

  //enemy statistics
  seek($eeaeab); string.skip()  //disable "-" separator (with MP)
  seek($eeaee2); string.skip()  //disable "-" separator (without MP)
  seek($eeaeb2); lda #$01d0     //available position
  seek($eeaee9); lda #$01d0     //unavailable position
  seek($eead33); lda #$06c2     //position of name+stats for single enemies (bosses usually)

  //cursor positions
  seek($eeac8d); lda #$0046  //X cursor position (player - from field)
  seek($eeac86); adc #$fff9  //Y cursor position
  seek($eeab00); lda #$0046  //X cursor position (dragon - from field)
  seek($eeab07); lda #$0097  //Y cursor position
  seek($eeaa2d); lda #$0046  //X cursor position (dragon - from dragon formation)
  seek($eeaa34); lda #$0097  //Y cursor position

  //player statistics HDMA fix:
  //8x12 height is simulated using HDMA on channel 7 from $eeb1c7 (ROM) to $2112 (BG3VOFS)
  //the original game had a small bug in the last entry of the table:
  //$00; $04,$08,$0c,$10; $16,$1a,$1e,$22; $28,$2c,$30,$34; $3a,$3e,$42,$46; $44
  //$44 should be $4c. this error resulted in the last text line being repeated twice.
  seek($eeb1fb); db $4c  //this modification to the HDMA table fixes the error.

  dequeue pc

  allocator.bpp2()
  allocator.create( 9, 4,name)
  allocator.create( 6, 1,unknown)
  allocator.create( 3, 4,level)
  allocator.create(11, 4,hpRange)
  allocator.create(11, 4,mpRange)
  allocator.create( 5, 1,attackLabel)
  allocator.create( 5, 1,defenseLabel)
  allocator.create( 5, 1,speedLabel)
  allocator.create( 5, 1,magicLabel)
  allocator.create( 3, 4,attackValue)
  allocator.create( 3, 4,defenseValue)
  allocator.create( 3, 4,speedValue)
  allocator.create( 3, 4,magicValue)
  allocator.create( 6,15,propertyLabel)
  allocator.create( 3,15,propertyValue)

  //A = player or dragon name
  function name {
    enter
    and #$00ff

    //move the name+stats position only for the dragon screens.
    //this is done to make room for the extra stats shown in the translation.
    cmp #$0002; bcc +
    cmp #$0009; bcs +
    pha; lda #$0812; sta $001860; lda #$07c2; sta $001864; pla; +

    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    allocator.index(name)
    lda #$0008; write.bpp2(names.buffer.bpp2)
    leave; rtl
  static:
    mul(8); tay
    allocator.index(name)
    lda #$0008; write.bpp2(lists.names.bpp2)
    leave; rtl
  }

  //A = enemy
  function enemy {
    enter
    and #$00ff; mul(9); tay
    allocator.index(name)
    lda #$0009; write.bpp2(lists.enemies.bpp2)
    leave; rtl

    //shown for enemies without sprite portrait previews (eg Alexander)
    function unknown {
      enter
      ldy.w #strings.bpp2.unknown
      allocator.index(unknown)
      lda #$0006; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }
  }

  //A = player or enemy level
  function level {
    enter
    and #$00ff; mul(3); tay
    allocator.index(level)
    lda #$0003; write.bpp2(lists.levels.bpp2)
    leave; rtl
  }

  namespace hp {
    variable(2, current)

    //A = current HP
    function setCurrent {
      enter
      sta current
      leave; rtl
    }

    //A = maximum HP
    function setMaximum {
      enter
      tay; lda current
      ldx #$0000; append.hpRange()
      lda #$000b; render.small.bpp2()
      allocator.index(hpRange); jsl write.bpp2
      leave; rtl
    }
  }

  namespace mp {
    variable(2, type)
    variable(2, current)
    variable(2, maximum)

    //A = type
    function setType {
      enter
      sta type
      leave; rtl
    }

    //force type to MP for enemies
    function setTypeMP {
      enter
      lda #$0080; sta type
      leave; rtl
    }

    //A = current MP
    function setCurrent {
      enter
      sta current
      leave; rtl
    }

    //A = maximum MP
    function setMaximum {
      enter
      sta maximum
      jsl render
      leave; rtl
    }

    function setCurrentUnavailable {
      enter
      lda #$ffff; sta current
      leave; rtl
    }

    function setMaximumUnavailable {
      enter
      lda #$ffff; sta maximum
      jsl render
      leave; rtl
    }

    function render {
      enter
      lda type; ldx #$0000
      cmp #$0000; bne +; lda maximum; tay; lda current; append.spRange(); +
      cmp #$0080; bne +; lda maximum; tay; lda current; append.mpRange(); +
      lda #$000b; render.small.bpp2()
      allocator.index(mpRange)
      lda #$000b; jsl write.bpp2
      leave; rtl
    }
  }

  macro writeLabel(define name) {
    enter
    ldy.w #strings.bpp2.{name}
    allocator.index({name}Label)
    lda #$0005; write.bpp2(lists.strings.bpp2)
    leave; rtl
  }

  //A = value
  macro writeValue(define name) {
    enter
    and #$00ff; mul(3); tay
    allocator.index({name}Value)
    lda #$0003; write.bpp2(lists.stats.bpp2)
    leave; rtl
  }

  namespace attack {
    label:; writeLabel(attack)
    value:; writeValue(attack)
  }

  namespace defense {
    label:; writeLabel(defense)
    value:; writeValue(defense)
  }

  namespace speed {
    label:; writeLabel(speed)
    value:; writeValue(speed)
  }

  namespace magic {
    label:; writeLabel(magic)
    value:; writeValue(magic)
  }

  hdmaTable: {
    db $0c,$00,$00
    db $0a,$02,$00
    db $0a,$08,$00
    db $0a,$0e,$00
    db $0a,$14,$00
    db $0a,$1a,$00
    db $0a,$20,$00
    db $0a,$26,$00
    db $0a,$2c,$00
    db $0a,$32,$00
    db $0a,$38,$00
    db $0a,$3e,$00
    db $0a,$44,$00
    db $0a,$4a,$00
    db $0a,$50,$00
    db $0a,$56,$00
    db $06,$56,$00
    db $0c,$56,$00
    db $0c,$5a,$00
    db $0c,$5e,$00
    db $0c,$62,$00
    db $04,$60,$00
    db $04,$5c,$00
    db $00
  }

  macro stat(variable index, define name) {
    lda.w #$0084+index*$80; sta $001860
    ldy.w #strings.menu.{name}
    allocator.index(propertyLabel)
    lda #$0006; write.bpp2(lists.menu.bpp2)
    lda table; tax
    lda.l dragons.stats.{name},x; and #$00ff
    mul(3); tay
    allocator.index(propertyValue)
    lda #$0003; write.bpp2(lists.stats.bpp2)
  }

  //------
  //eeb05a  ldy #$0006
  //eeb05d  lda [$40],y  ;get the current dragon
  //eeb05f  ply
  //eeb060  sec
  //eeb061  sbc #$0020   ;subtract a fixed offset
  //eeb064  sta $00
  //eeb066  lda #$0020   ;length of each dragon entry
  //eeb069  jsr $2ae9    ;multiply index by 32
  //------
  function stats {
    variable(2, table)

    enter
    lda.w #hdmaTable >> 0; sta $004372
    lda.w #hdmaTable >> 8; sta $004373
    ldy #$0006; lda [$40],y
    sub #$0020; mul(32); sta table
    stat( 0,fire)
    stat( 1,water)
    stat( 2,thunder)
    stat( 3,recovery)
    stat( 4,poison)
    stat( 5,strength)
    stat( 6,vitality)
    stat( 7,dexterity)
    stat( 8,intelligence)
    stat( 9,wisdom)
    stat(10,aggression)
    stat(11,affection)
    stat(12,timidity)
    stat(13,corruption)
    stat(14,mutation)
    leave; rtl
  }
}

codeCursor = pc()

}
