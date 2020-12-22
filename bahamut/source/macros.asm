//used to allocate unique memory addresses for all variables
inline variable(variable size, define name) {
  //the address is constant, but the data at the address in variable (mutable)
  constant {name} = sramCursor
  sramCursor = sramCursor + size
}

//implements modulo counters that do not need to be initialized before use
//these counters are used to implement tiledata double-buffering when rendering
macro getTileIndex(define counter, variable limit) {
  php; rep #$20
  lda {counter}
  cmp.w #limit; bcc {#}
  lda.w #0; {#}:
  inc; sta {counter}
  dec; plp
}

//A <= min(A, value)
namespace min {
  macro b(variable value) {
    cmp.b #value; bcc {#}; lda.b #value; {#}:
  }
  macro w(variable value) {
    cmp.w #value; bcc {#}; lda.w #value; {#}:
  }
}

//A <= max(A, value)
namespace max {
  macro b(variable value) {
    cmp.b #value; bcs {#}; lda.b #value; {#}:
  }
  macro w(variable value) {
    cmp.w #value; bcs {#}; lda.w #value; {#}:
  }
}

//A <= clamp(A, min, max)
namespace clamp {
  macro b(variable min, variable max) {
    min.b(max)
    max.b(min)
  }
  macro w(variable min, variable max) {
    min.w(max)
    max.w(min)
  }
}

expression color(r, g, b) =  (r & $1f) << 0 | (g & $1f) << 5 | (b & $1f) << 10

//multiplies the accumulator by various constant values
//<= 255 works with both 8-bit and 16-bit accumulator
//>= 256 requires 16-bit accumulator
macro mul(variable by) {
  if by == 1 {
    //do nothing
  } else if by == 2 {
    asl
  } else if by == 3 {
    pha; asl; add $01,s; sta $01,s; pla
  } else if by == 4 {
    asl #2
  } else if by == 5 {
    pha; asl #2; add $01,s; sta $01,s; pla
  } else if by == 6 {
    asl; pha; asl; add $01,s; sta $01,s; pla
  } else if by == 7 {
    pha; asl #3; sub $01,s; sta $01,s; pla
  } else if by == 8 {
    asl #3
  } else if by == 9 {
    pha; asl #3; add $01,s; sta $01,s; pla
  } else if by == 10 {
    asl; pha; asl #3; add $01,s; sta $01,s; pla
  } else if by == 11 {
    pha; asl #3; add $01,s; add $01,s; add $01,s; sta $01,s; pla
  } else if by == 12 {
    asl #2; pha; asl; add $01,s; sta $01,s; pla
  } else if by == 16 {
    asl #4
  } else if by == 24 {
    asl #3; pha; asl; add $01,s; sta $01,s; pla
  } else if by == 30 {
    pha; asl #5; sub $01,s; sub $01,s; sta $01,s; pla
  } else if by == 32 {
    asl #5
  } else if by == 44 {
    pha; asl; add $01,s; asl #2; sub $01,s; sta $01,s; pla; asl #2
  } else if by == 48 {
    asl #4; pha; asl; add $01,s; sta $01,s; pla
  } else if by == 64 {
    asl #6
  } else if by == 128 {
    asl #7
  } else if by == 176 {
    pha; asl; add $01,s; asl #2; sub $01,s; sta $01,s; pla; asl #4
  } else if by == 180 {
    pha; asl #3; add $01,s; sta $01,s; asl #2; add $01,s; sta $01,s; pla; asl #2
  } else if by == 256 {
    and #$00ff; xba
  } else if by == 512 {
    and #$00ff; xba; asl
  } else if by == 896 {
    and #$00ff; xba; lsr; pha; asl; pha; asl; add $01,s; add $03,s; sta $03,s; pla; pla
  } else if by == 960 {
    and #$00ff; xba; lsr #2; pha; asl #4; sub $01,s; sta $01,s; pla
  } else if by == 1024 {
    and #$00ff; xba; asl #2
  } else if by == 2048 {
    and #$00ff; xba; asl #3
  } else if by == 4096 {
    and #$00ff; xba; asl #4
  } else if by == 5632 {
    and #$00ff; xba; asl; pha; asl; pha; asl #2; add $01,s; add $03,s; sta $03,s; pla; pla
  } else if by == 8192 {
    clc; ror #4; and #$e000
  } else {
    error "unsupported multiplier: ", by
  }
}

//divides the accumulator by various constant values
//<= 255 works with both 8-bit and 16-bit accumulator
//>= 256 requires 16-bit accumulator
macro div(variable by) {
  if by == 1 {
    //do nothing
  } else if by == 2 {
    lsr
  } else if by == 4 {
    lsr #2
  } else if by == 8 {
    lsr #3
  } else if by == 16 {
    lsr #4
  } else if by == 32 {
    lsr #5
  } else if by == 64 {
    lsr #6
  } else if by == 128 {
    lsr #7
  } else if by == 256 {
    and #$ff00; xba
  } else if by == 512 {
    and #$ff00; xba; lsr
  } else if by == 1024 {
    and #$ff00; xba; lsr #2
  } else {
    error "unsupported divisor: ", by
  }
}
