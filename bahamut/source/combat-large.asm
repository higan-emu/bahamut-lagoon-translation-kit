namespace combat {

seek(codeCursor)

constant buffer = $5e  //the string to render is located at [$5e],y

namespace command {
  //custom command codes unique to combat renderer
  constant redirect   = $f0  //todo
  constant fontNormal = $f1
  constant fontYellow = $f2
  constant alignLeft  = $f3
  constant technique  = $f6
  constant item       = $f7
  constant dragon     = $f8
  constant integer    = $f9
}

namespace textPalette {
  //add yellow color to text color palette (assign entries 1-3)
  enqueue pc
  //originally:  dw color(31,31,31); dw color( 6, 6, 6); dw color(31,31,31)
  seek($c1ca4d); dw color(31,31,31); dw color( 6, 6, 6); dw color(31,31, 0)
  dequeue pc
}

function renderLargeText {
  enqueue pc
  seek($c13465); jsl main
  seek($c13671); jmp $3681; nop #13  //disable control codes $f0-$f3
  dequeue pc

  constant wramBuffer = $7e7566  //location to render strings to

  variable(256, string)  //control codes in the source string are parsed and decoded into string

  //------
  //c13465  lda [$5e],y  ;load next character to render
  //c13467  cmp #$f0     ;test if this is a control code
  //------
  function main {
    variable(2, width)      //width of text; set to 224 or 240
    variable(2, character)  //current character to render
    variable(2, pixel)      //current X rendering position
    variable(2, font)       //current font being used (0=normal, 1=yellow)

    phb; php; rep #$30; pha; phx

    ldb #$7e
    jsl parseControlCodes

    //determine window width based on BG2 tilemap position
    lda #$0000; sta width  //fallback in case width cannot be determined
    lda $4e42; cmp #$3801; bne +; lda.w #224; sta width; +  //top of screen
    lda $4880; cmp #$3801; bne +; lda.w #240; sta width; +  //bottom of screen

    //clear RAM before rendering; needed for combat dialogue text
    initialize: {
      lda #$0000; sta character; sta pixel; sta font; tax
      loop: {
        stz $7560,x; stz $7562,x; stz $7564,x; stz $7566,x
        stz $7568,x; stz $756a,x; stz $756c,x; stz $756e,x
        txa; add #$0010; tax
        cmp #$03c0; bcc loop
      }
    }

    //center the string (unless width could not be determined or the string is too long)
    tya;        add.b buffer+0; sta render.large.width.address+0
    lda #$0000; adc.b buffer+2; sta render.large.width.address+2
    jsl render.large.width; cmp width; bcs +
    pha; lda width; sub $01,s; div(2); sta pixel; pla; +

    renderCharacter: {
      lda [buffer],y; and #$00ff
      cmp.w #command.fontNormal; bne +; lda #$0000; sta font;  iny; bra renderCharacter; +
      cmp.w #command.fontYellow; bne +; lda #$0001; sta font;  iny; bra renderCharacter; +
      cmp.w #command.alignLeft;  bne +; lda #$0000; sta pixel; iny; bra renderCharacter; +
      cmp.w #command.pause; jcs finished
      phy; character.decode(); pha

      //perform font kerning
      lda character; xba; lsr; ora $01,s; tax
      lda largeFont.kernings,x; and #$00ff; pha
      lda pixel; sub $01,s; sta pixel; pla; pla
      sta character

      //calculate font read position: pixel % 8 * $1800 + character * 48
      lda pixel; and #$0007; mul($1800); pha
      lda character; mul(48); add $01,s; tax; pla

      //calculate RAM write position: wramBuffer + pixel / 8 * 32
      lda pixel; and #$00f8; asl #2; add.w #wramBuffer; tay

      //add the width of the current character to the pixel counter
      phx; lda character; tax
      lda largeFont.widths,x; and #$00ff
      plx; add pixel; sta pixel

      //draw all 12 lines of the current character
      lda font; jne tileYellow

      tileNormal: {
        macro line(variable n) {
          lda.l largeFont.normal+$00+n*2,x; ora.w $0000+n*2,y; sta.w $0000+n*2,y
          lda.l largeFont.normal+$18+n*2,x; ora.w $0020+n*2,y; sta.w $0020+n*2,y
        }
        line(0); line(1); line(2); line(3); line(4); line(5)
        line(6); line(7); line(8); line(9);line(10);line(11)
        ply; iny; jmp renderCharacter
      }

      tileYellow: {
        macro line(variable n) {
          lda.l largeFont.yellow+$00+n*2,x; ora.w $0000+n*2,y; sta.w $0000+n*2,y
          lda.l largeFont.yellow+$18+n*2,x; ora.w $0020+n*2,y; sta.w $0020+n*2,y
        }
        line(0); line(1); line(2); line(3); line(4); line(5)
        line(6); line(7); line(8); line(9);line(10);line(11)
        ply; iny; jmp renderCharacter
      }
    }

  finished:
    rep #$30; plx; pla; plp; plb
    lda [buffer],y; cmp #$f0; rtl
  }

  //used to convert control codes into text to ease string rendering
  function parseControlCodes {
    enter
    ldx #$0000  //string write cursor

    loop: {
      lda [buffer],y; and #$00ff; iny
      cmp.w #command.name;      jeq name
      cmp.w #command.technique; jeq technique
      cmp.w #command.item;      jeq item
      cmp.w #command.dragon;    jeq dragon
      cmp.w #command.integer;   jeq integer
      sta string,x; inx  //always write subsequent command codes to output string
      cmp.w #command.pause;     jeq pause
      cmp.w #command.wait;      jeq finished
      cmp.w #command.terminal;  jeq finished
      jmp loop  //ignore all other control codes
    }

    name: {
      lda [buffer],y; iny; and #$00ff
      append.name(string)
      jmp loop
    }

    technique: {
      lda [buffer],y; iny; and #$00ff
      append.stringIndexed(string, lists.techniques.text)
      jmp loop
    }

    item: {
      lda [buffer],y; iny; and #$007f
      append.stringIndexed(string, lists.items.text)
      jmp loop
    }

    dragon: {
      lda [buffer],y; iny; and #$00ff

      //load the first letter of the dragon type
      pha; phx; asl; tax
      lda.l lists.dragons.text,x; tax
      lda.l lists.dragons.text,x; and #$00ff; plx
      cmp.w #'A'; beq writeAn
      cmp.w #'E'; beq writeAn
      cmp.w #'I'; beq writeAn
      cmp.w #'O'; beq writeAn
      cmp.w #'U'; beq writeAn
      writeA:;  append.literal(string, "a " ); bra +
      writeAn:; append.literal(string, "an "); +
      pla; append.stringIndexed(string, lists.dragons.text)
      jmp loop
    }

    integer: {
      lda [buffer],y; iny #2
      append.integer5(string)
      jmp loop
    }

    pause: {
      //pass-through pause command + argument directly
      lda [buffer],y; iny
      sta string,x; inx
      jmp loop
    }

    finished: {
      //redirect text cursor to decoded string
      lda.w #string >>  0; sta.b buffer+0; sep #$20
      lda.b #string >> 16; sta.b buffer+2
      leave; rtl
    }
  }
}

function itemDescription {
  enqueue pc
  seek($c1432c); jsl main; jmp $4335
  dequeue pc

  //A = item
  //------
  //c14328  lda $7ec000,x  ;load item ID
  //c1432c  jsr $05fc      ;sets Y=A*2
  //c1432f  rep #$20
  //c14331  lda [$28],y    ;load pointer for item description
  //c14333  sta $5e        ;set string read position to item description
  //------
  function main {
    enter
    and #$007f  //entries 0-127 are item descriptions
    asl; tax; lda.l lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda.b #0
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2
    leave; rtl
  }
}

function techniqueDescription {
  enqueue pc
  seek($c14367); jsl main; jmp $4370
  dequeue pc

  //A => technique
  //------
  //c14364  lda $0850,x  ;load technique ID
  //c14367  jsr $05fc    ;sets Y=A*2
  //c1436a  rep #$20
  //c1435c  lda [$28],y  ;load pointer for technique description
  //c1436e  sta $5e      ;set string read position to technique description
  //------
  function main {
    enter
    and #$01ff; add.w #128  //entries 128-383 are technique descriptions
    asl; tax; lda.l lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda.b #0
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2
    leave; rtl
  }
}

//[$c1db21] "{technique}Ｌ{integer2}"
function techniqueUse {
  enqueue pc
  seek($c1b0b3); ldx.w #string >> 0
  seek($c1b0bc); mvn $7e=string>>16
  seek($c1b0b9); lda.w #string.end-string
  seek($c1b0c5); sta.l $7ec000+1+string.technique-string
  seek($c1b0d4); sta.l $7ec000+1+string.level-string
  dequeue pc

  function string {
  technique:
    db command.technique,0
    db " Lv. "
  level:
    db command.integer,0,0
    db command.terminal
  end:
  }
}

//[$c1db35] "{dragon}になった"
function dragonEvolved {
  enqueue pc
  seek($c1a1aa); ldx.w #string >> 0
  seek($c1a1b3); mvn $7e=string>>16
  seek($c1a1b0); lda.w #string.end-string
  seek($c1a1c6); sta.l $7ec100+1+string.dragon-string
  dequeue pc

  function string {
    db "Evolved into "
  dragon:
    db command.dragon,0
    db "."
    db command.terminal
  end:
  }
}

function bossDefeats {
  enqueue pc
//seek($c1a68a); jsl main
  dequeue pc

  //$7e3bd8 => boss defeat string index
  //$5e <= string address
  function main {
    enter
    sep #$20; lda.b #lists.defeats.text>>16; sta $60; rep #$20
    lda $7e3bd8; and #$00ff; asl; tax
    lda.l  lists.defeats.text,x
    add.w #lists.defeats.text; sta $5e
    leave; rtl
  }
}

codeCursor = pc()

}
