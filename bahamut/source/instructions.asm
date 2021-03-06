//add useful pseudo-instructions to the wdc65816 architecture

//16-bit conditional jumps
instrument "jeq *16; $d0 $03 $4c =a"
instrument "jne *16; $f0 $03 $4c =a"
instrument "jcc *16; $b0 $03 $4c =a"
instrument "jcs *16; $90 $03 $4c =a"

//pea $dbdb; plb; plb
instrument "ldb #*08; $f4 =a =a $ab $ab"

//pea $addr; pld
instrument "ldd #*16; $f4 =a $2b"

//rep #$02
instrument "clz; $c2 $02"

//sep #$02
instrument "sez; $e2 $02"

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
