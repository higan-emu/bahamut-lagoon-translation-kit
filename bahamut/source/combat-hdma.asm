namespace combat {

seek(codeCursor)

//there is a bug in S-CPU A where DMAs can fail if the last HDMA transfer had
//targeted BBADx=$00. this bug triggered on the experience screen after combat.
//this mitigation works by moving the HDMA to $21ff+$2100 instead.
//there is a second bug where writes to $2100 latch on the rising edge of the
//clock cycle, causing $2100 to become the previous value on the data bus (MDR.)
//this caused sprite glitches on 3-CHIP PPUs during Hblank tile fetching.
//this is mitigated by ensuring $21ff writes the same value as $2100 will.
namespace hdmaMitigation {
  //originally the HDMA table was at $7e5600-$7e5608.
  //the table has been moved to SRAM because it needs four additional bytes now.
  variable(16, hdmaTable)

  enqueue pc
  seek($c11341); {
    php; sep #$20; rep #$10
    phb; ldb #$31
    phx; ldx #$8080
    lda #$10; sta.w hdmaTable+$0; stx.w hdmaTable+$1
    lda #$60; sta.w hdmaTable+$3; stx.w hdmaTable+$4
    lda #$56; sta.w hdmaTable+$6; stx.w hdmaTable+$7
    lda #$08; sta.w hdmaTable+$9; stx.w hdmaTable+$a
    stz.w hdmaTable+$c
    lda #$01; sta $4370
    lda #$ff; sta $4371
    lda.b #hdmaTable >>  0; sta $4372; sta $4378
    lda.b #hdmaTable >>  8; sta $4373; sta $4379
    lda.b #hdmaTable >> 16; sta $4374
    plx; plb; plp
    assert(pc() == $c11395)
  }
  seek($c102f5); {
    jsl write; nop #4
    assert(pc() == $c102fd)
  }
  seek($c1c14f); {
    lda hdmaTable+$0; dec; sta hdmaTable+$0
    lda hdmaTable+$3; inc; sta hdmaTable+$3
    assert(pc() == $c1c161)
  }
  seek($c1c164); {
    lda hdmaTable+$0; inc; sta hdmaTable+$0
    lda hdmaTable+$3; dec; sta hdmaTable+$3
    assert(pc() == $c1c176)
  }
  seek($c28b86); {
    lda #$0f; sta hdmaTable+$0
    lda #$61; sta hdmaTable+$3
    assert(pc() == $c28b92)
  }
  seek($c2ec60); {
    lda #$10; sta hdmaTable+$0
    lda #$60; sta hdmaTable+$3
    assert(pc() == $c2ec6c)
  }
  dequeue pc

  function write {
    sta hdmaTable+$4; sta hdmaTable+$5
    sta hdmaTable+$7; sta hdmaTable+$8
    rtl
  }
}

codeCursor = pc()

}
