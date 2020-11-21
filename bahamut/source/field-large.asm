namespace field {

//memory address where text strings are written to for later rendering
constant output = $7e0720

seek(codeCursor)

namespace temp {
  enqueue pc
//  seek($e9fbe1); jsl hook; nop
  dequeue pc
  function hook {
    cpx #$ecec; bne +
    stp; +
    txy; iny; iny; ldx $06; rtl; +
  }
}

namespace renderLargeText {
  enqueue pc
  seek($c0d7fb); jml copy                  //hook to decode control codes prior to rendering
  seek($c07b2b); jml command               //parses control codes only used by multi-line windows
  seek($c00965); jml render                //renders characters and handles shared control codes
  seek($c0a41c); jsl convertTiledata; rts  //converts 2bpp tiledata to 4bpp for single-line windows
  seek($c009d2); rts; nop                  //disable 12x12 routine to copy character to WRAM
  seek($c09be5); and #$00ff; asl; nop #4   //convert 12x12 tile position to 8x12 tile position
  seek($c0e225); ldx #$2630                //starting tile + palette# 1 for multi-line dialogue text

  //palette 0: normal text palette (unchanged)
  //originally:  dw color(31,31,28), color(15,15,15), color( 3, 5, 5)
  seek($c6a042); dw color(31,31,28), color(15,15,15), color( 3, 5, 5)

  //palette 1: custom text palette (modified to support white+yellow text)
  //originally:  dw color(15,15,15), color( 9,10,10), color( 3, 4, 4)
  seek($c6a04a); dw color(31,31,31), color( 9,10,10), color(31,31, 0)
  dequeue pc

  constant buffer           = $7e0720  //text buffer
  constant wramBuffer       = $7ed000  //tiledata buffer
  constant characterLimit   = $7e011b  //max number of characters to render before DMA transfer
  constant characterIndex   = $7e011c  //current read index into buffer
  constant characterEncoded = $7e011e  //location where the current encoded character is stored
  constant drawCursor       = $7e01fa  //DMA starts transferring tiles from this coordinate

  variable(1024, text)     //memory to decode dialogue text to
  variable(2, index)       //the current index into the text string
  variable(2, font)        //the current font used for rendering (0=normal, 1=yellow)
  variable(2, character)   //the current decoded character being rendered
  variable(2, pixel)       //the current pixel offset being rendered to
  variable(2, lineNumber)  //the current line number being rendered to (0-2)
  variable(2, wramOffset)  //used to adjust vertical text centering for terrain windows

  //this routine originally decoded some control codes prior to the command hook
  //------
  //c0d7fb  cmp #$f0
  //c0d7fd  bcc $d87b
  //c0d7ff  cmp #$f4
  //c0d801  bcc $d873
  //c0d803  beq $d82a
  //c0d805  cmp #$f5
  //c0d807  beq $d835
  //c0d809  cmp #$f6
  //c0d80b  beq $d840
  //c0d80d  cmp #$f7
  //c0d80f  beq $d84b
  //c0d811  cmp #$f8
  //c0d813  beq $d856
  //c0d815  cmp #$f9
  //c0d817  beq $d81f
  //c0d819  cmp #$fa
  //c0d81b  beq $d86a
  //c0d81d  bra $d87b
  //------
  constant copy = $c0d87b  //copy control codes directly without decoding them

  //this hook is used to parse control codes used only by multi-line text boxes
  //------
  //c07b23  lda $fa
  //c07b25  cmp #$3d
  //c07b27  bne $7b29
  //c07b29  ldx $1c
  //c07b2b  lda $0720,x
  //c07b2e  cmp #$f9
  //c07b30  bcc $7b81
  //c07b32  beq $7b66
  //c07b34  cmp #$fa
  //c07b36  beq $7b67
  //c07b38  cmp #$fc
  //c07b3a  beq $7b75
  //c07b3c  cmp #$fd
  //c07b3e  beq $7b6d
  //c07b40  cmp #$fe
  //c07b42  bcc $7b29
  //c07b44  bne $7b92 => rts
  //------
  //c07b46  ...       => commandLineFeed
  //------
  //c07b6d  inc
  //c07b6f  stx $1c
  //c07b70  jsr $7b93  ;wait for a button press
  //------
  function command {
    cpx #$0000; bne +; jsl decode; +
    jsl read
    cmp.b #command.pause;      bne +; jsl pause;    jml $c07b7c; +
    cmp.b #command.wait;       bne +; jsl wait;     jml $c07b70; +
    cmp.b #command.lineFeed;   bne +; jsl lineFeed; jml $c07b46; +
    cmp.b #command.terminal;   bne +; jsl terminal; jml $c07b92; +
    jml $c07b81
  }

  //line wrapping was based on 12x12 tile widths; update to handle 8x12 tile widths
  //------
  //c07b46  lda $fa
  //c07b48  cmp #$28
  //c07b4a  beq $7b61
  //c07b4c  bcs $7b58
  //c07b4e  cmp #$14
  //c07b50  beq $7b61
  //c07b52  bcs $7b5d
  //c07b54  lda #$14
  //c07b56  bra $7b5f
  //c07b58  phx
  //c07b59  jsr $9b98
  //c07b5c  plx
  //c07b5d  lda #$28
  //c07b5f  sta $fa
  //c07b61  inc
  //c07b62  stx $1c
  //c07b64  bra $7b23
  //------
  namespace commandLineFeed {
    enqueue pc
    seek($c07b46); {
      //when rendering more than three lines of text:
      //call $c09b98 to scroll the textbox up one line,
      //and set the line number back to the third line.
      lda lineNumber; cmp #$03; bcc +
      dec; sta lineNumber
      phx; jsr $9b98; plx; +
      jmp $7b29
      fill $c07b66-pc(),$ea  //nop
    }
    dequeue pc
  }

  function decode {
    enter; ldb #$7e
    redirection.disable()
    lda #$0000; tax; tay
    sta index
    loop: {
      jsl read
      cmp.w #command.name; bne +; jsl name; bra loop; +
      cmp.w #command.redirect; bne +; jsl redirect; bra loop; +
      sta text,x; inx
      cmp.w #command.terminal; beq +
      bra loop; +
      sep #$20; inc $1c
      lda.b #command.redirect; sta.w buffer+0
      lda.b #command.terminal; sta.w buffer+1
      leave; rtl
    }

    function read {
      lda redirection.enabled; beq +
      redirection.read(); redirection.increment(); rtl
    +;lda.w buffer,y; iny; and #$00ff; rtl
    }

    function name {
      jsl read
      append.name(text); rtl
    }

    function redirect {
      lda.w buffer,y; iny; sta redirection.address+0
      lda.w buffer,y; iny; sta redirection.address+1
      lda.w buffer,y; iny; sta redirection.address+2
      redirection.enable()
      rtl
    }
  }

  //A <= encoded character
  //X <= read index
  function read {
    php; rep #$30
    lda buffer; and #$00ff
    cmp.w #command.redirect; bne +
    lda index; tax
    lda text,x; and #$00ff; plp; rtl
  +;ldx $1c; lda buffer,x; and #$00ff; plp; rtl
  }

  //X <= read index
  function increment {
    php; rep #$30; pha
    lda buffer; and #$00ff
    cmp.w #command.redirect; bne +
    lda index; inc; sta index; tax; pla; plp; rtl
  +;inc $1c; ldx $1c; pla; plp; rtl
  }

  function pause {
    jsl increment
    jsl read
    jsl increment
    rtl
  }

  function wait {
    jsl increment
    rtl
  }

  function lineFeed {
    jsl increment
    php; rep #$20; pha
    lda #$0000; sta character; sta pixel
    lda lineNumber; inc; sta lineNumber
    pla; plp; rtl
  }

  function terminal {
    redirection.disable()
    rtl
  }

  //this hook is used by both multi-line and single-line textboxes
  //------
  //c00965  lda $0720,x
  //c00968  sta $1e
  //------
  function render {
    jsl read; sta $1e
    cpx #$0000;                 bne +; jsl initialize; +
    cmp.b #command.base;        jcc character
    cmp.b #command.offsetLines; bne +; lda wramOffset; add #$04; sta wramOffset; jsl increment; bra render; +
    cmp.b #command.fontNormal;  bne +; jsl font.normal; bra render; +
    cmp.b #command.fontYellow;  bne +; jsl font.yellow; bra render; +
    cmp.b #command.alignCenter; bne +; jsl align.center; bra render; +
    cmp.b #command.alignRight;  bne +; jsl align.right; bra render; +
    cmp.b #command.lineFeed;    bcc +; jml $c0099b; +
    cmp.b #command.pause;       bne +; jsl increment; jsl increment; bra render; +
  unsupportedCommand:
    jsl increment
    bra render
  character:
    jsl renderCharacter
    jsl increment
    //multi-line windows render one character at a time
    //single-line windows render the entire line at once
    lda.b characterLimit; cmp #$01; bne render
    jml $c009bf
  }

  function initialize {
    enter; ldb #$7e
    lda #$0000; sta font; sta character; sta pixel; sta lineNumber
    lda.w #wramBuffer+4; sta wramOffset

    //descriptions do not clear the RAM tiledata region; so do this manually here
    phx; ldx #$03c0
  -;dex #2; stz $d000,x; bne -
  +;plx

    leave; rtl
  }

  namespace font {
    function normal {
      jsl increment
      lda #$00; sta font; rtl
    }

    function yellow {
      jsl increment
      lda #$01; sta font; rtl
    }
  }

  namespace align {
    function center {
      jsl increment
      php; rep #$30
      jsl width; pha
      lda.w #240; sub $01,s; lsr; sta pixel; pla
      plp; rtl
    }

    function right {
      jsl increment
      php; rep #$30
      jsl width; pha
      lda.w #192; sub $01,s; sta pixel; pla
      plp; rtl
    }

    function width {
      lda buffer; and #$00ff; cmp.w #command.redirect; beq +
      lda.b characterIndex; and #$00ff
      add.w #buffer >>  0; sta render.large.width.address+0; lda #$0000
      adc.w #buffer >> 16; sta render.large.width.address+2
      jsl render.large.width; rtl

    +;lda index
      add.w #text >>  0; sta render.large.width.address+0; lda #$0000
      adc.w #text >> 16; sta render.large.width.address+2
      jsl render.large.width; rtl
    }
  }

  //renders one character into the WRAM buffer
  //A => encoded character
  function renderCharacter {
    enter; ldb #$7e
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    //drawCursor points at an x,y tile coordinate.
    //the game engine will transfer 24x16 pixels from wramBuffer[drawCursor] to VRAM.
    //renderText draws one character at a time, so point it at the current drawing location here.
    //drawCursor = lineNumber * 30 + tileNumber
    lda lineNumber; and #$0003; mul(30); pha
    lda pixel; div(8); add $01,s; sta $01,s; pla
    sep #$20; sta.b drawCursor; rep #$20

    //target = wramOffset + lineNumber * 0x3c0 + (pixel / 8) * 32
    lda lineNumber; mul($3c0); pha
    lda pixel; and #$00f8; asl #2; add $01,s
    add wramOffset; tay; pla

    //source = font + (pixel % 8) * 0x1800 + character * 48
    lda pixel; and #$0007; mul($1800); pha
    lda character; mul(48); add $01,s; tax; pla

    //increment pixel by the width of the current character
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; sta pixel

    //transfer 12 character lines to the wramBuffer
    lda font; jeq renderNormal; jmp renderYellow

    renderNormal: {
      macro line(variable n) {
        lda.l largeFont.normal+$00+n*2,x; ora.w $0000+n*2,y; sta.w $0000+n*2,y
        lda.l largeFont.normal+$18+n*2,x; ora.w $0020+n*2,y; sta.w $0020+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5)
      line(6); line(7); line(8); line(9);line(10);line(11)
      leave; rtl
    }

    renderYellow: {
      macro line(variable n) {
        lda.l largeFont.yellow+$00+n*2,x; ora.w $0000+n*2,y; sta.w $0000+n*2,y
        lda.l largeFont.yellow+$18+n*2,x; ora.w $0020+n*2,y; sta.w $0020+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5)
      line(6); line(7); line(8); line(9);line(10);line(11)
      leave; rtl
    }
  }

  //this function converts rendered tiledata from 2bpp (at $7e:d000+) to 4bpp (at $7e:e000+)
  //at the same time, this function performs color conversion on the tile data:
  //0 => 4
  //1 => 1
  //2 => 6
  //------
  //c0a41c  jsr $a426  ;this draws a text shadow one pixel to the right of the text color
  //c0a41f  jsr $a522  ;this converts the 2bpp tiledata to 4bpp
  //c0a422  jsr $a4e7  ;this performs color conversion of the tiledata
  //c0ar25  rts
  //------
  function convertTiledata {
    constant source = $7ed000
    constant target = $7ee000
    variable(2, tiles)

    enter; ldb #$7e
    lda #$0030; sta tiles
    ldx #$0000; txy

    tile: {
      sep #$20
      macro line(variable n) {
        lda.w source+$00+n*2,y; sta.w target+$00+n*2,x
        ora.w source+$01+n*2,y; eor #$ff
        ora.w source+$01+n*2,y; sta.w target+$10+n*2,x
        lda.w source+$01+n*2,y; sta.w target+$01+n*2,x
        stz.w target+$11+n*2,x
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
      rep #$20
      tya; add #$0010; tay
      txa; add #$0020; tax
      lda tiles; dec; sta tiles
      jne tile
    }

    leave; rtl
  }
}

//these hooks fix the color math exclusion window right positions:
//the original game had these one pixel too long, resulting in one vertical line
//of the map behind the windows being erroneously color math exempt.
namespace windowMaskFixes {
  enqueue pc
  seek($c0ca8a); lda #$e7  //fixes the single-line dialogue font window
  seek($c0a9f9); jsl hook  //fixes the unit window
  dequeue pc

  function hook {
    dec; sta $7e7b1b; rtl
  }
}

codeCursor = pc()

}
