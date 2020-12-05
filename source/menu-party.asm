namespace menu {

seek(codeCursor)

namespace party {
  enqueue pc

  //shared
  seek($ee806d); jsl dragonName
  seek($ee7f3e); jsl playerName
  seek($ee7f79); jsl playerLevel
  seek($ee7f90); jml playerStatus
  seek($ee7fa3); jsl playerClass
  seek($ee7fef); jsl hp.setValue
  seek($ee7123); string.hook(mp.setTypeMP)  //"MP" text
  seek($ee7130); string.hook(mp.setTypeSP)  //"SP" text
  seek($ee716f); jsl mp.setValue
  seek($ee714f); jsl mp.setNone
  seek($ee7f5c); string.skip()  //"LV" text
  seek($ee7fd0); string.skip()  //"HP" text
  seek($ee7f31); lda #$0044     //name position
  seek($ee7f42); lda #$0054     //"LV" clear position
  seek($ee7f6c); lda #$0054     //"LV" text position
  seek($ee7f8a); lda #$00c4     //class position
  seek($ee7fe2); lda #$0144     //"HP" position
  seek($ee8000); lda #$014c     //"MP"/"SP" position
  seek($ee7df8); lda #$0016     //X cursor offset (command menu)
  seek($ee7df1); adc #$003d     //Y cursor offset (command menu)
  seek($ee7a7e); lda #$008e     //X cursor offset (player menu)
  seek($ee7a78); adc #$0021     //Y cursor offset (player menu)

  seek($ee671c); db $78
  seek($ee6720); db $78
  seek($ee6724); db $78
  seek($ee6728); db $78

  //campaign
  seek($ee8339); string.hook(formation)
  seek($ee834c); string.hook(dragons)
  seek($ee8379); string.hook(information)
  seek($ee838e); string.hook(equipment)
  seek($ee839f); string.hook(viewMap)
  seek($ee83b0); string.hook(sortie)
  seek($ee83c3); jsl sideQuestSetup; nop #8
  seek($ee7bd7); jml sideQuestCheck; nop
  seek($ee83d5); string.hook(sideQuest)
  seek($ee835f); string.hook(autoFormation)
  seek($ee7b9b); string.hook(formationSet)  //first line
  seek($ee7bb6); string.skip()              //second line

  //sortie
  seek($ee81b5); string.hook(magic)
  seek($ee81c6); string.hook(item)
  seek($ee81d9); string.hook(equipment)
  seek($ee81ea); string.hook(information)

  //"Chapter"#
  seek($ee8287); string.skip()      //label
  seek($ee82a4); jsl chapterNumber  //value
  seek($ee829a); lda #$06c6         //position

  //"Side Quest"#
  seek($ee8262); string.skip()        //label
  seek($ee8281); jsl sideQuestNumber  //value
  seek($ee8273); lda #$06c6           //position

  //"Turn"#
  seek($ee81ff); string.skip()  //label
  seek($ee82b9); jsl turn       //value
  seek($ee82af); lda #$0746     //position

  //"Piro"#
  seek($ee821a); string.skip()  //label
  seek($ee82d2); jsl piro       //value
  seek($ee82bd); lda #$07c6     //position

  //"Time"
  seek($ee823b); string.skip()        //time field separators
  seek($ee82dc); jsl time; jmp $8312  //value
  seek($ee82d6); lda #$0846           //position

  dequeue pc

  allocator.bpp4()
  allocator.create(7, 8,name)
  allocator.create(3, 8,level)
  allocator.create(8, 8,class)
  allocator.create(5, 8,hp)
  allocator.create(5, 8,mp)
  allocator.bpp2()
  allocator.create(8,11,menu)
  allocator.create(5, 2,party)
  allocator.create(8, 2,dragon)

  inline static(define name) {
    function {name} {
      enter
      ldy.w #strings.bpp2.{name}
      lda #$0008; allocator.index(menu)
      write.bpp2(lists.strings.bpp2)
      leave; rtl
    }
  }
  static(formation)
  static(dragons)
  static(information)
  static(equipment)
  static(viewMap)
  static(sortie)
  static(sideQuest)
  static(autoFormation)
  static(formationSet)
  static(magic)
  static(item)

  //------
  //ee83bf  lda $7e801c  ;load chapter#
  //ee83c3  cmp #$0006   ;side quests are available from chapter 6 onward
  //ee83c6  bcc $83e2    ;if at chapter 5 or earlier, don't draw "Side Quest" label
  //ee83c8  lda #$2000   ;draw "Side Quest" using white text palette
  //ee83cb  sta $001862  ;store attributes value
  //......               ;draw "Side Quest" label
  //ee83e2  plb
  //ee83e3  plp
  //ee83e4  rtl
  //------
  //A => chapter#
  function sideQuestSetup {
    php; rep #$20; pha
    cmp #$0006; bcc +  //prologue + chapters 1-5 lack side quests
    cmp #$001c; bcs +  //side quests themselves lack side quests (debugger fix)
    lda #$2000; sta $001862; pla; plp; rtl
  +;lda #$2400; sta $001862; pla; plp; rtl
  }

  //------
  //ee7bd3  lda $7e801c  ;load chapter#
  //ee7bd7  cmp #$0006   ;side quests are available from chapter 6 onward
  //ee7bda  bcs $7be5    ;if at chapter 6 or later, enter side quest menu
  //------
  //A => chapter#
  function sideQuestCheck {
    php; rep #$20; pha
    cmp #$0006; bcc +      //prologue + chapters 1-5 lack side quests
    cmp #$001c; bcs +      //side quests themselves lack side quests (debugger fix)
    pla; plp; jml $ee7be5  //enter side quest menu
  +;pla; plp; jml $ee7bdc  //do not enter side quest menu
  }

  //A => party
  function party {
    enter
    tilemap.setColorHeader()
    and #$0007; mul(5); tay
    lda #$0005; allocator.index(party); write.bpp2(lists.parties.bpp2)
    tilemap.setColorNormal()
    leave; rtl
  }

  //A => dragon
  function dragonName {
    enter
    getDragonName(); mul(8); tay
    lda #$0008; allocator.index(dragon); write.bpp2(names.buffer.bpp2)
    leave; rtl
  }

  //A => chapter#
  function chapterNumber {
    enter
    and #$001f; mul(8); tay
    lda #$0008; ldx #$0010
    write.bpp2(lists.chapters.bpp2)
    leave; rtl
  }

  //A => side quest#
  function sideQuestNumber {
    php; rep #$30; pha
    add #$001b; jsl chapterNumber
    pla; plp; rtl
  }

  //A => turn#
  function turn {
    enter; ldx #$0000
    append.literal("Turn")
    append.alignLeft()
    append.alignSkip(23)
    append.integer5()
    lda #$0006; render.small.bpp2()
    ldx #$0018; jsl write.bpp2
    leave; rtl
  }

  //$7e8016-$7e8018 => piro
  function piro {
    enter; ldx #$0000
    lda $7e8018; and #$00ff; tay
    lda $7e8016
    append.literal("Piro")
    append.alignLeft()
    append.alignSkip(23)
    append.integer10()
    lda #$0009; render.small.bpp2()
    ldx #$001e; jsl write.bpp2
    leave; rtl
  }

  //$7e3bd0 => hour
  //$7e3bd1 => minute
  //$7e2bd2 => second
  function time {
    enter; ldx #$0000
    append.literal("Time")
    append.alignLeft()
    append.alignSkip(23)
    lda $7e3bd0; and #$00ff
    append.integer02()
    append.literal(":")
    lda $7e3bd1; and #$00ff
    append.integer02()
    append.literal(":")
    lda $7e3bd2; and #$00ff
    append.integer02()
    lda #$0009; render.small.bpp2()
    ldx #$0027; jsl write.bpp2
    leave; rtl
  }

  //A => player name
  function playerName {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; allocator.index(name); write.bpp4(names.buffer.bpp4)
    leave; rtl
  static:
    mul(8); tay
    lda #$0007; allocator.index(name); write.bpp4(lists.names.bpp4)
    leave; rtl
  }

  //A => player level
  function playerLevel {
    enter
    and #$00ff; mul(3); tay
    lda #$0003; allocator.index(level); write.bpp4(lists.levels.bpp4)
    leave; rtl
  }

  function playerStatus {
    ldy #$0008; lda [$44],y; and.w #status.ailments.mask; beq +; jml $ee7fb3; +
    ldy #$000a; lda [$44],y; and.w #status.enchants.mask; beq +; jml $ee7fb3; +
    jml $ee7f9c
  }

  //A => player class
  function playerClass {
    enter
    and #$00ff; mul(8); tay
    lda #$0008; allocator.index(class); write.bpp4(lists.classes.bpp4)
    leave; rtl
  }

  namespace hp {
    function setValue {
      enter
      ldx #$0000; append.hpValue()
      lda #$0005; render.small.bpp4()
      allocator.index(hp); write.bpp4()
      leave; rtl
    }
  }

  namespace mp {
    variable(2, type)  //0 = MP, 1 = SP
    variable(2, value)
    variable(2, counter)

    setTypeMP:; php; rep #$20; pha; lda #$0000; sta type; pla; plp; rtl
    setTypeSP:; php; rep #$20; pha; lda #$0001; sta type; pla; plp; rtl

    function setValue {
      enter
      sta value; ldx #$0000
      lda type
      cmp #$0000; bne +; lda value; append.mpValue(); bra render; +
      cmp #$0001; bne +; lda value; append.spValue(); bra render; +
      leave; rtl
    render:
      lda #$0005; render.small.bpp4()
      allocator.index(mp); write.bpp4()
      leave; rtl
    }

    function setNone {
      php; rep #$30
      lda $001860; add #$0004; sta $001860
      lda #$ffff; jsl setValue
      plp; rtl
    }
  }
}

codeCursor = pc()

}
