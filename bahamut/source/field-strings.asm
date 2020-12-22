namespace field {

seek(codeCursor)

namespace command {
  constant unitDescription = $fa
}

namespace triggers {
  enqueue pc
  seek($c05f85); jsl main; rts
  dequeue pc

  //A => trigger
  //------
  //c05f81  lda $7e3fbe  ;load string index#
  //c05f85  rep #$21
  //c05f87  and #$00ff
  //c05f8a  asl #3
  //c04f8d  and $c70038  ;table starting address
  //c05f91  tay
  //c05f92  sep #$20
  //c05f94  lda #$08
  //c05f96  sta $08
  //c05f98  ldx #$0620   ;string target address
  //c05f9b  lda #$c7     ;string source bank
  //c05f9d  sta $10
  //c05f9f  jsr $e089    ;copy the string to RAM
  //c05fa2  lda #$ff     ;string terminator
  //c05fa4  sta $00,x    ;store value
  //c05fa6  rts
  //------
  function main {
    enter
    and #$00ff
    ldx #$0000; append.stringIndexed(output, lists.triggers.text)
    leave; rtl
  }
}

namespace unitDescription {
  enqueue pc
  seek($c0ab2d); jsl tilemap
  seek($c0ab4b); jsl render; rts
  dequeue pc

  //[$c0ecea] "てきのユニットです。"
  //[$c0ecf6] "ドラゴンユニットです。"
  //[$c0ed03] "ＮＰＣユニットです。"
  //[$c0ed0f] "パーティーユニットです。"
  //[$c0ed1c] "こうどうずみユニットです。"
  function render {
    enter
    and #$00ff; ldx #$0620
    cmp #$00c0; bne noMatch  //text should always be in bank $c0
    cpy #$ecea; bne +; ldy.w #enemyUnit-strings;    bra write; +
    cpy #$ecf6; bne +; ldy.w #dragonUnit-strings;   bra write; +
    cpy #$ed03; bne +; ldy.w #npcUnit-strings;      bra write; +
    cpy #$ed0f; bne +; ldy.w #partyUnit-strings;    bra write; +
    cpy #$ed1c; bne +; ldy.w #alreadyMoved-strings; bra write; +
    cpy #$eed6; bne +; ldy.w #cannotMove-strings;   bra write; +
    noMatch:; ldy.w #unknown-strings

  write:
    sep #$20
    lda.b #command.unitDescription; sta $00,x; inx
    lda.b #command.terminal; sta $00,x

    //this forces the window text length to 192px (to match all other 1-line dialogue text boxes)
    sep #$20; lda.b #24; sta $08  //24 tiles @ 8x8/tile => 192px

    //transfer the string to render
    phk; plb
    ldx #$0000; append.string(strings)  //source specified to use Y index

    lda #$18; render.large.bpp4()
    vsync()
    ldb #$00; rep #$20
    lda #$6000; lsr; sta $2116
    lda.w #render.buffer >>  0; sta $4302
    lda.w #render.buffer >> 16; sta $4304
    lda #$0600; sta $4305
    sep #$20
    lda #$80; sta $2115
    lda #$01; sta $4300
    lda #$18; sta $4301
    lda #$01; sta $420b
    leave; rtl

    strings: {
      enemyUnit:;    db "This is an enemy unit.",$ff
      dragonUnit:;   db "This is a dragon unit.",$ff
      npcUnit:;      db "This is an NPC unit.",$ff
      partyUnit:;    db "This is a party unit.",$ff
      alreadyMoved:; db "This unit has already moved.",$ff
      cannotMove:;   db "This unit cannot move.",$ff
      unknown:;      db "???",$ff
    }
  }

  function tilemap {
    lda output,x; cmp.b #command.unitDescription; beq +; rtl; +

    php; rep #$30; pha; phx; phy
    lda #$0018; tax  //string length in tiles
    lda #$2300       //tile attributes
  -;sta $0000,y; inc
    sta $0040,y; inc
    iny #2; dex; bne -
  +;ply; plx; pla; plp
    inx; jmp tilemap  //skip past the control code and load another byte
  }
}

//[$c0ed94] "よりみち"
//[$c0ed99] "シナリオ"
//[$c0ed9d] "ターン"
//"Scenario {#}, Turn {#}"
//"Scenario" has been localized as "Chapter"
//this is so that "Scenario 0" can be written as "Prologue", etc
namespace scenarioTurn {
  enqueue pc
  seek($c0a0a9); jsl main; rts
  dequeue pc

  //------
  //c0a0a9  lda $7e3bd8  ;load chapter#
  //c0a0ad  cmp #$1c     ;see if it's a side quest
  //c0a0af  bcc $a0c5    ;if not, print "scenario"; if so, print "side quest"
  //......               ;prints one of the two strings above
  //c0a0d4  jsr $a51f    ;prints scenario#
  //c0a0d7  lda $7e3bd6  ;load turn# (lower byte)
  //c0a0db  ora $7e3bd7  ;load turn# (upper byte)
  //c0a0df  beq $a0f5    ;don't print if zero
  //......               ;print "turn" + #
  //c0a0f5  lda #$ff     ;string terminator
  //c0a0f7  sta $0720,y  ;write terminator
  //c0a0fa  rts          ;end of function
  //------
  function main {
    constant chapter = $7e3bd8
    constant turn    = $7e3bd6

    enter; ldx #$0000
    lda.l chapter; and #$00ff; append.stringIndexed(output, lists.chapters.text)
    lda.l turn; beq +; append.literal(output, ", Turn "); append.integer5(output); +
    leave; rtl
  }
}

//[$c0edef] "はレベルアップ。"
//"{name} leveled up."
namespace leveledUp {
  enqueue pc
  seek($c0a755); jsl main; jmp $a761
  dequeue pc

  //A => name
  function main {
    enter; ldx #$0000
    and #$00ff; append.name(output)
    append.literal(output, " leveled up.")
    leave; rtl
  }
}

//{name} [{level} [{plus}] [[{times}] [{power}]]]
//"Inspire Lv.## +# *# P###"
//times => number of players with skill type (damage multiplier)
//power => MP ? Magic : SP ? Attack
namespace techniqueLarge {
  enqueue pc
  seek($c0a8b1); jsl main; rts
  dequeue pc

  //------
  //c0a8b1  lda $3d      ;load technique name
  //c0a8b3  jsr $d6d0    ;add name to string
  //c0a8b6  lda $1a05    ;see if the the string should stop printing after the name
  //c0a8b9  bne $a90f    ;if $1a05 == 0, then print additional information
  //c0a8bb  jsr $d6e7    ;add level to string
  //c0a8be  jsr $a914    ;prints "+#" if $7e3fc2 > 0 (truncates 10s/100s)
  //c0a8c1  lda $c0ffad  ;see if the debugger is enabled to print additional information
  //c0a8c5  bne $a90f    ;if $c0ffad == 0, then print additional information
  //c0a8c7  lda $30      ;load times
  //c0a8c9  beq $a8e2    ;only print if not-zero
  //......               ;print the value (1-digit)
  //c0a8e2  lda $3f      ;load power
  //c0a8e4  beq $a09f    ;stop printing if zero
  //......               ;print the value (3-digits)
  //c0a90f  lda #$ff     ;string terminator
  //c0a911  sta $00,x    ;write terminator
  //c0a913  rts          ;end of function
  //------
  function main {
    constant name      = $3d
    constant level     = $19
    constant stop      = $1a05
    constant plus      = $7e3fc2
    constant debugging = $c0ffad
    constant times     = $30
    constant power     = $3f

    enter; ldx #$0000
    lda.b name; and #$00ff
    append.stringIndexed(output, lists.techniques.text)
    lda.w stop; and #$00ff; beq +; leave; rtl; +
    lda.b level; and #$00ff; append.literal(output, " Lv."); append.integer_2(output)
    lda.l plus; and #$00ff; beq +; append.literal(output, " +"); append.integer1(output); +
    lda.l debugging; and #$00ff; beq +; leave; rtl; +
    lda.b times; and #$00ff; beq +; append.literal(output, " *"); append.integer1(output); +
    lda.b power; and #$00ff; beq +; append.literal(output, " P"); append.integer3(output); +
    leave; rtl
  }
}

namespace techniqueDescription {
  enqueue pc
  seek($c0d756); jsl main; rts
  dequeue pc

  function main {
    enter; ldx #$0000
    and #$00ff; add.w #352  //technique description index
    append.stringIndexed(output, lists.descriptions.text)
    leave; rtl
  }
}

//[$c0ef83] "パーティーの経験値＋"
namespace gainedExperience {
  enqueue pc
  seek($c0a70c); jsl main; jmp $a725
  dequeue pc

  function main {
    constant experience = $18fc

    enter; ldx #$0000
    lda.w experience
    append.literal(output, "Gained ")
    lda.w experience; append.integer5(output)
    append.literal(output, " experience.")
    leave; rtl
  }
}

//[$c0ef91] "全買の経験値＋"
namespace everyoneGainedExperience {
  enqueue pc
  seek($c08864); nop #3  //disable static text
  seek($c0887e); jsl main; jmp $888e
  dequeue pc

  //A => experience
  function main {
    enter; ldx #$0000
    append.literal(output, "Everyone gained ")
    append.integer5(output)
    append.literal(output, " experience.")
    leave; rtl
  }
}

//[$c0ef5a] "建物による回復"
namespace buildingRecovery {
  enqueue pc
  seek($c08e4c); jsl main; nop #4
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "Recovered HP from building.")
    leave; rtl
  }
}

