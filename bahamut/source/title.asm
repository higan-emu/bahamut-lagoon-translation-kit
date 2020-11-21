//this code replaces the textual menu on the title screen, for three reasons:
//1) to fix the typo found on the original title screen ("Temporally Play")
//2) to make the text more legible against the bright background.
//3) to better center the menu and copyright text onscreen.

namespace titleScreen {

seek(codeCursor)

namespace hook {
  enqueue pc

  //load new graphical data (copyright and menu text)
  seek($d5e6b9); lda.w #titleFont.data >>  0
  seek($d5e6c0); lda.b #titleFont.data >> 16

  //inactive menu item palette
  seek($e89de0); dw color( 0, 0, 0), color(21,21,21), color(31,31,31)

  //selected menu item palette
  seek($e89e00); dw color( 0, 0, 0), color(21, 8, 8), color(31,12,12)

  variable X = $df
  variable Y = $f5

  //New Game
  seek($d5e7b9); jsl newGame; lda #$8d; nop  //cursor position (after credits roll)
  seek($d5ebd3); jsl newGame; lda #$8d; nop  //cursor position (after skipping credits)
  seek($d5f595); dw +     //OAM address
  seek($d5f6ff); +; db 3  //16x16 sprite count
    db Y,X+$00,$38        //Y offset, X offset, tile index
    db Y,X+$10,$39
    db Y,X+$20,$3a

  //Load Game
  seek($d5e7ec); jsl loadGame; lda #$8d; nop
  seek($d5ebfe); jsl loadGame; lda #$8d; nop
  seek($d5f597); dw +
  seek($d5f709); +; db 3
    db Y,X+$00,$3b
    db Y,X+$10,$3c
    db Y,X+$20,$3d

  //Resume
  seek($d5e81f); jsl resume; lda #$8d; nop
  seek($d5ec29); jsl resume; lda #$8d; nop
  seek($d5f599); dw +
  seek($d5f713); +; db 2
    db Y,X+$00,$36
    db Y,X+$10,$37

  //Ex-Play
  seek($d5e858); jsl exPlay; lda #$8d; nop
  seek($d5ec5a); jsl exPlay; lda #$8d; nop
  seek($d5f5cd); dw +
  seek($d5f9c1); +; db 2
    db Y,X+$00,$3e
    db Y,X+$10,$3f

  variable X = $c0
  variable Y = $f8

  //(C) 1996 Square
  seek($d5f5cb); dw +
  seek($d5f71a); +; db 6
    db Y,X+$00,$30  //the logo wasn't properly centered before.
    db Y,X+$10,$31  //this centers it perfectly in the middle of the screen.
    db Y,X+$20,$32
    db Y,X+$30,$33
    db Y,X+$40,$34
    db Y,X+$50,$35

  dequeue pc

  //these functions dynamically center the menu options based on whether Ex-Play is shown.
  //this creates a better space balance between the logo and the copyright.

  function newGame {
    lda $a07fd0; and #$01; bne +
    lda #$a4; sta $0762; rtl
  +;lda #$9c; sta $0762; rtl
  }

  function loadGame {
    lda $a07fd0; and #$01; bne +
    lda #$b0; sta $0772; rtl
  +;lda #$a8; sta $0772; rtl
  }

  function resume {
    lda $a07fd0; and #$01; bne +
    lda #$bc; sta $0782; rtl
  +;lda #$b4; sta $0782; rtl
  }

  function exPlay {
    lda $a07fd0; and #$01; bne +
    lda #$c8; sta $0792; rtl
  +;lda #$c0; sta $0792; rtl
  }
}

codeCursor = pc()

}
