namespace menu {

seek(codeCursor)

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
  allocator.create(5, 6,party)
  allocator.create(7, 2,page)
  allocator.create(7,24,name)
  allocator.create(8,24,class)
  allocator.create(3,24,level)
  allocator.create(7, 2,selectedName)
  allocator.create(9, 2,selectedWeapon)
  allocator.create(9, 2,selectedArmor)

  //A = party
  function party {
    enter
    mul(5); tay
    lda #$0005; allocator.index(party); write.bpp2(lists.parties.bpp2)
    leave; rtl
  }

  function page {
    variable(2, pageIndex)
    variable(2, pageTotal)

    function index {
      sta pageIndex
      rtl
    }

    function total {
      enter
      sta pageTotal
      ldx #$0000; append.alignLeft(2); append.literal("Page"); append.alignRight(31)
      lda pageIndex; append.integer_2(); append.literal("/")
      lda pageTotal; append.integer_2()
      lda #$0007; render.small.bpp2()
      allocator.index(page); jsl write.bpp2
      leave; rtl
    }
  }

  //A = name
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

  //A = class
  function class {
    enter
    mul(8); tay
    lda #$0008; allocator.index(class); write.bpp2(lists.classes.bpp2)
    leave; rtl
  }

  //A = level
  function level {
    enter
    and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    mul(3); tay
    lda #$0003; allocator.index(level); write.bpp2(lists.levels.bpp2)
    leave; rtl
  }

  //A = name
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

  //A = weapon
  function selectedWeapon {
    enter
    cmp #$0000; bne +; lda.w #128; +  //"Nothing" => "No Weapon"
    mul(9); tay
    lda #$0009; allocator.index(selectedWeapon); write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  //A = armor
  function selectedArmor {
    enter
    cmp #$0000; bne +; lda.w #129; +  //"Nothing" => "No Armor"
    mul(9); tay
    lda #$0009; allocator.index(selectedArmor); write.bpp2(lists.items.bpp2)
    leave; rtl
  }
}

namespace equipment {
  enqueue pc
  seek($eeb6e7); jsl name
  seek($eeb721); jsl level
  seek($eeb73e); jsl class
  seek($eeb786); jsl hp.setCurrent
  seek($eeb7a3); jsl hp.setMaximum
  seek($eeb7cd); string.hook(attack.label)
  seek($eeb800); string.hook(defense.label)
  seek($eeb833); string.hook(speed.label)
  seek($eeb866); string.hook(magic.label)
  seek($eeb7ef); jsl attack.setFromValue
  seek($eeb822); jsl defense.setFromValue
  seek($eeb855); jsl speed.setFromValue
  seek($eeb888); jsl magic.setFromValue
  seek($eeb523); jsl shared.setToValue
  seek($eeb8a9); jsl shared.setToUnchanged
  seek($eeb8ea); jsl equippedWeapon
  seek($eeb926); jsl equippedArmor
  seek($eeb967); jsl drawWindowBG3
  seek($eeb9a5); jsl item
  seek($eeb995); jsl count
  seek($eeb705); string.skip()  //"LV" text
  seek($eeb715); lda #$0252     //"LV" position
  seek($eeb768); string.skip()  //"HP" text
  seek($eeb790); string.skip()  //"HP" separator
  seek($eeb797); lda #$0342     //"HP" position
  seek($eeb4cc); nop #12        //disable static "---" text
  seek($eeb515); nop #12        //disable static "   " text
  seek($eeb8ce); string.skip()  //"Weapon" text (disabled for space reasons)
  seek($eeb908); string.skip()  //"Armor"  text (disabled for space reasons)
  seek($eeb8de); lda #$0742     //weapon name position
  seek($eeb91a); lda #$07c2     //armor name position
  seek($eeb95d); ldx #$000f     //item list window width (increase by 1)
  seek($eeb946); ldx #$000f     //item list window clear width
  seek($eeb987); lda #$0016     //item quantity position
  seek($eeb2e2); lda #$0086     //weapon/armor X cursor position (initial)
  seek($eeb2db); adc #$009d     //weapon/armor Y cursor position (initial)
  seek($eeb3a2); lda #$0086     //weapon/armor X cursor position (active)
  seek($eeb39b); adc #$009d     //weapon/armor Y cursor position (active)
  dequeue pc

