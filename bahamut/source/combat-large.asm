namespace combat {

seek(codeCursor)

constant buffer = $5e  //the string to render is located at [$5e],y
variable(256, text)    //buffer used for redirected text

function renderLargeText {
  enqueue pc
  seek($c13465); jsl main
  seek($c13671); jmp $3681; nop #13  //disable control codes $f0-$f3
  seek($c13685); jmp $369f; nop #17  //disable control codes $f4-$f8
  dequeue pc

  constant wramBuffer = $7e7568  //location to render strings to

  variable(256, string)   //control codes in the source string are parsed and decoded into string
  variable(2, character)  //current character to render
  variable(2, pixel)      //current X rendering position
  variable(2, pixels)     //width of text: set to 224 or 240
  variable(2, style)      //current style being used ($00 = normal, $60 = italic)
  variable(2, color)      //current color being used ($00 = normal, $01 = yellow)

  //------
  //c13465  lda [$5e],y  ;load next character to render
  //c13467  cmp #$f0     ;test if this is a control code
  //------
  function main {
    phb; php; ldb #$7e
    rep #$30; pha; phx

    //determine window width based on BG2 tilemap text window position (ordering is important!)
    lda.w #224; sta pixels  //fallback in case width cannot be determined
    lda $4880; cmp #$3801; bne +; lda.w #240; sta pixels; +  //top of screen
    lda $4e42; cmp #$3801; bne +; lda.w #224; sta pixels; +  //bottom of screen

    //clear RAM before rendering; needed for combat dialogue text
    initialize: {
      lda #$0000; sta character; sta pixel; sta style; sta color
      ldx #$03c0
      clear: {
        txa; sub #$0010; tax
        stz $7560,x; stz $7562,x; stz $7564,x; stz $7566,x
        stz $7568,x; stz $756a,x; stz $756c,x; stz $756e,x
        bne clear
      }
    }

    loop: {
      lda [buffer],y; and #$00ff; iny
      cmp.w #command.base;        bcs +; jsl renderCharacter;   bra loop; +
      cmp.w #command.pause;       bcc +; jmp finished; +
      cmp.w #command.name;        bne +; jsl name;              bra loop; +
      cmp.w #command.redirect;    bne +; jsl redirect;          bra loop; +
      cmp.w #command.styleNormal; bne +; lda.w #$00; sta style; bra loop; +
      cmp.w #command.styleItalic; bne +; lda.w #$60; sta style; bra loop; +
      cmp.w #command.colorNormal; bne +; lda.w #$00; sta color; bra loop; +
      cmp.w #command.colorYellow; bne +; lda.w #$01; sta color; bra loop; +
      cmp.w #command.alignLeft;   bne +; jsl align.left;        bra loop; +
      cmp.w #command.alignCenter; bne +; jsl align.center;      bra loop; +
      cmp.w #command.alignRight;  bne +; jsl align.right;       jmp loop; +
      cmp.w #command.alignSkip;   bne +; jsl align.skip;        jmp loop; +
      jmp loop
    }

    finished: {
      rep #$30; plx; pla; plp; plb
      dey; lda [buffer],y; cmp #$f0; rtl
    }
  }

  //A => encoded character
  function renderCharacter {
    phx; phy
    character.decode(); add style

    //perform font kerning
    pha; lda character; mul(180); add $01,s; tax
    lda largeFont.kernings,x; and #$00ff; pha
    lda pixel; sub $01,s; sta pixel; pla; pla
    sta character

    //calculate font read position: pixel % 8 * 8192 + character * 48
    lda pixel; and #$0007; mul(8192); pha
    lda character; mul(44); add $01,s; tax; pla

    //calculate RAM write position: wramBuffer + pixel / 8 * 32
    lda pixel; and #$00f8; asl #2; add.w #wramBuffer; tay

    //add the width of the current character to the pixel counter
    phx; lda character; tax
    lda largeFont.widths,x; and #$00ff
    plx; add pixel; cmp pixels; bcc +; beq +
    lda pixels; sta pixel; ply; plx; rtl
  +;sta pixel

    //draw all 11 lines of the current character
    lda color; jne yellow

    macro render(variable font) {
      macro line(variable n) {
        lda.l font+$00+n*2,x; ora.w $0000+n*2,y; sta.w $0000+n*2,y
        lda.l font+$16+n*2,x; ora.w $0020+n*2,y; sta.w $0020+n*2,y
      }
      line(0); line(1); line(2); line(3); line(4)
      line(5); line(6); line(7); line(8); line(9); line(10)
      ply; plx; rtl
    }

    normal:; render(largeFont.normal)
    yellow:; render(largeFont.yellow)
  }

  namespace align {
    function left {
      lda.w #0; sta pixel; rtl
    }

    function center {
      tya;      add.b buffer+0; sta render.large.width.address+0
      lda.w #0; adc.b buffer+2; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; inc; sub $01,s; lsr; sta pixel; pla; rtl
    }

    function right {
      tya;      add.b buffer+0; sta render.large.width.address+0
      lda.w #0; adc.b buffer+2; sta render.large.width.address+2
      lda style; sta render.large.width.style; jsl render.large.width
      cmp pixels; bcc +; beq +; lda.w #0; sta pixel; rtl; +
      pha; lda pixels; sub $01,s; sta pixel; pla; rtl
    }

    function skip {
      lda [buffer],y; and #$00ff
      add pixel; sta pixel; rtl
    }
  }

  function name {
    lda [buffer],y; and #$00ff; iny
    ldx #$0000; append.name(); ldx #$0000
    loop: {
      lda render.text,x; and #$00ff; inx
      cmp.w #command.terminal; bne +; rtl; +
      jsl renderCharacter; bra loop
    }
  }

  function redirect {
    lda.w #text >> 0; sta.b buffer+0
    lda.w #text >> 8; sta.b buffer+1
    ldy #$0000; rtl
  }
}

function itemDescription {
  enqueue pc
  seek($c1432c); jsl main; jmp $4335
  dequeue pc

  //------
  //c14328  lda $7ec000,x  ;load item ID
  //c1432c  jsr $05fc      ;sets Y=A*2
  //c1432f  rep #$20
  //c14331  lda [$28],y    ;load pointer for item description
  //c14333  sta $5e        ;set string read position to item description
  //------
  //A => item
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

  //------
  //c14364  lda $0850,x  ;load technique ID
  //c14367  jsr $05fc    ;sets Y=A*2
  //c1436a  rep #$20
  //c1435c  lda [$28],y  ;load pointer for technique description
  //c1436e  sta $5e      ;set string read position to technique description
  //------
  //A => technique
  function main {
    enter
    and #$00ff; add.w #128  //entries 128-383 are technique descriptions
    asl; tax; lda.l lists.descriptions.text,x
    add.w #lists.descriptions.text >>  0; sta.b buffer+0; sep #$20; lda.b #0
    adc.b #lists.descriptions.text >> 16; sta.b buffer+2
    leave; rtl
  }
}

function techniqueName {
  enqueue pc
  seek($c1b4d6); jsl main; jmp $b4e6
  dequeue pc

  constant target = $7ec000

  //------
  //c1b4d6  sta $7ec001  ;store technique name ID
  //c1b4da  lda #$f6     ;technique control code
  //c1b4dc  sta $7ec000  ;store control code
  //c1b4e0  lda #$ff     ;string terminal
  //c1b4e2  sta $7ec002  ;store terminal
  //------
  //A => technique
  function main {
    enter; ldx #$0000; append.redirect(target); ldx #$0000
    and #$00ff
    append.alignCenter(text)
    append.stringIndexed(text, lists.techniques.text)
    leave; rtl
  }
}

function itemName {
  enqueue pc
  seek($c1b0e5); jsl main; nop #12
  dequeue pc

  constant target = $7ec000

  //------
  //c1b0e2  lda $08d5
  //c1b0e5  sta $7ec001
  //c1b0e9  lda #$f7
  //c1b0eb  sta $7ec000
  //c1b0ef  lda #$ff
  //c1b0f1  sta $7ec002
  //------
  //A => item
  function main {
    enter; ldx #$0000; append.redirect(target); ldx #$0000
    and #$00ff
    append.alignCenter(text)
    append.stringIndexed(text, lists.items.text)
    leave; rtl
  }
}

//[$c1db3c] "スカ"
function failed {
  enqueue pc
  seek($c1c089); jsl main; jmp $c09b
  dequeue pc

  constant target = $7ec100

  //------
  //c1c089  phb
  //c1c08a  rep #$20
  //c1c08c  ldx #$db3c   ;location of failed text
  //c1c08f  ldy #$c100   ;string target location
  //c1c092  lda #$0006   ;string length
  //c1c095  mvn $7e=$c1  ;transfer string
  //c1c098  sep #$20
  //c1c09a  plb
  //c1c09b  bra $c0b6
  //------
  function main {
    enter; ldx #$0000; append.redirect(target); ldx #$0000
    append.alignCenter(text)
    append.literal(text, "Failed!")
    leave; rtl
  }
}

//[$c1db3f] "ぶんしん"
function alterEgo {
  enqueue pc
  seek($c1b51b); jsl main; jmp $b52d
  dequeue pc

  constant target = $7ec000

  //------
  //c1b50f  lda $0955
  //c1b512  and #$04
  //c1b514  jsr $8bc7    ;performs three tests for game over condition
  //c1b517  cmp #$01
  //c1b519  bne $b567 => rts
  //c1b51b  php
  //c1b51c  rep #$20
  //c1b51e  ldx #$db3f   ;location of alter ego text
  //c1b521  ldy #$c000   ;string target location
  //c1b524  lda #$000f   ;string length
  //c1b527  mvn $7e=$c1  ;transfer string
  //c1b52a  sep #$20
  //c1b52c  plb
  //c1b52d  jsr $b4e6
  //------
  function main {
    enter; ldx #$0000; append.redirect(target); ldx #$0000
    append.alignCenter(text)
    append.literal(text, "Alter Ego")
    leave; rtl
  }
}

//[$c1db21] "{technique}Ｌ{integer2}"
function techniqueUse {
  enqueue pc
  seek($c1b0cc); jsl main; jmp $b0f5
  dequeue pc

  constant target = $7ec000
  constant name   = $7e08d5

  //------
  //c1b0b0  phb
  //c1b0b1  rep #$20
  //c1b0b3  ldx #$db21   ;template string source location
  //c1b0b6  ldy #$c000   ;string target location
  //c1b0b9  lda #$000f   ;string length
  //c1b0bc  mvn $7e=$c1
  //c1b0bf  sep #$20
  //c1b0c1  plb
  //c1b0c2  lda $08d5    ;technique name
  //c1b0c5  sta $7ec001  ;store the name into the template string
  //c1b0c9  jsr $69e3
  //......
  //c14ff7  lda $7e2006  ;technique level
  //......
  //c1b0cc  cmp #$00     ;if 0:
  //c1b0ce  beq $b0da    ;do not print the level
  //c1b0d0  cmp #$ff     ;if 255:
  //c1b0d2  beq $b0da    ;do not print the level
  //c1b0d4  sta $7ec005  ;store the level into the template string
  //c1b0d8  bra $b0f5
  //c1b0da  lda #$ff
  //c1b0dc  sta $7ec002  ;store the terminator into the template string
  //c1b0e0  bra $b0f5
  //------
  //A => level
  function main {
    variable(2, level)

    enter; ldx #$0000; append.redirect(target); ldx #$0000
    and #$00ff; sta level
    lda name; and #$00ff
    append.alignCenter(text)
    append.stringIndexed(text, lists.techniques.text)
    lda level; and #$00ff
    cmp #$0000; bne +; leave; rtl; +
    cmp #$00ff; bne +; leave; rtl; +
    append.literal(text, " Lv. ")
    append.integer3(text)
    leave; rtl
  }
}

//[$c1db35] "{dragon}になった"
//called when dragons evolve permanently due to feeding them certain items
function dragonEvolved {
  enqueue pc
  seek($c1a1c6); jsl main
  dequeue pc

  constant target = $7ec100

  //------
  //c1a1a7  phb
  //c1a1a8  rep #$20
  //c1a1aa  ldx #$db35     ;template string source location
  //c1a1ad  ldy #$c100     ;string target location
  //c1a1b0  lda #$0006     ;string length
  //c1a1b3  mvn $7e=$c1
  //c1a1b6  sep #$20
  //c1a1b8  plb
  //c1a1b9  lda $0967      ;load the dragon index
  //c1a1bc  sec
  //c1a1bd  sbc #$20       ;relative index adjust
  //c1a1bf  jsr $05ad      ;X = A * 32
  //c1a1c2  lda $7e3bf1,x  ;lookup dragon type
  //c1a1c6  sta $7ec101    ;store the type into the template string
  //------
  //A => dragon type
  function main {
    variable(2, type)
    variable(64, string)

    enter; ldx #$0000; append.redirect(target)
    and #$00ff; sta type
    ldx #$0000; append.stringIndexed(string, lists.dragons.text)
    ldx #$0000; append.byte(text, command.alignCenter)
    append.literal(text, "Evolved into a")
    lda string; and #$00ff
    cmp.w #'A'; bne +; append.literal(text, "n"); +
    cmp.w #'E'; bne +; append.literal(text, "n"); +
    cmp.w #'I'; bne +; append.literal(text, "n"); +
    cmp.w #'O'; bne +; append.literal(text, "n"); +
    cmp.w #'U'; bne +; append.literal(text, "n"); +
    append.literal(text, " ")
    lda type; append.stringIndexed(text, lists.dragons.text)
    leave; rtl
  }
}

//[$c1db35] "{dragon}になった"
//called when a dragon (eg a Behemoth) uses the "Transform" spell to temporarily change forms
function dragonTransformed {
  enqueue pc
  seek($c1c0b2); jsl main
  dequeue pc

  constant target = $7ec100

  //------
  //c1c09d  phb
  //c1c09e  rep #$20
  //c1c0a0  ldx #$db35     ;template string source location
  //c1c0a3  ldy #$c100     ;string target location
  //c1c0a6  lda #$0006     ;string length
  //c1c0a9  mvn $7e=$c1
  //c1c0ac  sep #$20
  //c1c0ad  plb
  //c1c0af  lda $095c      ;load the dragon index
  //c1c0b2  sta $7ec101    ;store the type into the template string
  //------
  //A => dragon type
  function main {
    variable(2, type)
    variable(64, string)

    enter; ldx #$0000; append.redirect(target)
    and #$00ff; sta type
    ldx #$0000; append.stringIndexed(string, lists.dragons.text)
    ldx #$0000; append.byte(text, command.alignCenter)
    append.literal(text, "Became a")
    lda string; and #$00ff
    cmp.w #'A'; bne +; append.literal(text, "n"); +
    cmp.w #'E'; bne +; append.literal(text, "n"); +
    cmp.w #'I'; bne +; append.literal(text, "n"); +
    cmp.w #'O'; bne +; append.literal(text, "n"); +
    cmp.w #'U'; bne +; append.literal(text, "n"); +
    append.literal(text, " ")
    lda type; append.stringIndexed(text, lists.dragons.text)
    leave; rtl
  }
}

codeCursor = pc()

}
