namespace render {

seek(codeCursor)

//input: a character-map encoded string, terminated by $ff
variable(256, text)

//output: the number of tiles generated after rendering text
variable(2, tiles)

//output: rendered tiledata is written to $32:6000-7fff (8KB)
constant buffer = $326000

//A => # of bytes to zero-fill in render.buffer (must be a multiple of tilesize; must not be 0)
//tilesize $10 => fully clear 2bpp or 4bpp tiles
//tilesize $20 => clear lower half of 4bpp tiles
macro clear(variable tilesize) {
  //DMA would certainly be faster than an unrolled loop here, but NMI uses DMA.
  //if we tried to use DMA here, it's possible NMI would trample on the registers.
loop{#}:
  sub.w #tilesize; tax
  stz buffer+$0,x; stz buffer+$2,x; stz buffer+$4,x; stz buffer+$6,x
  stz buffer+$8,x; stz buffer+$a,x; stz buffer+$c,x; stz buffer+$e,x
  bne loop{#}
}

namespace large {

//A => maximum number of tiles to render
function bpp2 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)
  variable(2, pixels)
  variable(2, style)
  variable(2, color)

  prologue: {
    enter; ldb #$32
    and #$001f; bne +; lda #$0020; +
    mul(8); sta pixels
    mul(4); render.clear($10)
    lda #$0000; sta index; sta character; sta pixel; sta style; sta color
  }

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra renderCharacter; +
    cmp.w #command.styleItalic; bne +; lda.w #$60; sta style; bra renderCharacter; +
    cmp.w #command.colorNormal; bne +; lda.w #$00; sta color; bra renderCharacter; +
    cmp.w #command.colorYellow; bne +; lda.w #$01; sta color; bra renderCharacter; +
    cmp.w #command.alignLeft;   bne +; jsl align.left;        bra renderCharacter; +
    cmp.w #command.alignCenter; bne +; jsl align.center;      bra renderCharacter; +
    cmp.w #command.alignRight;  bne +; jsl align.right;       bra renderCharacter; +
    cmp.w #command.alignSkip;   bne +; jsl align.skip;        bra renderCharacter; +
    cmp.w #command.break;       jcs epilogue
    jmp renderCharacter
  decode:
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(180); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(44); pha
    lda pixel; and #$0007; mul(8192)
    add $01,s; tax; pla

    lda pixel; and #$00f8; asl #2; tay

    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +; jmp epilogue; +
    sta pixel

    lda color; jne yellow

    macro render(variable font) {
      macro line(variable n) {
        lda.l font+$00+n*2,x; ora.w $6006+n*2,y; sta.w $6006+n*2,y
        lda.l font+$16+n*2,x; ora.w $6026+n*2,y; sta.w $6026+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4)
      line(5); line(6); line(7); line(8); line(9); line(10)
      jmp renderCharacter
    }

    normal:; render(largeFont.normal)
    yellow:; render(largeFont.yellow)
  }

  epilogue: {
    lda pixel; add #$0007; div(8); sta tiles
    leave; rtl
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      lda index; tax
      inc; sta index
      lda text,x; and #$00ff
      add pixel; sta pixel; rtl
    }
  }
}
macro bpp2() {
  jsl render.large.bpp2
}

