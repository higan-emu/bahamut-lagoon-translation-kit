//modifications to the name entry screen

namespace menu {

seek(codeCursor)

namespace decodeNameEntry {
  //called once when loading the name entry screen
  enqueue pc
  seek($eeda2c); jsl main; jmp $da5a
  dequeue pc

  //A => name index (0-9)
  //$7e2b00 => name table input
  //$7e9e00 <= name output
  //function must return with B set to #$7e: it is used by subsequent code
  main: {
    ldb #$7e  //B set by original routine
    enter
    and #$00ff; mul(8); tax
    lda $2b00,x; sta base56.decode.input+0
    lda $2b02,x; sta base56.decode.input+2
    lda $2b04,x; sta base56.decode.input+4
    lda $2b06,x; sta base56.decode.input+6
    jsl base56.decode

    lda base56.decode.output+ 0; sta $9e00
    lda base56.decode.output+ 2; sta $9e02
    lda base56.decode.output+ 4; sta $9e04
    lda base56.decode.output+ 6; sta $9e06
    lda base56.decode.output+ 8; sta $9e08
    lda base56.decode.output+10; sta $9e0a
    leave; rtl
  }
}

namespace encodeNameEntry {
  //called once when confirming a name and exiting the name entry screen
  enqueue pc
  seek($eedc21); jsl main; jmp $dc49
  dequeue pc

  variable(2, index)

  //A => name index (0-9)
  //$7e9e00 => name input
  //$7e2b00 <= name table output
  main: {
    ldb #$7e  //B set by original routine
    enter
    and #$00ff; sta index
    mul(8); tax
    lda $9e00; sta base56.encode.input+ 0
    lda $9e02; sta base56.encode.input+ 2
    lda $9e04; sta base56.encode.input+ 4
    lda $9e06; sta base56.encode.input+ 6
    lda $9e08; sta base56.encode.input+ 8
    lda $9e0a; sta base56.encode.input+10
    jsl base56.encode

    lda base56.encode.output+0; sta $2b00,x
    lda base56.encode.output+2; sta $2b02,x
    lda base56.encode.output+4; sta $2b04,x
    lda base56.encode.output+6; sta $2b06,x

    //pre-render the newly chosen name to the names cache
    lda index; jsl names.render
    leave; rtl
  }
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

namespace appendNameEntry {
  //called when attempting to add a character on the name entry screen.
  //limits maximum name lengths against both the large and small fonts.
  enqueue pc
  seek($eedb69); jsl main; jmp $db7d
  dequeue pc

  //$00 => character
  //$ca => name index (0-9)
  //$cc => name length
  //D   => $0e80
  //------
  //eedb69  sep #$20
  //eedb6b  ldx $cc        ;load name length
  //eedb6d  lda $00        ;load character to append
  //eedb6f  sta $7e9e00,x  ;store character
  //eedb73  lda #$ff
  //eedb75  sta $7e9e01,x  ;store terminal
  //eedb79  rep #$20
  //eedb7b  inc $cc        ;increment name length
  //------
  function main {
    variable(16, name)   //copy of name + character to append
    variable( 2, limit)  //8x8 width limit

    enter
    lda.w #60+1; sta limit     //dragon name limit (7.5 tiles) + 1 (shadow)
    lda $ca; cmp.w #2; bcs +   //test if this is a player name
    lda.w #52+1; sta limit; +  //player name limit (6.5 tiles) + 1 (shadow)

    ldx #$0000; txy; append.string(name, $7e9e00)
    lda $00; ora #$ff00; sta name,x
    render.large.width(name); cmp.w #66+1; bcs +
    render.small.width(name); cmp.l limit; bcs +

    ldx $cc
    lda $00; ora #$ff00
    sta $7e9e00,x
    inc $cc

  +;leave; rtl
  }
}

namespace nameEntry {
  enqueue pc
  seek($eedaa7); string.hook(draw)  //"Finished" text
  seek($eedaa1); lda #$0128         //"Finished" position
  seek($eed985); dec; sta $1056     //X cursor offset (character map)
  seek($eed98f); sbc #$001d         //Y cursor offset (character map)
  dequeue pc

  function draw {
    enter

    //use this as an anchor point to load "Space" into VRAM now
    //the "Space" tilemap data is set in names.characterMap
    lda tilemap.address      //this will write the tilemap where "Finished" is
    jsl spaceIndicator.draw  //this will place "Space" into VRAM
    sta tilemap.address      //but this will overwrite it with "Finished" as desired

    ldy.w #strings.bpp4.finished
    lda #$0005; ldx #$0030; write.bpp4(lists.strings.bpp4)
    leave; rtl
  }
}

namespace spaceIndicator {
  //the original game parses the tilemap copy in RAM to find non-zero tiles.
  //when it finds one, it allows the cursor to be moved to the left of said tile.
  //this makes it exceedingly difficult to print a "Space" indicator for said character.
  enqueue pc
  seek($eed9c5); jsl ignore     //lda $7ec400,x
  seek($eedb35); jsl transform  //lda $7ec400,x
  dequeue pc

