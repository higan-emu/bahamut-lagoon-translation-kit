#pragma once

#include "font-encoder.hpp"

struct TextEncoder : FontEncoder {
  using FontEncoder::load;

  struct Read {
    auto isUnknown() const -> bool { return type == Type::Unknown; }
    auto isTerminal() const -> bool { return type == Type::Terminal; }
    auto isLineFeed() const -> bool { return type == Type::LineFeed; }
    auto isCommand() const -> bool { return type == Type::Command; }
    auto isCharacter() const -> bool { return type == Type::Character; }

    auto setUnknown() -> Read& { type = Type::Unknown; return *this; }
    auto setTerminal() -> Read& { type = Type::Terminal; return *this; }
    auto setLineFeed() -> Read& { type = Type::LineFeed; return *this; }
    auto setCommand(string command, string argument = "") -> Read& {
      type = Type::Command;
      this->command = command;
      this->argument = argument;
      return *this;
    }
    auto setCharacter(u8 decoded, u8 encoded, u8 width, u8 kerning) -> Read& {
      type = Type::Character;
      this->decoded = decoded;
      this->encoded = encoded;
      this->width = width;
      this->kerning = kerning;
      return *this;
    }

    enum class Type : uint { Unknown, Terminal, LineFeed, Command, Character } type;
    string command;
    string argument;
    u8 decoded = 0;
    u8 encoded = 0;
    u8 width = 0;
    u8 kerning = 0;
  };

  auto resetKerning() -> void;
  auto read(const string& text, u32& index) -> Read;
  auto lineWidth(const string& text, u32 index = 0) -> maybe<u32>;

  u32 previous = 0;
};

auto TextEncoder::resetKerning() -> void {
  previous = 0;
}

auto TextEncoder::read(const string& text, u32& index) -> Read {
  while(text[index] == '\r') index++;  //ignore carriage returns

  u32 p1 = u8(text[index]);
  u32 p2 = u8(text(index + 1, 0x00)) | p1 << 8;
  u32 p3 = u8(text(index + 2, 0x00)) | p2 << 8;

  if(!p1) {
    previous = 0;
    return Read().setTerminal();
  }

  if(p1 == '\n') {
    previous = 0;
    index++;
    return Read().setLineFeed();
  }

  if(p1 == '{') {
    auto command = text.slice(index + 1).split("}", 1L);
    if(command.size() != 2) return Read().setUnknown();  //missing '}'
    index += command[0].size() + 2;
    auto argument = command[0].split(":", 1L);
    return Read().setCommand(argument[0], argument(1).strip());
  }

  if(p1 == '[') {
    index++;
    return Read().setCommand("font", "yellow");
  }

  if(p1 == ']') {
    index++;
    return Read().setCommand("font", "normal");
  }

     maybe<u8> decoded = toDecoded(p1);
  if(!decoded) decoded = toDecoded(p2);
  if(!decoded) decoded = toDecoded(p3);

       maybe<u8> encoded = toEncoded(p1); if(encoded) index += 1;
  if(!encoded) { encoded = toEncoded(p2); if(encoded) index += 2; }
  if(!encoded) { encoded = toEncoded(p3); if(encoded) index += 3; }

  if(decoded && encoded) {
    u8 width = FontEncoder::width(*decoded);
    u8 kerning = FontEncoder::kerning(*decoded, previous);
    previous = *decoded;
    return Read().setCharacter(*decoded, *encoded, width, kerning);
  }

  index += 1;  //skip the unknown character
  return Read().setUnknown();
}

//returns the number of pixels required to render a line of text.
//returns nothing if the line width cannot be determined or is ambiguous.
auto TextEncoder::lineWidth(const string& text, u32 index) -> maybe<u32> {
  u32 width = 0;
  while(true) {
    auto read = TextEncoder::read(text, index);
    if(read.isTerminal()) break;
    if(read.isLineFeed()) break;
    if(read.isCommand()) {
      if(read.command == "space") {
        width += read.argument.natural();
        continue;
      }
      return nothing;
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
