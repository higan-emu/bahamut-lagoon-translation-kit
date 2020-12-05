namespace menu {

seek(codeCursor)

namespace palette {
  enqueue pc
  seek($ee53a4); jsl hook
  dequeue pc

  //------
  //ee53a1  lda #$0000
  //ee53a4  sta $7e41e6
  //------
  function hook {
    //adds yellow text color and rearranges palette order
    php; rep #$20; pha
    lda.w #color(31,31,31); sta $7e41e2  //color 1: white
    lda.w #color( 0, 0, 0); sta $7e41e4  //color 2: black
    lda.w #color(31,31, 0); sta $7e41e6  //color 3: yellow
    pla; plp; rtl
  }
}

namespace largeText {
  enqueue pc
  seek($ee53fc); jsl description; jmp $5409   //descriptions
  seek($ee5532); jsl chapterName; jmp $553f   //chapter names
  seek($ee51f2); jsl main; nop #15            //text renderer for both description types
  seek($ee540b); jsl test; nop #2             //test if OAM text should be cleared during list navigation
  seek($ee9317); jml cancelStatus; nop #2     //clear OAM text when cancelling list navigation
  seek($eeba32); jml acceptEquipment; nop #2  //clear OAM text when accepting list navigation
  seek($eeba40); jml cancelEquipment; nop #2  //clear OAM text when cancelling list navigation
  seek($eee218); jml cancelShop; nop #2       //clear OAM text when cancelling list navigation
  seek($eeeca5); jml cancelInventory; nop #2  //clear OAM text when cancelling list navigation
  seek($ee5478); nop #2                       //disable post-main text increment (descriptions)
  seek($ee55af); nop #2                       //disable post-main text increment (name entry)
  seek($ee5175); nop #3                       //disable OAM setup (now handled inside main)
  seek($ee511c); nop #4                       //disable OAM clearing (left-half)
  seek($ee5140); nop #4                       //disable OAM clearing (right-half)
  dequeue pc

  //the tiledata output is segmented into four quadrants for sprite 16x16 alignment:
  //$7e7800 = (  0-127),(0- 7)
  //$7e7a00 = (  0-127),(8-15)
  //$7e7c00 = (128-255),(0- 7)
  //$7e7e00 = (128-255),(8-15)

  constant index  = $12      //current Y index into text string
  constant buffer = $14      //text string is located at [$14],y
  constant output = $7e7804  //where to write tiledata to ($7e:7800+)
  constant naming = $7e9e00  //name select screen text is always located here

  variable(2, pixel)         //current X position position to render to
  variable(2, pixels)        //maximum number of pixels that can be rendered for this line
  variable(2, ramAddressL)   //position of tile N
  variable(2, ramAddressR)   //position of tile N+1
  variable(2, character)     //current character being rendered
  variable(2, style)         //current font style being used (#$00 = normal, #$60 = italic)
  variable(2, color)         //current font color being used (#$00 = normal, #$01 = yellow, #$02 = shadow)

  //keeps track of the type of text being rendered.
  //item descriptions will be transferred to VRAM via main.
  //chapter descriptions will be transferred to VRAM via the original game engine.
  variable(2, type)
  namespace type {
    constant nameEntry   = 0
    constant chapterName = 1
    constant description = 2
  }

  function description {
    enter
    asl; tax; lda lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda #$00
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2; rep #$20
    lda.w #type.description; sta type
    leave; rtl
  }

  function chapterName {
    enter
    asl; tax; lda lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda #$00
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2; rep #$20
    lda.w #type.chapterName; sta type
    leave; rtl
  }

  //------
  //ee51f2  lda $12
  //ee51f4  and #$0001
  //ee51f7  beq $51fb
  //ee51f9  bra $5200
  //ee51fb  jsr $5207
  //ee51fe  bra $5205
  //ee5200  jsr $5283
  //ee5203  bra $5205
  //------
  function main {
    enter; ldb #$7e

    lda.b buffer+0; cmp.w #naming >> 0; bne +
    lda.b buffer+1; cmp.w #naming >> 8; bne +
    lda.w #type.nameEntry; sta type; +

  initialize:
    lda #$0000; sta character; sta pixel; sta style; sta color
    lda.w #216; sta pixels

  renderCharacter:
    ldy.b index; lda [buffer],y; and #$00ff
    cmp.w #command.terminal;    bne +; jml finished; +;       inc.b index
    cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra renderCharacter; +
    cmp.w #command.styleItalic; bne +; lda.w #$60; sta style; bra renderCharacter; +
    cmp.w #command.colorNormal; bne +; lda.w #$00; sta color; bra renderCharacter; +
    cmp.w #command.colorYellow; bne +; lda.w #$01; sta color; bra renderCharacter; +
    cmp.w #command.alignLeft;   bne +; jsl align.left;        bra renderCharacter; +
    cmp.w #command.alignCenter; bne +; jsl align.center;      bra renderCharacter; +
    cmp.w #command.alignRight;  bne +; jsl align.right;       bra renderCharacter; +
    cmp.w #command.alignSkip;   bne +; jsl align.skip;        bra renderCharacter; +
    cmp.w #command.base;        bcs renderCharacter
    character.decode(); add style; pha

    //perform font kerning
    lda character; mul(176); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    //calculate first RAM tile write position
    lda pixel; and #$00f8; asl #2; cmp #$0200; bcc +
    add #$0200; +; sta ramAddressL

    //calculate second RAM tile write position
    lda pixel; add #$0008; and #$00f8; asl #2; cmp #$0200; bcc +
    add #$0200; +; sta ramAddressR

    //select one of eight pre-shifted copies of the proportional font
    lda pixel; and #$0007; mul(8192); pha

    //select the tile for the given character
    lda character; mul(44); add $01,s; tax; pla

    //add character width to pixel position for next character render
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +
    lda pixels; sta pixel; jmp renderCharacter
  +;sta pixel

    //draw all 11 lines of the current character
    lda type; cmp.w #type.description; jne shadow
    lda color; jne yellow  //only descriptions support font color selection

    macro tile(variable font) {
      macro lineL(variable n) {
        variable t = n + 1
        variable r = t / 6 * $200 + t % 6 * 2 - t / 6 * 4
        lda.l font+$00+n*2,x; ora.w output+r,y; sta.w output+r,y
      }
      lda ramAddressL; tay
      lineL(0); lineL(1); lineL(2); lineL(3); lineL(4)
      lineL(5); lineL(6); lineL(7); lineL(8); lineL(9); lineL(10)
      macro lineR(variable n) {
        variable t = n + 1
        variable r = t / 6 * $200 + t % 6 * 2 - t / 6 * 4
        lda.l font+$16+n*2,x; ora.w output+r,y; sta.w output+r,y
      }
      lda ramAddressR; tay
      lineR(0); lineR(1); lineR(2); lineR(3); lineR(4)
      lineR(5); lineR(6); lineR(7); lineR(8); lineR(9); lineR(10)
      jmp renderCharacter  //keep rendering until all characters have been rendered
    }
    normal:; tile(largeFont.normal)
    yellow:; tile(largeFont.yellow)
    shadow:; tile(largeFont.shadow)

  finished:
    lda type; cmp.w #type.description; bne +; jsl write; +
    leave; rtl
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      lda.b index;  add.b buffer+0; sta render.large.width.address+0
      lda.w #$0000; adc.b buffer+2; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      lda.b index;  add.b buffer+0; sta render.large.width.address+0
      lda.w #$0000; adc.b buffer+2; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      ldy.b index; lda [buffer],y; and #$00ff; inc.b index
      add pixel; sta pixel; rtl
    }
  }

  function write {
    //write 15 OAM entries (240 pixels)
    lda #$c818; ldx #$0000; ldy #$000f
  -;sta $7e6e20,x; add #$0010
    inx #4; dey; bne -

    //descriptions were originally rendered one character at a time, and only the
    //next 24x16 pixels would be transferred after each function call, whereas this
    //routine renders the entire string all at once, so it needs to all be copied here.
    vwait()  //vsync() cannot be used here due to the large size of the transfer
    ldb #$00;   sep #$20
    lda #$01;   sta $4300
    lda #$18;   sta $4301
    ldx #$7800; stx $4302
    lda #$7e;   sta $4304
    ldx #$0800; stx $4305
    lda #$80;   sta $2115
    ldx #$7c00; stx $2116
    lda #$01;   sta $420b

    lda #$ff; sta [buffer]
    rtl
  }

  function clear {
    enter
    lda #$e000; ldx #$0000; ldy #$000f
  -;sta $7e6e20,x; add #$0010
    inx #4; dey; bne -
    leave; rtl
  }

  //------
  //ee9312  bit #$8000   ;test if B is pressed
  //ee9315  beq $92dd    ;branch if not set
  //ee9317  lda #$000c
  //ee931a  jsr $fb7c
  //------
  function cancelStatus {
    jsl clear
    lda #$000c
    pea $931c
    jml $eefb7c
  }

  //------
  //eeba2d  bit #$0080  ;test if A is pressed
  //eeba30  beq $ba3b   ;branch if not set
  //eeba32  lda #$000e
  //eeba35  jsr $fb7c
  //------
  function acceptEquipment {
    jsl clear
    lda #$000e
    pea $ba37
    jml $eefb7c
  }

  //------
  //eeba3b  bit #$8000  ;test if B is pressed
  //eeba3e  beq $ba49   ;branch if not set
  //eeba40  lda #$000c
  //eeba43  jsr $fb7c
  //------
  function cancelEquipment {
    jsl clear
    lda #$000c
    pea $ba45
    jml $eefb7c
  }

  //------
  //eee213  bit #$8000  ;test if B is pressed
  //eee216  beq $e221   ;branch if not set
  //eee218  lda #$000c
  //eee21b  jsr $fb7c
  //------
  function cancelShop {
    jsl clear
    lda #$000c
    pea $e21d
    jml $eefb7c
  }

  //------
  //eeeca0  bit #$8000  ;test if B is pressed
  //eeeca3  beq $ecae   ;branch if not set
  //eeeca5  lda #$000c
  //eeeca8  jsr $fb7c
  //------
  function cancelInventory {
    jsl clear
    lda #$000c
    pea $ecaa
    jml $eefb7c
  }

  //------
  //ee540b  lda [$14],y
  //ee540d  and #$00ff
  //------
  function test {
    lda [$14],y; and #$00ff
    cmp #$00ff; beq +; rtl; +
    cpy #$0000; beq +; rtl; +
    jsl clear; rtl
  }
}