//[$c0ef65] "毒のダメージ"
namespace poisonDamage {
  enqueue pc
  seek($c08b58); jml main; nop #2
  dequeue pc

  //------
  //c08b58  ldx #$ef65  ;string address
  //c08b5b  jsr $8b8b
  //c08b8b  lda #$22    ;string length
  //c08b8d  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Took poison damage.")
    leave
    pea $8b5d
    jml $c08b90
  }
}

//[$c0ef6e] "炎のダメージ"
namespace fireDamage {
  enqueue pc
  seek($c08b6b); jml main; nop #2
  dequeue pc

  //------
  //c08b6b  ldx #$ef6e  ;string address
  //c08b6e  jsr $8b8b
  //c08b8b  lda #$22    ;string length
  //c08b8d  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Took fire damage.")
    leave
    pea $8b70
    jml $c08b90
  }
}

//[$c0efee] "溶岩のダメージ"
namespace lavaDamage {
  enqueue pc
  seek($c08b7e); jml main; nop #2
  dequeue pc

  //------
  //c08b7e  ldx #$efee  ;string address
  //c08b81  jsr $8b8b
  //c08b8b  lda #$22    ;string length
  //c08b8d  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Took lava damage.")
    leave
    pea $8b83
    jml $c08b90
  }
}

