//this code pre-renders dynamic names on game loading and character naming.
//note that "Fahrenheit" is not rendered, as it's not used in 8x8 menus anywhere,
//and because there isn't enough room in the $33 SRAM bank for it.

namespace names {

seek(codeCursor)

namespace buffer {
  constant origin = $336000  //$1f80 bytes used
  constant bpp2   = origin
  constant bpp4   = origin + (8*9) * (16)
  constant bpo4   = origin + (8*9) * (16+32)
  constant bpa4   = origin + (8*9) * (16+32+32)
}

namespace hook {
  enqueue pc
  seek($edcfdf); jsl load; nop #3  //used when loading games or resuming temporary saves
  seek($ed8462); jsl load; nop #3  //used by the debugger when jumping to chapters
  dequeue pc
}

//------
//eecfdf  sep #$20
//eecfe1  sta $2b00,x
//eecfe4  rep #$20
//------
//ed8462  sep #$20
//ed8464  sta $2b00,x
//ed8467  rep #$20
//------
function load {
  sep #$20; sta $7e2b00,x
  rep #$20; txa
  //render names when (X&7)==7 (last character); set A <= name index
  lsr; bcs +; rtl; +
  lsr; bcs +; rtl; +
  lsr; bcs +; rtl; +
  jsl render; rtl
}

//A => name (player or dragon)
function render {
  variable(2, index)
  variable(2, tiles)

  enter
  and #$00ff; cmp #$0009
  bcc +; leave; rtl; +  //ignore "Fahrenheit"
  sta index
  ldb #buffer.origin>>16

  //render the name
  ldx #$0000; append.name()
  lda index; mul(128); tay
  lda #$0008; render.small.bpp2()

  //copy bpp2 result
  ldx #$0000
  bpp2: {
    macro line(variable n) {
      lda.l render.buffer+n*2,x
      sta.w buffer.bpp2+n*2,y
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    txa; add #$0010; tax
    tya; add #$0010; tay
    cpx #$0080; bcc bpp2
  }

  //convert to bpp4
  lda index; mul(256); tay
  ldx #$0000
  bpp4: {
    macro line(variable n) {
      lda.l render.buffer+n*2,x
      sta.w buffer.bpp4+$00+n*2,y; lda #$0000
      sta.w buffer.bpp4+$10+n*2,y
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    txa; add #$0010; tax
    tya; add #$0020; tay
    cpx #$0080; bcc bpp4
  }

  //convert to bpo4
  lda index; mul(256); tay
  ldx #$0000
  bpo4: {
    sep #$20
    macro line(variable n) {
      lda.l render.buffer+0+n*2,x; sta.w buffer.bpo4+$00+n*2,y
      lda.l render.buffer+1+n*2,x; sta.w buffer.bpo4+$01+n*2,y
      ora.w buffer.bpo4+$00+n*2,y; eor #$ff
      sta.w buffer.bpo4+$10+n*2,y; lda #$00
      sta.w buffer.bpo4+$11+n*2,y
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    rep #$20
    txa; add #$0010; tax
    tya; add #$0020; tay
    cpx #$0080; jcc bpo4
  }

  //convert to bpa4
  lda index; mul(256); tay
  ldx #$0000
  bpa4: {
    sep #$20
    macro line(variable n) {
      lda.l render.buffer+0+n*2,x; sta.w buffer.bpa4+$00+n*2,y
      and.l render.buffer+1+n*2,x; eor #$ff; pha
      lda.l render.buffer+1+n*2,x; sta.w buffer.bpa4+$01+n*2,y
      ora.w buffer.bpa4+$00+n*2,y; eor #$ff
      ora.w buffer.bpa4+$00+n*2,y; ora.w buffer.bpa4+$01+n*2,y; and $01,s
      sta.w buffer.bpa4+$10+n*2,y; lda #$00
      sta.w buffer.bpa4+$11+n*2,y; pla
    }
    line(0); line(1); line(2); line(3); line(4); line(5); line(6); line(7)
    rep #$20
    txa; add #$0010; tax
    tya; add #$0020; tay
    cpx #$0080; jcc bpa4
  }

  leave; rtl
}

codeCursor = pc()

}
