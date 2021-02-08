namespace field {

//memory address where text strings are written to for later rendering
constant output = $0720

seek(codeCursor)

namespace renderLargeText {
  enqueue pc
  seek($c0d7fb); jml copy                  //hook to decode control codes prior to rendering
  seek($c07b2b); jml command               //parses control codes only used by multi-line windows
  seek($c00965); jml render                //renders characters and handles shared control codes
  seek($c0a41c); jsl convertTiledata; rts  //converts 2bpp tiledata to 4bpp for single-line windows
  seek($c009d2); rts; nop                  //disable 12x12 routine to copy character to WRAM
  seek($c09be5); and #$00ff; asl; nop #4   //convert 12x12 tile position to 8x12 tile position
  seek($c0e225); ldx #$2e30                //starting tile + palette# 3 for multi-line dialogue text
  dequeue pc

  constant wramBuffer       = $7ed000  //tiledata buffer
  constant buffer           =   $0720  //text buffer
  constant characterLimit   =     $1b  //max number of characters to render before DMA transfer
  constant characterIndex   =     $1c  //current read index into buffer
  constant characterEncoded =     $1e  //location where the current encoded character is stored
  constant drawCursor       =     $fa  //DMA starts transferring tiles from this coordinate

  variable(1024, text)     //memory to decode dialogue text to
  variable(2, index)       //the current index into the text string
  variable(2, lineNumber)  //the current line number being rendered to (0-2)
  variable(2, wramOffset)  //used to adjust vertical text centering for terrain windows
  variable(2, character)   //the current decoded character being rendered
  variable(2, pixel)       //the current pixel offset being rendered to
  variable(2, pixels)      //the maximum number of pixels that can be rendered for this string
  variable(2, style)       //the current style used for rendering ($00 = normal, $60 = italic)
  variable(2, color)       //the current color used for rendering ($00 = normal, $01 = yellow)

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
    cmp.b #command.pause;    bne +; jsl pause;    jml $c07b7c; +
    cmp.b #command.wait;     bne +; jsl wait;     jml $c07b70; +
    cmp.b #command.lineFeed; bne +; jsl lineFeed; jml $c07b46; +
    cmp.b #command.terminal; bne +; jsl terminal; jml $c07b92; +
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
      nop #11; assert(pc() == $c07b66)
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
      cmp.w #command.name;     bne +; jsl name;     bra loop; +
      cmp.w #command.redirect; bne +; jsl redirect; bra loop; +
      sta text,x; inx
      cmp.w #command.terminal; beq +;               bra loop; +
      sep #$20; inc.b characterIndex
      lda.b #command.redirect; sta.w buffer+0
      lda.b #command.terminal; sta.w buffer+1
      leave; rtl
    }

    function name {
      jsl read
      append.name(text)

      //determine if the name is used as a singular possessive
      jsl peek; cmp.w #'\''; beq +; rtl; +
      jsl read; append.byte(text, '\'')
      jsl peek; cmp.w #'s';  beq +; rtl; +
      jsl read

      //omit trailing s if the name ends with an s already
      lda text-2,x; and #$00ff; cmp.w #'s'; beq +
      append.byte(text, 's')
    +;rtl
    }

    function redirect {
      lda.w buffer,y; iny; sta redirection.address+0
      lda.w buffer,y; iny; sta redirection.address+1
      lda.w buffer,y; iny; sta redirection.address+2
      redirection.enable(); rtl
    }

    function read {
      lda redirection.enabled; beq +
      redirection.read(); redirection.increment(); rtl
    +;lda.w buffer,y; iny; and #$00ff; rtl
    }

    function peek {
      lda redirection.enabled; beq +
      redirection.read(); rtl
    +;lda.w buffer,y; and #$00ff; rtl
    }
  }

  //A <= encoded character
  //X <= read index
  function read {
    php; rep #$30
    lda.w buffer; and #$00ff
    cmp.w #command.redirect; bne +
    lda index; tax
    lda text,x; and #$00ff; plp; rtl
  +;ldx.b characterIndex; lda.w buffer,x; and #$00ff; plp; rtl
  }

  //X <= read index
  function increment {
    php; rep #$30; pha
    lda.w buffer; and #$00ff
    cmp.w #command.redirect; bne +
    lda index; inc; sta index; tax; pla; plp; rtl
  +;inc.b characterIndex; ldx.b characterIndex; pla; plp; rtl
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
    jsl read
    sta.b characterEncoded
    cpx #$0000;                 bne +; jsl initialize; +
    cmp.b #command.base;        jcc character
    cmp.b #command.styleNormal; bne +; lda #$00; sta style; jsl increment; bra render; +
    cmp.b #command.styleItalic; bne +; lda #$60; sta style; jsl increment; bra render; +
    cmp.b #command.colorNormal; bne +; lda #$00; sta color; jsl increment; bra render; +
    cmp.b #command.colorYellow; bne +; lda #$01; sta color; jsl increment; bra render; +
    cmp.b #command.alignLeft;   bne +; jsl align.left;                     bra render; +
    cmp.b #command.alignCenter; bne +; jsl align.center;                   bra render; +
    cmp.b #command.alignRight;  bne +; jsl align.right;                    bra render; +
    cmp.b #command.alignSkip;   bne +; jsl align.skip;                     bra render; +
    cmp.b #command.lineFeed;    bcc +; jml $c0099b; +
    cmp.b #command.pause;       bne +; jsl increment; jsl increment;       jmp render; +
  unsupportedCommand:
    jsl increment
    jmp render
  character:
    jsl renderCharacter
    jsl increment
    //multi-line windows render one character at a time
    //single-line windows render the entire line at once
    lda.b characterLimit; cmp #$01; jne render
    jml $c009bf
  }

  function initialize {
    enter; ldb #$7e

    lda #$0000; sta lineNumber; sta character; sta pixel; sta style; sta color
    lda.w #wramBuffer+6; sta wramOffset

    //determine the number of pixels per scanline:
    //dialogue text is 240-pixels and renders one character at a time.
    //description windows are 192-pixels and render all characters at once.
    lda.w #192; sta pixels
    lda.b characterLimit; and #$00ff
    cmp #$0001; bne +; lda.w #240; sta pixels; +

    //determine if this is a terrain type string based on the function that called render.
    //if it is, offset the vertical position by two lines to center the text properly.
    lda $0c,s; cmp #$9c95; bne +; lda.w #wramBuffer+10; sta wramOffset; +

    //descriptions do not clear the RAM tiledata region; so do this manually here
    phx; ldx #$03c0
  -;txa; sub #$0010; tax
    stz $d000,x; stz $d002,x; stz $d004,x; stz $d006,x
    stz $d008,x; stz $d00a,x; stz $d00c,x; stz $d00e,x
    bne -
    plx; leave; rtl
  }

  namespace align {
    function left {
      jsl increment
      php; rep #$30
      lda.w #0; sta pixel
      plp; rtl
    }

    function center {
      jsl increment
      php; rep #$30
      jsl width; cmp pixels; bcc +; beq +; lda.w #0; sta pixel; plp; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; plp; rtl
    }

    function right {
      jsl increment
      php; rep #$30
      jsl width; cmp pixels; bcc +; beq +; lda.w #0; sta pixel; plp; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; plp; rtl
    }

    function skip {
      jsl increment
      jsl read
      jsl increment
      php; rep #$30
      and #$00ff; add pixel; sta pixel
      plp; rtl
    }

    function width {
      lda.w buffer; and #$00ff; cmp.w #command.redirect; beq +
      lda.b characterIndex; and #$00ff
      add.w #buffer >>  0; sta render.large.width.address+0; lda #$0000
      adc.w #buffer >> 16; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width; rtl

    +;lda index
      add.w #text >>  0; sta render.large.width.address+0; lda #$0000
      adc.w #text >> 16; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width; rtl
    }
  }

  //renders one character into the WRAM buffer
  //A => encoded character
  function renderCharacter {
    enter; ldb #$7e
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(180); add $01,s; tax
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

    //target <= wramOffset + lineNumber * 0x3c0 + (pixel / 8) * 32
    lda lineNumber; mul($3c0); pha
    lda pixel; and #$00f8; asl #2; add $01,s
    add wramOffset; tay; pla

    //source <= font + (pixel % 8) * 8192 + character * 44
    lda pixel; and #$0007; mul(8192); pha
    lda character; mul(44); add $01,s; tax; pla

    //increment pixel by the width of the current character
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +
    lda pixels; sta pixel; leave; rtl
  +;sta pixel

    //transfer 11 character lines to wramBuffer
    lda color; jne yellow

    macro render(variable font) {
      macro line(variable n) {
        lda.l font+$00+n*2,x; ora.w $0000+n*2,y; sta.w $0000+n*2,y
        lda.l font+$16+n*2,x; ora.w $0020+n*2,y; sta.w $0020+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4)
      line(5); line(6); line(7); line(8); line(9); line(10)
      leave; rtl
    }

    normal:; render(largeFont.normal)
    yellow:; render(largeFont.yellow)
  }

  //this function converts rendered tiledata from 2bpp (at $7e:d000+) to 4bpp (at $7e:e000+)
  //at the same time, this function performs color conversion on the tile data:
  //0 =>  4 (background)
  //1 => 13 (white)
  //2 => 14 (gray)
  //3 => 15 (yellow)
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
        lda.w source+$01+n*2,y; sta.w target+$01+n*2,x
        ora.w source+$00+n*2,y; sta.w target+$11+n*2,x
        lda.b #$ff; sta.w target+$10+n*2,x
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
