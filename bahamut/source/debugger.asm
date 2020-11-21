namespace debugger {

seek(codeCursor)

namespace write {
  //A = character count
  //X = target index
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

  //A (lower) = character count
  //A (upper) = tile attributes
  //X = data index
  //Y = map index
  function map {
    variable(2, attributes)

    enter; ldb #$7e
    pha; and #$ff00; sta attributes; pla; and #$00ff
    pha; phx; phy; plx; pla; ply
    ora attributes
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

  //A = chapter#
  function main {
    enter; jsl bg3fix

    pha
    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map; ora #$2200; jsl write.map

    pla
    ldx #$0000; append.literal("Jump to "); append.chapter()
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.line1.data; jsl write.bpp2
    ldy.w #address.line1.map; ora #$2e00; jsl write.map

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

  //A = chapter#
  function main {
    constant eventType  = $ba
    constant eventStart = 0
    constant eventEnd   = 1

    enter; jsl bg3fix

    pha
    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map; ora #$2200; jsl write.map

    lda.b eventType; and #$00ff
    cmp #$0000; jeq start
    cmp #$00ff; jeq end
    pla; leave; rtl

    start: {
      pla
      ldx #$0000; append.chapter()
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line1.data; jsl write.bpp2
      ldy.w #address.line1.map; ora #$2200; jsl write.map

      ldx #$0000; append.literal("B Button - Skip Event")
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line2.data; jsl write.bpp2
      ldy.w #address.line2.map; ora #$2200; jsl write.map

      ldx #$0000; append.literal("A Button - See Event")
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line3.data; jsl write.bpp2
      ldy.w #address.line3.map; ora #$2200; jsl write.map

      ldx #$0000; append.literal("Y Button - See Map Only")
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line4.data; jsl write.bpp2
      ldy.w #address.line4.map; ora #$2200; jsl write.map

      leave; rtl
    }

    end: {
      pla
      ldx #$0000; append.literal("Event "); append.integer3()
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line1.data; jsl write.bpp2
      ldy.w #address.line1.map; ora #$2200; jsl write.map

      ldx #$0000; append.literal("B Button - Skip Event")
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line2.data; jsl write.bpp2
      ldy.w #address.line2.map; ora #$2200; jsl write.map

      ldx #$0000; append.literal("A Button - See Event")
      lda #$0020; jsl render.large.bpp2
      ldx.w #address.line3.data; jsl write.bpp2
      ldy.w #address.line3.map; ora #$2200; jsl write.map

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
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map; ora #$2200; jsl write.map

    ldx #$0000; append.literal("B Button - Return to Field")
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.line1.data; jsl write.bpp2
    ldy.w #address.line1.map; ora #$2200; jsl write.map

    ldx #$0000; append.literal("A Button - Battle Test")
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.line2.data; jsl write.bpp2
    ldy.w #address.line2.map; ora #$2200; jsl write.map

    ldx #$0000; append.literal("X Button - Event Test")
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.line3.data; jsl write.bpp2
    ldy.w #address.line3.map; ora #$2200; jsl write.map

    leave; rtl
  }
}

//triggered by pressing X in the field test menu
namespace eventTestMenu {
  enqueue pc
  seek($c0cf48); jmp $cf51
  seek($c0ced6); jsl main; rts
  dequeue pc

  //A = selected entry
  function main {
    define eventNumber = $0310
    define unitNumber  = $0311

    variable(2, eventAttributes)
    variable(2, unitAttributes)

    enter; jsl bg3fix

    and #$0001
    cmp #$0000; bne +; pha; lda #$2e00; sta eventAttributes; lda #$2200; sta unitAttributes; pla; +
    cmp #$0001; bne +; pha; lda #$2200; sta eventAttributes; lda #$2e00; sta unitAttributes; pla; +

    ldx #$0000; append.literal("Bahamut Lagoon Debugger")
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.header.data; jsl write.bpp2
    ldy.w #address.header.map; ora #$2200; jsl write.map

    lda {eventNumber}; and #$00ff; ldx #$0000; append.literal("Event Number "); append.integer3()
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.line1.data; jsl write.bpp2
    ldy.w #address.line1.map; ora eventAttributes; jsl write.map

    lda {unitNumber}; and #$00ff; ldx #$0000; append.literal("Unit Number "); append.integer3()
    lda #$0020; jsl render.large.bpp2
    ldx.w #address.line2.data; jsl write.bpp2
    ldy.w #address.line2.map; ora unitAttributes; jsl write.map

    leave; rtl
  }
}

//triggered by pressing X in the chapter gameplay engine
//prints a 4-line text window of debug information
namespace chapter {
  enqueue pc
  seek($da5a87); jsl main; jmp $5b25
  dequeue pc

  function main {
    //the original game constructs the debug string here.
    //the original string is 80 bytes in length, and that length should not be exceeded.
    //the new string is 71 bytes in length currently.
    constant output = $7ef800

    variable(2, coordinateX)     //coordinates of where Byuu is currently standing
    variable(2, coordinateY)
    variable(2, tileID)          //the tile graphic shown (sky, ground, etc)
    variable(2, tileAttributes)  //properties of the tile (not affected by the tileID)
    //known tile attributes:
    //  d9: when 1, the tile cannot be walked on
    // d10: when 1, the tile cannot be walked on

    enter

    //copy the original game logic to look up the values
    lda $0320; and #$00ff; mul(16); tax
    lda $0704,x; add $037c; div(16)
    sta coordinateX
    lda $0702,x; add $037e; div(16)
    sta coordinateY; and #$003f; mul(128); pha
    lda coordinateX; and #$003f; mul(2); add $01,s; sta $01,s; plx
    lda $7e6800,x; sta tileID
    lda $7e8800,x; sta tileAttributes

    ldx #$0000; txy
    append.literal(output, "X-coordinate: ")
    lda coordinateX; and #$00ff; append.hex02(output); append.literal(output, "\n")
    append.literal(output, "Y-coordinate: ")
    lda coordinateY; and #$00ff; append.hex02(output); append.literal(output, "\n")
    append.literal(output, "Tile ID: ")
    lda tileID; append.hex04(output); append.literal(output, "\n")
    append.literal(output, "Tile attributes: ")
    lda tileAttributes; append.hex04(output); append.string(output, terminal)
    leave; rtl

    //this window expects a $fd terminator; but append() only writes $ff
    terminal:; db $fd,$ff
  }
}

codeCursor = pc()

}
