//add useful pseudo-instructions to the wdc65816 architecture

//16-bit conditional jumps
instrument "jeq *16; $d0 $03 $4c =a"
instrument "jne *16; $f0 $03 $4c =a"
instrument "jcc *16; $b0 $03 $4c =a"
instrument "jcs *16; $90 $03 $4c =a"

//16-bit conditional JMPs
instrument "jmpeq *16; $d0 $03 $4c =a"
instrument "jmpne *16; $f0 $03 $4c =a"
instrument "jmppl *16; $30 $03 $4c =a"
instrument "jmpmi *16; $10 $03 $4c =a"
instrument "jmpcc *16; $b0 $03 $4c =a"
instrument "jmpcs *16; $90 $03 $4c =a"
instrument "jmpvc *16; $70 $03 $4c =a"
instrument "jmpvs *16; $50 $03 $4c =a"

//16-bit conditional JSRs
instrument "jsreq *16; $d0 $03 $20 =a"
instrument "jsrne *16; $f0 $03 $20 =a"
instrument "jsrpl *16; $30 $03 $20 =a"
instrument "jsrmi *16; $10 $03 $20 =a"
instrument "jsrcc *16; $b0 $03 $20 =a"
instrument "jsrcs *16; $90 $03 $20 =a"
instrument "jsrvc *16; $70 $03 $20 =a"
instrument "jsrvs *16; $50 $03 $20 =a"

//24-bit conditional JMLs
instrument "jmleq *24; $d0 $04 $5c =a"
instrument "jmlne *24; $f0 $04 $5c =a"
instrument "jmlpl *24; $30 $04 $5c =a"
instrument "jmlmi *24; $10 $04 $5c =a"
instrument "jmlcc *24; $b0 $04 $5c =a"
instrument "jmlcs *24; $90 $04 $5c =a"
instrument "jmlvc *24; $70 $04 $5c =a"
instrument "jmlvs *24; $50 $04 $5c =a"

//24-bit conditional JSLs
instrument "jsleq *24; $d0 $04 $22 =a"
instrument "jslne *24; $f0 $04 $22 =a"
instrument "jslpl *24; $30 $04 $22 =a"
instrument "jslmi *24; $10 $04 $22 =a"
instrument "jslcc *24; $b0 $04 $22 =a"
instrument "jslcs *24; $90 $04 $22 =a"
instrument "jslvc *24; $70 $04 $22 =a"
instrument "jslvs *24; $50 $04 $22 =a"

//pea $dbdb; plb; plb
instrument "ldb #*08; $f4 =a =a $ab $ab"

//pea $addr; pld
instrument "ldd #*16; $f4 =a $2b"

//phb; php; rep #$30; pha; phx; phy
instrument "enter; $8b $08 $c2 $30 $48 $da $5a"

//rep #$30; ply; plx; pla; plp; plb
instrument "leave; $c2 $30 $7a $fa $68 $28 $ab"

//clc; adc => add
instrument "add #*16      ;$18 $69 =a"
instrument "add #*08      ;$18 $69 =a"
instrument "add *08,s     ;$18 $63 =a"
instrument "add (*08,s),y ;$18 $73 =a"
instrument "add (*08,x)   ;$18 $61 =a"
instrument "add (*08),y   ;$18 $71 =a"
instrument "add [*08],y   ;$18 $77 =a"
instrument "add (*08)     ;$18 $72 =a"
instrument "add [*08]     ;$18 $67 =a"
instrument "add *16,y     ;$18 $79 =a"
instrument "add *24,x     ;$18 $7f =a"
instrument "add *16,x     ;$18 $7d =a"
instrument "add *08,x     ;$18 $75 =a"
instrument "add *24       ;$18 $6f =a"
instrument "add *16       ;$18 $6d =a"
instrument "add *08       ;$18 $65 =a"
//
instrument "add.w #*16    ;$18 $69 ~a"
instrument "add.b #*08    ;$18 $69 ~a"
instrument "add.w *16,y   ;$18 $79 ~a"
instrument "add.l *24,x   ;$18 $7f ~a"
instrument "add.w *16,x   ;$18 $7d ~a"
instrument "add.b *08,x   ;$18 $75 ~a"
instrument "add.l *24     ;$18 $6f ~a"
instrument "add.w *16     ;$18 $6d ~a"
instrument "add.b *08     ;$18 $65 ~a"

//sec; sbc => sub
instrument "sub #*16      ;$38 $e9 =a"
instrument "sub #*08      ;$38 $e9 =a"
instrument "sub *08,s     ;$38 $e3 =a"
instrument "sub (*08,s),y ;$38 $f3 =a"
instrument "sub (*08,x)   ;$38 $e1 =a"
instrument "sub (*08),y   ;$38 $f1 =a"
instrument "sub [*08],y   ;$38 $f7 =a"
instrument "sub (*08)     ;$38 $f2 =a"
instrument "sub [*08]     ;$38 $e7 =a"
instrument "sub *16,y     ;$38 $f9 =a"
instrument "sub *24,x     ;$38 $ff =a"
instrument "sub *16,x     ;$38 $fd =a"
instrument "sub *08,x     ;$38 $f5 =a"
instrument "sub *24       ;$38 $ef =a"
instrument "sub *16       ;$38 $ed =a"
instrument "sub *08       ;$38 $e5 =a"
//
instrument "sub.w #*16    ;$38 $e9 ~a"
instrument "sub.b #*08    ;$38 $e9 ~a"
instrument "sub.w *16,y   ;$38 $f9 ~a"
instrument "sub.l *24,x   ;$38 $ff ~a"
instrument "sub.w *16,x   ;$38 $fd ~a"
instrument "sub.b *08,x   ;$38 $f5 ~a"
instrument "sub.l *24     ;$38 $ef ~a"
instrument "sub.w *16     ;$38 $ed ~a"
instrument "sub.b *08     ;$38 $e5 ~a"
