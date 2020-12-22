namespace menu {

seek(codeCursor)

namespace status {
  enqueue pc
  seek($ee9532); jsl name
  seek($ee957b); jsl playerClass
  seek($ee9617); jsl dragonClass
  seek($ee956a); jsl level  //player
  seek($ee95eb); jsl level  //dragon
  seek($ee99a1); jsl techniqueName
  seek($ee99ae); jsl techniqueLevel
  seek($ee9647); jsl hp.setCurrent
  seek($ee9665); jsl hp.setMaximum
  seek($ee96b3); jsl experience.value
  seek($ee96fe); jsl nextLevel.value
  seek($ee97c1); jsl attack.setStat
  seek($ee98d4); jsl attack.setBase
  seek($ee97fb); jsl defense.setStat
  seek($ee98bf); jsl defense.setBase
  seek($ee9835); jsl speed.setStat
  seek($ee98aa); jsl speed.setBase
  seek($ee986f); jsl magic.setStat
  seek($ee9895); jsl magic.setBase
  seek($ee9751); jsl weapon
  seek($ee9781); jsl armor
  seek($ee9948); jsl techniqueMenuName
  seek($ee995a); jsl techniqueMenuLevel
  seek($ee9bc0); jsl drawWindowBG3
  seek($ee9c1e); jsl techniqueItem.name
  seek($ee9c2c); jsl techniqueItem.level
  seek($ee9c3c); jsl techniqueItem.cost
  seek($ee9628); string.skip()   //"HP" text
  seek($ee9651); string.skip()   //"HP" separator
  seek($ee9687); string.hook(experience.label)
  seek($ee96d0); string.hook(nextLevel.label)
  seek($ee97a5); string.hook(attack.label)
  seek($ee97df); string.hook(defense.label)
  seek($ee9819); string.hook(speed.label)
  seek($ee9853); string.hook(magic.label)
  seek($ee98da); string.skip()  //"Attack","Defense","Speed","Magic" "( )" text
  seek($ee9734); string.skip()  //"Weapon" text (not printed for space reasons)
  seek($ee9762); string.skip()  //"Armor"  text (not printed for space reasons)
  seek($ee954d); string.skip()  //"LV" text (player)
  seek($ee95ce); string.skip()  //"LV" text (dragon)
  seek($ee955d); lda #$0090  //"LV" position (player)
  seek($ee95de); lda #$0090  //"LV" position (dragon)
  seek($ee95f6); lda #$0100  //"Class" position (dragon)
  seek($ee9658); lda #$0200  //"HP" position
  seek($ee969b); lda #$030a  //"Experience"# position
  seek($ee96e6); lda #$038a  //"Next Level"# position
  seek($ee98cc); lda #$004a  //"Attack"#  position (player)
  seek($ee98b7); lda #$00ca  //"Defense"# position
  seek($ee98a2); lda #$014a  //"Speed"#   position
  seek($ee988d); lda #$01ca  //"Magic"#   position
  seek($ee97b9); lda #$004a  //"Attack"#  position (dragon)
  seek($ee97f3); lda #$00ca  //"Defense"# position
  seek($ee982d); lda #$014a  //"Speed"#   position
  seek($ee9867); lda #$01ca  //"Magic"#   position
  seek($ee9744); lda #$0700  //"Weapon" position
  seek($ee9774); lda #$0780  //"Armor"  position
  seek($ee9c30); lda #$009c  //"Technique Cost" position
  seek($ee93d2); lda #$0016  //X cursor position (menu)
  seek($ee93e4); adc #$0001  //Y cursor position
  seek($ee93b4); lda #$0016  //X cursor position (list)
  seek($ee93c6); adc #$0049  //Y cursor position

  //the technique menu levels would overlap sprites in its previous position ($60)
  seek($ee6780); db $78  //X player sprite position
  dequeue pc

  allocator.bpp4()
  allocator.create( 8,1,name)
  allocator.create( 3,1,level)
  allocator.create( 8,1,class)
  allocator.create( 6,2,techniqueName)
  allocator.create( 3,2,techniqueLevel)
  allocator.create(11,1,hpRange)
  allocator.create(11,1,mpRange)
  allocator.create( 5,1,experienceLabel)
  allocator.create( 6,1,experienceValue)
  allocator.create( 5,1,nextLevelLabel)
  allocator.create( 6,1,nextLevelValue)
  allocator.create( 5,1,attackLabel)
  allocator.create( 6,1,attackValue)
  allocator.create( 5,1,defenseLabel)
  allocator.create( 6,1,defenseValue)
  allocator.create( 5,1,speedLabel)
  allocator.create( 6,1,speedValue)
  allocator.create( 5,1,magicLabel)
  allocator.create( 6,1,magicValue)
  allocator.create( 9,1,weapon)
  allocator.create( 9,1,armor)
  allocator.bpp2()
  allocator.create( 6,5,techniqueMenuName)
  allocator.create( 3,5,techniqueMenuLevel)
  allocator.create(8,24,techniqueItemName)
  allocator.create(3,24,techniqueItemLevel)
  allocator.create(3,24,techniqueItemCost)

  //disambiguation (dragons do not have base stat values)
  namespace character {
    variable(2, type)
    constant player = 0
    constant dragon = 1
  }

  //A => player or dragon name
  function name {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0008; allocator.index(name); write.bpp4(names.buffer.bpp4)
    leave; rtl
  static:
    mul(8); tay
    lda #$0008; allocator.index(name); write.bpp4(lists.names.bpp4)
    leave; rtl
  }

  //A => level
  function level {
    enter
    mul(3); tay
    lda #$0003; allocator.index(level); write.bpp4(lists.levels.bpp4)
    leave; rtl
  }

  //A => player class name
  function playerClass {
    enter
    and #$00ff; mul(8); tay
    lda #$0008; allocator.index(class); write.bpp4(lists.classes.bpp4)
    lda.w #character.player; sta character.type
    leave; rtl
  }

  //A => dragon class name
  function dragonClass {
    enter
    and #$00ff; mul(8); tay
    lda #$0008; allocator.index(class); write.bpp4(lists.dragons.bpp4)
    lda.w #character.dragon; sta character.type
    leave; rtl
  }

  //A => technique name
  function techniqueName {
    enter
    and #$00ff; mul(8); tay
    lda #$0006; allocator.index(techniqueName); write.bpp4(lists.techniques.bpp4)
    leave; rtl
  }

  //A => technique level
  function techniqueLevel {
    enter
    and #$00ff; mul(3); tay
    tilemap.incrementAddress(4)
    lda #$0003; allocator.index(techniqueLevel); write.bpp4(lists.levels.bpp4)
    leave; rtl
  }

  namespace hp {
    variable(2, current)

    //A => current HP
    function setCurrent {
      enter
      sta current
      leave; rtl
    }

    //A => maximum HP
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

    //A => type
    function setType {
      enter
      sta type
      leave; rtl
    }

    //force type to MP for enemies
    function setTypeMP {
      enter
      lda #$0080; sta type
      leave; rtl
    }

    //A => current MP
    function setCurrent {
      enter
      sta current
      leave; rtl
    }

    //A => maximum MP
    function setMaximum {
      enter
      sta maximum
      jsl render
      leave; rtl
    }

    function render {
      enter
      lda type; ldx #$0000
      cmp #$0000; bne +; lda maximum; tay; lda current; append.spRange(); +
      cmp #$0080; bne +; lda maximum; tay; lda current; append.mpRange(); +
      lda #$000b; render.small.bpp4()
      allocator.index(mpRange); write.bpp4()
      leave; rtl
    }
  }

  macro writeLabel(define name) {
    enter
    ldy.w #strings.bpp4.{name}
    allocator.index({name}Label)
    lda #$0005; write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  namespace experience {
    function label {
      writeLabel(experience)
    }

    function value {
      enter
      lda $1e; tay; lda $1c
      ldx #$0000; append.integer_8()
      lda #$0006; render.small.bpp4()
      allocator.index(experienceValue); write.bpp4()
      leave; rtl
    }
  }

  namespace nextLevel {
    function label {
      writeLabel(nextLevel)
    }

    function value {
      enter
      lda $1e; tay; lda $1c
      ldx #$0000; append.integer_8()
      lda #$0006; render.small.bpp4()
      allocator.index(nextLevelValue); write.bpp4()
      leave; rtl
    }
  }

  macro writePlayerValue(define name) {
    ldx #$0000
    lda stat; append.integer_3(); append.literal("/")
    lda #$0003; render.small.bpp4()
    allocator.index({name}Value); write.bpp4()
    lda base; mul(4); tay
    txa; add #$0003; tax
    lda #$0003; write.bpp4(lists.stats.bpd4)
  }

  macro writeDragonValue(define name) {
    ldx #$0000
    lda stat; append.integer_3()
    lda #$0003; render.small.bpp4()
    allocator.index({name}Value); write.bpp4()
  }

  macro setStat(define name) {
    enter
    sta stat
    lda character.type
    cmp.w #character.dragon; beq +; leave; rtl
  +;writeDragonValue({name})
    leave; rtl
  }

  macro setBase(define name) {
    enter
    sta base
    lda character.type
    cmp.w #character.player; beq +; leave; rtl
  +;writePlayerValue({name})
    leave; rtl
  }

  namespace attack {
    variable(2, stat)
    variable(2, base)

    label:;   writeLabel(attack)
    setStat:; setStat(attack)
    setBase:; setBase(attack)
  }

  namespace defense {
    variable(2, stat)
    variable(2, base)

    label:;   writeLabel(defense)
    setStat:; setStat(defense)
    setBase:; setBase(defense)
  }

  namespace speed {
    variable(2, stat)
    variable(2, base)

    label:;   writeLabel(speed)
    setStat:; setStat(speed)
    setBase:; setBase(speed)
  }

  namespace magic {
    variable(2, stat)
    variable(2, base)

    label:;   writeLabel(magic)
    setStat:; setStat(magic)
    setBase:; setBase(magic)
  }

  //A => weapon
  function weapon {
    enter
    and #$00ff; bne +; lda.w #128; +  //"Nothing" => "No Weapon"
    mul(9); tay
    lda #$0009; allocator.index(weapon); write.bpp4(lists.items.bpp4)
    leave; rtl
  }

  //A => armor
  function armor {
    enter
    and #$00ff;  bne +; lda.w #129; +  //"Nothing" => "No Armor"
    mul(9); tay
    lda #$0009; allocator.index(armor); write.bpp4(lists.items.bpp4)
    leave; rtl
  }

  //A => technique name
  function techniqueMenuName {
    enter
    and #$00ff; mul(8); tay
    allocator.index(techniqueMenuName)
    lda #$0006; write.bpp2(lists.techniques.bpp2)
    leave; rtl
  }

  //A => technique level
  function techniqueMenuLevel {
    enter
    and #$00ff; mul(3); tay
    allocator.index(techniqueMenuLevel)
    lda #$0003; write.bpp2(lists.levels.bpp2)
    leave; rtl
  }

  namespace techniqueItem {
    variable(2, nameID)

    //A => name
    function name {
      enter
      and #$00ff; sta nameID; mul(8); tay
      allocator.index(techniqueItemName)
      lda #$0008; write.bpp2(lists.techniques.bpp2)
      leave; rtl
    }

    //A => level
    function level {
      enter
      and #$00ff; mul(3); tay
      allocator.index(techniqueItemLevel)
      lda #$0003; write.bpp2(lists.levels.bpp2)
      leave; rtl
    }

    //A => cost
    function cost {
      enter
      and #$00ff; mul(3); tay

      //modify the text color if the text is not grayed out (insufficient MP/SP)
      lda tilemap.attributes; cmp.w palette.gray; beq +
      tilemap.setColorIvory(); +

      lda nameID; and #$00ff; cmp #$004c; jcc sp

      mp: {
        allocator.index(techniqueItemCost)
        lda #$0003; write.bpp2(lists.costsMP.bpp2)
        leave; rtl
      }

      sp: {
        allocator.index(techniqueItemCost)
        lda #$0003; write.bpp2(lists.costsSP.bpp2)
        leave; rtl
      }
    }
  }
}

codeCursor = pc()

}
