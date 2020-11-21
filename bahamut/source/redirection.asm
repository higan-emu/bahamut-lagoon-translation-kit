namespace redirection {

seek(codeCursor)

variable(2, enabled)
variable(4, address)

//decodes a 21-bit ROM address and sets enabled to true
function enable {
  php; sep #$20; pha

  lda address+1; asl #7
  ora address+0; sta address+0
  lda address+1; lsr #1; sta address+1
  lda address+2; asl #6
  ora address+1; sta address+1
  lda address+2; lsr #2
  ora #$f8; sta address+2  //redirected text always resides at $f8:0000-$ff:ffff
  lda #$01; sta enabled+0; dec; sta enabled+1

  pla; plp; rtl
}
macro enable() {
  jsl redirection.enable
}

//sets enabled to false
function disable {
  php; sep #$20; pha
  lda #$00; sta enabled+0; sta enabled+1
  pla; plp; rtl
}
macro disable() {
  jsl redirection.disable
}

//reads a byte from the current redirection address
function read {
  phb; php; rep #$30; phx
  lda address+0; tax
  lda address+2; xba; pha; plb; plb
  lda $0000,x; and #$00ff
  plx; plp; plb; rtl
}
macro read() {
  jsl redirection.read
}

//increments the current redirection address by one byte
function increment {
  php; sep #$20; pha; clc
  lda address+0; adc #$01; sta address+0
  lda address+1; adc #$00; sta address+1
  lda address+2; adc #$00; sta address+2
  pla; plp; rtl
}
macro increment() {
  jsl redirection.increment
}

codeCursor = pc()

}
