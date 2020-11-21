#pragma once

#include "text-encoder.hpp"

struct ScriptEncoder : TextEncoder {
  using TextEncoder::load;
  auto load() -> void;
  auto lineWidth(const string& text, u32 index = 0) -> maybe<u32>;

  vector<string> names;
};

auto ScriptEncoder::load() -> void {
  FontEncoder::load("font-large", 8, 12);
  names = string::read({pathEN, "scripts/lists/names.txt"}).split("\n");
}

//enhanced version of TextEncoder::lineWidth() supporting additional commands.
//returns the number of pixels required to render a line of text.
//returns nothing if the line width cannot be determined or is ambiguous.
auto ScriptEncoder::lineWidth(const string& text, u32 index) -> maybe<u32> {
  u32 width = 0;
  while(true) {
    auto read = TextEncoder::read(text, index);
    if(read.isTerminal()) break;
    if(read.isLineFeed()) break;
    if(read.isCommand()) {
      if(read.command == "font" ) continue;
      if(read.command == "pause") continue;
      if(read.command == "wait" ) continue;
      if(auto index = names.find(read.command)) {
        if(*index <= 9) {
          //dynamic name; assume the longest possible width
          width += 66;
        } else if(auto nameWidth = TextEncoder::lineWidth(names[*index])) {
          //static name; fixed width
          width += *nameWidth;
        }
        continue;
      }
      return nothing;  //other tags cannot be used with {center}
    }
    if(read.isCharacter()) {
      width -= read.kerning;
      width += read.width;
      continue;
    }
    return nothing;
  }
  return width;
}
