namespace chapter {

seek(codeCursor)

namespace renderLargeText {
  enqueue pc
  seek($da3b22); jsl main
  dequeue pc

  constant wramBuffer  = $7ee2a6  //location where rendered tiledata is written to
  constant eventNumber =   $0310  //the current event number that is running
  constant tileCount   =   $095f  //the number of tiles to be copied to VRAM
  constant lineNumber  =   $0960  //usually 0-2, but can be 0-3
  constant buffer      =     $76  //the text string is rendered from [$76],y

  variable(1024, text)    //memory to decode dialogue text to
  variable(2, character)  //the current decoded character being rendered
  variable(2, pixel)      //the current pixel offset being rendered to
  variable(2, pixels)     //the maximum number of pixels allowed on one line of text
  variable(2, style)      //the current style being used ($00 = normal, $60 = italic)
  variable(2, color)      //the current color being used ($00 = normal, $01 = yellow)

  //this routine renders one line of dialogue text per invocation
  //------
  //da3b22  lda [$76],y  ;load the next character
  //da3b24  cmp #$f0     ;test if it's a control code
  //------
  //Y => current string read position
  function main {
    //the opening credits uses a different routine for pre-rendered text with a different font
    lda.w eventNumber; cmp #$fa; bne +        //$fa is the opening credits event#
    lda $78; cmp.b #render.text >> 16; beq +  //ensure this isn't the debugger event# string
    jml openingCredits.main; +

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
    append.name(text)

    //determine if the name is used as a singular possessive
    lda [buffer],y; and #$00ff; cmp.w #'\''; beq +; rtl; +; iny
    append.byte(text, '\'')
    lda [buffer],y; and #$00ff; cmp.w #'s';  beq +; rtl; +; iny

    //omit trailing s if the name ends with an s already
    lda text-2,x; and #$00ff; cmp.w #'s'; beq +
    append.byte(text, 's')
  +;rtl
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

    //perform font kerning
    lda character; mul(180); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    //select the WRAM write location for the current character:
    //Y <= lineNumber * 1024 + tileNumber * 32
    lda.w lineNumber; mul(1024); pha
    lda pixel; and #$00f8; asl #2; add $01,s; tay; pla

    //select the font read location for the current character:
    //X <= (pixel & 7) * 8192 + character * 44
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
}

codeCursor = pc()

}
