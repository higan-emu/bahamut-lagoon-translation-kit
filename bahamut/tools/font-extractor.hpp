#pragma once

#include "decompressor.hpp"

struct FontExtractor {
  auto character(u32 character) const -> array_view<u8>;
  auto encodeBitmap(const vector<u32>& palette) const -> vector<u32>;
  auto extractLarge() -> void;
  auto extractMenu() -> void;
  auto extractField() -> void;
  auto extractCombat() -> void;
  auto extractStats() -> void;

  auto bitmapWidth() const -> u32 { return context.countWidth * (context.characterWidth + 1); }
  auto bitmapHeight() const -> u32 { return context.countHeight * (context.characterHeight + 1); }
  auto bitmapPitch() const -> u32 { return 4 * bitmapWidth(); }

protected:
  auto extract1bpp(array_view<u8> input) -> void;
  auto extract2bpp(array_view<u8> input) -> void;
  auto extract4bpp(array_view<u8> input) -> void;

  struct Context {
    string name;
    u32 depth;
    u32 countWidth;
    u32 countHeight;
    u32 characterWidth;
    u32 characterHeight;
    u32 bitsPerPixel;
  } context;

  struct Character {
    u8 data[144];
  };
  vector<Character> characters;
};

auto FontExtractor::character(u32 character) const -> array_view<u8> {
  if(character >= characters.size()) return {};
  return {characters[character].data, context.characterWidth * context.characterHeight};
}

auto FontExtractor::encodeBitmap(const vector<u32>& palette) const -> vector<u32> {
  vector<u32> output;
  output.resize(bitmapWidth() * bitmapHeight());
  for(auto& pixel : output) pixel = 0xffaa0000;

  for(u32 cy : range(context.countHeight)) {
    for(u32 cx : range(context.countWidth)) {
      auto& character = characters[cy * context.countWidth + cx];
      for(u32 py : range(context.characterHeight)) {
        for(u32 px : range(context.characterWidth)) {
          u8 pixel = character.data[py * context.characterWidth + px];
          u32 color = 255 << 24 | palette[pixel];
          u32 ay = cy * (context.characterHeight + 1) + py;
          u32 ax = cx * (context.characterWidth  + 1) + px;
          output[ay * bitmapWidth() + ax] = color;
        }
      }
    }
  }

  return output;
}

auto FontExtractor::extractLarge() -> void {
  context.name = "large";
  context.depth = 1;
  context.countWidth = 16;
  context.countHeight = 64;
  context.characterWidth = 12;
  context.characterHeight = 12;
  characters.resize(16 * 64);

  u32 offset = 0x2d0000;
  array_view<u8> input = {rom.data() + offset, rom.size() - offset};
  extract1bpp(input);
}

auto FontExtractor::extractMenu() -> void {
  context.name = "menu";
  context.depth = 2;
  context.countWidth = 16;
  context.countHeight = 16;
  context.characterWidth = 8;
  context.characterHeight = 8;
  characters.resize(16 * 16);

  u32 offset = 0x2e0020;
  auto input = decompressLZ77({rom.data() + offset, rom.size() - offset});
  extract2bpp(input);
}

auto FontExtractor::extractField() -> void {
  context.name = "field";
  context.depth = 2;
  context.countWidth = 16;
  context.countHeight = 13;
  context.characterWidth = 8;
  context.characterHeight = 8;
  characters.resize(16 * 13);

  u32 offset = 0x08a000;
  array_view<u8> input{rom.data() + offset, rom.size() - offset};
  extract2bpp(input);
}

auto FontExtractor::extractCombat() -> void {
  context.name = "combat";
  context.depth = 4;
  context.countWidth = 16;
  context.countHeight = 28;
  context.characterWidth = 8;
  context.characterHeight = 8;
  characters.resize(16 * 28);

  u32 offset = 0x261b40;
  array_view<u8> input{rom.data() + offset, rom.size() - offset};
  extract4bpp(input);
}

auto FontExtractor::extractStats() -> void {
  context.name = "stats";
  context.depth = 4;
  context.countWidth = 16;
  context.countHeight = 1;
  context.characterWidth = 8;
  context.characterHeight = 8;
  characters.resize(16 * 1);

  u32 offset = 0x266420;
  array_view<u8> input{rom.data() + offset, rom.size() - offset};
  extract4bpp(input);
}

//hardcoded to 12x12 size
auto FontExtractor::extract1bpp(array_view<u8> input) -> void {
  for(u32 cy : range(context.countHeight)) {
    for(u32 cx : range(context.countWidth)) {
      auto& character = characters[cy * context.countWidth + cx];
      for(u32 py : range(12)) {
        u32 address = (cy * 16 + cx) * 24;
        u8 data0 = input[address + py * 2 + 0];
        u8 data1 = input[address + py * 2 + 1];
        for(u32 px : range(8)) {
          u8 color = (data0 & 0x80 >> px) ? 1 : 0;
          character.data[py * 12 + px + 0] = color;
        }
        for(u32 px : range(4)) {
          u8 color = (data1 & 0x80 >> px) ? 1 : 0;
          character.data[py * 12 + px + 8] = color;
        }
      }
    }
  }
}

//hardcoded to 8x8 size
auto FontExtractor::extract2bpp(array_view<u8> input) -> void {
  for(u32 cy : range(context.countHeight)) {
    for(u32 cx : range(context.countWidth)) {
      auto& character = characters[cy * context.countWidth + cx];
      for(u32 py : range(8)) {
        u32 address = (cy * 16 + cx) * 16;
        u8 data0 = input[address + py * 2 + 0];
        u8 data1 = input[address + py * 2 + 1];
        for(u32 px : range(8)) {
          u8 color = 0;
          color += (data0 & 0x80 >> px) ? 1 : 0;
          color += (data1 & 0x80 >> px) ? 2 : 0;
          character.data[py * 8 + px] = color;
        }
      }
    }
  }
}

//hardcoded to 8x8 size
auto FontExtractor::extract4bpp(array_view<u8> input) -> void {
  for(u32 cy : range(context.countHeight)) {
    for(u32 cx : range(context.countWidth)) {
      auto& character = characters[cy * context.countWidth + cx];
      for(u32 py : range(8)) {
        u32 address = (cy * 16 + cx) * 32;
        u8 data0 = input[address + py * 2 +  0];
        u8 data1 = input[address + py * 2 +  1];
        u8 data2 = input[address + py * 2 + 16];
        u8 data3 = input[address + py * 2 + 17];
        for(u32 px : range(8)) {
          u8 color = 0;
          color += (data0 & 0x80 >> px) ? 1 : 0;
          color += (data1 & 0x80 >> px) ? 2 : 0;
          color += (data2 & 0x80 >> px) ? 4 : 0;
          color += (data3 & 0x80 >> px) ? 8 : 0;
          character.data[py * 8 + px] = color;
        }
      }
    }
  }
}
