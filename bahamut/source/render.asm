namespace render {

seek(codeCursor)

//input: a character-map encoded string, terminated by $ff
variable(256, text)

//input: the maximum number of tiles to render
variable(2, limit)

//output: the number of tiles generated after rendering text
variable(2, tiles)

//output: rendered tiledata is written to $a2:6000-7fff (8KB)
constant buffer = $a26000

//A = # of bytes to zero-fill in render.buffer (must be a multiple of tilesize; must not be 0)
//tilesize $10 => fully clear 2bpp or 4bpp tiles
//tilesize $20 => clear lower half of 4bpp tiles
macro clear(variable tilesize) {
  //DMA would certainly be faster than an unrolled loop here, but NMI uses DMA.
  //if we tried to use DMA here, it's possible NMI would trample on the registers.
-;sub.w #tilesize; tax
  stz buffer+$0,x; stz buffer+$2,x; stz buffer+$4,x; stz buffer+$6,x
  stz buffer+$8,x; stz buffer+$a,x; stz buffer+$c,x; stz buffer+$e,x
  bne -
}

namespace large {

function bpp2 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)

  enter
  ldb #$a2
  lda #$0400; render.clear($10)
  lda #$0000; sta index; sta character; sta pixel

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp #$00ff; jeq finished
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(48); pha
    lda pixel; and #$0007; mul($1800)
    add $01,s; tax; pla

    lda pixel; and #$00f8; asl #2; tay
    macro line(variable n) {
      lda.l largeFont.normal+$00+n*2,x; ora.w $6004+n*2,y; sta.w $6004+n*2,y
      lda.l largeFont.normal+$18+n*2,x; ora.w $6024+n*2,y; sta.w $6024+n*2,y
    }
    line(0); line(1); line(2); line(3); line(4); line(5)
    line(6); line(7); line(8); line(9);line(10);line(11)

    macro line(variable n) {
      lda.w $6004+n*2,y; ora.w $6005+n*2,y; sta.w $6004+n*2,y
      lda.w $6024+n*2,y; ora.w $6025+n*2,y; sta.w $6024+n*2,y
    }
    sep #$20
    line(0); line(1); line(2); line(3); line(4); line(5)
    line(6); line(7); line(8); line(9);line(10);line(11)
    rep #$20

    lda character; tax
    lda largeFont.widths,x; and #$00ff
    add pixel; sta pixel
    jmp renderCharacter
  }

finished:
  lda pixel; add #$0007; div(8); sta tiles
  leave; rtl
}
macro bpp2() {
  jsl render.large.bpp2
}

function bpp4 {
  variable(2, index)
  variable(2, character)
  variable(2, pixel)

  enter
  ldb #$a2
  lda #$0600; render.clear($10)
  lda #$0000; sta index; sta character; sta pixel

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp #$00ff; bne +; jmp finished; +
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(48); pha
    lda pixel; and #$0007; mul($1800)
    add $01,s; tax; pla

    lda pixel; and #$00f8; asl #3; tay
    macro upper(variable n) {
      lda.l largeFont.normal+$00+n*2,x; ora.w $6004+n*2,y; sta.w $6004+n*2,y
      lda.l largeFont.normal+$18+n*2,x; ora.w $6044+n*2,y; sta.w $6044+n*2,y
    }
    macro lower(variable n) {
      lda.l largeFont.normal+$0c+n*2,x; ora.w $6020+n*2,y; sta.w $6020+n*2,y
      lda.l largeFont.normal+$24+n*2,x; ora.w $6060+n*2,y; sta.w $6060+n*2,y
    }
    upper(0); upper(1); upper(2); upper(3); upper(4); upper(5)
    lower(0); lower(1); lower(2); lower(3); lower(4); lower(5)

    //color conversion:
    //0 => 4 (window background gradient palette index)
    //1 => 1 (text color)
    //2 => 6 (text shadow color)
    lda #$0000
    tile: {
      pha; mul(32); tax; sep #$20
      macro line(variable n) {
        lda.w $6000+n*2,x; ora.w $6001+n*2,x; eor #$ff
        ora.w $6001+n*2,x; sta.w $6010+n*2,x
      }
      line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
      rep #$20; pla; inc
      cmp.w #48; jcc tile
    }
    rep #$20

    lda character; tax
    lda largeFont.widths,x; and #$00ff
    add pixel; sta pixel
    jmp renderCharacter
  }

finished:
  lda pixel; add #$0007; div(8); sta tiles
  leave; rtl
}
macro bpp4() {
  jsl render.large.bpp4
}

