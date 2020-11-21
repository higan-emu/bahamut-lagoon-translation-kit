//utility functions to build text strings for dynamic text rendering
//append macros output to the specified target string with X as an index
//emit functions output to their own variables

seek(codeCursor)

namespace append {
  //X => target index
  macro byte(variable target, variable byte) {
    php; rep #$20; pha
    lda.w #$ff00|byte; sta.l target,x; inx
    pla; plp
  }
  macro byte(variable byte) {
    append.byte(render.text, byte)
  }

  //X => target index
  //Y => source index
  macro string(variable target, variable source) {
    phb; php; sep #$20; pha
    ldb #source>>16
    loop{#}: {
      lda.w source,y; iny
      sta.l target,x; inx
      cmp #$ff; bne loop{#}
    }
    dex; dey  //point cursors at the $ff terminal
    pla; plp; plb
  }
  macro string(variable source) {
    append.string(render.text, source)
  }

  //A => pointer index
  //X => target index
  macro stringIndexed(variable target, variable source) {
    php; rep #$30; pha; phy
    phx; asl; tax
    lda.l source,x; tay
    plx; append.string(target, source)
    ply; pla; plp
  }
  macro stringIndexed(variable source) {
    append.stringIndexed(render.text, source)
  }

  //X => target index
  macro literal(variable target, define source) {
    phb; php; rep #$30; pha; phy
    sep #$20; phk; plb; ldy #$0000
    loop{#}: {
      lda.w text{#},y; iny
      sta.l target,x; inx
      cmp #$ff; bne loop{#}
    }
    dex  //point cursor at the $ff terminal
    rep #$30; ply; pla; plp; plb
    bra skip{#}; text{#}:; db {source},$ff; skip{#}:
  }
  macro literal(define source) {
    append.literal(render.text, {source})
  }

  //A => pixels
  //X => target index
  macro alignLeft(variable target, variable pixels) {
    php; sep #$20; pha
    lda #$e8; sta.l target,x; inx
    lda.b #pixels; sta.l target,x; inx
    lda #$ff; sta.l target,x
    pla; plp
  }
  macro alignLeft(variable pixels) {
    append.alignLeft(render.text, pixels)
  }

  //A => pixels
  //X => target index
  macro alignRight(variable target, variable pixels) {
    php; sep #$20; pha
    lda #$e9; sta.l target,x; inx
    lda.b #pixels; sta.l target,x; inx
    lda #$ff; sta.l target,x
    pla; plp
  }
  macro alignRight(variable pixels) {
    append.alignRight(render.text, pixels)
  }

  macro emitter1(define type) {
    php; rep #$10; phy
    jsl emit.{type}; ldy #$0000
    append.string({target}, emit.{type}.output)
    ply; plp
  }

  macro integer02(target) {; append.emitter1(integer02); }
  macro integer_2(target) {; append.emitter1(integer_2); }
  macro integer_3(target) {; append.emitter1(integer_3); }
  macro integer_4(target) {; append.emitter1(integer_4); }
  macro integer_5(target) {; append.emitter1(integer_5); }
  macro integer_8(target) {; append.emitter1(integer_8); }
  macro integer1 (target) {; append.emitter1(integer1);  }
  macro integer3 (target) {; append.emitter1(integer3);  }
  macro integer5 (target) {; append.emitter1(integer5);  }
  macro integer10(target) {; append.emitter1(integer10); }
  macro hex02    (target) {; append.emitter1(hex02);     }
  macro hex04    (target) {; append.emitter1(hex04);     }
  macro name     (target) {; append.emitter1(name);      }
  macro dragon   (target) {; append.emitter1(dragon);    }
  macro enemy    (target) {; append.emitter1(enemy);     }
  macro technique(target) {; append.emitter1(technique); }
  macro chapter  (target) {; append.emitter1(chapter);   }
  macro turn     (target) {; append.emitter1(turn);      }
  macro piro     (target) {; append.emitter1(piro);      }
  macro time     (target) {; append.emitter1(time);      }
  macro hpValue  (target) {; append.emitter1(hpValue);   }
  macro hpRange  (target) {; append.emitter1(hpRange);   }
  macro mpValue  (target) {; append.emitter1(mpValue);   }
  macro mpRange  (target) {; append.emitter1(mpRange);   }
  macro spValue  (target) {; append.emitter1(spValue);   }
  macro spRange  (target) {; append.emitter1(spRange);   }
}

namespace emit {
  //converts a 16-bit integer into "00"-"99"
  //A => integer
  function integer02 {
    variable(4, output)

    enter
  -;cmp.w #10000; bcc +; sub.w #10000; bra -; +  //discard 10000s digit
  -;cmp.w  #1000; bcc +; sub.w  #1000; bra -; +  //discard  1000s digit
  -;cmp.w   #100; bcc +; sub.w   #100; bra -; +  //discard   100s digit

    ldy #$0000
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output+0; pla
    add.w #'0'; ora #$ff00; sta output+1
    leave; rtl
  }

  //converts a 16-bit integer into " 0"-"99"
  //A => integer
  function integer_2 {
    variable(4, output)

    enter
  -;cmp.w #10000; bcc +; sub.w #10000; bra -; +  //discard 10000s digit
  -;cmp.w  #1000; bcc +; sub.w  #1000; bra -; +  //discard  1000s digit
  -;cmp.w   #100; bcc +; sub.w   #100; bra -; +  //discard   100s digit

    cmp.w #10; bcs +; pha; lda.w #map.enspace; sta output+0; pla; +  //add 10s space

    cmp.w #10; bcc _1  //skip 10s zero

  _10:; ldy.w #0
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output+0; pla

  _1:
    add.w #'0'; ora #$ff00; sta output+1

    leave; rtl
  }

  //converts a 16-bit integer into "  0"-"999"
  //A => integer
  function integer_3 {
    variable(8, output)

    enter
  -;cmp.w #10000; bcc +; sub.w #10000; bra -; +  //discard 10000s digit
  -;cmp.w  #1000; bcc +; sub.w  #1000; bra -; +  //discard  1000s digit

    cmp.w #100; bcs +; pha; lda.w #map.enspace; sta output+0; pla; +  //add 100s space
    cmp.w  #10; bcs +; pha; lda.w #map.enspace; sta output+1; pla; +  //add  10s space

    cmp.w  #10; bcc  _1  //skip  10s zero
    cmp.w #100; bcc _10  //skip 100s zero

  _100:; ldy.w #0
  -;cmp.w #100; bcc +; sub.w #100; iny; bra -
  +;pha; tya; add.w #'0'; sta output+0; pla

  _10:; ldy.w #0
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output+1; pla

  _1:
    add.w #'0'; ora #$ff00; sta output+2

    leave; rtl
  }

  //converts a 16-bit integer into "   0"-"9999"
  //A => integer
  function integer_4 {
    variable(8, output)

    enter
  -;cmp.w #10000; bcc +; sub.w #10000; bra -; +  //discard 10000s digit

    cmp.w #1000; bcs +; pha; lda.w #map.enspace; sta output+0; pla; +  //add 1000s space
    cmp.w  #100; bcs +; pha; lda.w #map.enspace; sta output+1; pla; +  //add  100s space
    cmp.w   #10; bcs +; pha; lda.w #map.enspace; sta output+2; pla; +  //add   10s space

    cmp.w   #10; bcc   _1  //skip   10s zero
    cmp.w  #100; bcc  _10  //skip  100s zero
    cmp.w #1000; bcc _100  //skip 1000s zero

  _1000:; ldy.w #0
  -;cmp.w #1000; bcc +; sub.w #1000; iny; bra -
  +;pha; tya; add.w #'0'; sta output+0; pla

  _100:; ldy.w #0
  -;cmp.w #100; bcc +; sub.w #100; iny; bra -
  +;pha; tya; add.w #'0'; sta output+1; pla

  _10:; ldy.w #0
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output+2; pla

  _1:
    add.w #'0'; ora #$ff00; sta output+3

    leave; rtl
  }

  //converts a 16-bit integer into "    0"-"65535"
  //A => integer
  function integer_5 {
    variable(8, output)

    enter
    cmp.w #10000; bcs +; pha; lda.w #map.enspace; sta output+0; pla; +  //add 10000s space
    cmp.w  #1000; bcs +; pha; lda.w #map.enspace; sta output+1; pla; +  //add  1000s space
    cmp.w   #100; bcs +; pha; lda.w #map.enspace; sta output+2; pla; +  //add   100s space
    cmp.w    #10; bcs +; pha; lda.w #map.enspace; sta output+3; pla; +  //add    10s space

    cmp.w    #10; bcc    _1  //skip    10s zero
    cmp.w   #100; bcc   _10  //skip   100s zero
    cmp.w  #1000; bcc  _100  //skip  1000s zero
    cmp.w #10000; bcc _1000  //skip 10000s zero

  _10000:; ldy.w #0
  -;cmp.w #10000; bcc +; sub.w #10000; iny; bra -
  +;pha; tya; add.w #'0'; sta output+0; pla

  _1000:; ldy.w #0
  -;cmp.w #1000; bcc +; sub.w #1000; iny; bra -
  +;pha; tya; add.w #'0'; sta output+1; pla

  _100:; ldy.w #0
  -;cmp.w #100; bcc +; sub.w #100; iny; bra -
  +;pha; tya; add.w #'0'; sta output+2; pla

  _10:; ldy.w #0
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output+3; pla

  _1:
    add.w #'0'; ora #$ff00; sta output+4

    leave; rtl
  }

  //converts a 32-bit integer into "       0"-"99999999"
  //A => lower 16-bits
  //Y => upper 16-bits
  function integer_8 {
    variable( 6, input)
    variable(12, output)

    enter
    sta input+0; tya
    sta input+2

    ldy #$0000
    skip: {
      tya; mul(4); tax
      lda input+2; cmp table+2,x; bcc +; bne ++
      lda input+0; cmp table+0,x; bcc +; bra ++
    +;iny; cpy.w #9; bcc skip
    };+

    ldx #$0000; phy; cpy.w #0
  -;beq +; lda.w #map.enspace; sta output-2,x; inx; dey; bra -
  +;ply

    digit: {
      phx; phy
      tya; mul(4); tax
      ldy #$0000
      loop: {
        lda input+2; cmp table+2,x; bcc +; bne greater
        lda input+0; cmp table+0,x; bcc +
        greater: {
          lda input+0; sub table+0,x; sta input+0
          lda input+2; sbc table+2,x; sta input+2
          iny; bra loop
        }
      }
    +;tya; ply; plx
      add.w #'0'; sta output-2,x; inx
      iny; cpy.w #10; bcc digit
    }

    lda #$ffff; sta output-2,x
    leave; rtl

    table: {
      dd 1000000000
      dd  100000000
      dd   10000000
      dd    1000000
      dd     100000
      dd      10000
      dd       1000
      dd        100
      dd         10
      dd          1
    }
  }

  //converts a 16-bit integer into "0"-"9"
  //A => integer
  function integer1 {
    variable(2, output)

    enter
  -;cmp.w #10000; bcc +; sub.w #10000; bra -; +  //discard 10000s
  -;cmp.w  #1000; bcc +; sub.w  #1000; bra -; +  //discard  1000s
  -;cmp.w   #100; bcc +; sub.w   #100; bra -; +  //discard   100s
  -;cmp.w    #10; bcc +; sub.w    #10; bra -; +  //discard    10s
    add.w #'0'; ora #$ff00; sta output
    leave; rtl
  }

  //converts a 16-bit integer into "0"-"999"
  //A => integer
  function integer3 {
    variable(8, output)

    enter; ldx.w #0
  -;cmp.w #10000; bcc +; sub.w #10000; bra -; +  //discard 10000s
  -;cmp.w  #1000; bcc +; sub.w  #1000; bra -; +  //discard  1000s

    cmp.w  #10; bcc  _1  //skip leading  10s zero
    cmp.w #100; bcc _10  //skip leading 100s zero

  _100:; ldy.w #0
  -;cmp.w #100; bcc +; sub.w #100; iny; bra -
  +;pha; tya; add.w #'0'; sta output,x; inx; pla

  _10:; ldy.w #0
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output,x; inx; pla

  _1:;
    add.w #'0'; ora #$ff00; sta output,x
    leave; rtl
  }

  //converts a 16-bit integer into "0"-"65535"
  //A => integer
  function integer5 {
    variable(8, output)

    enter; ldx.w #0

    cmp.w    #10; bcc    _1  //skip leading    10s zero
    cmp.w   #100; bcc   _10  //skip leading   100s zero
    cmp.w  #1000; bcc  _100  //skip leading  1000s zero
    cmp.w #10000; bcc _1000  //skip leading 10000s zero

  _10000:; ldy.w #0
  -;cmp.w #10000; bcc +; sub.w #10000; iny; bra -
  +;pha; tya; add.w #'0'; sta output,x; inx; pla

  _1000:; ldy.w #0
  -;cmp.w #1000; bcc +; sub.w #1000; iny; bra -
  +;pha; tya; add.w #'0'; sta output,x; inx; pla

  _100:; ldy.w #0
  -;cmp.w #100; bcc +; sub.w #100; iny; bra -
  +;pha; tya; add.w #'0'; sta output,x; inx; pla

  _10:; ldy.w #0
  -;cmp.w #10; bcc +; sub.w #10; iny; bra -
  +;pha; tya; add.w #'0'; sta output,x; inx; pla

  _1:;
    add.w #'0'; ora #$ff00; sta output,x
    leave; rtl
  }

  //converts a 32-bit integer into "0"-"4294967295"
  //A => lower 16-bits
  //Y => upper 16-bits
  function integer10 {
    variable( 4, input)
    variable(12, output)

    enter
    sta input+0; tya
    sta input+2

    ldy #$0000
    skip: {
      tya; mul(4); tax
      lda input+2; cmp table+2,x; bcc +; bne ++
      lda input+0; cmp table+0,x; bcc +; bra ++
    +;iny; cpy.w #9; bcc skip
    };+

    ldx #$0000
    digit: {
      phx; phy
      tya; mul(4); tax
      ldy #$0000
      loop: {
        lda input+2; cmp table+2,x; bcc +; bne greater
        lda input+0; cmp table+0,x; bcc +
        greater: {
          lda input+0; sub table+0,x; sta input+0
          lda input+2; sbc table+2,x; sta input+2
          iny; bra loop
        }
      }
    +;tya; ply; plx
      add.w #'0'; sta output,x; inx
      iny; cpy.w #10; bcc digit
    }

    lda #$ffff; sta output,x
    leave; rtl

    table: {
      dd 1000000000
      dd  100000000
      dd   10000000
      dd    1000000
      dd     100000
      dd      10000
      dd       1000
      dd        100
      dd         10
      dd          1
    }
  }

  //converts an 8-bit integer into "00"-"FF"
  //A => integer
  function hex02 {
    variable(4, output)

    enter; sep #$30
    pha; lsr #4; tax; lda table,x; sta output+0
    pla; and #$0f; tax; lda table,x; sta output+1
    lda #$ff; sta output+2
    leave; rtl

    table:; db "0123456789ABCDEF"
  }

  //converts a 16-bit integer into "0000"-"FFFF"
  //A => integer
  function hex04 {
    variable(8, output)

    enter; sep #$30
    xba; pha; lsr #4; tax; lda table,x; sta output+0
    pla; and #$0f; tax; lda table,x; sta output+1
    xba; pha; lsr #4; tax; lda table,x; sta output+2
    pla; and #$0f; tax; lda table,x; sta output+3
    lda #$ff; sta output+4
    leave; rtl

    table:; db "0123456789ABCDEF"
  }

  //A => player or dragon name index
  function name {
    variable(16, output)

    enter
    and #$00ff; cmp #$000a; bcs static

  dynamic:
    mul(8); tay; ldb #$7e
    lda $2b00,y; sta base56.decode.input+0
    lda $2b02,y; sta base56.decode.input+2
    lda $2b04,y; sta base56.decode.input+4
    lda $2b06,y; sta base56.decode.input+6
    jsl base56.decode
    ldb #base56.decode.output>>16
    sep #$20; ldx #$0000; txy
  -;lda.w base56.decode.output,y; iny
    sta.l output,x; inx
    cmp #$ff; bne -
    bra finished

  static:
    ldb #lists.names.text>>16
    asl; tax; lda.w lists.names.text,x; tay
    sep #$20; ldx #$0000
  -;lda.w lists.names.text,y; iny
    sta.l output,x; inx
    cmp #$ff; bne -

  finished:
    leave; rtl
  }

  //A => dragon class index
  function dragon {
    variable(16, output)

    enter
    and #$00ff
    ldb #lists.dragons.text>>16
    asl; tax; lda.w lists.dragons.text,x; tay
    sep #$20; ldx #$0000
  -;lda.w lists.dragons.text,y; iny
    sta.l output,x; inx
    cmp #$ff; bne -
    leave; rtl
  }

  //A => enemy name index
  function enemy {
    variable(16, output)

    enter
    and #$00ff
    ldb #lists.enemies.text>>16
    asl; tax; lda.w lists.enemies.text,x; tay
    sep #$20; ldx #$0000
  -;lda.w lists.enemies.text,y; iny
    sta.l output,x; inx
    cmp #$ff; bne -
    leave; rtl
  }

  //A => technique name index
  function technique {
    variable(32, output)

    enter
    and #$00ff
    ldb #lists.techniques.text>>16
    asl; tax; lda.w lists.techniques.text,x; tay
    sep #$20; ldx #$0000
  -;lda.w lists.techniques.text,y; iny
    sta.l output,x; inx
    cmp #$ff; bne -
    leave; rtl
  }

  //A => chapter#
  function chapter {
    variable(16, output)

    enter
    ldx #$0000; txy

    sep #$20
    cmp.b #27; jeq epilogue
    cmp.b #28; jcs sideQuest
    cmp.b  #1; jcs chapter

    function prologue {
      append.literal(output, "Prologue")
      jmp finished
    }

    function chapter {
      append.literal (output, "Chapter ")
      append.integer3(output)
      jmp finished
    }

    function epilogue {
      append.literal(output, "Epilogue")
      jmp finished
    }

    function sideQuest {
      sub.b #27  //side quests start from chapter 28
      append.literal (output, "Side Quest ")
      append.integer3(output)
      jmp finished
    }

  finished:
    leave; rtl
  }

  //A => turn#
  function turn {
    variable(16, output)

    enter
    ldx #$0000; txy
    append.literal  (output, "Turn")
    append.alignLeft(output, 23)
    append.integer5 (output)
    leave; rtl
  }

  //A => piro (lower 16-bits)
  //Y => piro (upper 16-bits)
  function piro {
    variable(28, output)

    enter
    ldx #$0000
    append.literal  (output, "Piro")
    append.alignLeft(output, 23)
    append.integer10(output)
    leave; rtl
  }

  //AL => hour
  //AH => minute
  //Y  => second
  function time {
    variable(16, output)

    php; rep #$30; phx; pha; ldx #$0000
    append.literal  (output, "Time")
    append.alignLeft(output, 23); and #$00ff
    append.integer02(output); lda $02,s; and #$00ff
    append.literal  (output, ":")
    append.integer02(output); tya; and #$00ff
    append.literal  (output, ":")
    append.integer02(output)
    pla; plx; plp; rtl
  }

  //A => HP
  //>9999 => "????"
  function hpValue {
    variable(16, output)

    php; rep #$10; phx; ldx #$0000
    append.literal(output, "HP")
    append.alignRight(output, 24)
    cmp.w #10000; bcc _1; append.literal(output, "^^^^"); bra _2; _1:
    append.integer_4(output); _2:
    plx; plp; rtl
  }

  inline magicValue(define type) {
    variable(16, output)

    php; rep #$10; phx; ldx #$0000
    append.literal(output, {type})
    append.alignRight(output, 24)
    cmp.w #65535; bne _1; append.literal(output, "_~~~"); bra _3; _1:
    cmp.w  #1000; bcc _2; append.literal(output, "_^^^"); bra _3; _2:
    append.integer_4(output); _3:
    plx; plp; rtl
  }

  //A => MP
  //65535 => "---" (no magic skill)
  //>999  => "???"
  function mpValue {
    magicValue("MP")
  }

  //A => SP
  //65535 => "---" (no magic skill)
  //>999  => "???"
  function spValue {
    magicValue("SP")
  }

  //A => current HP
  //Y => maximum HP
  //>9999 => "????"
  function hpRange {
    variable(32, output)

    php; rep #$10; phx; ldx #$0000
    append.literal(output, "HP")
    append.alignRight(output, 54)
    cmp.w #10000; bcc _1; append.literal(output, "^^^^"); bra _2; _1:
    append.integer_4(output); _2:
    append.literal(output, "/"); tya
    cmp.w #10000; bcc _3; append.literal(output, "^^^^"); bra _4; _3:
    append.integer_4(output); _4:
    plx; plp; rtl
  }

  //A => current MP/SP
  //Y => maximum MP/SP
  inline magicRange(define type) {
    variable(32, output)

    php; rep #$10; phx; ldx #$0000
    append.literal(output, {type})
    append.alignRight(output, 54)
    cmp.w #65535; bne _1; append.literal(output, "_~~~"); bra _3; _1:
    cmp.w  #1000; bcc _2; append.literal(output, "_^^^"); bra _3; _2:
    append.integer_4(output); _3:
    append.literal(output, "/"); tya
    cmp.w #65535; bne _4; append.literal(output, "_~~~"); bra _6; _4:
    cmp.w  #1000; bcc _5; append.literal(output, "_^^^"); bra _5; _5:
    append.integer_4(output); _6:
    plx; plp; rtl
  }

  //A => current MP
  //Y => maximum MP
  //65535 = "---" (no magic skill)
  //>999  = "???"
  function mpRange {
    magicRange("MP")
  }

  //A => current SP
  //Y => maximum SP
  //65535 = "---" (no magic skill)
  //>999  = "???"
  function spRange {
    magicRange("SP")
  }
}

namespace append {
  macro emitter2(define type) {
    php; rep #$10; phy
    jsl emit.{type}; ldy #$0000
    append.string(render.text, emit.{type}.output)
    ply; plp; rtl
  }

  //functions reduce code generation size
  function integer02 {; append.emitter2(integer02); }
  function integer_2 {; append.emitter2(integer_2); }
  function integer_3 {; append.emitter2(integer_3); }
  function integer_4 {; append.emitter2(integer_4); }
  function integer_5 {; append.emitter2(integer_5); }
  function integer_8 {; append.emitter2(integer_8); }
  function integer1  {; append.emitter2(integer1);  }
  function integer3  {; append.emitter2(integer3);  }
  function integer5  {; append.emitter2(integer5);  }
  function integer10 {; append.emitter2(integer10); }
  function hex02     {; append.emitter2(hex02);     }
  function hex04     {; append.emitter2(hex04);     }
  function name      {; append.emitter2(name);      }
  function dragon    {; append.emitter2(dragon);    }
  function enemy     {; append.emitter2(enemy);     }
  function technique {; append.emitter2(technique); }
  function chapter   {; append.emitter2(chapter);   }
  function turn      {; append.emitter2(turn);      }
  function piro      {; append.emitter2(piro);      }
  function time      {; append.emitter2(time);      }
  function hpValue   {; append.emitter2(hpValue);   }
  function hpRange   {; append.emitter2(hpRange);   }
  function mpValue   {; append.emitter2(mpValue);   }
  function mpRange   {; append.emitter2(mpRange);   }
  function spValue   {; append.emitter2(spValue);   }
  function spRange   {; append.emitter2(spRange);   }

  //macros provide consistent interface with argument-taking macros
  macro integer02() {; jsl append.integer02; }
  macro integer_2() {; jsl append.integer_2; }
  macro integer_3() {; jsl append.integer_3; }
  macro integer_4() {; jsl append.integer_4; }
  macro integer_5() {; jsl append.integer_5; }
  macro integer_8() {; jsl append.integer_8; }
  macro integer1 () {; jsl append.integer1;  }
  macro integer3 () {; jsl append.integer3;  }
  macro integer5 () {; jsl append.integer5;  }
  macro integer10() {; jsl append.integer10; }
  macro hex02    () {; jsl append.hex02;     }
  macro hex04    () {; jsl append.hex04;     }
  macro name     () {; jsl append.name;      }
  macro dragon   () {; jsl append.dragon;    }
  macro enemy    () {; jsl append.enemy;     }
  macro technique() {; jsl append.technique; }
  macro chapter  () {; jsl append.chapter;   }
  macro turn     () {; jsl append.turn;      }
  macro piro     () {; jsl append.piro;      }
  macro time     () {; jsl append.time;      }
  macro hpValue  () {; jsl append.hpValue;   }
  macro hpRange  () {; jsl append.hpRange;   }
  macro mpValue  () {; jsl append.mpValue;   }
  macro mpRange  () {; jsl append.mpRange;   }
  macro spValue  () {; jsl append.spValue;   }
  macro spRange  () {; jsl append.spRange;   }
}

codeCursor = pc()
