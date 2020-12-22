#pragma once

#include "text-encoder.hpp"

struct ScriptEncoder : TextEncoder {
  using TextEncoder::load;
  auto load() -> void;
  auto lineWidth(const string& text, u32 index = 0) -> maybe<u32>;
};

auto ScriptEncoder::load() -> void {
  FontEncoder::load("font-large", 8, 11);
}

//enhanced version of TextEncoder::lineWidth() supporting additional commands.
//returns the number of pixels required to render a line of text.
//returns nothing if the line width cannot be determined or is ambiguous.
auto ScriptEncoder::lineWidth(const string& text, u32 index) -> maybe<u32> {
  u32 width = 0;
  TextEncoder::push();
  while(true) {
    auto read = TextEncoder::read(text, index);
    if(read.isTerminal()) break;
    if(read.isLineFeed()) break;
    if(read.isCommand()) {
      if(read.command == "skip") {
        width += read.argument.natural();
        continue;
      }
      if(read.command == "option") {
        width += 12;
        continue;
      }
      if(read.command == "style") {
        if(read.argument == "normal") { TextEncoder::setStyle(Style::Normal); continue; }
        if(read.argument == "italic") { TextEncoder::setStyle(Style::Italic); continue; }
      }
      if(read.command == "color") continue;
      if(read.command == "pause") continue;
      if(read.command == "wait" ) continue;
      if(auto index = TextEncoder::name(read.command)) {
        if(*index <= 9) {
          //dynamic name; assume the longest possible width
          width += 66;
        } else if(auto nameWidth = TextEncoder::lineWidth(read.command)) {
          //static name; fixed width
          width += *nameWidth;
        }
        continue;
      }
      return TextEncoder::pop(), nothing;  //other tags cannot be used with {center}
    }
    if(read.isCharacter()) {
      width -= read.kerning;
      width += read.width;
      continue;
    }
    return TextEncoder::pop(), nothing;
  }
  return TextEncoder::pop(), width;
}
