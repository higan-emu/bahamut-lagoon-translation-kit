namespace menu {

seek(codeCursor)

namespace information {
  enqueue pc
  seek($eeef93); jsl drawWindowOverview     //"Equipment Summary" and "Item Explanation" windows
  seek($eef090); jsl drawWindowOverview     //"Dragon Keeper's Item Explanation" window
  seek($eef31c); string.hook(summary)       //"Equipment Summary" text
  seek($eef35a); string.hook(explanation)   //"Item Explanation" text
  seek($eef345); string.skip()              //"Dragon Keeper's" text

  seek($eea640); string.skip()  //disable static "Page" text
  seek($eea65a); string.skip()  //disable static "-" page separator
  seek($eea673); lda #$06f0     //"Page#" text position
  seek($eea633); lda #$06f0     //"Page#" window border cutout offset
  seek($eea639); ldy #$0005     //"Page#" window border cutout length

  seek($eeefbd); string.skip()  //disable static "Page" text
  seek($eeefd7); string.skip()  //disable static "-" page separator
  seek($eeeff0); lda #$06f0     //"Page#" text position
  seek($eeef97); lda #$06f0     //"Page#" window border cutout offset
  seek($eeef9d); ldy #$0005     //"Page#" window border cutout length

  seek($eeedc0); adc #$004e     //X cursor offset (list)
  seek($eeedaa); inc; nop #2    //Y cursor offset (list) (was adc #$0002 sans clc)
  seek($eeeafa); adc #$009d     //Y cursor offset (menu)
  dequeue pc

  //it is necessary to share a tile allocator to double buffer correctly
  //when changing between the three screens in the information menu
  allocator.bpp2()
  allocator.create(7,24,list1)
  allocator.create(9,48,list2)

  namespace index {
    variable(2, counter)

    name:;       allocator.index(list1); rtl
    weapon:;     allocator.index(list2); rtl
    armor:;      allocator.index(list2); rtl
    item:;       allocator.index(list2); rtl
    property:;   allocator.index(list2); rtl
    countLeft:;  allocator.index(list1); pha; txa; sta counter; pla; rtl
    countRight:; pha; lda counter; add #$0003; tax; pla; rtl
  }

  function summary {
    enter
    ldy.w #strings.bpp2.equipmentSummary
    lda #$000b; ldx #$000b; write.bpp2(lists.strings.bpp2)
  //lda $7e3be0; ora #$0002; sta $7e3be0  //hack: enable ex-play menu
    leave; rtl
  }

  function explanation {
    enter
    lda $7e3be0; bit #$0002; jne explay
    ldy.w #strings.bpp2.itemExplanation
    lda #$0012; ldx #$0016; write.bpp2(lists.strings.bpp2)
    leave; rtl
  explay:
    ldy.w #strings.bpp2.dragonKeepersItemExplanation
    lda #$0012; ldx #$0016; write.bpp2(lists.strings.bpp2)
    leave; rtl
  }
}

namespace equipmentSummary {
  enqueue pc
  seek($eeee4b); jsl name
  seek($eeee72); jsl weapon
  seek($eeee99); jsl armor
  dequeue pc

  //A => name
  function name {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007
    jsl information.index.name; write.bpp2(names.buffer.bpp2)
    leave; rtl
  static:
    mul(8); tay
    lda #$0007; jsl information.index.name; write.bpp2(lists.names.bpp2)
    leave; rtl
  }

  //A => weapon
  function weapon {
    enter
    and #$007f; bne +; lda.w #128; +  //"Nothing" => "No Weapon"
    mul(9); tay
    lda #$0009; jsl information.index.weapon; write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  //A => armor
  function armor {
    enter
    and #$007f; bne +; lda.w #129; +  //"Nothing" => "No Armor"
    mul(9); tay
    lda #$0009; jsl information.index.armor; write.bpp2(lists.items.bpp2)
    leave; rtl
  }
}

//$7e80e6+ -> $7e9800 = item list
namespace itemExplanation {
  enqueue pc
  seek($eeef16); jsl item  //left
  seek($eeef41); jsl item  //right
  seek($eeef25); jsl countLeft
  seek($eeef50); jsl countRight
  seek($eeedd4); adc #$0016  //X cursor offset
  seek($eeef06); lda #$0006  //item position (left)
  seek($eeef1a); lda #$0018  //count position (left)
  seek($eeef31); lda #$0022  //item position (right)
  seek($eeef45); lda #$0034  //count position (right)
  dequeue pc

  //A => item
  function item {
    enter
    tilemap.setColorNormal()
    and #$007f; mul(9); tay
    lda #$0009; jsl information.index.item; write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  //A => count
  function countLeft {
    enter
    tilemap.setColorYellow()
    and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    mul(3); tay
    lda #$0003; jsl information.index.countLeft; write.bpp2(lists.counts.bpp2)
    leave; rtl
  }

  //A => count
  function countRight {
    enter
    tilemap.setColorYellow()
    and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    mul(3); tay
    lda #$0003; jsl information.index.countRight; write.bpp2(lists.counts.bpp2)
    leave; rtl
  }
}

namespace dragonKeepersItemExplanation {
  enqueue pc
  seek($eef079); jsl item           //called to print the item name at the top of the page
  seek($eef1a0); jsl stats; nop #2  //called to print the item stats (left-hand column)
  seek($eef1cd); nop #6             //called to print the item stats (right-hand column)
  seek($eef23a); string.skip()      //stat increase arrow
  seek($eef21c); string.skip()      //stat decrease arrow
  dequeue pc

  //A => item
  function item {
    enter
    and #$00ff; mul(9); tay
    lda #$0009; jsl information.index.item; write.bpp2(lists.items.bpp2)
    leave; rtl
  }

  macro stat(variable zindex, variable yindex, variable xindex, define name) {
    tilemap.setColorNormal()
    lda.w #$0146+xindex*$16+yindex*$80; sta $001860
    jsl information.index.property
    ldy.w #strings.bpp2.{name}
    lda #$0006; write.bpp2(lists.strings.bpp2)

    txa; add #$0006; pha
    lda index; tax
    lda $ef24a0+zindex,x; plx
    and #$00ff; beq unchanged{#}
    cmp #$0080; bcs negative{#}

    positive{#}: {
      tilemap.setColorYellow()
      jsl write{#}
      lda $001860; tax
      lda #$2cf1; sta $7ec400,x
      jmp finished{#}
    }

    negative{#}: {
      eor #$00ff; inc
      tilemap.setColorShadow()
      jsl write{#}
      lda $001860; tax
      lda #$24f2; sta $7ec400,x
      jmp finished{#}
    }

    unchanged{#}: {
      lda.w #257  //"---"
      pha; lda #$2400; sta $001862; pla; jsl write{#}
      jmp finished{#}
    }

    write{#}: {
      mul(3); tay
      lda #$0003; write.bpp2(lists.stats.bpp2)
      rtl
    }

    finished{#}:
      tilemap.setColorNormal()
  }

  function stats {
    variable(2, index)

    enter
    txa; sta index
    stat($00, 0,0,hp)
    stat($01, 0,1,mp)
    stat($06, 1,0,fire)
    stat($07, 2,0,water)
    stat($08, 3,0,thunder)
    stat($09, 4,0,recovery)
    stat($0a, 5,0,poison)
    stat($02, 6,0,strength)
    stat($03, 7,0,vitality)
    stat($04, 8,0,dexterity)
    stat($05, 9,0,intelligence)
    stat($0d,10,0,wisdom)
    stat($0e, 1,1,aggression)
    stat($10, 2,1,affection)
    stat($0b, 3,1,timidity)
    stat($0c, 4,1,corruption)
    stat($0f, 5,1,mutation)
    leave; rtl
  }
}

namespace stats {
  //these hooks disable the static statistics strings on both the information
  //and dragon statistics screens. this isn't necessary due to the code hooks
  //used in the translation that bypasses these, but it's done anyway to ensure
  //all strings have been hooked or skipped from the original game.
  enqueue pc
  seek($eef0b4); string.skip()  //HP
  seek($eef0c3); string.skip()  //MP
  seek($eef26d); string.skip()  //Strength
  seek($eef27e); string.skip()  //Vitality
  seek($eef28f); string.skip()  //Dexterity
  seek($eef2a0); string.skip()  //Intelligence
  seek($eef2b8); string.skip()  //Fire
  seek($eef2c5); string.skip()  //Water
  seek($eef2d4); string.skip()  //Thunder
  seek($eef2e7); string.skip()  //Recovery
  seek($eef2fa); string.skip()  //Poison
  seek($eef111); string.skip()  //Timidity
  seek($eef122); string.skip()  //Corruption
  seek($eef135); string.skip()  //Wisdom
  seek($eef148); string.skip()  //Aggression
  seek($eef15b); string.skip()  //Mutation
  seek($eef16c); string.skip()  //Affection
  dequeue pc
}

codeCursor = pc()

}
