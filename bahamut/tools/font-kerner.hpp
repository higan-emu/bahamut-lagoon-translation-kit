#pragma once

#include "character-map.hpp"

struct FontKerner {
  auto allocate(u32 characters) -> void;
  auto load(string name, bool italic = 0) -> void;

  u32 characters = 0;
  vector<u8> kernings;
};

auto FontKerner::allocate(u32 characters) -> void {
  this->characters = characters;
  kernings.reset();
  kernings.resize(characters * characters);
}

auto FontKerner::load(string name, bool italic) -> void {
  auto lines = string::read({pathEN, "fonts/", name, ".txt"}).split("\n");
  for(auto& line : lines) {
    if(!line || line[0] == '#') continue;

    s8 p = 0;
    u8 edge = line[p++] - '0';
    if(edge < 0 || edge > 9) continue;
    if(line[p++] != ' ') continue;

    u32 lhs = line[p++];
    if(lhs == 0xc3) lhs = lhs << 8 | line[p++];  //umlauts

    while(line[p]) {
      u32 rhs = line[p++];
      if(rhs == 0xc3) rhs = rhs << 8 | line[p++];  //umlauts

      auto lbyte = toDecoded(lhs);
      auto rbyte = toDecoded(rhs);
      if(!lbyte || !rbyte) continue;

      if(italic) {
        *lbyte += 0x60;
        *rbyte += 0x60;
      }

      u32 entry = *lbyte * characters + *rbyte;
      if(entry >= kernings.size()) continue;
      kernings[entry] = edge;
    }
  }
}
