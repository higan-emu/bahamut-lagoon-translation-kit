namespace palette {

constant white   = color(31,31,29)
constant gray    = color(15,15,15)
constant black   = color( 2, 2, 2)
constant yellow  = color(30,30, 2)
constant shadow  = color(20,20,20)
constant green   = color(17,31,17)
constant ivory   = color(31,31,15)
constant navy    = color( 2, 2,12)
constant red     = color(31,12,12)
constant silver  = color(21,21,21)
constant crimson = color(21, 8, 8)

seek(codeCursor)

namespace chapter {
  enqueue pc
  seek($e87cdd); {  //add yellow text color
    dw white   //color 1
    dw black   //color 2
    dw yellow  //color 3
  }
  dequeue pc
}

namespace field {
  enqueue pc
  seek($c6a052); {  //add yellow and ivory text colors
    dw ivory   //color  9
    dw gray    //color 10
    dw black   //color 11
    ds 2       //color 12
    dw white   //color 13
    dw black   //color 14
    dw yellow  //color 15
  }
  dequeue pc
}

namespace combat {
  enqueue pc
  seek($c1ca4d); {  //add yellow text color
    dw white   //color 1
    dw black   //color 2
    dw yellow  //color 3
  }
  seek($e64b42); {  //convert yellow text color to ivory
    dw white   //color 1
    dw gray    //color 2
    dw navy    //color 3
    ds 2       //color 4
    dw ivory   //color 5
  }
  dequeue pc
}

namespace menu {
  enqueue pc
  seek($ee53a4); jsl hook
  seek($ee85d2); {  //add green and ivory text colors
    dw white   //color  1
    dw gray    //color  2
    dw black   //color  3
    ds 2       //color  4
    dw shadow  //color  5
    dw gray    //color  6
    dw black   //color  7
    ds 2       //color  8
    dw green   //color  9
    dw gray    //color 10
    dw black   //color 11
    ds 2       //color 12
    dw ivory   //color 13
    dw gray    //color 14
    dw black   //color 15
  }
  dequeue pc

  //add yellow text color and rearrange palette order
  //------
  //ee53a1  lda #$0000
  //ee53a4  sta $7e41e6
  //------
  function hook {
    php; rep #$20; pha
    lda.w #white;  sta $7e41e2  //color 1
    lda.w #black;  sta $7e41e4  //color 2
    lda.w #yellow; sta $7e41e6  //color 3
    pla; plp; rtl
  }
}

namespace titleScreen {
  enqueue pc
  seek($e89de0); dw black, silver,  white  //inactive menu item palette
  seek($e89e00); dw black, crimson, red    //selected menu item palette
  dequeue pc
}

namespace endingScreen {
  enqueue pc
  seek($e8ddf0); insert "../en/binaries/fonts/font-ending-palette.bin"
  dequeue pc
}

codeCursor = pc()

}
