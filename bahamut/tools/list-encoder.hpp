#pragma once

#include "text-encoder.hpp"

struct ListEncoder : TextEncoder {
  template<u32 BitsPerPixel, bool SaveWidths> auto toSmall(string suffix, array_view<u8> palette, u32 characters, string category, string name) -> void;
  auto toLarge(string suffix, array_span<u8> palette, string category, string name) -> void;
  template<bool SaveWidths> auto toText(string suffix, u32 width, string category, string name) -> void;
};

template<u32 BitsPerPixel, bool SaveWidths>
auto ListEncoder::toSmall(string suffix, array_view<u8> palette, u32 characters, string category, string name) -> void {
  static_assert(BitsPerPixel == 2 || BitsPerPixel == 4);
  const u32 TileSize = (BitsPerPixel == 2 ? 16 : 32);
  const bool Manual = (characters == 0);
  if(palette.size() != 4) error("palette size incorrect");

  vector<u8> icons;
  icons.resize(12 * TileSize);
  if(BitsPerPixel == 2) {
    auto font = decompressLZ77({rom.data() + 0x2e0020, rom.size() - 0x2e0020});
    memory::copy(icons.data(), font.data() + 0xd5 * TileSize, icons.size());
  } else if(BitsPerPixel == 4 && palette[0] == 0) {
    auto font = decompressLZ77({rom.data() + 0x2e0020, rom.size() - 0x2e0020});
    for(u32 icon : range(12)) {
      memory::copy(icons.data() + icon * 32, font.data() + (0xd5 + icon) * 16, 16);
    }
  } else {
    auto font = array_view<u8>{rom.data() + 0x261b40, rom.size() - 0x261b40};
    memory::copy(icons.data(), font.data() + 0x1e * TileSize, icons.size());
  }

  vector<string> lines;
  vector<u8> tiles;
  vector<u8> widths;

  string filename = {pathEN, "scripts/", category, "/", name, ".txt"};
  if(file::exists(filename)) {
    lines = string::read(filename).trimRight("\n", 1L).split("\n");
  }
  if(name == "costsMP" || name == "costsSP") {
    for(u32 index : range(100)) {
      string line;
      line.append("{right}");
      if(index <=  9) line.append("{skip:5}");
      if(index >= 10) line.append("{tile:", hex(0x96 + index / 10, 2L), "}");
      line.append("{tile:", hex(0x96 + index % 10, 2L), "}");
      line.append("{skip:1}");
      if(name == "costsMP") line.append("{tile:6d}");
      if(name == "costsSP") line.append("{tile:73}");
      line.append("{tile:70}");
      lines.append(line);
    } {
      string line;
      line.append("{right}{tile:ad}{tile:ad}{skip:1}");  //"??"
      if(name == "costsMP") line.append("{tile:6d}");
      if(name == "costsSP") line.append("{tile:73}");
      line.append("{tile:70}");
      lines.append(line);
    } {
      string line;
      line.append("{right}{tile:ae}{tile:ae}{skip:1}");  //"--"
      if(name == "costsMP") line.append("{tile:6d}");
      if(name == "costsSP") line.append("{tile:73}");
      line.append("{tile:70}");
      lines.append(line);
    }
  }
  if(name == "counts") {
    for(u32 index : range(100)) lines.append({"{skip:5}*{skip:1}", pad(index, 2, '_')});
    lines.append("{skip:5}*{skip:1}^^");  //"??"
    lines.append("{skip:5}*{skip:1}~~");  //"--"
  }
  if(name == "items") {
    //additions not in the original Japanese text (list-editor would lose them otherwise)
    //todo: handle this better somehow
    lines.append("{icon:0}No Weapon");
    lines.append("{icon:0}No Armor");
  }
  if(name == "levels") {
    for(u32 index : range(100)) lines.append({"{right}Lv.{skip:1}", pad(index, 2, '_')});
    lines.append("{right}Lv.{skip:1}^^");  //"??"
    lines.append("{right}Lv.{skip:1}~~");  //"--"
  }
  if(name == "levels4") {
    for(u32 index : range(100)) lines.append({"{right}Lv.{skip:1}", pad(index, 2, '_'), "{skip:5}"});
    lines.append("{right}Lv.{skip:1}^^{skip:5}");  //"??"
    lines.append("{right}Lv.{skip:1}~~{skip:5}");  //"--"
  }
  if(name == "quantities") {
    for(u32 index : range(100)) lines.append({"{right}", pad(index, 2, '_')});
    lines.append("{right}^^");  //"??"
    lines.append("{right}~~");  //"--"
  }
  if(name == "stats") {
    for(u32 index : range(256)) lines.append({"{right}", pad(index, 3, '_')});
    lines.append("{right}^^^");  //"???"
    lines.append("{right}~~~");  //"---"
    if(characters == 4) {
      lines.resize(256);
      for(auto& line : lines) {
        if(suffix == "bpi4") line.append("{tile:5e}");
        if(suffix == "bpd4") line.append("{tile:5f}");
      }
    }
  }

  for(auto& line : lines) {
    vector<Natural<8>> output;
    output.resize(36 * TileSize);  //reserve extra space in case the string overflows the character count

    //clear tiledata to the background color (which may not be 0)
    for(u32 x = 0; x < 36 * 8; x += 8) {
      for(u32 py : range(8)) {
        for(u32 px : range(8)) {
          u32 color = palette[0];
          u32 offset = ((x + px) / 8 * TileSize) + (py * 2);
          output[offset +  0].bit(7 - (x + px) % 8) = bool(color & 1);
          output[offset +  1].bit(7 - (x + px) % 8) = bool(color & 2);
          if(BitsPerPixel == 2) continue;
          output[offset + 16].bit(7 - (x + px) % 8) = bool(color & 4);
          output[offset + 17].bit(7 - (x + px) % 8) = bool(color & 8);
        }
      }
    }

    u32 x = 0;
    if(Manual) characters = 0;

    while(line.beginsWith("{width:") || line.beginsWith("{icon:") || line.beginsWith("{right")) {
      vector<string> list;
      tokenize(list, line, "{*}*");
      string command = list.first();
      line = list.last();

      if(command.match("width:?*")) {
        characters = command.trimLeft("width:", 1L).strip().natural();
        if(characters > 32) error("bad width value");
      } else if(command.match("icon:?*")) {
        auto icon = command.trimLeft("icon:", 1L).natural();
        if(icon > 12) error("bad icon index: ", icon);
        //note: this ignores palette[0] background color; but in practice this works in-game
        if(icon != 0) memory::copy(output.data(), icons.data() + (icon - 1) * TileSize, TileSize);
        x += 9;
      } else if(command.match("right")) {
        if(auto width = TextEncoder::lineWidth(line)) {
          x = characters * 8 - width();
        } else {
          error("failed to determine line width for: ", line);
        }
      }
    }

    if(characters == 0) error("width not specified ");

    u32 index = 0;
    TextEncoder::reset();
    while(true) {
      auto read = TextEncoder::read(line, index);
      if(read.isTerminal()) break;
      if(read.isLineFeed()) break;
      if(read.isCommand()) {
        if(read.command == "skip") {
          x += read.argument.natural();
          continue;
        }
        if(read.command == "tile") {
          u8 tile = read.argument.hex();
          read.setCharacter(tile, 0x00, FontEncoder::width(tile), 0);
        }
        if(read.isCommand()) {
          error("invalid command: {", read.command, "}");
        }
      }
      if(read.isCharacter()) {
        x -= read.kerning;
        u8 byte = read.decoded;
        auto data = FontEncoder::character(read.decoded);
        u32 cy = byte / 16;
        u32 cx = byte % 16;
        for(u32 py : range(8)) {
          for(u32 px : range(read.width)) {
            u32 color = palette[data[py * 8 + px]];
            u32 offset = ((x + px) / 8 * TileSize) + (py * 2);

            Natural<4> previous;
            if constexpr(BitsPerPixel >= 2) {
              previous.bit(0) = output[offset +  0].bit(7 - (x + px) % 8);
              previous.bit(1) = output[offset +  1].bit(7 - (x + px) % 8);
            }
            if constexpr(BitsPerPixel >= 4) {
              previous.bit(2) = output[offset + 16].bit(7 - (x + px) % 8);
              previous.bit(3) = output[offset + 17].bit(7 - (x + px) % 8);
            }
            if(previous != palette[0]) continue;  //favor left-hand pixel on conflicts

            if constexpr(BitsPerPixel >= 2) {
              output[offset +  0].bit(7 - (x + px) % 8) = bool(color & 1);
              output[offset +  1].bit(7 - (x + px) % 8) = bool(color & 2);
            }
            if constexpr(BitsPerPixel == 4) {
              output[offset + 16].bit(7 - (x + px) % 8) = bool(color & 4);
              output[offset + 17].bit(7 - (x + px) % 8) = bool(color & 8);
            }
          }
        }
        x += read.width;
      }
    }

    //allow items to be one pixel too wide; this will cut off the shadow of the last character
    //this is needed for "Diamond Jacket", "Strategy Thesis", and "Toxic Mushroom"
    bool edge = (name == "dragons" || name == "enemies" || name == "items" || name == "techniques");
    if(x > characters * 8 + edge) warning("width exceeded for [", line, "]: ", x, " > ", characters * 8);
    output.resize(characters * TileSize);  //truncate overscan area
    tiles.append((vector<u8>&)output);  //this is a safe cast, Natural<8> is internally u8
    widths.append(x + 7 >> 3);
  }

  //special-case renaming for strings
  if(name.match("bp??")) name = "strings";

  file::write({pathEN, "binaries/lists/", name, "-", suffix, ".bin"}, tiles);
  if constexpr(!SaveWidths) return;
  file::write({pathEN, "binaries/lists/", name, "-widths.bin"}, widths);
}

