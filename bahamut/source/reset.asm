namespace reset {

seek(codeCursor)

//hook the reset vector to initialize WRAM:
//needed to prevent the debugger from triggering sporadically at reset.
namespace reset {
  enqueue pc
  seek($c0ffa2); jml main
  dequeue pc

  seek(codeCursor)
  function main {
    rep #$30; ldx #$01ff; txs

    lda.w #$0000; sta $002181
    lda.w #$0000; sta $002182
    lda.w #fill >> 0; sta $004302
    lda.w #fill >> 8; sta $004303
    lda.w #0; sta $004305; sep #$20
    lda #$08; sta $004300
    lda #$80; sta $004301
    lda #$01; sta $00420b  //zero-initialize first 64KB
    lda #$01; sta $00420b  //zero-initialize second 64KB
  //lda #$01; sta $307fd0  //enable ex-play
    lda #$1f; sta $7e3bd8  //prevents the debug menu from appearing at reset
    jml $c00000

    fill:; db $ff
  }
  codeCursor = pc()
}

//in the original game, this routine ended up writing to $006ea0-$006ea7.
//this area is unmapped on SHVC-1J3M-20, but is mapped to SRAM on SHVC-LJ3M-01.
//allowing this write to happen with SRAM mapped here will corrupt the second save slot.
//what it was intending to do originally was initialize a WRAM copy of the PPU OAM upper table.
//the WRAM table is located at $7e6ca0-$7e6ebf, and $7e6ca0 is the start of the upper table.
//based on other similar code, it seems that sta $000000,x should've been sta $7e0000,x.
//this is fixed both so that the OAM table is initialized properly, and just in case any
//SNES emulator chooses to map SRAM into the $00-1f,80-9f:6000-7fff memory region.
namespace sramCorruptionFix {
  //------
  //ee84e9  lda #$00ee     ;source bank
  //ee84ec  ldy #$85b6     ;source address
  //ee84ef  jsl $ee3d69    ;write 16-bit address=value pairs until $ffff reached
  //------
  //ee3d7e  sta $000000,x  ;write 16-bit values to B=$00
  //------
  //ee85b6  dw $6ea0,$aaaa
  //ee85ba  dw $6ea2,$aaaa
  //ee85be  dw $6ea4,$aaaa
  //ee85c2  dw $6ea6,$aaaa
  //ee84c6  dw $1830,$0001
  //ee84c8  dw $182e,$0001
  //ee84cc  dw $ffff
  //------
  enqueue pc
  seek($ee3d7e); sta $7e0000,x
  dequeue pc
}

codeCursor = pc()

}