//A => maximum number of tiles to render
function bpp4 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)
  variable(2, pixels)
  variable(2, style)

  prologue: {
    enter; ldb #$32
    and #$001f; bne +; lda #$0020; +
    mul(8); sta pixels
    mul(8); render.clear($10)
    lda #$0000; sta index; sta character; sta pixel; sta style
  }

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra renderCharacter; +
    cmp.w #command.styleItalic; bne +; lda.w #$60; sta style; bra renderCharacter; +
    cmp.w #command.alignLeft;   bne +; jsl align.left;        bra renderCharacter; +
    cmp.w #command.alignCenter; bne +; jsl align.center;      bra renderCharacter; +
    cmp.w #command.alignRight;  bne +; jsl align.right;       bra renderCharacter; +
    cmp.w #command.alignSkip;   bne +; jsl align.skip;        bra renderCharacter; +
    cmp.w #command.break;       jcs epilogue
    bra renderCharacter
  decode:
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(180); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(44); pha
    lda pixel; and #$0007; mul(8192)
    add $01,s; tax; pla

    lda pixel; and #$00f8; asl #3; tay

    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +; jmp epilogue; +
    sta pixel

    macro upper(variable n) {
      lda.l largeFont.normal+$00+n*2,x; ora.w $6006+n*2,y; sta.w $6006+n*2,y
      lda.l largeFont.normal+$16+n*2,x; ora.w $6046+n*2,y; sta.w $6046+n*2,y
    }
    macro lower(variable n) {
      lda.l largeFont.normal+$0a+n*2,x; ora.w $6020+n*2,y; sta.w $6020+n*2,y
      lda.l largeFont.normal+$20+n*2,x; ora.w $6060+n*2,y; sta.w $6060+n*2,y
    }
    upper(0); upper(1); upper(2); upper(3); upper(4)
    lower(0); lower(1); lower(2); lower(3); lower(4); lower(5)
    jmp renderCharacter
  }

  epilogue: {
    lda pixel; add #$0007; div(8); sta tiles
    jsl convert
    leave; rtl
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      lda index; tax
      inc; sta index
      lda text,x; and #$00ff
      add pixel; sta pixel; rtl
    }
  }

  //0 => 4 (window background gradient palette index)
  //1 => 1 (text color)
  //2 => 6 (text shadow color)
  function convert {
    variable(2, tiles)

    lda pixels; div(4); sta tiles
    lda #$0000
    tile: {
      pha; mul(32); tax; sep #$20
      macro line(variable n) {
        lda.w $6000+n*2,x; ora.w $6001+n*2,x; eor #$ff
        ora.w $6001+n*2,x; sta.w $6010+n*2,x
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
      rep #$20; pla; inc
      cmp tiles; jcc tile
    }
    rtl
  }
}
macro bpp4() {
  jsl render.large.bpp4
}

//address => text starting location
//style => font style ($00 = normal, $60 = italic)
//A <= number of pixels required to render text
function width {
  variable(4, address)
  variable(2, style)
  variable(2, character)
  variable(2, pixel)

  prologue: {
    phb; php; rep #$30; phx; phy
    lda address+1; pha; plb; plb
    lda address+0; tax
    lda #$0000; sta character; sta pixel
  }

  loop: {
    lda $0000,x; and #$00ff; inx
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra loop; +
    cmp.w #command.styleItalic; bne +; lda.w #$60; sta style; bra loop; +
    cmp.w #command.alignSkip;   bne +; lda $0000,x; and #$00ff; inx; add pixel; sta pixel; bra loop; +
    cmp.w #command.pause;       bne +; inx; bra loop; +
    cmp.w #command.wait;        jcs epilogue
    bra loop
  decode:
    character.decode(); add style; phx; pha
    lda character; mul(180); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character; tax
    lda largeFont.widths,x; plx; and #$00ff
    add pixel; sta pixel
    jmp loop
  }

  epilogue: {
    lda pixel
    ply; plx; plp; plb; rtl
  }
}
macro width(variable source) {
  php; rep #$20
  lda.w #source >> 0; sta render.large.width.address+0
  lda.w #source >> 8; sta render.large.width.address+1
  lda.w #$00; sta render.large.width.style
  jsl render.large.width; plp
}
macro width() {
  render.large.width(render.text)
}

}

