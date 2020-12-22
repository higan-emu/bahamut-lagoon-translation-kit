#pragma once

#include "font-extractor.hpp"
#include "font-kerner.hpp"

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
  auto pitch() const -> u32 { return context.pitch; }
  auto columns() const -> u8 { return context.columns; }
  auto rows() const -> u8 { return context.rows; }
  auto size() const -> u8 { return context.size; }

protected:
  auto calculateWidths() -> void;
  auto calculateKernings() -> void;

  struct Context {
    string name;
    u32 width;
    u32 height;
    u32 pitch;
    u32 columns;
    u32 rows;
    u32 size;
  } context;

  struct Character {
    u8 width;
    u8 kerning[192];
    u8 data[272];
  };
  vector<Character> characters;
};

auto FontEncoder::load(const string& name, u32 width, u32 height) -> void {
  if(width > 16 || height > 16) error("maximum size is 16x16");
  context.name   = name;
  context.width  = width;
  context.height = height;
  context.pitch  = (width + 1) * 16;

  Decode::BMP bitmap(string{pathEN, "fonts/", name, ".bmp"});
  context.columns = bitmap.width()  / (width  + 1);
  context.rows    = bitmap.height() / (height + 1);
  context.size    = context.columns * context.rows;
  if(context.columns != 16) error("bitmap size incorrect or file missing");
  if(context.rows    >  12) error("bitmap size incorrect or file missing");
  characters.resize(context.columns * context.rows);

  auto data = bitmap.data();
  for(u32 y : range(context.rows)) {
    for(u32 x : range(context.columns)) {
      auto& character = characters[y * 16 + x];
      for(u32 py : range(height)) {
        for(u32 px : range(width)) {
          u32 pixel = data[(y * (height + 1) + py) * pitch() + (x * (width + 1) + px)];
          u32 color = 0;
          switch(pixel & 0xffffff) {
          case 0x555555: color = 3; break;  //shadow
          case 0xaaaaaa: color = 2; break;  //hinting
          case 0xffffff: color = 1; break;  //text
          }
          character.data[py * width + px] = color;
        }
      }

      character.width = 0;
      u32 py = height;
      for(u32 px : range(width + 1)) {
        u32 pixel = data[(y * (height + 1) + py) * pitch() + (x * (width + 1) + px)];
        switch(pixel & 0xffffff) {
        case 0x00aa00: character.width = px + 1; break;  //manual-width override
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
    memory::fill<u8>(characters[0x70 + index].kerning, 192);
    memory::fill<u8>(characters[0x70 + index].data,    272);
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
  if(character >= size()) throw;
  return characters[character].data;
}

auto FontEncoder::width(u8 character) const -> u8 {
  if(character >= size()) throw;
  return characters[character].width;
}

auto FontEncoder::kerning(u8 character, u8 previous) const -> u8 {
  if(character >= size() || previous >= size()) throw;
  return characters[character].kerning[previous];
}

auto FontEncoder::calculateWidths() -> void {
  const u8 width  = context.width;
  const u8 height = context.height;

  for(u32 cy : range(context.rows)) {
    for(u32 cx : range(context.columns)) {
      auto& character = characters[cy * context.columns + cx];
      if(character.width) continue;  //manually specified

      //deduce width based on pixel data
      for(u32 py : range(height)) {
        for(u32 px : range(width)) {
          u32 pixel = character.data[py * context.width + px];
          if(pixel && px > character.width) character.width = px;
        }
      }

      //include the last pixel column in the character width
      //(unless it's the credits font, which uses a glow-type font shadow)
      if(width != 12) character.width++;
    }
  }
}

auto FontEncoder::calculateKernings() -> void {
  FontKerner kerner;
  kerner.allocate(size());
  kerner.load({context.name, ""       }, 0);
  kerner.load({context.name, "-normal"}, 0);
  kerner.load({context.name, "-italic"}, 1);
  kerner.load({context.name, "-tiny"  }, 1);

  for(u8 lhs : range(size())) {
    for(u8 rhs : range(size())) {
      characters[rhs].kerning[lhs] = kerner.kernings[lhs * size() + rhs];
    }
  }
}

auto FontEncoder::encodeCharacters(const vector<u8>& palette, u8 shift) const -> vector<u8> {
  if(shift >= 8) error("shift can only be between 0-7");

  vector<u8> output;
  output.resize(characters.size() * context.height * 2 * 2);

  for(u32 cy : range(context.rows)) {
    for(u32 cx : range(context.columns)) {
      auto& character = characters[cy * context.columns + cx];
      for(u32 py : range(context.height)) {
        for(u32 px : range(context.width)) {
          u32 color = character.data[py * context.width + px];
          u32 pixel = palette[color];
          u32 offset = (cy * context.columns + cx) * context.height * 2 * 2 + py * 2;
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
    auto data = encodeCharacters(palette, shift);
    if(data.size() > 0x2000) data.resize(0x2000);  //8x11 font reduction
    output.append(data);
  }
  return output;
}

auto FontEncoder::encodeWidths() const -> vector<u8> {
  vector<u8> output;
  output.resize(characters.size());
  for(u32 character : range(characters.size())) {
    output[character] = characters[character].width;
  }
  return output;
}

auto FontEncoder::encodeKernings() const -> vector<u8> {
  vector<u8> output;
  u32 count = min(180, characters.size());  //keep kernings table below 32KB
  output.resize(count * count);
  for(u32 previous : range(count)) {
    for(u32 character : range(count)) {
      output[previous * count + character] = kerning(character, previous);
    }
  }
  return output;
}
