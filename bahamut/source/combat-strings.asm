namespace combat {

seek(codeCursor)

namespace strings {
  enqueue pc
  seek($c1a68a); jsl hook
  dequeue pc

  variable(256, text)
  variable(4, source)

  //------
  //c1a67f  lda [$78],y
  //c1a681  clc
  //c1a682  adc $78
  //c1a684  sta $5e
  //c1a686  sep #$20
  //c1a688  lda $7a
  //c1a68a  adc #$00
  //c1a68c  sta $60
  //------
  function hook {
    adc #$00
    sta $60
    enter
    lda $5e; sta source+0
    lda $60; sta source+2

    lda.w #string.none >> 0; sta $5e
    lda.w #string.none >> 8; sta $5f

    lda source+2; and #$00ff
    cmp #$00dd; bne +; jsl hookDD; +
    cmp #$00de; bne +; jsl hookDE; +
    leave; rtl
  }

  macro hook(define address) {
    cmp.w #${address}; bne +; pha
    lda.w #string.{address} >> 0; sta $5e
    lda.w #string.{address} >> 8; sta $5f
    pla; +
  }

  function hookDD {
    pha; lda source+0
    hook(dd88b7)
    hook(dd88ed)
    hook(dd8923)
    hook(dd8962)
    hook(dd89ab)
    hook(dd89f1)
    hook(dd8a28)
    hook(dd8a5c)
    hook(dd8a9c)
    hook(dd8ad6)
    hook(dd8b06)
    hook(dd8b42)
    hook(dd8b7c)
    hook(dd8bbb)
    hook(dd8bf7)
    hook(dd8c2a)
    hook(dd8c62)
    hook(dd8c9f)
    hook(dd8cde)
    hook(dd8d1a)
    hook(dd8d55)
    hook(dd8d8d)
    hook(dd8dc9)
    hook(dd8dfb)
    hook(dd8e26)
    hook(dd8e57)
    hook(dd8e93)
    hook(dd8ec5)
    pla; rtl
  }

  function hookDE {
    pha; lda source+0
    hook(de1d7b)
    hook(de1d83)
    hook(de1d97)
    hook(de1da0)
    hook(de1da9)
    pla; rtl
  }

  namespace string {
    inline text(define value) {; db {value}; }
    inline normal() {; db command.fontNormal; }
    inline yellow() {; db command.fontYellow; }
    inline left() {; db command.alignLeft; }
    inline name(variable value) {; db command.name,value,":"; }
    inline await() {; db command.pause,$80,command.wait,command.terminal; }
    inline terminal() {; db command.terminal; }

    none:;   terminal()

    dd88b7:; left(); text("You can HAVE the damn ship!"); await()
    dd88ed:; left(); text("It's all up to you now... Grauel..."); await()
    dd8923:; left(); text("My work here... is done..."); await()
    dd8962:; left(); text("Heh... I'm done buying them time now!"); await()
    dd89ab:; left(); text("Hmph! I... I'll give you my supplies!"); await()
    dd89f1:; left(); text("My... My Campbell..."); await()
    dd8a28:; left(); text("Ack!"); await()
    dd8a5c:; left(); text("Eeee hee hee hee! Not quite good enough!"); await()
    dd8a9c:; left(); text("Eeee hee hee hee! I'll get you for this!"); await()
    dd8ad6:; left(); text("The Divine Dragons!?"); await()
    dd8b06:; left(); text("Argh! My role in this is over!"); await()
    dd8b42:; left(); text("But the night belongs to me... Why!?"); await()
    dd8b7c:; left(); text("With... this... I must vanish..."); await()
    dd8bbb:; left(); text("So fierce, the power of the Divine Dragons..."); await()
    dd8bf7:; left(); text("Out homeland... We only wanted to..."); await()
    dd8c2a:; left(); text("Go back now... Divine Dragons..."); await()
    dd8c62:; left(); text("Come... to Altair..."); await()
    dd8c9f:; left(); text("G'huh huh! I AM a persistent one!"); await()
    dd8cde:; left(); text("Is this the end of the Granvelos Empire...?"); await()
    dd8d1a:; left(); text("Thank... you..."); await()
    dd8d55:; left(); text("Not quite! I still have my castle!"); await()
    dd8d8d:; left(); text("The empire... was supposed to be mine..."); await()
    dd8dc9:; left(); text("Did you make it back...?"); await()
    dd8dfb:; left(); text("Defeat... Alexander..."); await()
    dd8e26:; left(); text("Graaaaargggh..."); await()
    dd8e57:; left(); text("Groooooargh..."); await()
    dd8e93:; left(); text("I lost to you..."); await()
    dd8ec5:; left(); text("What...!? I lost!?"); await()

    de1d7b:; left(); yellow(); name($01); normal(); text(" Stop it!"); terminal()
    de1d83:; left(); yellow(); name($01); normal(); text(" I'll talk with the divine dragon!"); terminal()
    de1d97:; left(); yellow(); name($01); normal(); text(" Aaaah!"); terminal()
    de1da0:; left(); yellow(); text("Sauthar:"); normal(); text(" ..."); terminal()
    de1da9:; left(); yellow(); text("Sauthar:"); normal(); text(" So this is the Divine Dragons' power..."); terminal()
  }
}

codeCursor = pc()

}
