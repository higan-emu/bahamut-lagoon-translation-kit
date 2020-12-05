namespace menu {

seek(codeCursor)

//formation and equipment overview shared code
namespace overviews {
  enqueue pc
  seek($eea6d2); jsl name
  seek($eea6e6); jsl class
  seek($eea6fa); jsl level
  seek($eea628); jsl drawWindowOverview
  seek($eea26b); lda #$0056   //X cursor position (initial)
  seek($eea265); inc; nop #2  //Y cursor position (initial) (was adc #$0002 sans clc)
  seek($eea113); lda #$0056   //X cursor position (active)
  seek($eea10d); inc; nop #2  //Y cursor position (active)  (was adc #$0002 sans clc)
  dequeue pc

  allocator.bpp2()
  allocator.create(5, 6,party)
  allocator.create(7,24,name)
  allocator.create(8,24,class)
  allocator.create(3,24,level)

  //A => party
  function party {
    enter
    mul(5); tay
    lda #$0005; allocator.index(party); write.bpp2(lists.parties.bpp2)
    leave; rtl
  }

  //A => name
  function name {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; allocator.index(name); write.bpp2(names.buffer.bpp2)
    leave; rtl
  static:
    mul(8); tay
    lda #$0007; allocator.index(name); write.bpp2(lists.names.bpp2)
    leave; rtl
  }

  //A => class
  function class {
    enter
    mul(8); tay
    lda #$0008; allocator.index(class); write.bpp2(lists.classes.bpp2)
    leave; rtl
  }

  //A => level
  function level {
    enter
    and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    mul(3); tay
    lda #$0003; allocator.index(level); write.bpp2(lists.levels.bpp2)
    leave; rtl
  }
}

//formation overview
namespace formations {
  enqueue pc
  seek($ee99f8); jsl technique
  seek($ee9a05); jsl technique.level
  seek($ee9a1e); jsl technique.multiplier; nop #5
  seek($ee9a2c); jsl technique.count
  seek($eea5cd); jsl technique.blank
  dequeue pc

  allocator.bpp2()
  allocator.shared(5, 6,party)
  allocator.shared(7,24,name)
  allocator.shared(8,24,class)
  allocator.shared(3,24,level)
  allocator.create(5, 2,selectedParty)
  allocator.create(6, 5,techniqueName)
  allocator.create(3, 5,techniqueLevel)

  //A => party
  function party {
    enter
    mul(5); tay
    lda #$0005; allocator.index(selectedParty); write.bpp2(lists.parties.bpp2)
    leave; rtl
  }

  //A => technique
  function technique {
    enter
    and #$00ff
    mul(8); tay
    lda #$0006; allocator.index(techniqueName); write.bpp2(lists.techniques.bpp2)
    leave; rtl

    function blank {
      enter
      lda #$00ff  //position of "--------" in technique list
      jsl technique
      leave; rtl
    }

    //A => technique level
    function level {
      enter
      and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
      mul(3); tay
      lda #$0003; allocator.index(techniqueLevel); write.bpp2(lists.levels.bpp2)
      leave; rtl
    }

    //------
    //ee9a1e  lda #$00e7
    //ee9a21  ora $1862
    //ee9a24  sta $c400,x
    //------
    function multiplier {
      enter
      lda $001860; sub #$0002; sta $001860
      tilemap.setColorYellow()
      tilemap.write($e7)  //"x"
      leave; rtl
    }

    //A => technique count
    function count {
      enter
      tilemap.setColorYellow()
      and #$00ff; add #$0001; pha
      lda $001860; tax; pla
      ora $001862
      sta $7ec400,x
      leave; rtl
    }
  }
}

//equipment overview
namespace equipments {
  enqueue pc
  seek($eea475); jsl selectedName
  seek($eea48c); jsl selectedWeapon
  seek($eea49c); jsl selectedArmor
  seek($eea6ea); lda #$0032  //"LV" position
  seek($eea711); nop #4      //"LV" static text disable
  dequeue pc

  allocator.bpp2()
  allocator.shared(5, 6,party)
  allocator.shared(7,24,name)
  allocator.shared(8,24,class)
  allocator.shared(3,24,level)
  allocator.create(7, 2,selectedName)
  allocator.create(9, 2,selectedWeapon)
  allocator.create(9, 2,selectedArmor)

  //A => name
  function selectedName {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; allocator.index(selectedName); write.bpp2(names.buffer.bpp2)
    leave; rtl
  static:
    mul(8); tay
    lda #$0006; allocator.index(selectedName); write.bpp2(lists.names.bpp2)
    leave; rtl
  }

  //A => weapon
  function selectedWeapon {
    enter
    cmp #$0000; bne +; lda.w #128; +  //"Nothing" => "No Weapon"
    mul(9); tay
    lda #$0009; allocator.index(selectedWeapon); write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  //A => armor
  function selectedArmor {
    enter
    cmp #$0000; bne +; lda.w #129; +  //"Nothing" => "No Armor"
    mul(9); tay
    lda #$0009; allocator.index(selectedArmor); write.bpp2(lists.items.bpp2)
    leave; rtl
  }
}

codeCursor = pc()

}
