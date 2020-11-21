namespace menu {

seek(codeCursor)

namespace shop {
  enqueue pc

  //item list
  seek($eee746); jsl item.name
  seek($eee766); jsl item.cost
  seek($eee6b6); string.hook(page.noItems)
  seek($eee681); jsl drawWindowBG3
  seek($eee74a); lda #$0054  //item cost position
  seek($eee5ac); lda #$0016  //X cursor position
  seek($eee5a5); adc #$003d  //Y cursor position

  //item exchange (buy/sell quantity)
  seek($eee3b8); jsl exchange.quantity
  seek($eee3c7); jsl exchange.piro
  seek($eee3d2); string.skip()  //disable "ko" item counter
  seek($eee3b0); lda #$0246     //exchange quantity position
  seek($eee3bc); lda #$0250     //exchange piro position
  seek($eede9c); lda #$001b     //X cursor position
  seek($eedea3); lda #$0025     //Y cursor position

  //this is a fix for pressing up when choosing the quantity of an item to buy or sell.
  //in the original game, it would load Y with 10, and then increment the item one number
  //at a time, calling the function to update the tilemap after each increment.
  //this was fine and mostly instantaneous for just a tilemap update, but with a
  //proportional font, each increment requires a vsync, causing the player to see the
  //quantity and piro amount updating ten times instead of just once when pressing up.
  //pressing down doesn't have this issue and the game subtracts ten from the quantity
  //all at once. this patch disables the call to update the tilemap after each increment,
  //and results in the counter only incrementing once at the end, making it much faster,
  //and consistent with the behavior of pressing down.
  //seek($eee355); nop #3
  //todo: this fix is currently broken (and thus disabled)

  //item page#
  seek($eee6cb); string.skip()  //disable static "Page" text
  seek($eee6e5); string.skip()  //disable static "Page" "-" separator
  seek($eee6fe); lda #$044e     //"Page#" text position
  seek($eee6a5); lda #$044e     //"Page#" window border cutout offset
  seek($eee6ab); ldy #$0007     //"Page#" window border cutout length

  //menu
  seek($eedda0); string.hook(menu.buy)
  seek($eeddaf); string.hook(menu.sell)
  seek($eeddbe); string.hook(menu.equipment)
  seek($eeddcf); string.hook(menu.information)
  seek($eee5db); adc #$001e  //X cursor position
  seek($eee5c6); adc #$0001  //Y cursor position

  //equippable
  seek($eedd7a); string.hook(equippable)

  //piro
  seek($eee40c); string.hook(piro.label)
  seek($eee449); jsl piro.amount
  seek($eee42b); lda #$03f0  //piro amount position

  //holding
  seek($eee467); string.hook(holding.label)
  seek($eee4c5); jsl holding.quantity
  seek($eee4ef); jsl holding.blank
  seek($eee48e); lda #$0578  //holding quantity position
  seek($eee4dc); lda #$0578  //holding blank position

  //equipped
  seek($eee523); string.hook(equipped.label)
  seek($eee569); jsl equipped.quantity  //buying screen
  seek($eee591); jsl equipped.quantity  //selling screen
  seek($eee506); jsl equipped.blank
  seek($eee54e); lda #$06f8  //equipped quantity position
  seek($eee4f3); lda #$06f8  //equipped blank position

  dequeue pc

  allocator.bpp2()
  allocator.create( 9,16,itemName)
  allocator.create( 4,16,itemCost)
  allocator.create( 7, 2,page)
  allocator.create( 3, 2,exchangeQuantity)
  allocator.create( 9, 2,exchangePiro)
  allocator.create( 2, 1,buy)
  allocator.create( 2, 1,sell)
  allocator.create( 7, 1,equipment)
  allocator.create( 7, 1,information)
  allocator.create(12, 1,equippable)
  allocator.create( 3, 1,piroLabel)
  allocator.create( 6, 2,piroAmount)
  allocator.create(11, 1,holdingLabel)
  allocator.create( 2, 2,holdingQuantity)
  allocator.create(11, 1,equippedLabel)
  allocator.create( 2, 2,equippedQuantity)

  namespace item {
    //A = item#
    function name {
      enter
      and #$007f; mul(9); tay
      lda #$0009
      allocator.index(itemName); write.bpp2(lists.items.bpp2)
      leave; rtl
    }

    //A = item cost
    function cost {
      define cost = $00181c

      enter
      lda {cost}; ldx #$0000; append.alignRight(30); append.integer_5()
      lda #$0004; render.small.bpp2()
      allocator.index(itemCost); write.bpp2()
      leave; rtl
    }
  }

  namespace page {
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

    function noItems {
      enter
      ldy.w #strings.bpp2.noItemsCentered
      allocator.index(page)
      lda #$0007; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }
  }

  namespace exchange {
    //A = quantity
    function quantity {
      enter
      and #$00ff; mul(3); tay
      allocator.index(exchangeQuantity)
      lda #$0003; write.bpp2(lists.counts.bpp2)
      leave; rtl
    }

    //A = piro
    function piro {
      define piroLower = $00181c
      define piroUpper = $00181e

      enter
      lda {piroUpper}; tay; lda {piroLower}
      ldx #$0000; append.alignRight(68); append.integer_8(); append.literal(" Piro")
      lda #$0009; render.small.bpp2()
      allocator.index(exchangePiro); write.bpp2()
      leave; rtl
    }
  }

  namespace menu {
    function buy {
      enter
      ldy.w #strings.bpp2.buy
      allocator.index(buy)
      lda #$0002; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }

    function sell {
      enter
      ldy.w #strings.bpp2.sell
      allocator.index(sell)
      lda #$0002; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }

    function equipment {
      enter
      ldy.w #strings.bpp2.equipment
      allocator.index(equipment)
      lda #$0007; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }

    function information {
      enter
      ldy.w #strings.bpp2.information
      allocator.index(information)
      lda #$0007; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }
  }

  function equippable {
    enter
    ldy.w #strings.bpp2.classesAbleToEquip
    allocator.index(equippable)
    lda #$000c; write.bpp2(lists.strings.bpp2)
    leave; rtl
  }

  namespace piro {
    function label {
      enter
      ldy.w #strings.bpp2.piro
      allocator.index(piroLabel)
      lda #$0003; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }

    function amount {
      constant piroLower = $7e8016
      constant piroUpper = $7e8018

      enter
      lda piroUpper; tay; lda piroLower
      ldx #$0000; append.alignRight(48); append.integer_8()
      lda #$0006; render.small.bpp2()
      allocator.index(piroAmount); write.bpp2()
      leave; rtl
    }
  }

  namespace holding {
    function label {
      enter
      ldy.w #strings.bpp2.currentlyHolding
      allocator.index(holdingLabel)
      lda #$000b; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }

    //A => # of current item player holds
    function quantity {
      enter
      and #$00ff
      cmp #$00ff; bne +; lda.w #101; bra ++; +  //"--"
      cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
      mul(2); tay
      allocator.index(holdingQuantity)
      lda #$0002; write.bpp2(lists.costs.bpp2)
      leave; rtl
    }

    function blank {
      enter
      lda #$ffff; jsl quantity
      leave; rtl
    }
  }

  namespace equipped {
    function label {
      enter
      ldy.w #strings.bpp2.currentlyEquipped
      allocator.index(equippedLabel)
      lda #$000b; write.bpp2(lists.strings.bpp2)
      leave; rtl
    }

    //A => # of current item player has equipped
    function quantity {
      enter
      and #$00ff
      cmp #$00ff; bne +; lda.w #101; bra ++; +  //"--"
      cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
      mul(2); tay
      allocator.index(equippedQuantity)
      lda #$0002; write.bpp2(lists.costs.bpp2)
      leave; rtl
    }

    function blank {
      enter
      lda #$ffff; jsl quantity
      leave; rtl
    }
  }
}

codeCursor = pc()

}
