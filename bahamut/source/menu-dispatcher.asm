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
  seek($eea6d2); jsl name
  seek($eea6e6); jsl class
  seek($eea6fa); jsl level

  //unit and status screens
  seek($ee6fe4); string.hook(mp.setType)  //"MP"
  seek($ee6ff1); string.hook(mp.setType)  //"SP"
  seek($ee705a); jsl mp.setCurrent
  seek($ee707f); jsl mp.setMaximum
  seek($ee701c); jsl mp.setCurrentUnavailable
  seek($ee7039); jsl mp.setMaximumUnavailable

  //formations and equipments screens
  seek($eea628); jsl drawWindowOverview
  seek($eea26b); lda #$0056   //X cursor position (initial)
  seek($eea265); inc; nop #2  //Y cursor position (initial) (was adc #$0002 sans clc)
  seek($eea113); lda #$0056   //X cursor position (active)
  seek($eea10d); inc; nop #2  //Y cursor position (active)  (was adc #$0002 sans clc)

  //formations, information, equipments and shop screens
  seek($eef02b); jsl page.index  //cache the page index
  seek($eef01b); jsl page.total  //render the full "Page index/total" string

  //shared positions
  seek($ee700f); adc #$0000  //"MP"- position (magic, item, unit screens)
  seek($ee702c); adc #$0000  //"MP"/ position (magic, item, unit screens)
  seek($ee7044); adc #$0000  //"SP"# position (magic, item, unit screens)

  //shared strings
  seek($ee6f6c); string.skip()  //"Party" static text (used by several screens)

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

  //A = party#
  function party {
    enter; pha
    //#$8052 = main menu
    //#$a570 = player formations
    //#$a75e = equipment overview
    lda $0f,s
    cmp #$8052; bne +; pla; dec; jsl   party.party; leave; rtl; +
    cmp #$cb3e; bne +; pla; dec; jsl dragons.party; leave; rtl; +
    lda screen.id
    cmp.w #screen.formations; bne +; pla; dec; jsl formations.party; leave; rtl; +
    cmp.w #screen.equipments; bne +; pla; dec; jsl equipments.party; leave; rtl; +
    pla; leave; rtl

    function other {
      enter
      lda #$0007  //location of "Other" string (+1) in parties list
      jsl party
      leave; rtl
    }
  }

  //A = name
  function name {
    enter
    pha; lda screen.id
    cmp.w #screen.formations; bne +; pla; jsl formations.name; leave; rtl; +
    cmp.w #screen.equipments; bne +; pla; jsl equipments.name; leave; rtl; +
    pla; leave; rtl
  }

  //A = class
  function class {
    enter
    pha; lda screen.id
    cmp.w #screen.formations; bne +; pla; jsl formations.class; leave; rtl; +
    cmp.w #screen.equipments; bne +; pla; jsl equipments.class; leave; rtl; +
    pla; leave; rtl
  }

  //A = level
  function level {
    enter
    pha; lda screen.id
    cmp.w #screen.formations; bne +; pla; jsl formations.level; leave; rtl; +
    cmp.w #screen.equipments; bne +; pla; jsl equipments.level; leave; rtl; +
    pla; leave; rtl
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
    //A => current page
    function index {
      php; rep #$20; pha
      lda $001860
      cmp #$075a; bne +; lda $01,s; jsl shop.page.index; pla; plp; rtl; +
      cmp #$06f4; beq +; pla; plp; rtl; +
      lda screen.id
      cmp.w #screen.formations;  bne +; lda $01,s; jsl  formations.page.index; pla; plp; rtl; +
      cmp.w #screen.information; bne +; lda $01,s; jsl information.page.index; pla; plp; rtl; +
      cmp.w #screen.equipments;  bne +; lda $01,s; jsl  equipments.page.index; pla; plp; rtl; +
      pla; plp; rtl
    }

    //A => total number of pages
    function total {
      php; rep #$20; pha
      lda $001860
      cmp #$0754; bne +; lda $01,s; jsl shop.page.total; pla; plp; rtl; +
      cmp #$06ee; beq +; pla; plp; rtl; +
      lda screen.id
      cmp.w #screen.formations;  bne +; lda $01,s; jsl  formations.page.total; pla; plp; rtl; +
      cmp.w #screen.information; bne +; lda $01,s; jsl information.page.total; pla; plp; rtl; +
      cmp.w #screen.equipments;  bne +; lda $01,s; jsl  equipments.page.total; pla; plp; rtl; +
      pla; plp; rtl
    }
  }
}

codeCursor = pc()

}
