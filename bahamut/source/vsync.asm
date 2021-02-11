seek(codeCursor)

//this function must be called before transferring tiledata to VRAM.
//after calling, there will be time to DMA transfer at least 1KB of data.
//if the screen is still drawing, it will wait until vblank begins.
//if within vblank, it will ensure enough time remains to transfer tiledata.
//if within vblank and not enough time remains, it will wait for the next vblank.
function vsync {
  php; rep #$20; pha

  sep #$20
  lda $00213f                 //reset OPVCT latch
  lda $002137                 //latch the counters
  lda $00213d; xba            //read OPVCTL
  lda $00213d; and #$01; xba  //read OPVCTH

  rep #$20
  cmp.w #225; bcc waitForThisVblank  //still in active display
  cmp.w #253; bcs waitForNextVblank  //not enough Vblank time remaining
  pla; plp; rtl

  waitForThisVblank: {
    sep #$20
    -; lda $004212; bpl -
    rep #$20; pla; plp; rtl
  }

  waitForNextVblank: {
    sep #$20
    -; lda $004212; bmi -
    -; lda $004212; bpl -
    rep #$20; pla; plp; rtl
  }
}
macro vsync() {
  jsl vsync
}

//this function should be used instead of vsync for transfers larger than 1KB.
//it will always wait for the start of the next vblank to maximize vblank time.
function vwait {
  php; sep #$20; pha
  -; lda $004212; bmi -
  -; lda $004212; bpl -
  pla; plp; rtl
}
macro vwait() {
  jsl vwait
}

codeCursor = pc()
