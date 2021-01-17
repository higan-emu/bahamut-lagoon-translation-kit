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

  //Logo
  variable X = $8e  //was $94
  variable Y = $d8  //was $d1

  //Bahamut Lagoon
  seek($d5f5de); db 27  //27 sprites objects make up the logo
    db Y+$00,X+$00,$00
    db Y+$00,X+$10,$01
    db Y+$02,X+$20,$02
    db Y+$02,X+$30,$03
    db Y+$02,X+$40,$04
    db Y+$02,X+$50,$05
    db Y+$05,X+$60,$06
    db Y+$05,X+$70,$07
    db Y+$10,X+$00,$08
    db Y+$10,X+$10,$09
    db Y+$12,X+$20,$0a
    db Y+$12,X+$30,$0b
    db Y+$12,X+$40,$0c
    db Y+$12,X+$50,$0d
    db Y+$15,X+$60,$0e
    db Y+$15,X+$70,$0f
    db Y+$20,X+$00,$10
    db Y+$20,X+$10,$11
    db Y+$0e,X+$80,$12
    db Y+$0e,X+$90,$13
    db Y+$0e,X+$a0,$14
    db Y+$0e,X+$b0,$15
    db Y+$1e,X+$80,$1a
    db Y+$1e,X+$90,$1b
    db Y+$1e,X+$a0,$1c
    db Y+$1e,X+$b0,$1d
    db Y+$1e,X+$c0,$1e

  //Menu
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
    db Y,X+$00,$30  //the graphic wasn't properly centered before.
    db Y,X+$10,$31  //this centers it perfectly in the middle of the screen.
    db Y,X+$20,$32
    db Y,X+$30,$33
    db Y,X+$40,$34
    db Y,X+$50,$35

  dequeue pc

  //these functions dynamically center the menu options based on whether Ex-Play is shown.
  //this creates a better space balance between the logo and the copyright.

  function newGame {
    lda $307fd0; and #$01; bne +
    lda #$a4; sta $0762; rtl
  +;lda #$9c; sta $0762; rtl
  }

  function loadGame {
    lda $307fd0; and #$01; bne +
    lda #$b0; sta $0772; rtl
  +;lda #$a8; sta $0772; rtl
  }

  function resume {
    lda $307fd0; and #$01; bne +
    lda #$bc; sta $0782; rtl
  +;lda #$b4; sta $0782; rtl
  }

  function exPlay {
    lda $307fd0; and #$01; bne +
    lda #$c8; sta $0792; rtl
  +;lda #$c0; sta $0792; rtl
  }
}

codeCursor = pc()

}