auto ListEncoder::toLarge(string suffix, array_span<u8> palette, string category, string name) -> void {
  if(palette.size() != 4) error("palette size incorrect");

  vector<string> blocks;

  string filename = {pathEN, "scripts/", category, "/", name, ".txt"};
  blocks = string::read(filename).strip().split("\n\n");
  for(u32 blockIndex : range(blocks.size())) {
    string block = blocks[blockIndex];
    u32 lines = block.split("\n").size();
    vector<Natural<8>> output;
    output.resize(32 * 28 * lines);

    u32 x = 0;
    u32 y = 0;
    u32 index = 0;
    while(true) {
      auto read = TextEncoder::read(block, index);
      if(read.isTerminal()) {
        if(x >= 240) warning("text overflow");
        break;
      }
      if(read.isLineFeed()) {
        if(x >= 240) warning("text overflow");
        x = 0;
        y++;
        continue;
      }
      if(read.isCommand()) {
        if(read.command == "color") {
          if(read.argument == "normal") { palette[1] = 1; continue; }
          if(read.argument == "yellow") { palette[1] = 3; continue; }
        }
        if(read.command == "center") {
          if(auto width = TextEncoder::lineWidth(block, index)) {
            if(*width >= 224) continue;
            x = (224 - *width) / 2;
          }
          continue;
        }
        error("unrecognized command: ", read.command);
      }
      if(read.isCharacter()) {
        x -= read.kerning;
        u8 byte = read.decoded;
        auto data = FontEncoder::character(read.decoded);
        u32 cy = byte / 16;
        u32 cx = byte % 16;
        for(u32 py : range(13)) {
          for(u32 px : range(12)) {
            u32 color = palette[data[py * 12 + px]];
            u32 offset = (y * 32 * 28) + ((x + px) / 8 * 32) + (py * 2);

            Natural<2> previous;
            previous.bit(0) = output[offset + 0].bit(7 - (x + px) % 8);
            previous.bit(1) = output[offset + 1].bit(7 - (x + px) % 8);
            if(previous != palette[0] && color == palette[0]) continue;  //favor right-hand pixel on conflicts

            output[offset + 0].bit(7 - (x + px) % 8) = bool(color & 1);
            output[offset + 1].bit(7 - (x + px) % 8) = bool(color & 2);
          }
        }
        x += read.width;
      }
    }

    string indexID = hex(blockIndex);
    if(blockIndex == 16) indexID = "g";
    if(blockIndex == 17) indexID = "h";
    file::write({pathEN, "binaries/lists/", name, "-", indexID, "-", suffix, ".bin"}, (vector<u8>&)output);
  }
}

