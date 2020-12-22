#include "tools.hpp"
#include "decompressor.hpp"
#include "script-extractor.hpp"
#include "compressor.hpp"
#include "script-encoder.hpp"

struct Encoder : ScriptEncoder {
  Encoder();
  auto loadScript(Script& script, const string& filename) -> vector<string>;
  auto encodeScript(Script& script, vector<string>& english) -> void;

  struct Context {
    vector<u8> script;
  } context;
};

Encoder::Encoder() {
  ScriptEncoder::load();
}

auto Encoder::loadScript(Script& script, const string& filename) -> vector<string> {
  u32 count = script.pointers.size();
  vector<string> english;
  english.resize(count);
  auto blocks = string::read(filename).split("\n{end}\n\n");
  for(auto& block : blocks) {
    u16 offset = slice(block, 1, 4).hex();
    for(u32 index : range(count)) {
      if(script.pointers[index].target != offset) continue;
      english(index) = slice(block, 7);
      break;
    }
  }
  return english;
}

auto Encoder::encodeScript(Script& script, vector<string>& english) -> void {
  u32 count = script.pointers.size();

  //erase the Japanese text to allow for better compression
  for(u32 index = script.origin; index < script.data.size(); index++) {
    script.data[index] = Command::Terminal;
  }

  //encode pointers to English text into the Japanese text
  for(u32 pointer : range(count)) {
    u32 source = context.script.size();
    u16 target = script.pointers[pointer].target;
    //write 21-bit redirection pointer command; leaving d7 clear for the pointer
    //this is to prevent a value of 0xf0-0xff being misinterpreted as a control byte
    write8(script.data, target + 0, Command::Redirect);
    write8(script.data, target + 1, source >>  0 & 0x7f);
    write8(script.data, target + 2, source >>  7 & 0x7f);
    write8(script.data, target + 3, source >> 14 & 0x7f);
    string text = english(pointer);
    u32 index = 0;
    u32 x = 0;
    TextEncoder::reset();
    while(true) {
      auto read = TextEncoder::read(text, index);
      if(read.isTerminal()) {
        u8 terminal = script.pointers(pointer).terminal;
        context.script.append(terminal);
        x = 0;
        break;
      }
      if(read.isLineFeed()) {
        context.script.append(Command::LineFeed);
        x = 0;
        continue;
      }
      if(read.isCommand()) {
        if(read.command == "style" && read.argument == "normal") {
          TextEncoder::setStyle(TextEncoder::Style::Normal);
          context.script.append(Command::StyleNormal);
          continue;
        }
        if(read.command == "style" && read.argument == "italic") {
          TextEncoder::setStyle(TextEncoder::Style::Italic);
          context.script.append(Command::StyleItalic);
          continue;
        }
        if(read.command == "color" && read.argument == "normal") {
          context.script.append(Command::ColorNormal);
          continue;
        }
        if(read.command == "color" && read.argument == "yellow") {
          context.script.append(Command::ColorYellow);
          continue;
        }
        if(read.command == "left") {
          context.script.append(Command::AlignLeft);
          x = 0;
          continue;
        }
        if(read.command == "center") {
          context.script.append(Command::AlignCenter);
          if(auto width = ScriptEncoder::lineWidth(text, index)) {
            x = (240 - *width) / 2;
          }
          continue;
        }
        if(read.command == "right") {
          context.script.append(Command::AlignRight);
          if(auto width = ScriptEncoder::lineWidth(text, index)) {
            x = (240 - *width);
          }
          continue;
        }
        if(read.command == "skip") {
          context.script.append(Command::AlignSkip);
          context.script.append(read.argument.natural());
          x += read.argument.natural();
          if(x > 240) error("overflow detected: {\n", text, "\n}\n");
          continue;
        }
        if(read.command == "option") {
          context.script.append(Command::AlignSkip);
          context.script.append(12);
          if(x > 240) error("overflow detected: {\n", text, "\n}\n");
          continue;
        }
        if(read.command == "pause") {
          context.script.append(Command::Pause);
          context.script.append(read.argument.hex());
          continue;
        }
        if(read.command == "wait" && script.mode == Script::Mode::Field) {
          context.script.append(Command::Wait);
          continue;
        }
        if(auto index = TextEncoder::name(read.command)) {
          context.script.append(Command::Name);
          context.script.append(*index);
          if(*index <= 9) {
            x += 66;  //maximum dynamic name length
          } else if(auto nameWidth = TextEncoder::lineWidth(read.command)) {
            x += *nameWidth;
          }
          if(x > 240) error("overflow detected: {\n", text, "\n}\n");
          continue;
        }
        error("unrecognized command: {", read.command, "}\n", text, "\n");
      }
      if(read.isCharacter()) {
        context.script.append(read.encoded);
        x -= read.kerning;
        x += read.width;
        if(x > 240) error("overflow detected: {\n", text, "\n}\n");
        continue;
      }
      error("unknown symbol: ", hex(text[index], 2L));
    }
    if(context.script.size() - source >= 1000) {
      error("1KB maximum block size exceeded for ", script.label(pointer));
    }
  }
}

//this is needed to move the opening credits text down one line
auto encodeOpeningCredits() -> void {
  u8 index = 0xfa;
  u32 address = read24(rom, tableChapter + index * 3) - 0xc00000;
  u16 size = 0;

  auto input = decompressLZSS({rom.data() + address, rom.size() - address}, &size);
  input[0x13] = 0x03;  //Y position for opening credits text strings (was 0x02)
  for(u32 offset = 0x0402; offset < input.size(); offset++) {
    input[offset] = 0xff;  //erase the original text for better script file compression
  }

  auto output = compressLZSS(input);
  if(output.size() > size) {
    error("Chapter ", hex(index, 2L), ": ", output.size(), " > ", size);
  }
  file::write({pathEN, "binaries/chapters/chapter-", hex(index, 2L), ".bin"}, output);
}

auto nall::main() -> void {
  directory::create({pathEN, "binaries/script/"});
  directory::create({pathEN, "binaries/chapters/"});
  directory::create({pathEN, "binaries/fields/"});

  Encoder encoder;

  for(u32 index : range(256)) {
    Script script;
    if(!script.loadChapter(index)) continue;
    if(!script.analyze()) continue;
    string source = {pathEN,  "scripts/chapters/chapter-", hex(index, 2L), ".txt"};
    string target = {pathEN, "binaries/chapters/chapter-", hex(index, 2L), ".bin"};
    auto english = encoder.loadScript(script, source);
    encoder.encodeScript(script, english);
    auto data = compressLZSS(script.data);
    if(data.size() > script.size) {
      error("Chapter ", hex(index, 2L), ": ", data.size(), " > ", script.size);
    }
    file::write(target, data);
  }

  for(u32 index : range(33)) {
    Script script;
    if(!script.loadField(index)) continue;
    if(!script.analyze()) continue;
    string source = {pathEN,  "scripts/fields/field-", hex(index, 2L), ".txt"};
    string target = {pathEN, "binaries/fields/field-", hex(index, 2L), ".bin"};
    auto english = encoder.loadScript(script, source);
    encoder.encodeScript(script, english);
    auto data = compressLZSS(script.data);
    if(data.size() > script.size) {
      error("Field ", hex(index, 2L), ": ", data.size(), " > ", script.size);
    }
    file::write(target, data);
  }

  file::write({pathEN, "binaries/script/script.bin"}, encoder.context.script);

  encodeOpeningCredits();
}