//[$c0efe7] "{item}{quantity}を入手。"
namespace obtainedItems {
  enqueue pc
  seek($c07720); jsl main; rts
  dequeue pc

  //XL => item
  //XH => count
  function main {
    variable(2, item)
    variable(2, count)
    variable(64, name)

    enter
    txa; and #$007f; sta item
    txa; xba; and #$00ff; sta count
    ldx #$0000; append.literal(output, "Obtained ")
    lda count; cmp #$0001; jne pluralCount

  singularCount:
    append.literal(output, "a")
    phx; ldx #$0000; lda item; append.stringIndexed(name, lists.items.text); plx
    lda name; and #$00ff
    cmp.w #'A'; bne +; append.literal(output, "n"); +
    cmp.w #'E'; bne +; append.literal(output, "n"); +
    cmp.w #'I'; bne +; append.literal(output, "n"); +
    cmp.w #'O'; bne +; append.literal(output, "n"); +
    cmp.w #'U'; bne +; append.literal(output, "n"); +
    jmp itemName

  pluralCount:
    append.integer3(output)

  itemName:
    append.literal(output, " "); +
    lda item; append.stringIndexed(output, lists.items.text)
    lda count; cmp #$0001; jne pluralName

  singularName:
    append.literal(output, ".")
    leave; rtl

  pluralName:
    lda output-1,x; and #$00ff
    cmp.w #'s'; jeq pluralNameS
    cmp.w #'y'; jeq pluralNameY
    append.literal(output, "s.")
    leave; rtl

  pluralNameS:
    append.literal(output, "es.")
    leave; rtl

  pluralNameY:
    dex; append.literal(output, "ies.")
    leave; rtl
  }
}

//[$c0ef37] "このパーティーと戦いますか？"
namespace attackEnemy {
  enqueue pc
  seek($c09c2c); jsl main; nop #4
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "Engage this party in battle?")
    leave; rtl
  }
}

//[$c0eee4] "ゲームをセーブしますか？"
namespace createTemporarySave {
  enqueue pc
  seek($c036d4); jsl main; nop #4
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "Create a temporary save?")
    leave; rtl
  }
}

//[$c0eef1] "テンポラリーにセーブしました。"
namespace createdTemporarySave {
  enqueue pc
  seek($c036fe); jsl main; nop #4
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "A temporary save was created.")
    leave; rtl
  }
}