  allocator.bpp4()
  allocator.create( 7, 1,name)
  allocator.create( 3, 1,level)
  allocator.create( 8, 1,class)
  allocator.create(11, 1,hpRange)
  allocator.create(11, 1,mpRange)
  allocator.create( 9, 2,equippedWeapon)
  allocator.create( 9, 2,equippedArmor)
  allocator.create( 5, 1,attackLabel)
  allocator.create( 5, 1,defenseLabel)
  allocator.create( 5, 1,speedLabel)
  allocator.create( 5, 1,magicLabel)
  allocator.create( 6, 2,attackChange)
  allocator.create( 6, 2,defenseChange)
  allocator.create( 6, 2,speedChange)
  allocator.create( 6, 2,magicChange)
  allocator.bpp2()
  allocator.create( 9,24,item)
  allocator.create( 3,24,count)

  //A = player name
  function name {
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

  //A = level
  function level {
    enter
    and #$00ff; mul(3); tay
    lda #$0003; allocator.index(level); write.bpp4(lists.levels.bpp4)
    leave; rtl
  }

  //A = class
  function class {
    enter
    and #$00ff; mul(8); tay
    lda #$0008; allocator.index(class); write.bpp4(lists.classes.bpp4)
    leave; rtl
  }

  namespace hp {
    variable(2, current)

    //A = current HP
    function setCurrent {
      enter
      sta current
      leave; rtl
    }

    //A = maximum HP
    function setMaximum {
      enter
      tay; lda current
      ldx #$0000; append.hpRange()
      lda #$000b; render.small.bpp4()
      allocator.index(hpRange); write.bpp4()
      leave; rtl
    }
  }

  namespace mp {
    variable(2, type)
    variable(2, current)
    variable(2, maximum)

    //A = type
    function setType {
      enter
      sta type
      leave; rtl
    }

    //A = current MP
    function setCurrent {
      enter
      sta current
      leave; rtl
    }

    //A = maximum MP
    function setMaximum {
      enter
      sta maximum
      jsl render
      leave; rtl
    }

    function render {
      enter
      ldx #$0000; lda type
      cmp #$0000; bne +; lda maximum; tay; lda current; append.spRange(); +
      cmp #$0080; bne +; lda maximum; tay; lda current; append.mpRange(); +
      lda #$000b; render.small.bpp4()
      allocator.index(mpRange)
      lda #$000b; write.bpp4()
      leave; rtl
    }
  }

  namespace shared {
    function setToValue {
      enter; ldb #$00; ldx $1860
      cpx #$14fa; bne +; jsl  attack.setToValue; +
      cpx #$157a; bne +; jsl defense.setToValue; +
      cpx #$15fa; bne +; jsl   speed.setToValue; +
      cpx #$167a; bne +; jsl   magic.setToValue; +
      leave; rtl
    }

    function setToUnchanged {
      enter; ldb #$00; ldx $1860
      cpx #$14f6; bne +; jsl  attack.setToUnchanged; +
      cpx #$1576; bne +; jsl defense.setToUnchanged; +
      cpx #$15f6; bne +; jsl   speed.setToUnchanged; +
      cpx #$1676; bne +; jsl   magic.setToUnchanged; +
      leave; rtl
    }
  }

  macro label(define name) {
    enter
    ldy.w #strings.bpp4.{name}
    allocator.index({name}Label)
    lda #$0005; write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  //original game used two palettes:
  //palette 1 for white text (when stats would increase)
  //palette 2 for  gray text (when stats would decrease)
  //translation patch encodes two sets of stats tiles for palette 0 instead:
  //colors 13,14,15 => yellow text (when stats will increase)
  //colors  5, 6, 3 =>   gray text (when stats will decrease)
  //colors  1, 2, 3 =>  white text (for the stat base values)
  //this allows adding yellow text to better indicate stat increases.
  macro value(define name, variable mapAddress) {
    enter

    lda #$2000; sta $001862         //always use palette 0 instead
    lda.w #mapAddress; sta $001860  //manually set tilemap write position

    //determine whether to write "###" (normal) or "###/###" (change)
    lda changed; jeq normal{#}
    lda from; cmp to; jeq normal{#}
    jmp change{#}

  normal{#}:
    ldx #$0000
    lda from; append.integer_3()
    lda #$0006; render.small.bpp4()
    allocator.index({name}Change); write.bpp4()
    leave; rtl

  change{#}:
    ldx #$0000
    lda from; append.integer_3()
    append.literal("/")
    lda #$0003; render.small.bpp4()
    allocator.index({name}Change); write.bpp4()
    lda from; cmp to; jcs decrease{#}

  //write change# in yellow text
  increase{#}:
    lda to; mul(3); tay
    txa; add #$0003; tax
    lda #$0003; write.bpp4(lists.stats.bpi4)
    leave; rtl

  //write change# in gray text
  decrease{#}:
    lda to; mul(3); tay
    txa; add #$0003; tax
    lda #$0003; write.bpp4(lists.stats.bpd4)
    leave; rtl
  }

  namespace attack {
    variable(2, from)
    variable(2, to)
    variable(2, changed)

    label:;          label(attack)
    value:;          value(attack,$14ec)
    setFromValue:;   enter; sta from; leave; rtl
    setToValue:;     enter; sta to; lda #$0001; sta changed; jsl value; leave; rtl
    setToUnchanged:; enter; lda #$0000; sta changed; jsl value; leave; rtl
  }

  namespace defense {
    variable(2, from)
    variable(2, to)
    variable(2, changed)

    label:;          label(defense)
    value:;          value(defense,$156c)
    setFromValue:;   enter; sta from; leave; rtl
    setToValue:;     enter; sta to; lda #$0001; sta changed; jsl value; leave; rtl
    setToUnchanged:; enter; lda #$0000; sta changed; jsl value; leave; rtl
  }

  namespace speed {
    variable(2, from)
    variable(2, to)
    variable(2, changed)

    label:;          label(speed)
    value:;          value(speed,$15ec)
    setFromValue:;   enter; sta from; leave; rtl
    setToValue:;     enter; sta to; lda #$0001; sta changed; jsl value; leave; rtl
    setToUnchanged:; enter; lda #$0000; sta changed; jsl value; leave; rtl
  }

  namespace magic {
    variable(2, from)
    variable(2, to)
    variable(2, changed)

    label:;          label(magic)
    value:;          value(magic,$166c)
    setFromValue:;   enter; sta from; leave; rtl
    setToValue:;     enter; sta to; lda #$0001; sta changed; jsl value; leave; rtl
    setToUnchanged:; enter; lda #$0000; sta changed; jsl value; leave; rtl
  }

  //A = currently equipped weapon
  function equippedWeapon {
    enter
    and #$00ff; bne +; lda.w #128; +  //"Nothing" => "No Weapon"
    mul(9); tay
    lda #$0009; allocator.index(equippedWeapon); write.bpp4(lists.items.bpp4)
    leave; rtl
  }

  //A = currently equipped armor
  function equippedArmor {
    enter
    and #$00ff; bne +; lda.w #129; +  //"Nothing" => "No Armor"
    mul(9); tay
    lda #$0009; allocator.index(equippedArmor); write.bpp4(lists.items.bpp4)
    leave; rtl
  }

  //A = list item#
  function item {
    enter
    and #$007f; mul(9); tay
    lda #$0009; allocator.index(item); write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  //A = list item# count
  function count {
    enter
    and #$00ff; mul(3); tay
    lda #$0003; allocator.index(count); write.bpp2(lists.counts.bpp2)
    leave; rtl
  }
}

codeCursor = pc()

}