namespace small {

//A => maximum number of tiles to render
function bpp2 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)
  variable(2, pixels)
  variable(2, style)

  prologue: {
    enter; ldb #$32
    and #$001f; bne +; lda #$0020; +
    mul(8); sta pixels
    mul(2); render.clear($10)
    lda #$0000; sta index; sta character; sta pixel; sta style
  }

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra renderCharacter; +
    cmp.w #command.styleTiny;   bne +; lda.w #$60; sta style; bra renderCharacter; +
    cmp.w #command.alignLeft;   bne +; jsl align.left;        bra renderCharacter; +
    cmp.w #command.alignCenter; bne +; jsl align.center;      bra renderCharacter; +
    cmp.w #command.alignRight;  bne +; jsl align.right;       bra renderCharacter; +
    cmp.w #command.alignSkip;   bne +; jsl align.skip;        bra renderCharacter; +
    cmp.w #command.break;       jcs epilogue
    bra renderCharacter
  decode:
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(176); add $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(32); pha
    lda pixel; and #$0007; mul(5632)
    add $01,s; tax; pla
    lda pixel; and #$00f8; asl; tay

    phx; lda character; tax
    lda smallFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +; jmp epilogue; +
    sta pixel

    tile: {
      macro line(variable n) {
        lda.l smallFont.data+$00+n*2,x; ora.w $6000+n*2,y; sta.w $6000+n*2,y
        lda.l smallFont.data+$10+n*2,x; ora.w $6010+n*2,y; sta.w $6010+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    }
    jmp renderCharacter
  }

  epilogue: {
    lda pixel; add #$0007; div(8); sta tiles
    leave; rtl
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      lda index; tax
      inc; sta index
      lda text,x; and #$00ff
      add pixel; sta pixel; rtl
    }
  }
}
macro bpp2() {
  jsl render.small.bpp2
}

//A => maximum number of tiles to render
function bpp4 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)
  variable(2, pixels)
  variable(2, style)

  prologue: {
    enter; ldb #$32
    and #$001f; bne +; lda #$0020; +
    mul(8); sta pixels
    mul(4); render.clear($10)
    lda #$0000; sta index; sta character; sta pixel; sta style
  }

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra renderCharacter; +
    cmp.w #command.styleTiny;   bne +; lda.w #$60; sta style; bra renderCharacter; +
    cmp.w #command.alignLeft;   bne +; jsl align.left;        bra renderCharacter; +
    cmp.w #command.alignCenter; bne +; jsl align.center;      bra renderCharacter; +
    cmp.w #command.alignRight;  bne +; jsl align.right;       bra renderCharacter; +
    cmp.w #command.alignSkip;   bne +; jsl align.skip;        bra renderCharacter; +
    cmp.w #command.break;       jcs epilogue
    bra renderCharacter
  decode:
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(176); add $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(32); pha
    lda pixel; and #$0007; mul(5632)
    add $01,s; tax; pla
    lda pixel; and #$00f8; asl #2; tay

    phx; lda character; tax
    lda smallFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +; jmp epilogue; +
    sta pixel

    tile: {
      macro line(variable n) {
        lda.l smallFont.data+$00+n*2,x; ora.w $6000+n*2,y; sta.w $6000+n*2,y
        lda.l smallFont.data+$10+n*2,x; ora.w $6020+n*2,y; sta.w $6020+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    }
    jmp renderCharacter
  }

  epilogue: {
    lda pixel; add #$0007; div(8); sta tiles
    leave; rtl
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      lda index; tax
      inc; sta index
      lda text,x; and #$00ff
      add pixel; sta pixel
      rtl
    }
  }
}
macro bpp4() {
  jsl render.small.bpp4
}