//[$c0ef10] "プレイヤーフェイズを終了します。"
namespace endPlayerPhase {
  enqueue pc
  seek($c036a3); jsl main; nop #4
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "End player phase?")
    leave; rtl
  }
}

//[$c0ef9e] "アイテムを入手しました。"
namespace receivedItems {
  enqueue pc
  seek($c061d6); jml main; nop #2
  dequeue pc

  //note: making the string plural (item vs items) is tricky because the item
  //quantity doesn't factor in how many of each item was received.
  //------
  //c061b8  lda $0360   ;load item drop quantity
  //c061bb  bne $61d6   ;only print if non-zero
  //......
  //c061d6  ldx #$ef9e  ;string address
  //c061d9  jsr $8b8b   ;reuse code
  //......
  //c08b8b  lda #$22    ;string length
  //c08b8d  jsr $a113   ;print the string
  //c08b90  ...         ;essential JSRs that display the string onscreen
  //------
  //A => item quantity
  function main {
    enter; ldx #$0000
    append.literal(output, "Received item drop.")
    leave
    pea $61db    //fake jsr $8b8b from $c061d9
    jml $c08b90  //but also skip over Japanese text copy of $8b8b subroutine
  }
}

//**untested**
//[$c0efad] "お金を入手しました。"
namespace receivedPiro {
  enqueue pc
  seek($c061c3); jml main; nop #2
  dequeue pc

  //------
  //c061c3  ldx #$efad  ;string address
  //c061c6  jsr $8b8b
  //c08b8b  lda #$22    ;string length
  //c08b8d  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Received piro.")
    leave
    pea $61c8
    jml $c08b90
  }
}

//**untested**
//[$c0edab] "えがら"
//[$c0edae] "ポーズ"
namespace patternPose {
  enqueue pc
  seek($c0b695); jsl main; rts
  dequeue pc

  //------
  //c0b695  ldx #$edab   ;pattern text
  //c0b698  ldy #$0000   ;target string offset
  //c0b69b  lda #$03     ;string length
  //c0b69d  jsr $a113    ;write string
  //c0b6a0  lda $0afa    ;pattern number
  //c0b6a3  jsr $a15f    ;write single-digit integer
  //c0b6a6  ldx #$edae   ;pose text
  //c0b6a9  lda #$03     ;string length
  //c0b6ab  jsr $a116    ;write string
  //c0b6ae  lda $0af9    ;pose number
  //c0b6b1  jsr $a15f    ;write single-digit integer
  //c0b6b4  lda #$ff     ;terminal
  //c0b6b6  sta $0720,y  ;write terminal
  //c0b6b9  rts
  //------
  function main {
    constant patternNumber = $0afa
    constant poseNumber    = $0af9

    enter; ldx #$0000
    append.literal(output, "Pattern ")
    lda.w patternNumber; and #$00ff
    append.integer3(output)
    append.literal(output, ", Pose ")
    lda.w poseNumber; and #$00ff
    append.integer3(output)
    leave; rtl
  }
}

//**untested**
//[$c0efbc] "に進化しました。"
namespace dragonEvolved {
  enqueue pc
  seek($c0a78f); jsl main; jmp $a7c2
  dequeue pc

  //------
  //c0a78b  lda $7e3bf1,x  ;load dragon type
  //c0a78f  rep #$21
  //c0a791  and #$00ff
  //c0a794  asl #3
  //c0a797  adc #$63d8     ;dragon type string table offset
  //c0a79a  tay
  //c0a79b  sep #$20
  //c0a79d  lda #$08
  //c0a79f  ldx #$0620     ;string write target
  //c0a7a2  jsr $e083      ;copy dragon type to string target
  //c0a7a5  lda $00,x      ;seek backwards to find the end of the string
  //c0a7a7  cmp #$ef
  //c0a7a9  bne $a7b1
  //c0a7ab  dex
  //c0a7ac  cpx #$0620
  //c0a7af  bne $a7a5
  //c0a7b1  inx
  //c0a7b2  rep #$21
  //c0a7b4  txa
  //c0a7b5  sec
  //c0a7b6  sbc #$0620
  //c0a7b9  tay
  //c0a7ba  sep #$20
  //c0a7bc  ldx #$efbc     ;evolved into text location
  //c0a7bf  jsr $a942      ;append to string
  //------
  //A => dragon type
  function main {
    variable(2, type)
    variable(64, string)

    enter
    and #$00ff; sta type
    ldx #$0000; append.stringIndexed(string, lists.dragons.text)
    ldx #$0000; append.literal(output, "Evolved into a")
    lda string; and #$00ff
    cmp.w #'A'; bne +; append.literal(output, "n"); +
    cmp.w #'E'; bne +; append.literal(output, "n"); +
    cmp.w #'I'; bne +; append.literal(output, "n"); +
    cmp.w #'O'; bne +; append.literal(output, "n"); +
    cmp.w #'U'; bne +; append.literal(output, "n"); +
    append.literal(output, " ")
    lda type; append.stringIndexed(output, lists.dragons.text)
    append.literal(output, ".")
    leave; rtl
  }
}

