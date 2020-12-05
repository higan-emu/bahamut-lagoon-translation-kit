namespace command {
  constant base  = $f0  //$f0-$ff
  constant break = $fe  //$fe-$ff

  constant styleNormal = $f0
  constant styleItalic = $f1  //8x11 font
  constant styleTiny   = $f1  // 8x8 font
  constant colorNormal = $f2
  constant colorYellow = $f3
  constant name        = $f4
  constant redirect    = $f5
  constant alignLeft   = $f6
  constant alignCenter = $f7
  constant alignRight  = $f8
  constant alignSkip   = $f9
  constant reserved0   = $fa
  constant reserved1   = $fb
  constant pause       = $fc
  constant wait        = $fd
  constant lineFeed    = $fe
  constant terminal    = $ff
}

namespace status {
  namespace ailments {
    constant mask      = $f1  //used bits only
    constant bunny     = $01
    constant unused    = $02
    constant frozen    = $04  //unused (but functional)
    constant shield    = $08  //unused
    constant sleeping  = $10
    constant poisoned  = $20
    constant petrified = $40
    constant defeated  = $80
  }

  namespace enchants {
    constant mask    = $80  //used bits only
    constant protect = $01  //unused
    constant reflect = $02  //unused
    constant unused  = $7c
    constant bingo   = $80
  }

  namespace affinity {
    constant mask    = $f8  //used bits only
    constant unused  = $07
    constant thunder = $08
    constant crystal = $10
    constant poison  = $20
    constant water   = $40
    constant fire    = $80
  }

  namespace property {
    constant mask   = $01  //used bits only
    constant undead = $01
    constant unused = $fe
  }
}

namespace dragons {

namespace stats {
  constant hp           = $7e2107  //0-9999
  constant mp           = $7e210b  //0-999

  constant base         = $7e3bf0
  constant strength     = $7e3bf6  //0-250
  constant vitality     = $7e3bf7  //0-250
  constant dexterity    = $7e3bf8  //0-250
  constant intelligence = $7e3bf9  //0-250
  constant fire         = $7e3bfa  //0-100
  constant water        = $7e3bfb  //0-100
  constant thunder      = $7e3bfc  //0-100
  constant recovery     = $7e3bfd  //0-100
  constant poison       = $7e3bfe  //0-100
  constant corruption   = $7e3bff  //0-100
  constant timidity     = $7e3c00  //0-100
  constant wisdom       = $7e3c01  //0-100
  constant aggression   = $7e3c02  //0-100
  constant mutation     = $7e3c03  //0-100
  constant affection    = $7e3c04  //0-100
}

}