namespace bpp4 {
namespace to {

//A => number of tiles to convert in-place
//0 => 0
//1 => 8
//2 => 9
//3 => 10
function bph4 {
  prologue: {
    enter; ldb #$32
    mul(32)
  }

  convert: {
    sub #$0020; tax
    pha; sep #$20
    macro line(variable n) {
      lda.w $6000+n*2,x; ora.w $6001+n*2,x; sta.w $6011+n*2,x
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    rep #$20; pla; jne convert
  }

  epilogue: {
    leave; rtl
  }
}
macro bph4() {
  jsl render.small.bpp4.to.bph4
}

}
}

//A => maximum number of tiles to render
//0 => 4
//1 => 1
//2 => 2
//3 => 3
function bpo4 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)
  variable(2, pixels)
  variable(2, style)

  prologue: {
    enter; ldb #$32
    and #$001f; bne +; lda #$0020; +
    mul(8); sta pixels
    mul(4); render.clear($20)
    lda #$0000; sta index; sta character; sta pixel; sta style
  }

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra renderCharacter; +
    cmp.w #command.styleTiny;   bne +; lda.w #$60; sta style; bra renderCharacter; +
    cmp.w #command.alignLeft;   bne +; jsl align.left;        bra renderCharacter; +
    cmp.w #command.alignCenter; bne +; jsl align.center;      bra renderCharacter; +
    cmp.w #command.alignRight;  bne +; jsl align.right;       bra renderCharacter; +
    cmp.w #command.alignSkip;   bne +; jsl align.skip;        bra renderCharacter; +
    cmp.w #command.break;       jcs epilogue
    bra renderCharacter
  decode:
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(176); add $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(32); pha
    lda pixel; and #$0007; mul(5632)
    add $01,s; tax; pla
    lda pixel; and #$00f8; asl #2; tay

    phx; lda character; tax
    lda smallFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +; jmp epilogue; +
    sta pixel

    tile: {
      macro line(variable n) {
        lda.l smallFont.data+$00+n*2,x; ora.w $6000+n*2,y; sta.w $6000+n*2,y
        lda.l smallFont.data+$10+n*2,x; ora.w $6020+n*2,y; sta.w $6020+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    }
    jmp renderCharacter
  }

  epilogue: {
    lda pixel; add #$0007; div(8); sta tiles
    jsl convert
    leave; rtl
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      lda index;  add.w #text >>  0; sta width.address+0
      lda #$0000; adc.w #text >> 16; sta width.address+2
      lda style; sta width.style; jsl width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      lda index; tax
      inc; sta index
      lda text,x; and #$00ff
      add pixel; sta pixel; rtl
    }
  }

  function convert {
    lda pixels; mul(4)
  -;sub #$0020; tax
    pha; sep #$20
    macro line(variable n) {
      lda.w $6000+n*2,x
      ora.w $6001+n*2,x; eor #$ff
      sta.w $6010+n*2,x
      stz.w $6011+n*2,x
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    rep #$20; pla; jne -
    rtl
  }
}
macro bpo4() {
  jsl render.small.bpo4
}

namespace bpo4 {
namespace to {

//A => number of tiles to convert in-place
//4 => 4
//1 => 5
//2 => 6
//3 => 3
function bpa4 {
  prologue: {
    enter; ldb #$32
    mul(32)
  }

  convert: {
    sub #$0020; tax
    pha; sep #$20
    macro line(variable n) {
      lda.w $6000+n*2,x; and.w $6001+n*2,x; eor #$ff; pha
      lda.w $6000+n*2,x; ora.w $6001+n*2,x; and $01,s
      ora.w $6010+n*2,x; sta.w $6010+n*2,x; pla
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    rep #$20; pla; jne convert
  }

  epilogue: {
    leave; rtl
  }
}
macro bpa4() {
  jsl render.small.bpo4.to.bpa4
}

}
}

//address => text string location
//style => font style ($00 = normal, $60 = tiny)
//A <= number of pixels required to render text
function width {
  variable(4, address)
  variable(2, style)
  variable(2, character)
  variable(2, pixel)

  prologue: {
    phb; php; rep #$30; phx; phy
    lda address+1; pha; plb; plb
    lda address+0; tax
    lda #$0000; sta character; sta pixel
  }

  loop: {
    lda $0000,x; and #$00ff; inx
    cmp.w #command.base;        bcc decode
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra loop; +
    cmp.w #command.styleTiny;   bne +; lda.w #$60; sta style; bra loop; +
    cmp.w #command.alignSkip;   bne +; lda $0000,x; and #$00ff; inx; add pixel; sta pixel; bra loop; +
    cmp.w #command.pause;       bne +; inx; bra loop; +
    cmp.w #command.wait;        jcs epilogue
    bra loop
  decode:
    character.decode(); add style; phx; pha
    lda character; mul(176); add $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character; tax
    lda smallFont.widths,x; plx; and #$00ff
    add pixel; sta pixel
    jmp loop
  }

  epilogue: {
    lda pixel
    ply; plx; plp; plb; rtl
  }
}
macro width(variable source) {
  php; rep #$20
  lda.w #source >> 0; sta render.small.width.address+0
  lda.w #source >> 8; sta render.small.width.address+1
  lda.w #$00; sta render.small.width.style
  jsl render.small.width; plp
}
macro width() {
  render.small.width(render.text)
}

}

codeCursor = pc()

}
