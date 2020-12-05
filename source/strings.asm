//this file keeps track of tiledata indexes into pre-rendered string lists in one place

namespace strings {

variable counter = 0

inline reset() {
  strings.counter = 0
}

inline constant(variable size, define label) {
  constant {label} = strings.counter
  strings.counter = strings.counter + size
}

namespace bpp2 {
  reset()
  constant( 8,formation)
  constant( 8,dragons)
  constant( 8,information)
  constant( 8,equipment)
  constant( 8,viewMap)
  constant( 8,sortie)
  constant( 8,sideQuest)
  constant( 8,autoFormation)
  constant( 8,formationSet)
  constant( 8,magic)
  constant( 8,item)
  constant( 6,strength)
  constant( 6,vitality)
  constant( 6,dexterity)
  constant( 6,intelligence)
  constant( 6,fire)
  constant( 6,water)
  constant( 6,thunder)
  constant( 6,earth)
  constant( 6,recovery)
  constant( 6,poison)
  constant( 6,timidity)
  constant( 6,corruption)
  constant( 6,wisdom)
  constant( 6,aggression)
  constant( 6,mutation)
  constant( 6,affection)
  constant( 6,hp)
  constant( 6,mp)
  constant(16,reserveDragon)
  constant( 8,attack)
  constant( 8,defense)
  constant( 8,speed)
  constant( 2,buy)
  constant( 2,sell)
  constant(12,classesAbleToEquip)
  constant( 4,piro)
  constant(12,currentlyHolding)
  constant(12,currentlyEquipped)
  constant( 8,noItemsLeftAligned)
  constant( 8,noItemsCentered)
  constant(12,equipmentSummary)
  constant(18,itemExplanation)
  constant(18,dragonKeepersItemExplanation)
  constant( 6,unknown)
  constant( 4,space)
  constant( 9,commandCome)
  constant( 9,commandGo)
  constant( 9,commandWait)
  constant( 3,boss)
}

namespace bpp4 {
  reset()
  constant( 8,attack)
  constant( 8,defense)
  constant( 8,speed)
  constant( 8,magic)
  constant( 8,experience)
  constant( 8,nextLevel)
  constant(16,overwriteSave)
  constant(16,continuePlaying)
  constant(16,beginSortie)
  constant( 4,yes)
  constant( 4,no)
  constant( 8,finished)
}

namespace bpo4 {
  reset()
  constant( 3,feed)
  constant( 3,exit)
}

namespace bph4 {
  reset()
  constant( 8,noData)
  constant( 8,exPlay)
  constant(12,bonusDungeon1)
  constant(12,bonusDungeon2)
  constant(12,bonusDungeon3)
}

}
