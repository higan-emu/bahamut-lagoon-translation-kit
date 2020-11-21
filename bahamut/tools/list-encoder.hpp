#pragma once

#include "text-encoder.hpp"

struct ListEncoder : TextEncoder {
  template<u32 BitsPerPixel, bool SaveWidths> auto toTiles(string_view suffix, array_view<u8> palette, u32 characters, string_view category, string_view name) -> void;
  template<bool SaveWidths> auto toText(string_view suffix, u32 width, string_view category, string_view name) -> void;
};

template<u32 BitsPerPixel, bool SaveWidths>
auto ListEncoder::toTiles(string_view suffix, array_view<u8> palette, u32 characters, string_view category, string_view name) -> void {
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
  if(name == "costs") {
    for(u32 index : range(100)) lines.append({"{right}", pad(index, 2, '_')});
    lines.append("{right}^^");
    lines.append("{right}~~");
  }
  if(name == "counts") {
    for(u32 index : range(100)) lines.append({"{space:5}*{space:1}", pad(index, 2, '_')});
    lines.append("{space:5}*{space:1}^^");
    lines.append("{space:5}*{space:1}~~");
  }
  if(name == "items") {
    //additions not in the original Japanese text (list-editor would lose them otherwise)
    //todo: handle this better somehow
    lines.append("{icon:0}No Weapon");
    lines.append("{icon:0}No Armor");
  }
  if(name == "levels") {
    for(u32 index : range(100)) lines.append({"{space:2}Lv.{space:1}", pad(index, 2, '_')});
    lines.append("{space:2}Lv.{space:1}^^");
    lines.append("{space:2}Lv.{space:1}~~");
  }
  if(name == "stats") {
    for(u32 index : range(256)) lines.append({"{right}", pad(index, 3, '_')});
    lines.append("{right}^^^");
    lines.append("{right}~~~");
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

    if(line.beginsWith("{width:") || line.beginsWith("{icon:") || line.beginsWith("{right")) {
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
    while(true) {
      auto read = TextEncoder::read(line, index);
      if(read.isTerminal()) break;
      if(read.isLineFeed()) break;
      if(read.isCommand()) {
        if(read.command == "space") {
          TextEncoder::resetKerning();
          x += read.argument.natural();
          continue;
        }
        error("invalid command: {", read.command, "}");
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

            if(previous != palette[0] && color == palette[0]) continue;

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
    bool edge = (name == "items");
    if(x > characters * 8 + edge) warning("width exceeded for [", line, "]: ", x, " > ", characters * 8);
    output.resize(characters * TileSize);  //truncate overscan area
    tiles.append((vector<u8>&)output);  //this is a safe cast, Natural<8> is internally u8
    widths.append(x + 7 >> 3);
  }

  //special-case renaming
  if(name == "bpp2") name = "strings";
  if(name == "bpp4") name = "strings";
  if(name == "bpo4") name = "strings";
  if(name == "bpa4") name = "strings";

  file::write({pathEN, "binaries/lists/", name, "-", suffix, ".bin"}, tiles);
  if constexpr(!SaveWidths) return;
  file::write({pathEN, "binaries/lists/", name, "-widths.bin"}, widths);
}

template<bool SaveWidths>
auto ListEncoder::toText(string_view suffix, u32 width, string_view category, string_view name) -> void {
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
        if(read.command == "font") {
          if(read.argument == "normal") text.append(Command::FontNormal);
          if(read.argument == "yellow") text.append(Command::FontYellow);
          continue;
        }
        if(read.command == "right") {
          text.append(Command::AlignRight);
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
        if(read.command == "space") {
          text.append(0xef);
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
    if(name == "defeats") {
      text.append(Command::LineFeed);
    } else {
      text.append(Command::Terminal);
    }
    output.append(text);
    widths.append(x + 7 >> 3);
  }
  file::write({pathEN, "binaries/lists/", name, "-", suffix, ".bin"}, output);
  if constexpr(SaveWidths) file::write({pathEN, "binaries/lists/", name, "-widths.bin"}, widths);
}