namespace disableTileQueuing {
  //original renderer would queue up two 24x8 DMA transfers at a time.
  //this resulted in choppy partial-character text rendering.
  //------
  //trying to extend it to transfer the entire #$0800 bytes of tiledata failed:
  //the DMA list processing would occasionally run beyond vblank for the NMI routine,
  //which resorted in severe graphical distortion. so instead of using this routine,
  //tiledata is uploaded to VRAM manually inside renderCharacter.
  //------
  //a second issue is that this list can only hold 96 entries, and each character adds
  //two (or when striding the left/right quadrants, four) transfer requests. however,
  //some strings render immediately and queue all characters before sending any.
  //this would cause the DMA transfer buffer to overflow on particularly long strings.
  enqueue pc
  seek($ee5178); plp; rts
  dequeue pc
}

namespace disableTileAlignment {
  //original renderer drew 12x12 tiles onto 16x16 sprites.
  //after rendering 10 tiles, 120 of 128 pixels were used.
  //the game would then skip the remaining 8 pixels, too short for another character,
  //and place all subsequent sprites 8 pixels further to the left to account for this.
  //the proportional font renderer writes to all 128 pixels, so this is not desirable.
  //------
  //ee5352  cpx #$001c  ;is this the first tile of the second line?
  //ee5355  bne $535b   ;no, continue as normal
  //ee5357  sec         ;yes, subtract 8 for sprite X position,
  //ee5358  sbc #$0008  ;which will affect all remaining tiles
  //------
  enqueue pc
  seek($ee5355); db $80  //bne $535b -> bra $535b
  dequeue pc
}