template<bool SaveWidths>
auto ListEncoder::toText(string suffix, u32 width, string category, string name) -> void {
  vector<string> lines;
  string path = {pathEN, "scripts/", category, "/"};
  if(name == "descriptions") {
    //the descriptions list has been split into multiple sub-lists for editing purposes.
    //recombine the sub-lists back into one large master list here.
    vector<string> names = {"items", "techniques", "ranges", "chapters", "strings"};
    string list;
    for(auto& name : names) list.append(string::read({path, name, ".txt"}));
    lines = list.trimRight("\n", 1L).split("\n");
    if(lines.size() != 630) error("descriptions list entry count is incorrect");
  } else {
    //all other lists have one file per list
    lines = string::read({path, name, ".txt"}).trimRight("\n", 1L).split("\n");
  }
  vector<u8> widths;
  vector<u8> output;
  output.resize(lines.size() * 2);  //pointer space pre-allocation
  for(u32 offset : range(lines.size())) {
    //store pointer to start of text string in pointer table
    output[offset * 2 + 0] = output.size() >> 0;
    output[offset * 2 + 1] = output.size() >> 8;

    //convert string to binary
    vector<u8> text;
    u32 x = 0;
    u32 index = 0;
    while(true) {
      auto read = TextEncoder::read(lines[offset], index);
      if(read.isTerminal()) break;
      if(read.isLineFeed()) break;
      if(read.isCommand()) {
        if(read.command == "icon") {
          //icons are ignored in text mode
          continue;
        }
        if(read.command == "style") {
          if(read.argument == "normal") text.append(Command::StyleNormal);
          if(read.argument == "italic") text.append(Command::StyleItalic);
          continue;
        }
        if(read.command == "color") {
          if(read.argument == "normal") text.append(Command::ColorNormal);
          if(read.argument == "yellow") text.append(Command::ColorYellow);
          continue;
        }
        if(read.command == "left") {
          text.append(Command::AlignLeft);
          continue;
        }
        if(read.command == "center") {
          text.append(Command::AlignCenter);
          continue;
        }
        if(read.command == "right") {
          text.append(Command::AlignRight);
          continue;
        }
        if(read.command == "skip") {
          text.append(Command::AlignSkip);
          text.append(read.argument.natural());
          continue;
        }
        if(read.command == "pause") {
          text.append(Command::Pause);
          text.append(read.argument.hex());
          continue;
        }
        if(read.command == "wait") {
          text.append(Command::Wait);
          continue;
        }
        if(read.command == "skip") {
          //ignore argument and use a regular space for 12x12 text
          text.append(0xef);
          continue;
        }
        if(auto index = TextEncoder::name(read.command)) {
          text.append(Command::Name);
          text.append(*index);
          if(*index <= 9) {
            //dynamic name; assume the longest possible width
            width += 66;
          } else if(auto nameWidth = TextEncoder::lineWidth(read.command)) {
            //static name; fixed width
            width += *nameWidth;
          }
          continue;
        }
        error("unrecognized command: ", read.command);
      }
      if(read.isCharacter()) {
        x -= read.kerning;
        text.append(read.encoded);
        x += read.width;
        continue;
      }
    }
    if(width && x > width) warning("width exceeded for [", lines[offset], "]: ", x, " > ", width);
    text.append(Command::Terminal);
    output.append(text);
    widths.append(x + 7 >> 3);
  }
  file::write({pathEN, "binaries/lists/", name, "-", suffix, ".bin"}, output);
  if constexpr(SaveWidths) file::write({pathEN, "binaries/lists/", name, "-widths.bin"}, widths);
}