  function draw {
    enter
    ldy.w #strings.bpp2.space
    lda #$0003; ldx #$0030; write.bpp2(lists.strings.bpp2)
    leave; rtl
  }

  //this tricks the game into thinking the tiles immediately after "Space" are blank.
  //doing so prevents the cursor from moving on top of the subsequent tiles.
  function ignore {
    lda tilemap.location,x
    cpx #$0492; bcc +
    cpx #$0496; bcs +
    lda #$2000
  +;rtl
  }

  //this tricks the game into thinking the first tile for "Space" is an actual space.
  //it's really our tiledata, but we need the game to insert a space into the name here.
  function transform {
    lda tilemap.location,x
    cpx #$0490; bne +
    lda #$20ef
  +;rtl
  }
}

namespace forceSinglePage {
  enqueue pc

  //the original game had three pages of characters: hiragana, katakana, and romaji.
  //only a single English character page is needed, so force the page to page zero.
  //------
  //eed892  lda $c0    ;load current selected page
  //eed894  beq $d8a3  ;if page# = 0, go to $d8a3
  //------
  seek($eed894); db $80  //beq -> bra

  //this forces the "Finished" option to be the only selectable option
  //------
  //eed7dc  lda $c0      ;load current selected page
  //eed7de  sta $00      ;store selected page
  //eed7e0  lda #$0030   ;length of each option in pixels
  //eed7e3  jsr $2a39    ;multiply A by $00
  //eed7e6  clc
  //eed7e7  adc #$0034   ;base offset
  //eed7ea  sta $001056  ;store X cursor position
  //eed7ee  lda #$0014   ;Y cursor position
  //eed7f1  sta $001058  ;store Y cursor position
  //eed7f5  plp
  //eed7f6  rts
  //------
  seek($eed7dc); {
    lda #$0003   //3 => "Finished" menu option
    sta $c0      //set current selected page to "Finished"
    lda #$00a4   //load cursor X offset
    sta $001056  //store value
    lda #$0013   //load cursor Y offset
    sta $001058  //store value
    plp; rts
  }

  //originally, the "Finished" option would disable the three character pages.
  //disable this so that characters can now be selected with "Finished" active.
  //------
  //eed7c4  lda $c0     ;load current page
  //eed7c6  cmp #$0003  ;test if it is the "Finished" option
  //eed7c9  beq $d777   ;if so, do not allow the down key to be pressed
  //------
  seek($eed7c9); nop #2

  dequeue pc
}

namespace increaseNameLengthLimits {
  enqueue pc
  seek($eedb00); lda.w #11  //dragon name length limit (was 8)
  seek($eedb0c); lda.w #11  //player name length limit (was 6)
  dequeue pc
}

//note that the character map is technically encoded as LZ77 data.
//but so long as we don't insert $1a or $1b pointer codes, we can just write out uncompressed data.
function characterMap {
  enqueue pc
  seek($eed8a7); dl characterMap
  dequeue pc

  db $00  //first byte is always skipped by lz77 decompressor

  //    00,   01,   02,   03,   04,   05,   06,   07,   08,   09,   0a,   0b,   0c,   0d,   0e,   0f
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //00
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //01
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //02
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //03
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //04
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //05
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //06
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //07
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //08
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //09
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //0a
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //0b
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$20b9,$2000,$20ba,$2000,$20bb,$2000,$20bc,$2000  //0c
  dw $20bd,$2000,$20be,$2000,$20bf,$2000,$20c0,$2000,$20c1,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //0d
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //0e
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //0f
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$20c2,$2000,$20c3,$2000,$20c4,$2000,$20c5,$2000  //10
  dw $20c6,$2000,$20c7,$2000,$20c8,$2000,$20c9,$2000,$20ca,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //11
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //12
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //13
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$20cb,$2000,$20cc,$2000,$20cd,$2000,$20ce,$2000  //14
  dw $20cf,$2000,$20d0,$2000,$20d1,$2000,$20d2,$2000,$20ae,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //15
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //16
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //17
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2074,$2000,$2075,$2000,$2076,$2000,$2077,$2000  //18
  dw $2078,$2000,$2079,$2000,$207a,$2000,$207b,$2000,$207c,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //19
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //1a
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //1b
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$207d,$2000,$207e,$2000,$207f,$2000,$2080,$2000  //1c
  dw $2081,$2000,$2082,$2000,$2083,$2000,$2084,$2000,$2085,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //1d
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //1e
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //1f
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2086,$2000,$2087,$2000,$2088,$2000,$2089,$2000  //20
  dw $208a,$2000,$208b,$2000,$208c,$2000,$208d,$2000,$208e,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //21
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //22
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //23
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2030,$2031,$2032,$2000,$2000,$2000,$2000,$2000  //24
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //25
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //26
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //27
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //28
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //29
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //2a
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //2b
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //2c
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //2d
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //2e
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //2f
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //30
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //31
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //32
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //33
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //34
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //35
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //36
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //37
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //38
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //39
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //3a
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //3b
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //3c
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //3d
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //3e
  dw $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000  //3f

  db $1a,$00,$01  //end of compressed block code
}

codeCursor = pc()

}
