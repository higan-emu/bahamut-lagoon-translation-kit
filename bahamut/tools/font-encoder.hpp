#pragma once

#include "font-extractor.hpp"
#include "font-kerner-large.hpp"
#include "font-kerner-small.hpp"

struct FontEncoder {
  auto load(const string& name, u32 width, u32 height) -> void;
  auto loadMenuIcons() -> void;
  auto character(u8 character) const -> const u8*;
  auto width(u8 character) const -> u8;
  auto kerning(u8 character, u8 previous) const -> u8;
  auto encodeCharacters(const vector<u8>& palette, u8 shift) const -> vector<u8>;
  auto encodeCharacters(const vector<u8>& palette) const -> vector<u8>;
  auto encodeWidths() const -> vector<u8>;
  auto encodeKernings() const -> vector<u8>;

protected:
  auto calculateWidths() -> void;
  auto calculateKernings() -> void;

  struct Context {
    string name;
    u8 width;
    u8 height;
  } context;

  struct Character {
    u8 width;
    u8 kerning[128];
    u8 data[144];
  } characters[256];
};

auto FontEncoder::load(const string& name, u32 width, u32 height) -> void {
  if(width != 8 || height > 16) error("maximum size is 8x16");
  context.name   = name;
  context.width  = width;
  context.height = height;

  Decode::BMP bitmap(string{pathEN, "fonts/", name, ".bmp"});
  if(bitmap.width()  != (width  + 1) * 16) error("bitmap size incorrect or file missing");
  if(bitmap.height()  > (height + 1) * 16) error("bitmap size incorrect or file missing");
  auto data = bitmap.data();
  u32 pitch = (width + 1) * 16;

  for(u32 y : range(bitmap.height() / (height + 1))) {
    for(u32 x : range(16)) {
      auto& character = characters[y * 16 + x];
      for(u32 py : range(height + 1)) {
        for(u32 px : range(width)) {
          u32 pixel = data[(y * (height + 1) + py) * pitch + (x * (width + 1) + px)];
          u32 color = 0;
          switch(pixel & 0xffffff) {
          case 0x555555: color = 3; break;  //shadow
          case 0xaaaaaa: color = 2; break;  //hinting
          case 0xffffff: color = 1; break;  //text
          case 0x00aa00: color = 4; break;  //manual-width override
          }
          character.data[py * 8 + px] = color;
        }
      }
    }
  }

  calculateWidths();
  calculateKernings();
}

//loads icons from the Japanese 8x8 menu font into character slots 0x70-0x7c.
//this is used to allow the list editor to render icons in the English preview area.
auto FontEncoder::loadMenuIcons() -> void {
  FontExtractor font;
  font.extractMenu();
  for(u32 index : range(13)) {
    characters[0x70 + index].width = 9;
    memory::fill<u8>(characters[0x70 + index].kerning, 128);
    memory::fill<u8>(characters[0x70 + index].data,    144);
    if(index == 0) continue;
    for(u32 py : range(8)) {
      for(u32 px : range(8)) {
        u8 color = font.character(0xd4 + index)[py * 8 + px];
        switch(color) {
        case 1: color = 1; break;
        case 2: color = 2; break;
        case 3: color = 3; break;
        }
        characters[0x70 + index].data[py * 8 + px] = color;
      }
    }
  }
}

auto FontEncoder::character(u8 character) const -> const u8* {
//if(character >= 128) throw;
  return characters[character].data;
}

auto FontEncoder::width(u8 character) const -> u8 {
  if(character >= 128) throw;
  return characters[character].width;
}

auto FontEncoder::kerning(u8 character, u8 previous) const -> u8 {
  if(character >= 128 || previous >= 128) throw;
  return characters[character].kerning[previous];
}

auto FontEncoder::calculateWidths() -> void {
  const u8 width = context.width;
  const u8 height = context.height;

  for(u32 cy : range(8)) {
    for(u32 cx : range(16)) {
      auto& character = characters[cy * 16 + cx];
      character.width = 0;

      //deduce width based on pixel data
      for(u32 py : range(height)) {
        for(u32 px : range(width)) {
          u32 pixel = character.data[py * context.width + px];
          if(pixel && px > character.width) character.width = px;
        }
      }

      //check for manual-width overrides
      for(u32 px : range(width)) {
        u32 pixel = character.data[context.height * context.width + px];
        if(pixel && px > character.width) character.width = px;
      }

      //include the last pixel column in the character width
      character.width++;
    }
  }
}

auto FontEncoder::calculateKernings() -> void {
  for(u8 lhs : range(128)) {
    for(u8 rhs : range(128)) {
      u8 kerning = (context.height == 12 ? fontKerningLarge(lhs, rhs) : fontKerningSmall(lhs, rhs));
      characters[rhs].kerning[lhs] = kerning;
    }
  }
}

auto FontEncoder::encodeCharacters(const vector<u8>& palette, u8 shift) const -> vector<u8> {
  if(shift >= 8) error("shift can only be between 0-7");

  vector<u8> output;
  output.resize(128 * context.height * 2 * 2);

  for(u32 cy : range(8)) {
    for(u32 cx : range(16)) {
      auto& character = characters[cy * 16 + cx];
      for(u32 py : range(context.height)) {
        for(u32 px : range(context.width)) {
          u32 color = character.data[py * context.width + px];
          u32 pixel = palette[color];
          u32 offset = (cy * 16 + cx) * context.height * 2 * 2 + py * 2;
          u32 x = px + shift;
          if(x >= 8) x -= 8, offset += context.height * 2;
          output[offset + 0] |= bool(pixel & 1) << 7 - x;
          output[offset + 1] |= bool(pixel & 2) << 7 - x;
        }
      }
    }
  }

  return output;
}

auto FontEncoder::encodeCharacters(const vector<u8>& palette) const -> vector<u8> {
  vector<u8> output;
  for(u32 shift : range(8)) {
    output.append(encodeCharacters(palette, shift));
  }
  return output;
}

auto FontEncoder::encodeWidths() const -> vector<u8> {
  vector<u8> output;
  output.resize(128);
  for(u32 character : range(128)) {
    output[character] = characters[character].width;
  }
  return output;
}

auto FontEncoder::encodeKernings() const -> vector<u8> {
  vector<u8> output;
  output.resize(128 * 128);
  for(u32 previous : range(128)) {
    for(u32 character : range(128)) {
      output[previous * 128 + character] = kerning(character, previous);
    }
  }
  return output;
}
