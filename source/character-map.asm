namespace character {
  seek(codeCursor)

  //converts character in A from text index into font index
  //A => encoded character
  //A <= decoded character
  macro decode() {
    php; rep #$30; phx
    and #$00ff; tax
    lda character.decoder,x; and #$00ff
    plx; plp
  }

  //converts character in A from font index into text index
  //A => decoded character
  //A <= encoded character
  macro encode() {
    php; rep #$30; phx
    and #$00ff; tax
    lda character.encoder,x; and #$00ff
    plx; plp
  }

  //[A-Z][0-9][space] are kept in the same locations as the Japanese font
  decoder: {
    //   0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  a,  b,  c,  d,  e,  f
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //0
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //1
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //2
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //3
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //4
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //5
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //6
    db $00,$00,$00,$00,$1b,$1c,$1d,$1e,$1f,$20,$21,$22,$23,$24,$25,$26  //7
    db $27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f,$30,$31,$32,$33,$34,$40,$41  //8
    db $42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f,$50,$51  //9
    db $52,$53,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e,$5f,$35,$36  //a
    db $37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f,$01,$02,$03,$04,$05,$06,$07  //b
    db $08,$09,$0a,$0b,$0c,$0d,$0e,$0f,$10,$11,$12,$13,$14,$15,$16,$17  //c
    db $18,$19,$1a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //d
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //e
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //f
  }

  encoder: {
    //   0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  a,  b,  c,  d,  e,  f
    db $ef,$b9,$ba,$bb,$bc,$bd,$be,$bf,$c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7  //0
    db $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf,$d0,$d1,$d2,$74,$75,$76,$77,$78  //1
    db $79,$7a,$7b,$7c,$7d,$7e,$7f,$80,$81,$82,$83,$84,$85,$86,$87,$88  //2
    db $89,$8a,$8b,$8c,$8d,$ae,$af,$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8  //3
    db $8e,$8f,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d  //4
    db $9e,$9f,$a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad  //5
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //6
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //7
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //8
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //9
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //a
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //b
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //c
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //d
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //e
    db $ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //f
  }

  codeCursor = pc()
}

map ' ', $ef

map 'A', $b9
map 'B', $ba
map 'C', $bb
map 'D', $bc
map 'E', $bd
map 'F', $be
map 'G', $bf
map 'H', $c0
map 'I', $c1
map 'J', $c2
map 'K', $c3
map 'L', $c4
map 'M', $c5
map 'N', $c6
map 'O', $c7
map 'P', $c8
map 'Q', $c9
map 'R', $ca
map 'S', $cb
map 'T', $cc
map 'U', $cd
map 'V', $ce
map 'W', $cf
map 'X', $d0
map 'Y', $d1
map 'Z', $d2

map 'a', $74
map 'b', $75
map 'c', $76
map 'd', $77
map 'e', $78
map 'f', $79
map 'g', $7a
map 'h', $7b
map 'i', $7c
map 'j', $7d
map 'k', $7e
map 'l', $7f
map 'm', $80
map 'n', $81
map 'o', $82
map 'p', $83
map 'q', $84
map 'r', $85
map 's', $86
map 't', $87
map 'u', $88
map 'v', $89
map 'w', $8a
map 'x', $8b
map 'y', $8c
map 'z', $8d

map '-', $ae
map '0', $af
map '1', $b0
map '2', $b1
map '3', $b2
map '4', $b3
map '5', $b4
map '6', $b5
map '7', $b6
map '8', $b7
map '9', $b8

map '.', $8e
map ',', $8f
map '?', $90
map '!', $91
map '\'',$92
map '\"',$93
map ':', $94
map ';', $95
map '*', $96
map '+', $97
map '/', $98
map '(', $99
map ')', $9a
map '^', $9b  //en-question
map '~', $9c  //en-dash
map '_', $9d  //en-space

map '%', $9e

map '<', command.styleNormal
map '>', command.styleItalic
map '[', command.colorYellow
map ']', command.colorNormal
map '\n',command.lineFeed
map '$', command.terminal

namespace map {
  constant umlautA   = $9f
  constant umlautO   = $a0
  constant umlautU   = $a1
  constant hexA      = $a2
  constant hexB      = $a3
  constant hexC      = $a4
  constant hexD      = $a5
  constant hexE      = $a6
  constant hexF      = $a7
  constant reserved0 = $a8
  constant reserved1 = $a9
  constant reserved2 = $aa
  constant reserved3 = $ab
  constant reserved4 = $ac
  constant reserved5 = $ad
}
