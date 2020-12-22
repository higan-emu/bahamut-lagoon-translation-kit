namespace debugger {

seek(codeCursor)

//triggered by holding player 1 select button during reset or event loading
//provides a 1-line text window to select an event to skip to
namespace eventSelection {
  enqueue pc
  seek($da59a1); jsl main
  dequeue pc

  constant eventNumber = $0310

  //------
  //da5979  phb
  //da597a  rep #$20
  //da597c  ldx #$59a9   ;source string address
  //da597f  ldy #$f800   ;target string address
  //da5982  lda #$000f   ;string length
  //da5985  mvn $7e=$da  ;transfer string
  //da5988  sep #$20
  //da598a  plb
  //da598b  lda $0310    ;load event#
  //da598e  sta $7ef808  ;write into string
  //------
  function main {
    enter
    jsl clear  //text isn't cleared between updates; do so manually
    lda.w eventNumber; and #$00ff
    ldx #$0000
    append.literal("Event Number: ")
    append.colorYellow()
    append.hex02()
    append.byte(command.wait)
    lda.w #render.text >> 0; sta $76
    lda.w #render.text >> 8; sta $77
    leave; rtl
  }

  //$7ee2a0 <= WRAM buffer
  function clear {
    enter; ldb #$7e
    ldx #$03c0
  -;txa; sub #$0010; tax
    stz $e2a0,x; stz $e2a2,x; stz $e2a4,x; stz $e2a6,x
    stz $e2a8,x; stz $e2aa,x; stz $e2ac,x; stz $e2ae,x
    bne -
    leave; rtl
  }
}

//triggered by pressing X in the chapter gameplay engine
//prints a 4-line text window of debug information
namespace tileInformation {
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
    lda coordinateX; and #$00ff; append.hex02(output); append.lineFeed(output)
    append.literal(output, "Y-coordinate: ")
    lda coordinateY; and #$00ff; append.hex02(output); append.lineFeed(output)
    append.literal(output, "Tile ID: ")
    lda tileID; append.hex04(output); append.lineFeed(output)
    append.literal(output, "Tile attributes: ")
    lda tileAttributes; append.hex04(output); append.wait(output)

    leave; rtl
  }
}

codeCursor = pc()

}
