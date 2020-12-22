namespace menu {

seek(codeCursor)

//code used by both game loading and saving
namespace saves {
  enqueue pc

  seek($ee55bb); jsl hookDMA; jmp $5629  //expand chapter name DMA transfer size

  //All Slots
  seek($eed577); string.skip()        //"Chapter" text
  seek($eed5d5); string.skip()        //"Time" text
  seek($eefa1f); jsl bonusDungeon     //"Bonus Dungeon#" integer
  seek($eed5a9); string.hook(exPlay)  //"Ex-Play" text
  seek($eef9fc); string.skip()        //"Bonus Dungeon" text
  seek($eefa18); lda #$0000           //"Bonus Dungeon" position

  //Slot 1
  seek($eed280); dw 22, 3                //X,Y cursor position
  seek($eed3d2); string.hook(noData)     //"No Data" text
  seek($eed47e); jsl chapter.slot1       //"Chapter#" integer
  seek($eed488); jsl time.slot1; nop #2  //"Time" timestamp
  seek($eed3cc); lda #$0086              //"No Data" position
  seek($eed476); lda #$0086              //"Chapter#" position
  seek($eed482); lda #$0096              //"Time" position
  seek($eed46a); lda #$009e              //"Ex-Play" position
  seek($eed456); lda #$00c6              //"Chapter Name" position
  seek($eef8de); lda #$0086              //"Bonus Dungeon Name" position
  seek($eed4a0); lda #$2400              //"Chapter Name" tiledata position
  seek($eef919); lda #$2400              //"Bonus Dungeon" tiledata position
  seek($eed45c); lda #$0140; jsl writeChapterNameTilemap  //"Chapter" text
  seek($eef8ff); lda #$0140; jsl writeChapterNameTilemap  //"Bonus Dungeon" text

  //Slot 2
  seek($eed284); dw 22,43                //X,Y cursor position
  seek($eed3eb); string.hook(noData)     //"No Data" text
  seek($eed4da); jsl chapter.slot2       //"Chapter#" integer
  seek($eed4e4); jsl time.slot2; nop #2  //"Time" timestamp
  seek($eed3e5); lda #$01c6              //"No Data" position
  seek($eed4d2); lda #$01c6              //"Chapter#" position
  seek($eed4de); lda #$01d6              //"Time" position
  seek($eed4c6); lda #$01de              //"Ex-Play" position
  seek($eed4b2); lda #$0206              //"Chapter Name" position
  seek($eef935); lda #$01c6              //"Bonus Dungeon Name" position
  seek($eed4fc); lda #$2800              //"Chapter Name" tiledata position
  seek($eef970); lda #$2800              //"Bonus Dungeon" tiledata position
  seek($eed4b8); lda #$0180; jsl writeChapterNameTilemap  //"Chapter" text
  seek($eef956); lda #$0180; jsl writeChapterNameTilemap  //"Bonus Dungeon" text

  //Slot 3
  seek($eed288); dw 22,83                //X,Y cursor position
  seek($eed404); string.hook(noData)     //"No Data" text
  seek($eed536); jsl chapter.slot3       //"Chapter#" integer
  seek($eed540); jsl time.slot3; nop #2  //"Time" timestamp
  seek($eed3fe); lda #$0306              //"No Data" position
  seek($eed52e); lda #$0306              //"Chapter#" position
  seek($eed53a); lda #$0316              //"Time" position
  seek($eed522); lda #$031e              //"Ex-Play" position
  seek($eed50e); lda #$0346              //"Chapter Name" position
  seek($eef98c); lda #$0306              //"Bonus Dungeon Name" position
  seek($eed558); lda #$2c00              //"Chapter Name" tiledata position
  seek($eef9c7); lda #$2c00              //"Bonus Dungeon" tiledata position
  seek($eed514); lda #$01c0; jsl writeChapterNameTilemap  //"Chapter" text
  seek($eef9ad); lda #$01c0; jsl writeChapterNameTilemap  //"Bonus Dungeon" text

  //Menu
  seek($eed29c); string.hook(save)   //"Save?" text
  seek($eed2bf); string.hook(done)   //"Continue playing?" text
  seek($eed2e2); string.hook(load)   //"Begin sortie?" text
  seek($eed300); string.hook(yes)    //"Yes" text
  seek($eed30f); string.hook(no)     //"No" text
  seek($eed28f); lda #$0446          //"Save?" position
  seek($eed2b2); lda #$0446          //"Continue playing?" position
  seek($eed2d5); lda #$0446          //"Begin sortie?" position
  seek($eed2fa); lda #$04c8          //"Yes" position
  seek($eed309); lda #$0548          //"No" option
  seek($eed33a); adc #$008b          //Y cursor offset
  seek($eed34e); jml clearText; nop  //clear text hook
  seek($eed362); lda #$0406          //clear offset
  seek($eed368); ldx #$0010          //clear width
  seek($eed36b); ldy #$0006          //clear height

  dequeue pc

  allocator.bpp4()
  allocator.create( 8,2,chapterSlot1)
  allocator.create( 8,2,chapterSlot2)
  allocator.create( 8,2,chapterSlot3)
  allocator.create(12,3,bonusDungeon)
  allocator.create( 8,1,exPlay)
  allocator.create(10,2,timeSlot1)
  allocator.create(10,2,timeSlot2)
  allocator.create(10,2,timeSlot3)
  allocator.create( 8,1,noData)
  allocator.create(16,1,save)
  allocator.create(16,1,done)
  allocator.create(16,1,load)
  allocator.create( 4,1,yes)
  allocator.create( 4,1,no)
  if allocator.bank1 > $140 {
    error "small tiledata overlaps large tiledata area"
  }

  function hookDMA {
    lda $001a00; tax
    lda #$8000; sta $000006,x     //$2115 = VRAM write mode
    lda $34;    sta $000003,x     //$2116 = VRAM target address
    lda #$0800; sta $000005,x     //$4305 = DMA transfer length
    lda #$7e00; sta $000001,x     //$4302 = DMA source bank
    lda #$7800; sta $000000,x     //$4300 = DMA source address
    txa; add #$0008; sta $001a00  //seek to next entry in the list
    rtl
  }

  //the original game did not clear the large text when exiting menus.
  //this would leave the question prompt onscreen without the menu.
  //this hook detects when the menu is cancelled and clears the text area manually.
  //------
  //eed34e  bit #$0c00
  //eed351  beq $d362
  //------
  function clearText {
    bit #$0c00; beq +; jml $eed353; +
    jsl largeText.clearSprites; jml $eed362
  }

  //originally chapter names were limited to a width of 120 pixels.
  //the screen has been rearranged to allow for up to 240 pixels of text.
  //the original tilemap writing function only supported the left two RAM segments,
  //so it is replaced with this routine that can write all four segments properly.
  function writeChapterNameTilemap {
    //A => starting tilemap character index
    enter; ldb #$7e
    ora.w tilemap.attributes
    pha; lda.w tilemap.address; tax; pla

    //write top-left quadrant
    ldy #$0010
    -;sta.w tilemap.location,x; inc
      inx #2; dey; bne -

    //write top-right quadrant
    ldy #$0010; add #$0010
    -;sta.w tilemap.location,x; inc
      inx #2; dey; bne -

    //write bottom-left quadrant
    ldy #$0010; sub #$0020
    -;sta.w tilemap.location,x; inc
      inx #2; dey; bne -

    //write bottom-right quadrant
    ldy #$0010; add #$0010
    -;sta.w tilemap.location,x; inc
      inx #2; dey; bne -

    leave; rtl
  }

  //A => chapter#
  //X => tilemap index
  function chapter {
    enter
    tilemap.setColorPalette(0)
    and #$00ff; mul(8); tay
    lda #$0008; write.bpp4(lists.chapters.bph4)
    leave; rtl

    slot1:; enter; pha; allocator.index(chapterSlot1); pla; jsl chapter; leave; rtl
    slot2:; enter; pha; allocator.index(chapterSlot2); pla; jsl chapter; leave; rtl
    slot3:; enter; pha; allocator.index(chapterSlot3); pla; jsl chapter; leave; rtl
  }

  //X => tilemap index
  //$3065c8 => hour
  //$3065c9 => minute
  //$3065ca => second
  function time {
    variable(2, index)
    variable(2, hour)
    variable(2, minute)
    variable(2, second)

    enter
    tilemap.setColorPalette(0)
    phx; lda index; tax
    lda $3065c8,x; and #$00ff; sta hour
    lda $3065c9,x; and #$00ff; sta minute
    lda $3065ca,x; and #$00ff; sta second

    ldx #$0000
    lda hour; cmp.w #100; jcs digits_3

  digits_2:
    append.alignSkip(9)
    append.literal("Time")
    append.alignLeft()
    append.alignSkip(32)
    lda hour
    append.integer02()
    append.literal(":")
    lda minute
    append.integer02()
    append.literal(":")
    lda second
    append.integer02()
    jmp render

  digits_3:
    append.alignSkip(6)
    append.literal("Time")
    append.alignLeft()
    append.alignSkip(29)
    lda hour
    append.integer_3()
    append.literal(":")
    lda minute
    append.integer02()
    append.literal(":")
    lda second
    append.integer02()
    jmp render

  render:
    lda #$000a; render.small.bpp4(); render.small.bpp4.to.bph4()
    lda #$000a; plx; write.bpp4()
    leave; rtl

    slot1:; enter; lda #$0000; sta index; allocator.index(timeSlot1); jsl time; leave; rtl
    slot2:; enter; lda #$05c8; sta index; allocator.index(timeSlot2); jsl time; leave; rtl
    slot3:; enter; lda #$0b90; sta index; allocator.index(timeSlot3); jsl time; leave; rtl
  }

  //A => bonus dungeon# (1-3)
  function bonusDungeon {
    enter; dec  //strings are zero-indexed
    tilemap.setColorPalette(0)
    mul(12); add.w #strings.bph4.bonusDungeon1; tay
    lda #$000c; allocator.index(bonusDungeon); write.bpp4(lists.strings.bph4)
    leave; rtl
  }

  function exPlay {
    enter
    tilemap.setColorPalette(0)
    ldy.w #strings.bph4.exPlay
    lda #$0008; allocator.index(exPlay); write.bpp4(lists.strings.bph4)
    leave; rtl
  }

  function noData {
    enter
    tilemap.setColorPalette(0)
    ldy.w #strings.bph4.noData
    lda #$0008; allocator.index(noData); write.bpp4(lists.strings.bph4)
    leave; rtl
  }

  function save {
    enter
    ldy.w #strings.bpp4.overwriteSave
    lda #$0010; allocator.index(save); write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  function done {
    enter
    ldy.w #strings.bpp4.continuePlaying
    lda #$0010; allocator.index(done); write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  function load {
    enter
    ldy.w #strings.bpp4.beginSortie
    lda #$0010; allocator.index(load); write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  function yes {
    enter
    ldy.w #strings.bpp4.yes
    lda #$0004; allocator.index(yes); write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  function no {
    enter
    ldy.w #strings.bpp4.no
    lda #$0004; allocator.index(no); write.bpp4(lists.strings.bpp4)
    leave; rtl
  }
}

codeCursor = pc()

}
