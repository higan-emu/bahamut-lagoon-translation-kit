namespace menu {

seek(codeCursor)

//formation overview
namespace formations {
  enqueue pc
  seek($ee99f8); jsl technique
  seek($ee9a05); jsl technique.level
  seek($ee9a2c); jsl technique.count
  seek($eea5cd); jsl technique.blank
  dequeue pc

  allocator.bpp2()
  allocator.create(5, 8,party)
  allocator.create(7, 2,page)
  allocator.create(7,24,name)
  allocator.create(8,24,class)
  allocator.create(3,24,level)
  allocator.create(5, 2,selectedParty)
  allocator.create(6, 5,techniqueName)
  allocator.create(3, 5,techniqueLevel)

  //A = party
  function party {
    variable(2, counter1)
    variable(2, counter2)
    variable(2, counter3)
    variable(2, counter4)

    enter
    mul(5); tay
    lda $001860
    cmp #$00c6; bne +; getTileIndex(counter1, 2); ora #$0000; bra render; +
    cmp #$02c6; bne +; getTileIndex(counter2, 2); ora #$0002; bra render; +
    cmp #$04c6; bne +; getTileIndex(counter3, 2); ora #$0004; bra render; +
    cmp #$074e; bne +; getTileIndex(counter4, 2); ora #$0006; bra render; +
    leave; rtl

  render:
    allocator.lookup(party)
    lda #$0005; write.bpp2(lists.parties.bpp2)
    leave; rtl
  }

  function page {
    variable(2, pageIndex)
    variable(2, pageTotal)

    function index {
      sta pageIndex
      rtl
    }

    function total {
      enter
      sta pageTotal
      ldx #$0000; append.alignLeft(2); append.literal("Page"); append.alignRight(31)
      lda pageIndex; append.integer_2(); append.literal("/")
      lda pageTotal; append.integer_2()
      lda #$0007; render.small.bpp2()
      allocator.index(page); jsl write.bpp2
      leave; rtl
    }
  }

  //A = name
  function name {
    enter
    and #$00ff
    cmp #$0009; jcs static
  dynamic:
    mul(8); tay
    lda #$0007; allocator.index(name); write.bpp2(names.buffer.bpp2)
    leave; rtl
  static:
    mul(8); tay
    lda #$0007; allocator.index(name); write.bpp2(lists.names.bpp2)
    leave; rtl
  }

  //A = class
  function class {
    enter
    mul(8); tay
    lda #$0008; allocator.index(class); write.bpp2(lists.classes.bpp2)
    leave; rtl
  }

  //A = level
  function level {
    enter
    and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
    mul(3); tay
    lda #$0003; allocator.index(level); write.bpp2(lists.levels.bpp2)
    leave; rtl
  }

  //A = technique
  function technique {
    enter
    and #$00ff
    mul(8); tay
    lda #$0006; allocator.index(techniqueName); write.bpp2(lists.techniques.bpp2)
    leave; rtl

    function blank {
      enter
      lda #$00ff  //position of "--------" in technique list
      jsl technique
      leave; rtl
    }

    //A = technique level
    function level {
      enter
      and #$00ff; cmp.w #100; bcc +; lda.w #100; +  //100+ => "??"
      mul(3); tay
      lda #$0003; allocator.index(techniqueLevel); write.bpp2(lists.levels.bpp2)
      leave; rtl
    }

    //A = technique count
    function count {
      enter
      and #$00ff; add #$0001; pha
      lda $001860; tax; pla
      ora $001862
      sta $7ec400,x
      leave; rtl
    }
  }
}

codeCursor = pc()

}
