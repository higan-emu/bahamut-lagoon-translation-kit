namespace chapter {

seek(codeCursor)

namespace openingCredits {
  constant tileCount  = $095f  //number of tiles to transfer to VRAM
  constant lineNumber = $0960  //current line number being rendered

  //------
  //da3b22  lda [$76],y  ;load the next character
  //da3b24  cmp #$f0     ;test if it's a control code
  //------
  function main {
    inline hook(define address, define index, variable lines) {
      cmp.w #${address}; jne return{#}
      //transfer static tiledata line to WRAM
      lda.w lineNumber; and #$0003; mul( 896); add.w #opening.block{index}; tax
      lda.w lineNumber; and #$0003; mul(1024); add.w #$e2c0; tay
      lda.w #896-1; mvn $7e=opening.block{index}>>16
      leave
      //store amount of tiles needed to transfer
      lda.b #28; sta.w tileCount
      //if this is the last line of text, return #$fd (string terminal with no wait)
      //otherwise, return #$fe (line feed), so that this function will be called again
      lda.b #$fe
      ldy.w lineNumber; cpy.w #lines-1; bcc +; dec; +
      sec; rtl
      return{#}:
    }

    enter
    lda $76  //hooks arranged in the order they appear onscreen
    hook(a402,0,1)
    hook(a43f,1,2)
    hook(a48c,2,2)
    hook(a4b9,3,2)
    hook(a4e5,4,3)
    hook(a52c,5,2)
    hook(a55f,6,2)
    hook(a592,7,2)
    hook(a5c4,8,3)
    hook(a609,9,2)
    hook(a637,a,3)
    hook(a684,b,2)
    hook(a6b7,c,2)
    hook(a6ec,d,4)
    hook(a74f,e,2)
    hook(a77f,f,2)
    hook(a7af,g,2)
    hook(a7d9,h,2)
    leave
    lda #$fd; sec; rtl
  }
}

namespace endingCredits {
  enqueue pc
  seek($da2856); jsl disableColorMath
  seek($da758b); jsl main; jmp $7599
  dequeue pc

  constant eventNumber = $7e0310  //$f8 => ending credits
  constant tilemap     = $7e6000
  constant hdmaTable   = $7ed790

  //the original game enabled color math on BG3 during the ending credits.
  //this had the effect of dramatically reducing readability of the text.
  //the byte in ROM that controls this is shared by several places in the game.
  //this routine ensures that the byte is only modified during the ending credits.
  //------
  //da2856  lda [$28],y  ;load value to write to $2131 (CGADDSUB)
  //da2858  sta $71      ;save value for later use
  //------
  function disableColorMath {
    lda $28; cmp #$f0;         beq +; lda [$28],y; sta $71; rtl; +
    lda $29; cmp #$08;         beq +; lda [$28],y; sta $71; rtl; +
    lda $2a; cmp #$c7;         beq +; lda [$28],y; sta $71; rtl; +
    cpy #$0017;                beq +; lda [$28],y; sta $71; rtl; +
    lda eventNumber; cmp #$f8; beq +; lda [$28],y; sta $71; rtl; +
    lda [$28],y; and #$fb; sta $71; rtl  //clear BG3 color math enable bit
  }

  //------
  //da758b  lda [$76],y  ;load the next tile
  //da758d  cmp #$ff     ;check for the terminal
  //da758f  beq $7599    ;if found, finish rendering
  //da7591  jsr $759a    ;otherwise, transfer tile to tilemap
  //da7594  inx #2
  //da7596  iny
  //da7597  bra $758b
  //------
  function main {
    macro hook(define address) {
      cmp.w #${address}; bne +; jsl {address}; leave; rtl; +
    }

    enter
    lda #$0000; sta hdmaTable  //disable HDMA BG3VOFS table
    lda $76  //hooks arranged in the order they appear onscreen
    hook(a711)
    hook(a746)
    hook(a793)
    hook(a7d1)
    hook(a82f)
    hook(a976)
    hook(a927)
    hook(a8a5)
    hook(a9d6)
    hook(aa3d)
    hook(aa9e)
    hook(aae8)
    hook(ab5d)
    hook(ab7b)
    leave; rtl
  }

  //A => tile count
  //X => tile index
  //Y => tilemap index
  function writeLine {
    enter; ldb #$7e
    pha; phx; pla; plx
    ora #$2000
    loop: {
      sta.w tilemap+$00,y; inc #2
      iny #2; dex; bne loop
    }
    leave; rtl
  }

  macro write(define index) {
    enter; ldb #$00
    vwait()
    lda.w #ending.block{index} >> 0; sta $4302
    lda.w #ending.block{index} >> 8; sta $4303
    lda.w #ending.block{index}.size; sta $4305
    lda.w #$6090 >> 1; sta $2116; sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave
  }

  macro write(variable vramIndex, variable mapIndex) {
    lda.w #28
    ldx.w #vramIndex*28*2+9
    ldy.w #mapIndex*64+$04
    jsl writeLine
    ldy.w #mapIndex*64+$44; inx
    jsl writeLine
  }

  //Presented By Square
  function a711 {
    write(0)
    write(0,12)
    write(1,14)
    rtl
  }

  //Project Leader
  function a746 {
    write(1)
    write(0, 2)
    write(1, 4)
    rtl
  }

  //Director + Story Event Producer
  function a793 {
    write(2)
    write(0, 2)
    write(1, 4)
    write(2, 7)
    write(3, 9)
    rtl
  }

  //Main Programmers
  function a7d1 {
    write(3)
    write(0, 2)
    write(1, 4)
    write(2, 6)
    write(3, 8)
    rtl
  }

  //Story Event Planner + Simulation Planner + Field Planner
  function a82f {
    write(4)
    write(0, 2)
    write(1, 4)
    write(2, 7)
    write(3, 9)
    write(4,12)
    write(5,14)
    rtl
  }

  //Special Effects Programmer + Special Effects Graphic Designer
  function a976 {
    write(5)
    write(0, 2)
    write(1, 4)
    write(2, 7)
    write(3, 9)
    rtl
  }

  //Assistant Director + Event Planner
  function a927 {
    write(6)
    write(0, 2)
    write(1, 4)
    write(2, 7)
    write(3, 9)
    rtl
  }

  //Music Composer + Sound Engineer + Sound Programmer
  function a8a5 {
    write(7)
    write(0, 2)
    write(1, 4)
    write(2, 7)
    write(3, 9)
    write(4,12)
    write(5,14)
    rtl
  }

  //Character Graphic Designers + Monster Graphic Designer
  function a9d6 {
    write(8)
    write(0, 2)
    write(1, 4)
    write(2, 6)
    write(3, 9)
    write(4,11)
    rtl
  }

  //Event Background Graphic Designer + Field Graphic Designers
  function aa3d {
    write(9)
    write(0, 2)
    write(1, 4)
    write(2, 7)
    write(3, 9)
    write(4,11)
    rtl
  }

  //Special Thanks
  function aa9e {
    write(a)
    write(0, 2)
    write(1, 4)
    write(2, 6)
    write(3, 8)
    write(4,10)
    write(5,12)
    rtl
  }

  //Special Thanks
  function aae8 {
    write(b)
    write(0, 2)
    write(1, 4)
    write(2, 6)
    write(3, 8)
    write(4,10)
    write(5,12)
    write(6,14)
    rtl
  }

  //Supervisor
  function ab5d {
    write(c)
    write(0,12)
    write(1,14)
    rtl
  }

  //Executive Producer
  function ab7b {
    write(d)
    write(0,12)
    write(1,14)
    rtl
  }
}

namespace endingGraphic {
  enqueue pc
  seek($d5f159); jsl hook; nop
  dequeue pc

  //the original "The End" graphic was comprised of only 4 sprite list entries.
  //the new graphic needs 24 sprite list entries, but there is no space for it.
  //so the original graphic is disabled, and the OAM WRAM table is manually set up.
  //------
  //d5f159  lda #$01   ;#$01 = enable; #$00 = disable
  //d5f15b  sta $0720  ;enable drawing sprite 2 ("The End" graphic)
  //------
  function hook {
    //disable the original graphic OAM transfer request.
    //as this was the only sprite onscreen, this disables all OAM WRAM table writes.
    stz $0720

    enter; ldb #$7e

    //clear the entire OAM WRAM table
    lda #$e000; ldx.w #0
  -;sta $6ca0,x; stz $6ca2,x; inx #4; cpx #$0200; bcc -  //clear lower table
  -;stz $6ca0,x; stz $6ca2,x; inx #4; cpx #$0220; bcc -  //clear upper table

    //transfer 8x3 sprites to OAM WRAM table
    macro line(variable line) {
      macro item(variable item) {
        variable x = $40 + item * 16  //centered horizontally
        variable y = $58 + line * 16  //centered vertically
        variable tile = line * 32 + item * 2
        variable slot = line *  8 + item * 1
        lda.w #x<<0|y<<8;  sta.w $6ca0+slot*4
        lda.w #$3100|tile; sta.w $6ca2+slot*4
      }
      item(0); item(1); item(2); item(3); item(4); item(5); item(6); item(7)
    }
    line(0); line(1); line(2)

    leave; rtl
  }
}

codeCursor = pc()

}
