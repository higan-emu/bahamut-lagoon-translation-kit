#pragma once

#include "converter.hpp"

auto fontKerningSmall(u8 lhs, u8 rhs) -> u8 {
  auto lascii = toAscii(lhs);
  auto rascii = toAscii(rhs);
  if(!lascii || !rascii) return 0;
  lhs = *lascii;
  rhs = *rascii;
  #define pair(l, r, v) if(lhs == l && rhs == r) return v

  pair('I','f',1);
  pair('I','q',1);
  pair('I','t',1);

  pair('K','f',1);

  pair('L','f',1);
  pair('L','t',1);

  pair('T','a',1);
  pair('T','c',1);
  pair('T','d',1);
  pair('T','e',1);
  pair('T','f',1);
  pair('T','g',1);
  pair('T','j',1);
  pair('T','m',1);
  pair('T','n',1);
  pair('T','o',1);
  pair('T','p',1);
  pair('T','q',1);
  pair('T','r',1);
  pair('T','s',1);
  pair('T','t',1);
  pair('T','u',1);
  pair('T','v',1);
  pair('T','w',1);
  pair('T','x',1);
  pair('T','y',1);
  pair('T','z',1);
  pair('X','f',1);
  pair('Z','f',1);

  pair('r','a',1);

  pair('F','.',1);
  pair('P','.',1);
  pair('T','.',1);
  pair('V','.',1);
  pair('W','.',1);
  pair('Y','.',1);
  pair('f','.',1);
  pair('r','.',2);
  pair('v','.',2);

  pair('F',',',1);
  pair('T',',',2);
  pair('V',',',2);
  pair('W',',',1);
  pair('Y',',',2);
  pair('f',',',1);
  pair('p',',',1);
  pair('r',',',2);
  pair('v',',',2);

  pair('L','?',1);
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

  #undef pair
  return 0;
}
