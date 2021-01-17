namespace combat {

seek(codeCursor)

//$7e3b7a => item list
namespace dragons {
  enqueue pc
  seek($c12f13); jml class.hook   //write the dragon name and class together
  seek($c198b0); jsl values; rts  //write all stat labels and values
  seek($c1a2c8); jml changes      //blink stats to indicate effects of feeding item
  seek($c19784); nop #3           //disable 16 dragon-stat tiles from being copied to $d0-$df
  seek($c19ad0); nop #2           //always show corruption stat even when timidity is < 100
  dequeue pc

  namespace positions {
    constant hp           = $7e48e6
    constant mp           = $7e48f2
    constant fire         = $7e4902
    constant water        = $7e490e
    constant thunder      = $7e491a
    constant recovery     = $7e4926
    constant poison       = $7e4932
    constant strength     = $7e4942
    constant vitality     = $7e494e
    constant dexterity    = $7e495a
    constant intelligence = $7e4966
    constant wisdom       = $7e4972
    constant aggression   = $7e4982
    constant affection    = $7e498e
    constant timidity     = $7e499a
    constant corruption   = $7e49a6
    constant mutation     = $7e49b2
  }

  namespace changes {
    constant hp           = $7e088b
    constant mp           = $7e088c
    constant strength     = $7e088d
    constant vitality     = $7e088e
    constant dexterity    = $7e088f
    constant intelligence = $7e0890
    constant fire         = $7e0891
    constant water        = $7e0892
    constant thunder      = $7e0893
    constant recovery     = $7e0894
    constant poison       = $7e0895
    constant corruption   = $7e0896
    constant timidity     = $7e0897
    constant wisdom       = $7e0898
    constant aggression   = $7e0899
    constant mutation     = $7e089a
    constant affection    = $7e089b
  }

  namespace tiles {
    constant hp           = $00d  //2 tiles
    constant mp           = $00b  //2 tiles
    constant fire         = $013  //1 tile
    constant water        = $014  //1 tile
    constant thunder      = $017  //1 tile
    constant recovery     = $0cb  //1 tile
    constant poison       = $015  //1 tile
    constant strength     = $16a  //2 tiles
    constant vitality     = $16e  //2 tiles
    constant dexterity    = $170  //2 tiles
    constant intelligence = $172  //2 tiles
    constant wisdom       = $174  //2 tiles
    constant aggression   = $176  //2 tiles
    constant affection    = $178  //2 tiles
    constant timidity     = $17a  //2 tiles
    constant corruption   = $17c  //2 tiles
    constant mutation     = $17e  //2 tiles
    constant separator    = $004  //1 tile
  }

  namespace class {
    //------
    //c12f13  jsr $2fb5
    //c12f16  bra $2eed
    //------
    function hook {
      enter; sep #$20
      pha; lda.b #constants.hook; sta $002180
      lda.b #constants.dragonClass; sta $002180
      pla; sta $002180
      lda.b #constants.terminal; sta $002180
      leave; jml $c12eed
    }

    //A => dragon class name
    function name {
      variable(2, identifier)

      enter
      and #$00ff; sta identifier
      lda player.name.identifier
      ldx #$0000; txy; append.name()
      append.literal(" - ")
      lda name.identifier; append.dragon()
      lda #$0012; render.small.bpo4()
      index.to18x1(0); lda #$0012; write.bpp4()
      txy; ldx #$00c2
      lda #$0012; tilemap.write()
      leave; rtl
    }
  }

  macro value(variable index, variable separator, variable tiles, define stat) {
    if separator  {; lda.w #tiles.separator; ora #$3800; sta.w positions.{stat}+0; }
    if tiles >= 1 {; lda.w #tiles.{stat}+0;  ora #$3800; sta.w positions.{stat}+2; }
    if tiles >= 2 {; lda.w #tiles.{stat}+1;  ora #$3800; sta.w positions.{stat}+4; }
    if index == 0 {
      //HP
      lda points; tax
      lda.l dragons.stats.{stat},x; ldx #$0000
      cmp.w #10000; bcc hp1{#}; append.literal("^^^^"); bra hp2{#}; hp1{#}:
      append.integer_4(); hp2{#}:
    }
    if index == 1 {
      //MP
      lda points; tax
      lda.l dragons.stats.{stat},x; ldx #$0000; append.alignRight()
      cmp.w #1000; bcc mp1{#}; append.literal("^^^"); bra mp2{#}; mp1{#}:
      append.integer_3(); mp2{#}:
    }
    if index == 0 || index == 1 {
      lda #$0003; render.small.bpo4()
      index.to3x17(index)
      lda #$0003; write.bpp4()
      txa; add #$00a0; tax
      lda #$0003; render.small.bpo4.to.bpa4(); write.bpp4()
      txa; sub #$00a0; tay
    } else {
      lda stats; tax
      lda.l dragons.stats.{stat},x; and #$00ff
      mul(3); tay
      index.to3x17(index)
      lda #$0003; write.bpp4(lists.stats.bpo4)
      txa; add #$00a0; tax
      lda #$0003; write.bpp4(lists.stats.bpa4)
      txa; sub #$00a0; tay
    }
    lda #$0003; ldx.w #positions.{stat}+6&$3ff; tilemap.write()
  }

  //X => HP/MP index
  function values {
    constant statIndex = $0967

    variable(2, points)
    variable(2, stats)

    enter; ldb #$7e
    txa; sta points
    lda.w statIndex; and #$00ff
    sub #$0020; mul(32); sta stats
    value( 0,1,2,hp)
    value( 1,1,2,mp)
    value( 2,0,1,fire)
    value( 3,1,1,water)
    value( 4,1,1,thunder)
    value( 5,1,1,recovery)
    value( 6,1,1,poison)
    value( 7,0,2,strength)
    value( 8,1,2,vitality)
    value( 9,1,2,dexterity)
    value(10,1,2,intelligence)
    value(11,1,2,wisdom)
    value(12,0,2,aggression)
    value(13,1,2,affection)
    value(14,1,2,timidity)
    value(15,1,2,corruption)
    value(16,1,2,mutation)
    leave
    lda $3c; ora #$02; sta $3c  //request tilemap to VRAM transfer
    rtl
  }

  macro change(define stat) {
    lda.w changes.{stat}; and #$00ff
    beq finished{#}
    cmp #$0080; bcs decrease{#}  //8-bit signed value
  increase{#}:  //white -> yellow text
    lda.w positions.{stat}+ 6; add #$00a0; sta.w positions.{stat}+ 6
    lda.w positions.{stat}+ 8; add #$00a0; sta.w positions.{stat}+ 8
    lda.w positions.{stat}+10; add #$00a0; sta.w positions.{stat}+10
    bra finished{#}
  decrease{#}:  //white -> gray text
    lda.w positions.{stat}+ 6; ora #$1c00; sta.w positions.{stat}+ 6
    lda.w positions.{stat}+ 8; ora #$1c00; sta.w positions.{stat}+ 8
    lda.w positions.{stat}+10; ora #$1c00; sta.w positions.{stat}+10
  finished{#}:
  }

  //------
  //c1a2c8  pha
  //c1a2c9  jsr $a2de
  //------
  function changes {
    pha
    enter; ldb #$7e
    change(hp)
    change(mp)
    change(strength)
    change(vitality)
    change(dexterity)
    change(intelligence)
    change(fire)
    change(water)
    change(thunder)
    change(recovery)
    change(poison)
    change(corruption)
    change(timidity)
    change(wisdom)
    change(aggression)
    change(mutation)
    change(affection)
    leave
    lda $3c; ora #$02; sta $3c  //request tilemap to VRAM transfer
    jml $c1a2cc
  }

  function feed {
    enter
    ldy.w #strings.bpo4.feed
    index.to9x16(0)
    lda #$0003; write.bpp4(lists.strings.bpo4)
    txa; ora #$3800
    sta $7e4c20; inc
    sta $7e4c22; inc
    sta $7e4c24
    leave; rtl
  }

  function exit {
    enter
    ldy.w #strings.bpo4.exit
    index.to9x16(1)
    lda #$0003; write.bpp4(lists.strings.bpo4)
    txa; ora #$3800
    sta $7e4ca0; inc
    sta $7e4ca2; inc
    sta $7e4ca4
    leave; rtl
  }
}

codeCursor = pc()

}
