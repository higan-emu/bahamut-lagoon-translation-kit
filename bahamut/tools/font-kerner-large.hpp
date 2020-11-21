#pragma once

#include "converter.hpp"

auto fontKerningLarge(u8 lhs, u8 rhs) -> u8 {
  auto lascii = toAscii(lhs);
  auto rascii = toAscii(rhs);
  if(!lascii || !rascii) return 0;
  lhs = *lascii;
  rhs = *rascii;
  #define pair(l, r, v) if(lhs == l && rhs == r) return v

  pair('F','a',1);
  pair('P','a',1);
  pair('T','a',1);
  pair('V','a',1);
  pair('Y','a',1);
  pair('f','a',1);
  pair('r','a',1);
  pair('v','a',1);
  pair('y','a',1);

  pair('T','c',1);
  pair('T','d',1);
  pair('T','e',1);
  pair('T','f',1);
  pair('T','g',1);

  pair('A','j',1);
  pair('B','j',1);
  pair('C','j',1);
  pair('D','j',1);
  pair('E','j',1);
  pair('F','j',1);
  pair('G','j',1);
  pair('H','j',1);
  pair('I','j',1);
  pair('J','j',1);
  pair('K','j',1);
  pair('L','j',1);
  pair('M','j',1);
  pair('N','j',1);
  pair('O','j',1);
  pair('P','j',1);
  pair('R','j',1);
  pair('S','j',1);
  pair('T','j',2);
  pair('U','j',1);
  pair('V','j',1);
  pair('W','j',1);
  pair('X','j',1);
  pair('Y','j',1);
  pair('Z','j',1);
  pair('a','j',1);
  pair('b','j',1);
  pair('c','j',1);
  pair('d','j',1);
  pair('e','j',1);
  pair('f','j',1);
  pair('h','j',1);
  pair('i','j',1);
  pair('k','j',1);
  pair('l','j',1);
  pair('m','j',1);
  pair('n','j',1);
  pair('o','j',1);
  pair('p','j',1);
  pair('r','j',1);
  pair('s','j',1);
  pair('t','j',1);
  pair('u','j',1);
  pair('v','j',1);
  pair('w','j',1);
  pair('x','j',1);
  pair('y','j',1);
  pair('z','j',1);

  pair('T','m',1);
  pair('T','n',1);
  pair('T','o',1);
  pair('T','p',1);
  pair('T','q',1);
  pair('T','r',1);
  pair('T','s',1);

  pair('E','t',1);
  pair('I','t',1);
  pair('K','t',1);
  pair('L','t',1);
  pair('T','t',1);

  pair('T','u',1);

  pair('E','v',1);
  pair('I','v',1);
  pair('K','v',1);
  pair('L','v',1);
  pair('T','v',1);

  pair('T','w',1);
  pair('T','x',1);
  pair('T','y',1);
  pair('T','z',1);

  pair('F','.',1);
  pair('P','.',1);
  pair('T','.',1);
  pair('V','.',1);
  pair('Y','.',1);
  pair('f','.',1);
  pair('r','.',1);
  pair('v','.',1);
  pair('y','.',1);

  pair('B',',',1);
  pair('C',',',1);
  pair('D',',',1);
  pair('F',',',1);
  pair('G',',',1);
  pair('J',',',1);
  pair('O',',',1);
  pair('P',',',2);
  pair('S',',',1);
  pair('T',',',2);
  pair('U',',',1);
  pair('V',',',2);
  pair('W',',',1);
  pair('Y',',',2);
  pair('b',',',1);
  pair('f',',',2);
  pair('r',',',2);
  pair('s',',',1);
  pair('u',',',1);
  pair('v',',',2);
  pair('w',',',1);
  pair('y',',',2);

  pair('D','?',1);
  pair('a','?',1);
  pair('b','?',1);
  pair('c','?',1);
  pair('e','?',1);
  pair('g','?',1);
  pair('h','?',1);
  pair('k','?',1);
  pair('m','?',1);
  pair('n','?',1);
  pair('o','?',1);
  pair('p','?',1);
  pair('q','?',1);
  pair('r','?',1);
  pair('s','?',1);
  pair('t','?',1);
  pair('u','?',1);
  pair('v','?',1);
  pair('w','?',1);
  pair('x','?',1);
  pair('y','?',1);
  pair('z','?',1);

  pair('Y','c',1);
  pair('Y','d',1);
  pair('Y','e',1);
  pair('Y','f',1);
  pair('Y','g',1);
  pair('Y','o',1);
  pair('Y','q',1);
  pair('Y','s',1);

  #undef pair
  return 0;
}
