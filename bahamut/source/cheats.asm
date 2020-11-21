namespace cheats {

//maximum experience after one move on the field
seek($c0880b); {
  lda #$ff
  sta $7e2125,x
  sta $7e2126,x
  sta $7e2127,x
  jmp $8829
}

//infinite MP/SP for all players
seek($c0410b); {
  nop #13
}

}
