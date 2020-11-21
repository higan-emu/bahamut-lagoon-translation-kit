namespace character {
  seek(codeCursor)

  //converts character in A from text index into font index
  //A = character
  macro decode() {
    php; rep #$30; phx
    and #$00ff; tax
    lda character.decoder,x; and #$007f
    plx; plp
  }

  //converts character in A from font index into text index
  //A = character
  macro encode() {
    php; rep #$30; phx
    and #$00ff; tax
    lda character.encoder,x; and #$00ff
    plx; plp
  }

  decoder: {
    //   0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  a,  b,  c,  d,  e,  f
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //0
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //1
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //2
    db $00,$00,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //3
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //4
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //5
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //6
    db $00,$00,$00,$00,$00,$00,$50,$4f,$4e,$4d,$4c,$4b,$4a,$49,$48,$47  //7
    db $46,$45,$44,$43,$42,$41,$40,$1b,$1c,$1d,$1e,$1f,$20,$21,$22,$23  //8
    db $24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f,$30,$31,$32,$33  //9
    db $34,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$35,$36  //a
    db $37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f,$01,$02,$03,$04,$05,$06,$07  //b
    db $08,$09,$0a,$0b,$0c,$0d,$0e,$0f,$10,$11,$12,$13,$14,$15,$16,$17  //c
    db $18,$19,$1a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //d
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //e
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  //f
  }

  encoder: {
    //   0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  a,  b,  c,  d,  e,  f
    db $ef,$b9,$ba,$bb,$bc,$bd,$be,$bf,$c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7  //0
    db $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf,$d0,$d1,$d2,$87,$88,$89,$8a,$8b  //1
    db $8c,$8d,$8e,$8f,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9a,$9b  //2
    db $9c,$9d,$9e,$9f,$a0,$ae,$af,$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8  //3
    db $86,$85,$84,$83,$82,$81,$80,$7f,$7e,$7d,$7c,$7b,$7a,$79,$78,$77  //4
    db $76,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //5
    db $33,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef  //6
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
map 'a', $87
map 'b', $88
map 'c', $89
map 'd', $8a
map 'e', $8b
map 'f', $8c
map 'g', $8d
map 'h', $8e
map 'i', $8f
map 'j', $90
map 'k', $91
map 'l', $92
map 'm', $93
map 'n', $94
map 'o', $95
map 'p', $96
map 'q', $97
map 'r', $98
map 's', $99
map 't', $9a
map 'u', $9b
map 'v', $9c
map 'w', $9d
map 'x', $9e
map 'y', $9f
map 'z', $a0
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
map '.', $86
map ',', $85
map '?', $84
map '!', $83
map '\'',$82
map '\"',$81
map ':', $80
map ';', $7f
map '*', $7e
map '+', $7d
map '/', $7c
map '(', $7b
map ')', $7a
map '^', $79  //en-question
map '~', $78  //en-dash
map '_', $77  //en-space
map '\n',$fe

namespace map {
  constant enquestion = $79
  constant endash     = $78
  constant enspace    = $77
}
