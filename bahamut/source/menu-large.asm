namespace menu {

seek(codeCursor)

constant index  = $12  //current Y index into text string
constant buffer = $14  //text string is located at [$14],y
constant wramBuffer = $7e7804  //where to write tiledata to ($7e:7800+)

//the tiledata output is segmented into four quadrants:
//$7e7800 = (  0-127),(0- 7)
//$7e7a00 = (  0-127),(8-15)
//$7e7c00 = (128-255),(0- 7)
//$7e7e00 = (128-255),(8-15)

variable(2, pixel)        //current X position position to render to
variable(2, ramAddressL)  //position of tile N
variable(2, ramAddressR)  //position of tile N+1
variable(2, character)    //current character being rendered

namespace renderLargeText {
  //originally, one character was rendered at a time.
  //this function has been modified to render the entire string all at once.
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
  enqueue pc
  seek($ee53fc); jsl item; jmp $5409     //item descriptions
  seek($ee5532); jsl chapter; jmp $553f  //chapter descriptions
  seek($ee51f2); jsl main; nop #15       //text renderer for both description types
  dequeue pc

  //keeps track of the type of description being rendered.
  //item descriptions will be transferred to VRAM via main.
  //chapter descriptions will be transferred to VRAM via the original game engine.
  variable(2, description)
  namespace description {
    constant item    = 0
    constant chapter = 1
  }

  function item {
    enter
    asl; tax; lda lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda #$00
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2; rep #$20
    lda.w #description.item; sta description
    leave; rtl
  }

  function chapter {
    enter
    asl; tax; lda lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda #$00
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2; rep #$20
    lda.w #description.chapter; sta description
    leave; rtl
  }

  function main {
    enter
    ldb #$7e

    //initialize variables on the start of a new string
    ldy.b index; bne +
    lda #$0000; sta character; sta pixel; +

  renderCharacter:
    //get next character character to draw
    lda [buffer],y; and #$00ff
    character.decode(); pha

    //perform font kerning
    lda character; xba; lsr; ora $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    //calculate first RAM tile write position
    lda pixel; and #$fff8; asl #2; cmp #$0200; bcc +
    add #$0200; +; sta ramAddressL

    //calculate second RAM tile write position
    lda pixel; add #$0008; and #$fff8; asl #2; cmp #$0200; bcc +
    add #$0200; +; sta ramAddressR

    //select one of eight pre-shifted copies of the proportional font
    lda pixel; and #$0007; mul($1800); pha

    //select the tile for the given character
    lda character; mul(48); add $01,s; tax; pla

    //add character width to pixel position for next character render
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; sta pixel

    //draw all 12 lines of the current character
    tile: {
      macro lineL(variable n) {
        variable r = n / 6 * $200 + n % 6 * 2 - n / 6 * 4
        lda.l largeFont.sprite+$00+n*2,x; ora.w wramBuffer+r,y; sta.w wramBuffer+r,y
      }
      lda ramAddressL; tay
      lineL(0); lineL(1); lineL(2); lineL(3); lineL(4); lineL(5)
      lineL(6); lineL(7); lineL(8); lineL(9);lineL(10);lineL(11)
      macro lineR(variable n) {
        variable r = n / 6 * $200 + n % 6 * 2 - n / 6 * 4
        lda.l largeFont.sprite+$18+n*2,x; ora.w wramBuffer+r,y; sta.w wramBuffer+r,y
      }
      lda ramAddressR; tay
      lineR(0); lineR(1); lineR(2); lineR(3); lineR(4); lineR(5)
      lineR(6); lineR(7); lineR(8); lineR(9);lineR(10);lineR(11)
    }

    //keep rendering characters until reaching the string terminator
    ldy.b index; iny
    lda [buffer],y; and #$00ff
    cmp.w #command.terminal; beq +
    inc.b index; jmp renderCharacter; +

    //if this is a chapter description, let the original game transfer it to VRAM.
    //chapter strings appear on the load/save screen at three different positions,
    //and the position to write to isn't yet known here.
    lda description; cmp.w #description.chapter; bne +; leave; rtl; +

    //if this is an item description, transfer it to VRAM ourselves.
    //item strings were originally rendered one character at a time, and only the
    //next 24x16 pixels would be transferred after each function call, whereas this
    //routine renders the entire string all at once, so it needs to all be copied here.
    vwait()  //vwait() is needed instead of vsync() due to the large size of the transfer
    ldb #$00;   sep #$20
    lda #$01;   sta $4300
    lda #$18;   sta $4301
    ldx #$7800; stx $4302
    lda #$7e;   sta $4304
    ldx #$0800; stx $4305
    lda #$80;   sta $2115
    ldx #$7c00; stx $2116
    lda #$01;   sta $420b
    leave; rtl
  }
}

namespace calculateSpritesRequired {
  //original renderer computed how many 16x16 sprites were needed
  //in order to render a given number of 12x12 rendered tiles.
  //------
  //ee5330  lda $12        ;load current character write position
  //ee5332  asl            ;multiply by 2
  //ee5333  tax            ;x = index into lookup table
  //ee5334  lda $ee5364,x  ;lookup table: a = (a+1)*12/16
  //ee5338  tay            ;y = sprite table loop counter
  //------
  enqueue pc
  seek($ee5330); jsl hook; nop #4
  dequeue pc

  function hook {
    lda pixel   //load current pixel rendering position (set by renderCharacter)
    add #$000f  //round up to nearest sprite
    div(16)     //divide by sprite width
    cmp #$000f; bcc +; lda #$000f; +  //a = min(a, 15) (max 15*16 = 240 pixels)
    rtl
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