namespace disableCharacterLengthLimits {
  //original game limited the maximum length of text strings.
  //this doesn't work well for the thinner proportional font, so disable these checks.
  //------
  //ee547a  lda $12     ;load how many characters have been rendered
  //ee547c  cmp #$0014  ;20 characters * 12x12 = 240 pixels
  //ee547f  bcs $5484   ;if length exceeded, skip rendering character
  //------
  //ee55b1  lda $12     ;load how many characters have been rendered
  //ee55b3  cmp #$000a  ;10 characters * 12x12 = 120 pixels
  //ee55b6  bcs $55bb   ;if length exceeded, skip rendering character
  //------
  enqueue pc
  seek($ee547c); nop #5
  seek($ee55b3); nop #5
  dequeue pc
}

namespace calculateNameLength {
  enqueue pc
  //------
  //eedbf1  lda $cc      ;load number of characters in name
  //eedbf3  sta $00      ;store as multiplicand
  //eedbf5  lda #$000c   ;multiplier
  //eedbf8  jsr $2ae9    ;a = 12 * $cc
  //eedbfb  clc
  //eedbfc  adc #$003a   ;add base offset
  //eedbff  sta $0010d6  ;store cursor X position
  //------
  seek($eedbf1); jsl main; jmp $dbfb
  seek($eedbfc); adc #$0041  //X cursor offset
  seek($eedc03); lda #$fffd  //Y cursor offset
  seek($eeda76); lda #$0050  //X name offset
  dequeue pc

  //used to place the cursor on the name entry screen dynamically
  //$7e9e00 => name
  //A <= length of name in pixels
  function main {
    render.large.width($7e9e00)
    rtl
  }
}

codeCursor = pc()

}
