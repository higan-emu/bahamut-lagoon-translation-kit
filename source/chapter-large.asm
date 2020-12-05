namespace chapter {

seek(codeCursor)

namespace renderLargeText {
  enqueue pc
  seek($da3b22); jsl main
  seek($da6eb5); jsl copy; rts
  seek($e87cdd); dw color(31,31,31), color( 0, 0, 0), color(31,31, 0)  //add yellow text color
  dequeue pc

  constant wramBuffer = $7ee2a6  //location where rendered tiledata is written to
  constant tileCount  =   $095f  //the number of tiles to be copied to VRAM
  constant lineNumber =   $0960  //usually 0-2, but can be 0-3
  constant gameMode   =     $41  //indicates which mode of the game is currently running
  constant buffer     =     $76  //the text string is rendered from [$76],y
  namespace gameMode {
    constant openingCredits = $04
  }

  variable(1024, text)    //memory to decode dialogue text to
  variable(2, character)  //the current decoded character being rendered
  variable(2, pixel)      //the current pixel offset being rendered to
  variable(2, pixels)     //the maximum number of pixels allowed on one line of text
  variable(2, style)      //the current style being used ($00 = normal, $60 = italic)
  variable(2, color)      //the current color being used ($00 = normal, $01 = yellow)

  //this routine is used by the debugger, which doesn't clear text between strings rendered
  function clear {
    enter; ldb #$7e
    ldx #$03c0
  -;txa; sub #$0010; tax
    stz $e2a0,x; stz $e2a2,x; stz $e2a4,x; stz $e2a6,x
    stz $e2a8,x; stz $e2aa,x; stz $e2ac,x; stz $e2ae,x
    bne -
    leave; rtl
  }

  //this routine renders one line of dialogue text per invocation
  //------
  //da3b22  lda [$76],y  ;load the next character
  //da3b24  cmp #$f0     ;test if it's a control code
  //------
  //Y => current string read position
  function main {
    //this hooks both in-game dialogue as well as the opening credits dialogue.
    //the opening credits uses a separate fixed-width font, and needs to be handled differently.
    lda.b gameMode; bit.b #gameMode.openingCredits; beq dialogue

  openingCredits:
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
      cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; iny; bra loop; +
      cmp.w #command.styleItalic; bne +; lda.w #$60; sta style; iny; bra loop; +
      cmp.w #command.colorNormal; bne +; lda.w #$00; sta color; iny; bra loop; +
      cmp.w #command.colorYellow; bne +; lda.w #$01; sta color; iny; bra loop; +
      cmp.w #command.alignLeft;   bne +; jsl align.left;   bra loop; +
      cmp.w #command.alignCenter; bne +; jsl align.center; bra loop; +
      cmp.w #command.alignRight;  bne +; jsl align.right;  bra loop; +
      cmp.w #command.alignSkip;   bne +; jsl align.skip;   bra loop; +
      iny; jmp loop
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
    lda #$0000; sta character; sta pixel; sta style; sta color
    lda.w #240; sta pixels

    //decode text for easier processing
    ldx #$0000
    loop: {
      lda [buffer],y; iny; and #$00ff
      cmp.w #command.name;     bne +; jsl name;     bra loop; +
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

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      iny; tya; add buffer+0; sta render.large.width.address+0
      lda.w #0; adc buffer+2; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      iny; tya; add buffer+0; sta render.large.width.address+0
      lda.w #0; adc buffer+2; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      iny; lda [buffer],y; iny; and #$00ff
      add pixel; sta pixel; rtl
    }
  }

  //A => encoded character
  function renderCharacter {
    phy; character.decode(); add style; pha

    //perform character kerning
    lda character; mul(176); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    //select the WRAM write location for the current character:
    //Y = lineNumber * 1024 + tileNumber * 32
    lda.w lineNumber; mul(1024); pha
    lda pixel; and #$00f8; asl #2; add $01,s; tay; pla

    //select the font read location for the current character:
    //X = (pixel & 7) * 8192 + character * 44
    lda pixel; and #$0007; mul(8192); pha
    lda character; mul(44); add $01,s; tax; pla

    //add the width of the current character to the pixel counter
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +
    lda pixels; sta pixel; ply; rtl
  +;sta pixel

    //draw all 11 lines of the current character
    lda color; jne yellow

    macro render(variable font) {
      macro line(variable n) {
        lda.l font+$00+n*2,x; ora.w wramBuffer+$00+n*2,y; sta.w wramBuffer+$00+n*2,y
        lda.l font+$16+n*2,x; ora.w wramBuffer+$20+n*2,y; sta.w wramBuffer+$20+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4)
      line(5); line(6); line(7); line(8); line(9); line(10)
      ply; rtl
    }

    normal:; render(largeFont.normal)
    yellow:; render(largeFont.yellow)
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

namespace endingCredits {
  enqueue pc
  seek($da7533); jsl main; rts
  dequeue pc

  constant source = $7ee000  //location of 1bpp tileset to read
  constant target = $7ee400  //location of 2bpp tileset to write

  //convert 1bpp font to 2bpp font with {x+1,y},{x,y+1,{x+1,y+1} shadow
  function main {
    enter; ldb #$7e
    sep #$20; ldx $10; ldy $12

    macro line(variable dl) {
      //tiles are stored following sprite alignment rules:
      //this means that the first line of the next tile starts 16 tiles further in RAM.
      variable d0 = dl*2
      variable d1 = dl*2+1
      variable d3 = dl<7 ? dl*2+3 : $101

      lda.w source+dl,x
      sta.w target+d0,y
      sta.w target+d3,y; lsr; pha
      ora.w target+d1,y; sta.w target+d1,y; pla
      ora.w target+d3,y; sta.w target+d3,y
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)

    //clear text and shadow overlap (erases palette color 3 from the tiledata)
    macro line(variable n) {
      lda.w target+n*2+0,y; eor #$ff; pha
      lda.w target+n*2+1,y; and $01,s
      sta.w target+n*2+1,y; pla
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)

    rep #$20
    lda $10; add #$0008; sta $10
    lda $12; add #$0010; sta $12
    leave; rtl
  }
}

codeCursor = pc()

}