//A <= number of pixels required to render text
function width {
  variable(4, address)
  variable(2, character)
  variable(2, pixel)

  phb; php; rep #$30; phx; phy
  lda address+1; pha; plb; plb
  lda address+0; tax
  lda #$0000; sta character; sta pixel
  loop: {
    lda $0000,x; and #$00ff; inx
    cmp.w #command.pause; bne +; inx; bra loop; +
    cmp.w #command.wait; jcs finished
    cmp.w #command.base; jcs loop
    character.decode(); phx; pha
    lda character; xba; lsr; ora $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character; tax
    lda largeFont.widths,x; plx; and #$00ff
    add pixel; sta pixel
    bra loop
  }
finished:
  lda pixel
  ply; plx; plp; plb; rtl
}
macro width(variable source) {
  php; rep #$30
  lda.w #source >> 0; sta render.large.width.address+0
  lda.w #source >> 8; sta render.large.width.address+1
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

  enter
  ldb #$a2
  and #$001f; bne +; lda #$0020; +
  mul(8); inc #2; sta limit; dec #2
  mul(2); render.clear($10)
  lda #$0000; sta index; sta character; sta pixel

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp #$00e8; bne +; jsl alignLeft;  bra renderCharacter; +
    cmp #$00e9; bne +; jsl alignRight; bra renderCharacter; +
    cmp #$00ff; jeq finished
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(32); pha
    lda pixel; and #$0007; mul($1000)
    add $01,s; tax; pla
    lda pixel; and #$00f8; asl; tay

    phx; lda character; tax
    lda smallFont.widths,x; and #$00ff; plx
    add pixel; cmp limit; jcs finished
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

finished:
  lda pixel; add #$0007; div(8); sta tiles
  leave; rtl

  alignLeft: {
    inx; lda text,x; inx; and #$00ff
    sta pixel
    txa; sta index; rtl
  }

  alignRight: {
    inx; lda text,x; inx; and #$00ff
    pha; lda limit; dec #2; sub $01,s; sta pixel; pla
    txa; sta index; rtl
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

  enter
  ldb #$a2
  and #$001f; bne +; lda #$0020; +
  mul(8); inc #2; sta limit; dec #2
  mul(4); render.clear($10)
  lda #$0000; sta index; sta character; sta pixel

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp #$00e8; jeq alignLeft
    cmp #$00e9; jeq alignRight
    cmp #$00ff; jeq finished
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(32); pha
    lda pixel; and #$0007; mul($1000)
    add $01,s; tax; pla
    lda pixel; and #$00f8; asl #2; tay

    phx; lda character; tax
    lda smallFont.widths,x; and #$00ff; plx
    add pixel; cmp limit; jcs finished
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

  finished: {
    lda pixel; add #$0007; div(8); sta tiles
    leave; rtl
  }

  alignLeft: {
    inx; lda text,x; inx; and #$00ff
    sta pixel
    txa; sta index
    jmp renderCharacter
  }

  alignRight: {
    inx; lda text,x; inx; and #$00ff
    pha; lda limit; dec #2; sub $01,s; sta pixel; pla
    txa; sta index
    jmp renderCharacter
  }
}
macro bpp4() {
  jsl render.small.bpp4
}

//A => maximum number of tiles to render
//0 => 4
//1 => 1
//2 => 2
//3 => 3
function bpo4 {
  variable(2, bytes)
  variable(2, index)
  variable(2, character)
  variable(2, pixel)

  enter
  ldb #$a2
  and #$001f; bne +; lda #$0020; +
  mul(8); inc #2; sta limit; dec #2
  mul(4); sta bytes; render.clear($20)
  lda #$0000; sta index; sta character; sta pixel

  renderCharacter: {
    lda index; tax
    inc; sta index
    lda text,x; and #$00ff
    cmp #$00e8; jeq alignLeft
    cmp #$00e9; jeq alignRight
    cmp #$00ff; jeq finished
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    mul(32); pha
    lda pixel; and #$0007; mul($1000)
    add $01,s; tax; pla
    lda pixel; and #$00f8; asl #2; tay

    phx; lda character; tax
    lda smallFont.widths,x; and #$00ff; plx
    add pixel; cmp limit; jcs finished
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

  alignLeft: {
    inx; lda text,x; inx; and #$00ff
    sta pixel
    txa; sta index
    jmp renderCharacter
  }

  alignRight: {
    inx; lda text,x; inx; and #$00ff
    pha; lda limit; dec #2; sub $01,s; sta pixel; pla
    txa; sta index
    jmp renderCharacter
  }

  finished: {
    lda pixel; add #$0007; div(8); sta tiles
  }

  convert: {
    lda bytes
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
    leave; rtl
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
  enter
  ldb #$a2; mul(32)
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
  leave; rtl
}
macro bpa4() {
  jsl render.small.bpo4.to.bpa4
}

}
}

//A => maximum number of tiles to render
//0 => 4
//1 => 5
//2 => 6
//3 => 3
function bpa4 {
  //used only by combat-small.asm to render "Page #/#"
  jsl bpo4
  jsl bpo4.to.bpa4
}
macro bpa4() {
  jsl render.small.bpa4
}

//A <= number of pixels required to render text
function width {
  variable(4, address)
  variable(2, character)
  variable(2, pixel)

  phb; php; rep #$30; phx; phy
  lda address+1; pha; plb; plb
  lda address+0; tax
  lda #$0000; sta character; sta pixel
  loop: {
    lda $0000,x; and #$00ff; inx
    cmp.w #command.wait; jcs finished
    cmp.w #command.base; jcs loop
    character.decode(); phx; pha
    lda character; xba; lsr; ora $01,s; tax
    lda smallFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character; tax
    lda smallFont.widths,x; plx; and #$00ff
    add pixel; sta pixel
    bra loop
  }
finished:
  lda pixel
  ply; plx; plp; plb; rtl
}
macro width(variable source) {
  php; rep #$30
  lda.w #source >> 0; sta render.small.width.address+0
  lda.w #source >> 8; sta render.small.width.address+1
  jsl render.small.width; plp
}
macro width() {
  render.small.width(render.text)
}

}

codeCursor = pc()

}
