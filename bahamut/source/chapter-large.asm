namespace chapter {

seek(codeCursor)

namespace renderLargeText {
  enqueue pc
  seek($da3b22); jsl main
  seek($da6eb5); jsl copy; rts
  //originally:  dw color(31,31,31), color( 0, 0, 0), color(31,31,31)  //adds yellow text color
  seek($e87cdd); dw color(31,31,31), color( 0, 0, 0), color(31,31, 0)  //text palette
  dequeue pc

  constant tileCount  = $7e095f  //the number of tiles to be copied to VRAM
  constant lineNumber = $7e0960  //usually 0-2, but can be 0-3
  constant wramBuffer = $7ee2a4  //location where rendered tiledata is written to
  constant gameMode   =     $41  //indicates which mode of the game is currently running
  constant buffer     =     $76  //the text string is rendered from [$76],y
  namespace gameMode {
    constant credits = $04
  }

  variable(1024, text)    //memory to decode dialogue text to
  variable(2, character)  //the current decoded character being rendered
  variable(2, pixel)      //the current pixel offset being rendered to
  variable(2, font)       //the current font being used (0=normal, 1=yellow)

  //this routine renders one line of dialogue text per invocation
  //Y = current string read position
  //------
  //da3b22  lda [$76],y  ;load the next character
  //da3b24  cmp #$f0     ;test if it's a control code
  //------
  function main {
    //this hooks both in-game dialogue as well as the opening credits dialogue.
    //the opening credits uses a separate fixed-width font, and needs to be handled differently.
    lda.b gameMode; bit.b #gameMode.credits; beq dialogue

  credits:
    lda [buffer],y
    cmp.b #command.wait; bcc +; jsl shadow; +
    cmp.b #command.base; rtl

  dialogue:
    phb; php; rep #$30; phx
    ldb #$7e

    //detect the first character in a textbox rendered to initialize state
    cpy #$0000; bne +; jsl initialize; +

    loop: {
      lda [buffer],y; and #$00ff
      cmp.w #command.base;        bcs +; jsl renderCharacter; iny; bra loop; +
      cmp.w #command.pause;       bcc +; bra return; +
      cmp.w #command.fontNormal;  bne +; lda #$0000; sta font; iny; bra loop; +
      cmp.w #command.fontYellow;  bne +; lda #$0001; sta font; iny; bra loop; +
      cmp.w #command.alignCenter; bne +; jsl alignCenter; bra loop; +
      cmp.w #command.alignRight;  bne +; jsl alignRight; bra loop; +
      cmp.w #command.skipPixels;  bne +; jsl skipPixels; bra loop; +
      iny; bra loop
    }

  return:
    //store the number of tiles rendered so the game will transfer them all to VRAM
    pha; lda pixel; add #$0007; div(8)
    sep #$20; sta.w tileCount; rep #$20
    pla; cmp.w #command.lineFeed; bne +; pha; lda #$0000; sta character; sta pixel; pla; +
    plx; plp; plb
    sec; rtl
  }

  function initialize {
    lda #$0000; sta character; sta pixel; sta font

    //decode text for easier processing
    ldx #$0000
    loop: {
      lda [buffer],y; iny; and #$00ff
      cmp.w #command.name;     bne +; jsl name; bra loop; +
      cmp.w #command.redirect; bne +; jsl redirect; bra loop; +
      sta text,x; inx
      cmp.w #command.wait;     beq +
      cmp.w #command.terminal; beq +
      bra loop; +
    }

    //redirect text to decoded copy
    lda.w #text >> 0; sta buffer+0
    lda.w #text >> 8; sta buffer+1
    ldy #$0000; rtl
  }

  function name {
    lda [buffer],y; iny; and #$00ff
    append.name(text); rtl
  }

  function redirect {
    lda [buffer],y; iny; sta redirection.address+0
    lda [buffer],y; iny; sta redirection.address+1
    lda [buffer],y; iny; sta redirection.address+2
    redirection.enable()
    lda redirection.address+0; sta buffer+0
    lda redirection.address+1; sta buffer+1
    redirection.disable()
    ldy #$0000; rtl
  }

  function alignCenter {
    iny; tya; add buffer+0; sta render.large.width.address+0
    lda.w #0; adc buffer+2; sta render.large.width.address+2
    jsl render.large.width; pha
    lda.w #240; sub $01,s; lsr; sta pixel; pla
    rtl
  }

  function alignRight {
    iny; tya; add buffer+0; sta render.large.width.address+0
    lda.w #0; adc buffer+2; sta render.large.width.address+2
    jsl render.large.width; pha
    lda.w #240; sub $01,s; sta pixel; pla
    rtl
  }

  function skipPixels {
    iny; lda [buffer],y; and #$00ff
    add pixel; sta pixel
    iny; rtl
  }

  //A => encoded character
  function renderCharacter {
    phy; character.decode(); pha

    //perform character kerning
    lda character; xba; lsr; ora $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; and #$00ff; sub $01,s; sta pixel; pla; pla
    sta character

    //select the WRAM write location for the current character:
    //Y = lineNumber * 1024 + tileNumber * 32
    lda.w lineNumber; mul(1024); pha
    lda pixel; and #$00f8; asl #2; add $01,s; tay; pla

    //select the font read location for the current character:
    //X = (pixel & 7) * 0x1800 + character * 48
    lda pixel; and #$0007; mul($1800); pha
    lda character; mul(48); add $01,s; tax; pla

    //add the width of the current character to the pixel counter
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; sta pixel

    //draw all 12 lines of the current character
    lda font; jne tileYellow

    tileNormal: {
      macro line(variable n) {
        lda.l largeFont.normal+$00+n*2,x; ora.w wramBuffer+$00+n*2,y; sta.w wramBuffer+$00+n*2,y
        lda.l largeFont.normal+$18+n*2,x; ora.w wramBuffer+$20+n*2,y; sta.w wramBuffer+$20+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5)
      line(6); line(7); line(8); line(9);line(10);line(11)
      ply; rtl
    }

    tileYellow: {
      macro line(variable n) {
        lda largeFont.yellow+$00+n*2,x; ora.w wramBuffer+$00+n*2,y; sta.w wramBuffer+$00+n*2,y
        lda largeFont.yellow+$18+n*2,x; ora.w wramBuffer+$20+n*2,y; sta.w wramBuffer+$20+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5)
      line(6); line(7); line(8); line(9);line(10);line(11)
      ply; rtl
    }
  }

  //this routine is used only by the credits:
  //this routine originally converted the 1bpp tile to a 2bpp tile, and added a shadow to {x+1,y}
  //this modified routine converts the tile to 2bpp, but does not apply any shadow yet.
  function copy {
    phb; ldb #$7e
    macro line(variable n) {
      lda.w $0947+n,y; sta.w $e280+n*2,x; stz.w $e281+n*2,x
      lda.w $094f+n,y; sta.w $e290+n*2,x; stz.w $e291+n*2,x
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    rep #$20; txa; add #$0010; tax; sep #$20
    plb; rtl
  }

  //this routine is used only by the credits:
  //once a line has finished rendering completely, the shadow is applied all at once.
  //this works in practice as the credits display all of the text at once, not letter-by-letter.
  function shadow {
    variable(2, index)

    enter; ldb #$7e

    //first, add the shadow as color 2
    lda #$0000; sta index
    include: {
      lda.w lineNumber; and #$0003; mul(1024); pha
      lda index; mul(32); add $01,s; tax; pla; sep #$20
      macro line(variable n) {
        if n < 15 {
          //add shadow to {x+1,y}, {x,y+1}, {x+1,y+1}
          lda.w $e280+n*2,x; pha; lsr
          ora.w $e281+n*2,x; sta.w $e281+n*2,x; pla; pha
          ora.w $e283+n*2,x; sta.w $e283+n*2,x; pla; pha; lsr
          ora.w $e283+n*2,x; sta.w $e283+n*2,x; pla; xba; lsr; and #$80; pha
          ora.w $e2a1+n*2,x; sta.w $e2a1+n*2,x; pla
          ora.w $e2a3+n*2,x; sta.w $e2a3+n*2,x
        } else {
          //add shadow to {x+1,y}; handled specially so as to not write out-of-bounds
          lda.w $e280+n*2,x; pha; lsr
          ora.w $e281+n*2,x; sta.w $e281+n*2,x; pla; xba; lsr; and #$80
          ora.w $e2a1+n*2,x; sta.w $e2a1+n*2,x
        }
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
      line(8); line(9);line(10);line(11);line(12);line(13);line(14);line(15)
      rep #$20; lda index; inc; sta index
      cmp #$001f; jcc include  //stop a tile early so {x+1} shadow doesn't write out-of-bounds
    }

    //next, remove the shadow when it overlaps the text to prevent emitting color 3
    lda #$0000; sta index
    exclude: {
      lda.w lineNumber; and #$0003; mul(1024); pha
      lda index; mul(32); add $01,s; tax; pla; sep #$20
      macro line(variable n) {
        lda.w $e280+n*2,x; eor #$ff; pha
        lda.w $e281+n*2,x; and $01,s
        sta.w $e281+n*2,x; pla
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
      line(8); line(9);line(10);line(11);line(12);line(13);line(14);line(15)
      rep #$20; lda index; inc; sta index
      cmp #$0020; jcc exclude
    }

    leave; rtl
  }
}

codeCursor = pc()

}
