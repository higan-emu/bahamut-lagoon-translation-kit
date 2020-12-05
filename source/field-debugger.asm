namespace debugger {

seek(codeCursor)

namespace write {
  //A => character count
  //X => target index
  function bpp2 {
    enter; vwait()
    ldb #$00; tay
    lda.w #render.buffer >>  0; sta $4302
    lda.w #render.buffer >> 16; sta $4304
    txa; mul(16); add #$8000; lsr; sta $2116
    tya; mul(32); sta $4305; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave; rtl
  }

  //A => character count
  //X => data index
  //Y => map index
  function map {
    enter; ldb #$7e
    and #$00ff
    pha; phx; phy; plx; pla; ply
    ora #$2e00  //palette #3
  -;sta $0000,x; inc
    sta $0040,x; inc
    inx #2; dey; bne -
  +;leave; rtl
  }
}

function bg3fix {
  php; sep #$20; pha
  lda #$00
  sta $7e01c7; sta $7e01c8
  sta $002111; sta $002111
  sta $002112; sta $002112
  pla; plp; rtl
}

namespace address {
  namespace header {
    constant data = $0030
    constant map  = $c404
  }
  namespace line1 {
    constant data = $0070
    constant map  = $c488
  }
  namespace line2 {
    constant data = $00b0
    constant map  = $c508
  }
  namespace line3 {
    constant data = $0100
    constant map  = $c588
  }
  namespace line4 {
    constant data = $0140
    constant map  = $c608
  }
}

//triggered at reset and when choosing "New Game"
namespace scenarioJump {
  enqueue pc
  seek($c0af88); jmp $afa8  //disable static text
  seek($c0afdf); jsl main; rts
  dequeue pc

  //A => chapter#
  function main {
    enter; jsl bg3fix

    pha
    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; render.large.bpp2()
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map;  jsl write.map

    pla
    ldx #$0000; append.colorYellow()
    append.literal("Jump to "); append.chapter()
    lda #$0020; render.large.bpp2()
    ldx.w #address.line1.data; jsl write.bpp2
    ldy.w #address.line1.map;  jsl write.map

    leave; rtl
  }
}

//triggered when choosing a chapter from the scenario jump menu.
//also triggered once defeated on battle.
namespace scenarioAction {
  enqueue pc
  seek($c0cf6a); jmp $cf7a  //disable static text
  seek($c0cf2c); jsl main; rts
  dequeue pc

  //A => chapter#
  function main {
    constant eventType  = $ba
    constant eventStart = 0
    constant eventEnd   = 1

    enter; jsl bg3fix

    pha
    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; render.large.bpp2()
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map;  jsl write.map

    lda.b eventType; and #$00ff
    cmp #$0000; jeq start
    cmp #$00ff; jeq end
    pla; leave; rtl

    start: {
      pla
      ldx #$0000; append.chapter()
      lda #$0020; render.large.bpp2()
      ldx.w #address.line1.data; jsl write.bpp2
      ldy.w #address.line1.map;  jsl write.map

      ldx #$0000; append.literal("B Button - Skip Event")
      lda #$0020; render.large.bpp2()
      ldx.w #address.line2.data; jsl write.bpp2
      ldy.w #address.line2.map;  jsl write.map

      ldx #$0000; append.literal("A Button - See Event")
      lda #$0020; render.large.bpp2()
      ldx.w #address.line3.data; jsl write.bpp2
      ldy.w #address.line3.map;  jsl write.map

      ldx #$0000; append.literal("Y Button - See Map Only")
      lda #$0020; render.large.bpp2()
      ldx.w #address.line4.data; jsl write.bpp2
      ldy.w #address.line4.map;  jsl write.map

      leave; rtl
    }

    end: {
      pla
      ldx #$0000; append.literal("Event "); append.hex02()
      lda #$0020; render.large.bpp2()
      ldx.w #address.line1.data; jsl write.bpp2
      ldy.w #address.line1.map;  jsl write.map

      ldx #$0000; append.literal("B Button - Skip Event")
      lda #$0020; render.large.bpp2()
      ldx.w #address.line2.data; jsl write.bpp2
      ldy.w #address.line2.map;  jsl write.map

      ldx #$0000; append.literal("A Button - See Event")
      lda #$0020; render.large.bpp2()
      ldx.w #address.line3.data; jsl write.bpp2
      ldy.w #address.line3.map;  jsl write.map

      leave; rtl
    }
  }
}

//triggered by pressing B on a blank tile on the battle field
namespace fieldMenu {
  enqueue pc
  seek($c0cf93); jsl main; jmp $cf9c
  dequeue pc

  function main {
    enter; jsl bg3fix

    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; render.large.bpp2()
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map;  jsl write.map

    ldx #$0000; append.literal("B Button - Return to Field")
    lda #$0020; render.large.bpp2()
    ldx.w #address.line1.data; jsl write.bpp2
    ldy.w #address.line1.map;  jsl write.map

    ldx #$0000; append.literal("A Button - Battle Test")
    lda #$0020; render.large.bpp2()
    ldx.w #address.line2.data; jsl write.bpp2
    ldy.w #address.line2.map;  jsl write.map

    ldx #$0000; append.literal("X Button - Event Test")
    lda #$0020; render.large.bpp2()
    ldx.w #address.line3.data; jsl write.bpp2
    ldy.w #address.line3.map;  jsl write.map

    leave; rtl
  }
}

//triggered by pressing X in the field test menu
namespace eventTestMenu {
  enqueue pc
  seek($c0cf48); jmp $cf51
  seek($c0ced6); jsl main; rts
  dequeue pc

  //A => selected entry
  function main {
    constant eventNumber = $7e0310
    constant unitNumber  = $7e0311

    variable(2, selected)

    enter; jsl bg3fix
    and #$0001; sta selected

    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; render.large.bpp2()
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map;  jsl write.map

    ldx #$0000; lda selected; bne +; append.colorYellow(); +
    lda.l eventNumber; and #$00ff
    append.literal("Event Number "); append.hex02()
    lda #$0020; render.large.bpp2()
    ldx.w #address.line1.data; jsl write.bpp2
    ldy.w #address.line1.map;  jsl write.map

    ldx #$0000; lda selected; beq +; append.colorYellow(); +
    lda.l unitNumber; and #$00ff
    append.literal("Unit Number "); append.alignSkip(9); append.hex02()
    lda #$0020; render.large.bpp2()
    ldx.w #address.line2.data; jsl write.bpp2
    ldy.w #address.line2.map;  jsl write.map

    leave; rtl
  }
}

codeCursor = pc()

}
