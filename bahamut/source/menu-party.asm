namespace menu {

seek(codeCursor)

namespace party {
  enqueue pc

//seek($c11877); sbc #$0080  //large sprites X offset

  //shared
  seek($ee806d); jsl dragonName
  seek($ee7f3e); jsl playerName
  seek($ee7f79); jsl playerLevel
  seek($ee7fa3); jsl playerClass
  seek($ee7fef); jsl hp.setValue
  seek($ee7123); string.hook(mp.setTypeMP)  //"MP" text
  seek($ee7130); string.hook(mp.setTypeSP)  //"SP" text
  seek($ee716f); jsl mp.setValue
  seek($ee714f); jsl mp.setNone
  seek($ee7f5c); string.skip()  //"LV" text
  seek($ee7fd0); string.skip()  //"HP" text
  seek($ee7f6c); lda #$0050     //"LV" position
  seek($ee7fe2); lda #$0140     //"HP" position
  seek($ee8000); lda #$0148     //"MP"/"SP" position
  seek($ee7df8); lda #$0016     //X cursor offset (command menu)
  seek($ee7df1); adc #$003d     //Y cursor offset (command menu)
  seek($ee7a7e); lda #$007e     //X cursor offset (player menu)
  seek($ee7a78); adc #$0021     //Y cursor offset (player menu)

  //campaign
  seek($ee8339); string.hook(formation)
  seek($ee834c); string.hook(dragons)
  seek($ee8379); string.hook(information)
  seek($ee838e); string.hook(equipment)
  seek($ee839f); string.hook(viewMap)
  seek($ee83b0); string.hook(sortie)
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
  seek($ee829a); lda #$06c4         //position

  //"Side Quest"#
  seek($ee8262); string.skip()        //label
  seek($ee8281); jsl sideQuestNumber  //value
  seek($ee8273); lda #$06c4           //position

  //"Turn"#
  seek($ee81ff); string.skip()  //label
  seek($ee82b9); jsl turn       //value
  seek($ee82af); lda #$0744     //position

  //"Piro"#
  seek($ee821a); string.skip()  //label
  seek($ee82d2); jsl piro       //value
  seek($ee82bd); lda #$07c4     //position

  //"Time"
  seek($ee823b); string.skip()        //time field separators
  seek($ee82dc); jsl time; jmp $8312  //value
  seek($ee82d6); lda #$0844           //position

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
      ldy.w #strings.menu.{name}
      lda #$0008; allocator.index(menu)
      write.bpp2(lists.menu.bpp2)
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

  //A = party
  function party {
    enter
    and #$0007; mul(5); tay
    lda #$0005; allocator.index(party); write.bpp2(lists.parties.bpp2)
    leave; rtl
  }

  //A = dragon
  function dragonName {
    enter
    getDragonName(); mul(8); tay
    lda #$0008; allocator.index(dragon); write.bpp2(names.buffer.bpp2)
    leave; rtl
  }

  //A = chapter#
  function chapterNumber {
    enter
    and #$001f; mul(8); tay
    lda #$0008; ldx #$0010
    write.bpp2(lists.chapters.bpp2)
    leave; rtl
  }

  //A = side quest#
  function sideQuestNumber {
    php; rep #$30; pha
    add #$001b; jsl chapterNumber
    pla; plp; rtl
  }

  //A = turn#
  function turn {
    enter
    and #$00ff
    ldx #$0000; append.turn()
    lda #$0006; render.small.bpp2()
    ldx #$0018; jsl write.bpp2
    leave; rtl
  }

  //$7e8016-$7e8018 = piro
  function piro {
    enter
    lda $7e8018; tay
    lda $7e8016
    ldx #$0000; append.piro()
    lda #$0009; render.small.bpp2()
    ldx #$001e; jsl write.bpp2
    leave; rtl
  }

  //$7e3bd0 = hour
  //$7e3bd1 = minute
  //$7e2bd2 = second
  function time {
    enter
    lda $7e3bd2; and #$00ff; tay
    lda $7e3bd0
    ldx #$0000; append.time()
    lda #$0009; render.small.bpp2()
    ldx #$0027; jsl write.bpp2
    leave; rtl
  }

  //A = player name
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

  //A = player level
  function playerLevel {
    enter
    and #$00ff; mul(3); tay
    lda #$0003; allocator.index(level); write.bpp4(lists.levels.bpp4)
    leave; rtl
  }

  //A = player class
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
