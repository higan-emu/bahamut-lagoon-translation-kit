//base56 encoding and decoding routines:
//names are stored at $7e:2b00+, and each name is eight bytes long.
//this is not long enough for "Salamander", "Ice Dragon", "Thunderhawk", and "Fahrenheit"
//rather than attempting to migrate the names in both WRAM and SRAM, base56 is used.
//this allows for the storage of 11 characters in 8 bytes of space, with the downside
//that it limits the range of available characters to [A-Z][a-z][.- ] and a terminal marker.
//it is very difficult to perform 64-bit multiplication and division, and so pre-generated
//lookup tables are used to accelerate the process. the general idea is that multiplication
//and division by 8 is trivial, and then multiplication and division by 7 can be done: 8*7=56

namespace base56 {

seek(codeCursor)

//encoded <= base56.encode(encoding)
function encode {
  variable(16, input)   //88-bit decoded string
  variable(16, output)  //64-bit encoded string

  enter
  ldb #$a1  //allow 16-bit access to variables
  stz.w output+0; stz.w output+2; stz.w output+4; stz.w output+6  //initialize output

  ldx.w #10; ldy.w #0
  loop: {
    phx; tya; xba; lsr #2; pha   //s = y * 64
    tya; xba; asl                //a = y * 512
    sub $01,s; sta $01,s         //s = a - s
    lda.w input,x; and #$00ff    //a = character[x]
    jsl encodeCharacter          //a = toBase56[x]
    asl #3; add $01,s; tax; pla  //x = s + a * 8

    //output = output * 56 + A
    lda.w output+0; add products+0,x; sta.w output+0
    lda.w output+2; adc products+2,x; sta.w output+2
    lda.w output+4; adc products+4,x; sta.w output+4
    lda.w output+6; adc products+6,x; sta.w output+6

    plx; iny; dex; bpl loop
  }

  //store string terminator
  lda #$ffff; sta.w output+8
  leave; rtl

  encodeCharacter: {
    cmp #$00ae; bne +; lda #$0035; rtl; +  //encode '-'
    cmp #$0086; bne +; lda #$0040; rtl; +  //encode '.'
    cmp #$00ff; bne +; lda #$0037; rtl; +  //encode terminal
    character.decode(); rtl                //encode 'A-Z' and 'a-z'
  }
}

//decoded <= base56.decode(decoding)
function decode {
  variable(16, input)       //64-bit encoded string
  variable(16, output)      //88-bit decoded string
  variable( 4, multiplier)  //31-bit base7

  enter
  ldb #$a1  //allow 16-bit access to variables

  //multiplier = decoding >> 32
  lda.w input+4; sta.w multiplier+0
  lda.w input+6; sta.w multiplier+2

  //copy low 3-bits of each character to output buffer
  lda.w input+0; asl #2; and #$0700; sta.w output+8-1
  lda.w input+1; asl #1; and #$0700; sta.w output+5-1
  lda.w input+3; asl #2; and #$0700; sta.w output+0-1  //output[-1] is input[15] (unused padding)
  sep #$20
  lda.w input+0;         pha; and #$07; sta.w output+10; pla; lsr #3; and #$07; sta.w output+9
  lda.w input+1; lsr #1; pha; and #$07; sta.w output+ 7; pla; lsr #3; and #$07; sta.w output+6
  lda.w input+2; lsr #2; pha; and #$07; sta.w output+ 4; pla; lsr #3; and #$07; sta.w output+3
  lda.w input+3;         pha; and #$07; sta.w output+ 2; pla; lsr #3; and #$07; sta.w output+1

  //multiplier >>= 1
  clc; ror.w multiplier+3; ror.w multiplier+2; ror.w multiplier+1; ror.w multiplier+0

  //restore base7 upper 3-bits of each character for output buffer
  ldy.w #10
  loop: {
    lda #$00
    xba; lda.w multiplier+3; tax; lda quotients,x; sta.w multiplier+3; lda remainders,x
    xba; lda.w multiplier+2; tax; lda quotients,x; sta.w multiplier+2; lda remainders,x
    xba; lda.w multiplier+1; tax; lda quotients,x; sta.w multiplier+1; lda remainders,x
    xba; lda.w multiplier+0; tax; lda quotients,x; sta.w multiplier+0; lda remainders,x
    asl #3; ora.w output,y
    jsl decodeCharacter; sta.w output,y
    dey; bpl loop
  }

  //store string terminator
  lda #$ff; sta.w output+11
  leave; rtl

  decodeCharacter: {
    cmp #$35; bne +; lda #$ae; rtl; +
    cmp #$36; bne +; lda #$86; rtl; +
    cmp #$37; bne +; lda #$ff; rtl; +
    character.encode(); rtl
  }
}

codeCursor = pc()

}