//[$c0eebe] "ここにいるとおぼれます。（３）"
namespace drowningWarning {
  enqueue pc
  seek($c08fe7); jsl main; jmp $8ff4
  dequeue pc

  //------
  //c08fe7  pha         ;save the encoded # of turns before drowning
  //c08fe8  ldx #$eebe  ;string address
  //c08feb  lda #$22    ;string length
  //c08fed  jsr $a113   ;print the string
  //c08ff0  pla         ;restore the encoded # of turns before drowning
  //c08ff1  sta $072d   ;store it in the string
  //------
  //A => # of turns before drowning (starting from '0')
  function main {
    enter; ldx #$0000
    append.literal(output, "Will drown in ")
    and #$00ff; sub.w #'0'; append.integer1(output)
    append.literal(output, " more turn")
    cmp #$0001; beq +; append.literal(output, "s"); +
    append.literal(output, ".")
    leave; rtl
  }
}

//[$c0eece] "おぼれました。"
namespace drowned {
  enqueue pc
  seek($c08fd6); jsl main; nop #4
  dequeue pc

  //------
  //c08fd6  ldx #$eece  ;string address
  //c08fd9  lda #$22    ;string length
  //c08fdb  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Drowned.")
    leave; rtl
  }
}

//**untested**
//[$c0ef48] "移動先を指定してください。"
function moveDestination {
  enqueue pc
  seek($c0932d); jsl main; jmp $9335
  dequeue pc

  //------
  //c0932d  ldx #$ef48  ;string address
  //c09330  lda #$22    ;string length
  //c09332  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Please specify the move destination.")
    leave; rtl
  }
}

//[$c0efc8] "章の始めからやりなおしますか？"
function gameOverRetry {
  enqueue pc
  seek($c0a1b3); jsl main; nop #4
  dequeue pc

  //------
  //c0a1b3  ldx #$efc8  ;string address
  //c0a1b6  lda #$20    ;string length
  //c0a1b8  jsr $a113   ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Try again from the beginning?")
    leave; rtl
  }
}

//crash handler strings
//---------------------

//[$c0edc7] "エラー１　ＰＵ００Ｘ００Ｙ００"
namespace error1 {
  enqueue pc
  seek($c0a2f4); jsl main; rts
  dequeue pc

  //I am unaware of the meaning of these three debugging values.
  //------
  //c0a2f4  ldx #$edc7  ;string address
  //c0a2f7  ldy #$0000  ;write address
  //c0a2fa  lda #$10    ;string length
  //c0a2fc  jsr $a113   ;print the string
  //c0a2ff  lda $b1
  //c0a301  cmp #$0c
  //c0a303  bcc $a30e
  //c0a305  sbc #$0c
  //c0a307  sta $b1
  //c0a309  lda #$bd
  //c0a30b  sta $0725
  //c0a30e  ldy #$0007
  //c0a311  lda $b1
  //c0a313  jsr $a32d   ;print hex value
  //c0a316  ldy #$000a
  //c0a319  ldx $b2
  //c0a31b  lda $1401,x
  //c0a31e  jsr $a32d   ;print hex value
  //c0a321  ldy #$000d
  //c0a324  ldx $b2
  //c0a326  lda $1402,x
  //c0a329  jsr $a32d   ;print hex value
  //c0a32c  rts         ;finished generating debug string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Error 1:")

    lda $b1; and #$00ff; cmp #$000c; bcc +
    sbc #$000c; append.literal(output, " EU"); append.hex02(output); bra ++
  +;append.literal(output, " PU"); append.hex02(output)
  +;phx; ldx $b2; lda $1401,x; and #$00ff; plx
    append.literal(output, " PX"); append.hex02(output)
    phx; ldx $b2; lda $1402,x; and #$00ff; plx
    append.literal(output, " PY"); append.hex02(output)

    leave; rtl
  }
}

