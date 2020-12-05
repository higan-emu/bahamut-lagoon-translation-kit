namespace menu {

seek(codeCursor)

//Bahamut Lagoon shares a lot of code routines between each menu,
//which interferes greatly with tile allocation strategies.
//the dispatcher attempts to record when screens are entered into,
//in order to disambiguate shared routines, and call handlers for
//specific screens instead.

namespace dispatcher {
  enqueue pc

  seek($ee7b64); jsl hookCampaignMenu
  seek($ee7947); jsl hookPartyMenu; nop
  seek($ee6f83); jsl party
  seek($eea74d); string.hook(party.other)
  seek($eea512); string.hook(party.other)
  seek($ee6f6c); string.skip()  //"Party" static text (used by several screens)

  //unit and status screens
  seek($ee6fe4); string.hook(mp.setType)  //"MP"
  seek($ee6ff1); string.hook(mp.setType)  //"SP"
  seek($ee705a); jsl mp.setCurrent
  seek($ee707f); jsl mp.setMaximum
  seek($ee701c); jsl mp.setCurrentUnavailable
  seek($ee7039); jsl mp.setMaximumUnavailable

  //formations, equipments, information, shop screens
  seek($eef02b); jsl page.index
  seek($eef01b); jsl page.total
  seek($eee6b6); string.hook(page.noItems)  //"No Items" text (shop screen)
  seek($eeefa8); string.hook(page.noItems)  //"No Items" text (information screen)

  //shared positions
  seek($ee700f); adc #$0000  //"MP"- position (magic, item, unit screens)
  seek($ee702c); adc #$0000  //"MP"/ position (magic, item, unit screens)
  seek($ee7044); adc #$0000  //"SP"# position (magic, item, unit screens)

  dequeue pc

  namespace screen {
    variable(2, id)
    constant unknown     = 0
    constant formations  = 1
    constant dragons     = 2
    constant information = 3
    constant equipments  = 4
    constant magicItem   = 5
    constant equipment   = 6
    constant status      = 7
    constant unit        = 8
  }

  function hookCampaignMenu {
    lda $4c
    enter
    cmp #$0000; bne +; lda.w #screen.formations;  sta screen.id; jmp return; +
    cmp #$0001; bne +; lda.w #screen.dragons;     sta screen.id; jmp return; +
    cmp #$0002; bne +; lda.w #screen.information; sta screen.id; jmp return; +
    cmp #$0003; bne +; lda.w #screen.equipments;  sta screen.id; jmp return; +
    lda.w #screen.unknown; sta screen.id
  return:
    leave
    asl; tax; rtl
  }

  function hookPartyMenu {
    lda $4c
    enter
    cmp #$0000; bne +; lda.w #screen.magicItem;   sta screen.id; jmp return; +  //Magic
    cmp #$0001; bne +; lda.w #screen.magicItem;   sta screen.id; jmp return; +  //Item
    cmp #$0002; bne +; lda.w #screen.equipment;   sta screen.id; jmp return; +
    cmp #$0003; bne +; lda.w #screen.information; sta screen.id; jmp return; +
    lda.w #screen.unknown; sta screen.id
  return:
    leave
    cmp #$0003; rtl
  }

  //A => party# (1-7)
  function party {
    enter
    //target #$074e => formation overview selected party
    //caller #$8052 => campaign and party menus
    //caller #$a570 => formation overview
    //caller #$a75e => equipment overview
    //caller #$cb3e => dragon formations
    dec; and #$0007
    pha; lda $0f,s; tax; lda $001860; tay; pla
    cpy #$074e; bne +; jsl formations.party; leave; rtl; +
    cpx #$8052; bne +; jsl      party.party; leave; rtl; +
    cpx #$a570; bne +; jsl  overviews.party; leave; rtl; +
    cpx #$a75e; bne +; jsl  overviews.party; leave; rtl; +
    cpx #$cb3e; bne +; jsl    dragons.party; leave; rtl; +
    leave; rtl

    function other {
      php; rep #$20; pha
      lda #$0006  //location of "Other" string in parties list
      jsl overviews.party
      pla; plp; rtl
    }
  }

  namespace mp {
    variable(2, screen)
    variable(2, type)

    //A => type ($00 = MP, $80 = SP)
    function setType {
      php; rep #$20; pha
      and #$0080; sta type
      lda $0c,s
      cmp #$8fb5; bne +; lda.w #screen.magicItem; sta screen; lda type; jsl magicItem.mp.setType; pla; plp; rtl; +
      cmp #$9679; bne +; lda.w #screen.status;    sta screen; lda type; jsl    status.mp.setType; pla; plp; rtl; +
      cmp #$ae65; bne +; lda.w #screen.unit;      sta screen; lda type; jsl      unit.mp.setType; pla; plp; rtl; +
      cmp #$b7bf; bne +; lda.w #screen.equipment; sta screen; lda type; jsl equipment.mp.setType; pla; plp; rtl; +
      lda.w #screen.unknown; sta screen; pla; plp; rtl
    }

    //A => current value
    function setCurrent {
      php; rep #$20; pha
      lda screen
      cmp.w #screen.magicItem; bne +; pla; jsl magicItem.mp.setCurrent; plp; rtl; +
      cmp.w #screen.status;    bne +; pla; jsl    status.mp.setCurrent; plp; rtl; +
      cmp.w #screen.unit;      bne +; pla; jsl      unit.mp.setCurrent; plp; rtl; +
      cmp.w #screen.equipment; bne +; pla; jsl equipment.mp.setCurrent; plp; rtl; +
      pla; plp; rtl
    }

    //A => maximum value
    function setMaximum {
      php; rep #$20; pha
      lda screen
      cmp.w #screen.magicItem; bne +; pla; jsl magicItem.mp.setMaximum; plp; rtl; +
      cmp.w #screen.status;    bne +; pla; jsl    status.mp.setMaximum; plp; rtl; +
      cmp.w #screen.unit;      bne +; pla; jsl      unit.mp.setMaximum; plp; rtl; +
      cmp.w #screen.equipment; bne +; pla; jsl equipment.mp.setMaximum; plp; rtl; +
      pla; plp; rtl
    }

    function setCurrentUnavailable {
      php; rep #$20; pha
      lda #$ffff; jsl setCurrent
      pla; plp; rtl
    }

    function setMaximumUnavailable {
      php; rep #$20; pha
      lda #$ffff; jsl setMaximum
      pla; plp; rtl
    }
  }

  namespace page {
    variable(2, pageIndex)
    variable(2, pageTotal)
    variable(2, counter)

    //A => current page
    function index {
      enter
      and #$00ff; sta pageIndex
      leave; rtl
    }

    //A => total number of pages
    function total {
      enter
      tilemap.setColorNormal()
      and #$00ff; sta pageTotal
      ldx #$0000; append.styleTiny()
      append.alignSkip(2); append.literal("Page ")
      lda pageIndex; append.integer1(); append.literal("/")
      lda pageTotal; append.integer1()
      lda #$0005; render.small.bpp2()
      getTileIndex(counter, 2); mul(5); add #$03f6; tax
      lda #$0005; write.bpp2()
      leave; rtl
    }

    function noItems {
      enter
      tilemap.setColorNormal()
      ldx #$0000; append.styleTiny()
      append.alignSkip(3); append.literal("No Items")
      lda #$0005; render.small.bpp2()
      getTileIndex(counter, 2); mul(5); add #$03f6; tax
      lda #$0005; write.bpp2()
      leave; rtl
    }
  }
}

codeCursor = pc()

}
