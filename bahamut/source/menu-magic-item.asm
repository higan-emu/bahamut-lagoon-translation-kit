namespace menu {

seek(codeCursor)

//4bpp player layout shared by both magic and item screens
namespace magicItem {
  enqueue pc
  seek($ee8f59); jsl name
  seek($ee8f94); jsl level
  seek($ee8fef); jsl hp.setCurrent
  seek($ee900d); jsl hp.setMaximum
  seek($ee8f77); string.skip()  //"LV" text
  seek($ee8fd0); string.skip()  //"HP" text
  seek($ee8ff9); string.skip()  //"HP" separator

  //positions
  seek($ee674e); dw $0088    //player #1 X
  seek($ee6752); dw $0088    //player #2 X
  seek($ee6756); dw $0088    //player #3 X
  seek($ee675a); dw $0088    //player #4 X
  seek($ee675e); dw $0030    //player #1 Y
  seek($ee6762); dw $0060    //player #2 Y
  seek($ee6766); db $0090    //player #3 Y
  seek($ee676a); db $00c0    //player #4 Y
  seek($ee8f3f); lda #$0082  //name clear
  seek($ee8f4c); lda #$0082  //name
  seek($ee8f5d); lda #$0090  //"LV" clear
  seek($ee8f71); lda #$0090  //"LV" label
  seek($ee8f87); lda #$0090  //"LV" value
  seek($ee9011); lda #$00c2  //status ailments
  seek($ee8fb6); lda #$0102  //"HP" clear
  seek($ee8fca); lda #$0102  //"HP" label
  seek($ee8fe2); lda #$0102  //"HP" current value
  seek($ee8ff3); lda #$0102  //"HP" separator label
  seek($ee9000); lda #$0102  //"HP" maximum value
  seek($ee8f98); lda #$0142  //"MP" clear
  seek($ee8fa5); lda #$0142  //"MP" line
  dequeue pc

  allocator.bpp4()
  allocator.create( 7,2,reserved)  //magic screen cost
  allocator.create( 7,8,name)
  allocator.create( 3,8,level)
  allocator.create(11,8,hpRange)
  allocator.create(11,8,mpRange)

  //A => player name
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

  //A => level
  function level {
    enter
    mul(3); tay
    lda #$0003; allocator.index(level); write.bpp4(lists.levels.bpp4)
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
      lda #$000a; render.small.bpp4()
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

    function setCurrentUnavailable {
      enter
      lda #$ffff; sta current
      leave; rtl
    }

    function setMaximumUnavailable {
      enter
      lda #$ffff; sta maximum
      jsl render
      leave; rtl
    }

    function render {
      enter
      lda type; ldx #$0000
      cmp #$0000; bne +; lda maximum; tay; lda current; append.spRange(); +
      cmp #$0080; bne +; lda maximum; tay; lda current; append.mpRange(); +
      lda #$000a; render.small.bpp4()
      allocator.index(mpRange); write.bpp4()
      leave; rtl
    }
  }
}

namespace magic {
  enqueue pc
  seek($eec0d4); jsl magicName
  seek($eec0e3); jsl magicLevel
  seek($eec1a5); string.hook(magicCostLabel)
  seek($eebfd1); jsl magicCostValue
  seek($eec061); jsl drawWindowBG2
  seek($ee6f2f); jmp $6f5a   //disable magic list static "LV" text

  //positions
  seek($eec047); lda #$0242  //window
  seek($ee8e01); lda #$0016  //item quantity
  seek($eec19f); lda #$01c6  //"MP Cost" label
  seek($eebfbe); lda #$01ce  //"MP Cost" value
  seek($eebcca); lda #$0016  //X cursor (list initial)
  seek($eebcdc); adc #$003d  //Y cursor
  seek($eebf83); lda #$0016  //X cursor (list normal)
  seek($eebf95); adc #$003d  //Y cursor
  seek($eebf21); lda #$0096  //X cursor (player)
  seek($eebf1b); adc #$fffd  //Y cursor
  dequeue pc

  allocator.bpp2()
  allocator.create(8,24,magicName)
  allocator.create(3,24,magicLevel)
  allocator.bpp4()
  allocator.create(4,1,magicCostLabel)
  allocator.create(3,1,magicCostValue)

  //A => magic name
  function magicName {
    enter
    and #$00ff; mul(8); tay
    lda #$0008; allocator.index(magicName); write.bpp2(lists.techniques.bpp2)
    leave; rtl
  }

  //A => magic level
  function magicLevel {
    enter
    and #$00ff; mul(3); tay
    lda #$0003; allocator.index(magicLevel); write.bpp2(lists.levels.bpp2)
    leave; rtl
  }

  function magicCostLabel {
    enter
    ldy.w #strings.bpp4.magicCost
    lda #$0004; allocator.index(magicCostLabel); write.bpp4(lists.strings.bpp4)
    leave; rtl
  }

  //A => magic cost
  function magicCostValue {
    enter
    and #$00ff; mul(3); tay
    lda #$0003; allocator.index(magicCostValue); write.bpp4(lists.stats.bpp4)
    leave; rtl
  }
}

namespace item {
  enqueue pc
  seek($ee8e20); jsl item
  seek($ee8e0d); jsl count
  seek($ee8d83); string.hook(noItems)
  seek($ee8dc1); jsl drawWindowBG2  //when item count >= 1
  seek($ee8d6b); jsl drawWindowBG2  //when item count == 0
  seek($ee8da7); lda #$0182  //window position when item count >= 1
  seek($ee8d5f); lda #$0182  //window position when item count == 0

  //positions
  seek($ee8c63); lda #$000f  //X cursor (list)
  seek($ee8c5d); adc #$0025  //Y cursor
  seek($ee89a3); lda #$0096  //X cursor (player)
  seek($ee899d); adc #$fffd  //Y cursor
  dequeue pc

  allocator.bpp2()
  allocator.create(9,20,item)
  allocator.create(3,20,count)
  allocator.create(5, 1,noItems)

  //A => item
  function item {
    variable(2, counter)

    enter
    and #$007f; mul(9); tay
    lda #$0009; allocator.index(item); write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  //A => item count
  function count {
    enter
    and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    mul(3); tay
    lda #$0003; allocator.index(count); write.bpp2(lists.counts.bpp2)
    leave; rtl
  }

  function noItems {
    enter
    ldy.w #strings.bpp2.noItemsLeftAligned
    allocator.index(noItems)
    lda #$0005; write.bpp2(lists.strings.bpp2)
    leave; rtl
  }
}

codeCursor = pc()

}