//[$c0ede0] "エラー２　ＰＵ００　ＰＵ００"
namespace error2 {
  enqueue pc
  seek($c0a2ba); jsl main; rts
  dequeue pc

  //I am unaware of the meaning of these two debugging values.
  //------
  //c0a2ba  ldx #$ede0  ;string address
  //c0a2bd  ldy #$0000  ;write address
  //c0a2c0  lda #$10    ;string length
  //c0a2c2  jsr $a113   ;print string
  //c0a2c5  lda $26
  //c0a2c7  cmp #$0c
  //c0a2c9  bcc $a2d4
  //c0a2cb  sbc #$0c
  //c0a2cd  sta $26
  //c0a2cf  lda #$bd
  //c0a2d1  sta $0725
  //c0a2d4  lda $27
  //c0a2d6  cmp #$0c
  //c0a2d8  bcc $a2e3
  //c0a2da  sbc #$0c
  //c0a2dc  sta $27
  //c0a2de  lda #$bd
  //c0a2e0  sta $072a
  //c0a2e3  ldy #$0007
  //c0a2e6  lda $26
  //c0a2e8  jsr $a32d  ;print hex value
  //c0a2eb  ldy #$000c
  //c0a2ee  lda $27
  //c0a2f0  jsr $a32d  ;print hex value
  //c0a2f3  rts        ;finished generating debug string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "Error 2:")

    lda $26; and #$00ff; cmp #$000c; bcc +
    sbc #$000c; append.literal(output, " EU"); append.hex02(output); bra ++
  +;append.literal(output, " PU"); append.hex02(output)
  +;lda $27; and #$00ff; cmp #$000c; bcc +
    sbc #$000c; append.literal(output, " EU"); append.hex02(output); bra ++
  +;append.literal(output, " PU"); append.hex02(output)
  +;

    leave; rtl
  }
}

//[$c0edd7] "リセットします。"
namespace resetting {
  enqueue pc
  seek($c0a2aa); jsl main; nop
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "The game will now be reset.")
    leave; rtl
  }
}

//debugger strings
//----------------

//[$c0edbd] "バトルをしますか？"
namespace allowBattle {
  enqueue pc
  seek($c02c69); jsl main; nop #4
  dequeue pc

  function main {
    enter; ldx #$0000
    append.literal(output, "Allow this move?")
    leave; rtl
  }
}

//[$c0efdc] "使用不可です。"
//when $c0ffad=#$01, temporary saving is disabled and shows this message instead.
namespace cannotCreateTemporarySave {
  enqueue pc
  seek($c0370a); jml main; nop
  dequeue pc

  //------
  //c036cc  lda $c0ffad  ;load lower debugging flag
  //c036d0  cmp #$01
  //c036d2  beq $370a
  //......
  //c0370a  ldx #$efdc   ;string address
  //c0370d  bra $3701    ;reuse code
  //......
  //c03701  lda #$10     ;string length
  //c03703  jsr $a113    ;print the string
  //------
  function main {
    enter; ldx #$0000
    append.literal(output, "This feature cannot be used.")
    leave
    jml $c03706
  }
}

//unused strings
//--------------

namespace unusedStrings {
  enqueue pc

  //most likely, these were used prior to the full-screen phase/win/lose graphics
  seek($c0ed7b); db "Player Phase",$ff;   assert(pc() == $c0ed88)  //"プレイヤーフェイズです。"
  seek($c0ed88); db "Enemy Phase",$ff;    assert(pc() == $c0ed94)  //"エネミーフェイズです。"
  seek($c0ee89); db "Game Over",$ff,$ff;  assert(pc() == $c0ee94)  //"ゲームオーバーです。"
  seek($c0ee94); db "Player Won",$ff,$ff; assert(pc() == $c0eea0)  //"シナリオクリアーです。"

  //these strings might be used, but I cannot locate any code references to them
  seek($c0eede); db " TF.",$ff,$ff;            assert(pc() == $c0eee4)  //"になった。"
  seek($c0ef23); db "Tech ?? P ?? TID ??",$ff; assert(pc() == $c0ef37)  //"技ＮＯ？？パワー？？地ＩＤ？？"
  seek($c0ef77); db "Can't move.",$ff;         assert(pc() == $c0ef83)  //"行動不能状態です。"

  //this is likely leftover data between valid strings
  seek($c0eeac); fill 18,$ff; assert(pc() == $c0eebe)

  dequeue pc
}

codeCursor = pc()

}
