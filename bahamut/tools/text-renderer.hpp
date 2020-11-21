#pragma once

#include "font-extractor.hpp"
#include "script-encoder.hpp"

struct TextRendererAbstract {
  struct Offset { s32 x, y; };
  struct Size { s32 width, height; };
  struct Rectangle { s32 x, y, width, height; };
  u32 backgroundColor = 0x000000;
  u32 textColor = 0xffffff;
  u32 nameColor = 0xffff00;

  const vector<u32> normalPalette = {0x000000, 0xffffff, 0x555555, 0x000000};
  const vector<u32> yellowPalette = {0x000000, 0xffff00, 0x555500, 0x000000};
  vector<u32> textPalette = {0x000000, 0xffffff, 0x555555, 0x000000};

  auto drawDialogueBoxTransparent(array_span<u32> canvas, Size size, u32 lines, u32 index = 0) -> void;
  auto drawDialogueBoxOpaque(array_span<u32> canvas, Size size, u32 lines, u32 index = 0) -> void;
  auto drawDialogueBox(array_span<u32> canvas, Size size, bool opaque, u32 lines, u32 index = 0) -> void;
  auto drawRectangle(array_span<u32> canvas, Size size, Rectangle rectancle, u32 color) -> void;
};

struct TextRendererJapanese : TextRendererAbstract, FontExtractor {
  auto drawCharacter(array_span<u32> canvas, Size size, Offset base, array_view<u32> palette, u8 bank, u8 character) -> void;
  auto drawScript(array_span<u32> canvas, Size size, const Script& script, u16 block) -> void;
  auto drawLineLarge(array_span<u32> canvas, Size size, array_view<u8> text, u32 width) -> void;
  auto drawLineSmall(array_span<u32> canvas, Size size, array_view<u8> text, u32 width) -> void;
};

struct TextRendererEnglish : TextRendererAbstract, ScriptEncoder {
  TextRendererEnglish();
  auto drawCharacter(array_span<u32> canvas, Size size, Offset base, array_view<u32> palette, u8 character) -> void;
  auto drawScript(array_span<u32> canvas, Size size, Script& script, u16 block, const string& text) -> void;
  auto drawLine(array_span<u32> canvas, Size size, const string& text, u32 width) -> bool;
};

//draws a 1-pixel box around each dialogue window for script blocks that do not show window decorations
auto TextRendererAbstract::drawDialogueBoxTransparent(array_span<u32> canvas, Size size, u32 lines, u32 index) -> void {
  const u32 outline = 0xc0c0c0;

  auto write = [&](u32 x, u32 y, u32 color) -> void {
    y = index * ((1 + lines) * 16) + y;
    if(x >= size.width ) return;
    if(y >= size.height) return;
    canvas[y * size.width + x] = 255 << 24 | color;
  };

  { u32 py = 3;
    for(u32 px = 3; px <= 252; px++) write(px, py, outline);
  }

  { u32 px = 3;
    for(u32 py = 3; py <= 16 * lines + 12; py++) write(px, py, outline);
  }

  { u32 px = 252;
    for(u32 py = 3; py <= 16 * lines + 12; py++) write(px, py, outline);
  }

  { u32 py = 16 * lines + 12;
    for(u32 px = 3; px <= 252; px++) write(px, py, outline);
  }
}

//draws a simulation of the text window as it appears in Bahamut Lagoon for script blocks that use window decorations
auto TextRendererAbstract::drawDialogueBoxOpaque(array_span<u32> canvas, Size size, u32 lines, u32 index) -> void {
  const u32 blue  = 0x010378;
  const u32 dark  = 0x888898;
  const u32 light = 0xe8f0ff;

  auto write = [&](u32 x, u32 y, u32 color) -> void {
    y = index * ((1 + lines) * 16) + y;
    if(x >= size.width ) return;
    if(y >= size.height) return;
    canvas[y * size.width + x] = 255 << 24 | color;
  };

  { u32 py = 0;
    for(s32 px = 0; px <= 255; px++) write(px, py, blue);
  }
  { u32 py = 1;
    write(  0, py, blue); write(  1, py, blue);
    for(u32 px = 2; px <= 253; px++) write(px, py, dark);
    write(254, py, blue); write(255, py, blue);
  }
  { u32 py = 2;
    write(  0, py, blue); write(  1, py, dark);
    for(u32 px = 2; px <= 253; px++) write(px, py, light);
    write(254, py, dark); write(255, py, blue);
  }
  { u32 py = 3;
    write(  0, py, blue);  write(  1, py, light);
    for(u32 px = 2; px <= 253; px++) write(px, py, dark);
    write(254, py, light); write(255, py, blue);
  }
  { u32 py = 4;
    write(  0, py, blue); write(  1, py, light); write(  2, py, dark);
    for(u32 px = 3; px <= 252; px++) write(px, py, blue);
    write(253, py, dark); write(254, py, light); write(255, py, blue);
  }
  for(u32 py = 5; py <= 16 * lines + 10; py++) {
    u32 shade = uclamp<8>(f64(py - 5) / f64(lines * 16) * 0xc0);  //black-to-blue gradient fade
    write(  0, py, blue); write(  1, py, light); write(  2, py, dark);  write(  3, py, blue);
    for(u32 px = 4; px <= 251; px++) write(px, py, shade);
    write(252, py, blue); write(253, py, dark);  write(254, py, light); write(255, py, blue);
  }
  { u32 py = 16 * lines + 11;
    write(  0, py, blue); write(  1, py, light); write(  2, py, dark);
    for(u32 px = 3; px <= 252; px++) write(px, py, blue);
    write(253, py, dark); write(254, py, light); write(255, py, blue);
  }
  { u32 py = 16 * lines + 12;
    write(  0, py, blue);  write(  1, py, light);
    for(u32 px = 2; px <= 253; px++) write(px, py, dark);
    write(254, py, light); write(255, py, blue);
  }
  { u32 py = 16 * lines + 13;
    write(  0, py, blue); write(  1, py, dark);
    for(u32 px = 2; px <= 253; px++) write(px, py, light);
    write(254, py, dark); write(255, py, blue);
  }
  { u32 py = 16 * lines + 14;
    write(  0, py, blue); write(  1, py, blue);
    for(u32 px = 2; px <= 253; px++) write(px, py, dark);
    write(254, py, blue); write(255, py, blue);
  }
  { u32 py = 16 * lines + 15;
    for(s32 px = 0; px <= 255; px++) write(px, py, blue);
  }
}

//wrapper to disambiguate opacity parameter
auto TextRendererAbstract::drawDialogueBox(array_span<u32> canvas, Size size, bool opaque, u32 lines, u32 index) -> void {
  if(opaque == 0) drawDialogueBoxTransparent(canvas, size, lines, index);
  if(opaque == 1) drawDialogueBoxOpaque(canvas, size, lines, index);
}

//draws a rectangle of a specified color onto the canvas.
//can also be used to draw a line by specifying a width or height of 1.
auto TextRendererAbstract::drawRectangle(array_span<u32> canvas, Size size, Rectangle rectangle, u32 color) -> void {
  for(u32 py : range(rectangle.height)) {
    for(u32 px : range(rectangle.width)) {
      if(rectangle.x + px >= size.width ) continue;
      if(rectangle.y + py >= size.height) continue;
      canvas[(rectangle.y + py) * size.width + (rectangle.x + px)] = 255 << 24 | color;
    }
  }
}

//

auto TextRendererJapanese::drawCharacter(array_span<u32> canvas, Size size, Offset base, array_view<u32> palette, u8 bank, u8 character) -> void {
  auto input = FontExtractor::character(bank * 256 + character);

  //draw shadow (for 1bpp large font only)
  if(context.depth == 1)
  for(u32 py : range(context.characterHeight)) {
    for(u32 px : range(context.characterWidth)) {
      if(base.x + px + 1 >= size.width ) continue;
      if(base.y + py + 1 >= size.height) continue;
      u32 pixel = input[py * context.characterWidth + px];
      if(pixel) canvas[(base.y + py + 1) * size.width + (base.x + px + 1)] = 255 << 24 | palette[3];
    }
  }

  //draw character
  for(u32 py : range(context.characterHeight)) {
    for(u32 px : range(context.characterWidth)) {
      if(base.x + px >= size.width ) continue;
      if(base.y + py >= size.height) continue;
      u32 pixel = input[py * context.characterWidth + px];
      if(pixel) canvas[(base.y + py) * size.width + (base.x + px)] = 255 << 24 | palette[pixel];
    }
  }
}

auto TextRendererJapanese::drawScript(array_span<u32> canvas, Size size, const Script& script, u16 block) -> void {
  auto& pointer = script.pointers[block];
  drawDialogueBox(canvas, size, pointer.opaque(true), pointer.height(3));

  Offset base = {8, 8};
  u32 x = 0;
  u32 y = 0;
  u32 line = 0;
  u8 bank = 0;
  u32 offset = pointer.target;
  while(offset < script.data.size()) {
    u8 byte = script.data[offset++];
    if(byte <= 0xef) {
      drawCharacter(canvas, size, {base.x + x, base.y + y + 2}, textPalette, bank, byte);
      x += 12;
      continue;
    }
    if(byte >= 0xf0 && byte <= 0xf3) {
      bank = byte & 3;
      continue;
    }
    if(byte == 0xf4) {
      bank = 0;
      u8 name = script.data[offset++];
      for(u32 index : range(8)) {
        byte = rom[0x2f0380 + name * 8 + index];
        if(byte == 0xff) break;
        drawCharacter(canvas, size, {base.x + x, base.y + y + 2}, textPalette, bank, byte);
        drawRectangle(canvas, size, {base.x + x, base.y + y + 15, 12, 1}, nameColor);
        x += 12;
      }
      continue;
    }
    if(byte == 0xfc) {
      byte = script.data[offset++];
      //pause
      continue;
    }
    if(byte == 0xfd) {
      if(script.mode == Script::Mode::Chapter) break;
      //wait
      continue;
    }
    if(byte == 0xfe) {
      //line feed
      x  = 0;
      y += 16;
      if((++line) % pointer.height(3) == 0) {
        drawDialogueBox(canvas, size, pointer.opaque(true), pointer.height(3), line / pointer.height(3));
        y += 16;
      }
      continue;
    }
    if(byte == 0xff) break;
  }
}

auto TextRendererJapanese::drawLineLarge(array_span<u32> canvas, Size size, array_view<u8> text, u32 width) -> void {
  drawRectangle(canvas, size, {0, 0, size.width, size.height}, 0x0000c0);
  const Offset base = {5, (size.height - 12) / 2};

  u32 address = 0;
  u32 x = 0;
  u32 y = 0;
  u32 bank = 0;
  while(address < text.size()) {
    u8 byte = text[address++];
    if(byte <= 0xef) {
      drawCharacter(canvas, size, {base.x + x, base.y + y}, textPalette, bank, byte);
      x += 12;
      continue;
    }
    if(byte >= 0xf0 && byte <= 0xf3) {
      bank = byte & 3;
      continue;
    }
    if(byte >= 0xf4) break;
  }

  drawRectangle(canvas, size, {0, 0, size.width, 5}, backgroundColor);
  drawRectangle(canvas, size, {0, 0, 5, size.height}, backgroundColor);
  drawRectangle(canvas, size, {5 + width, 0, size.width - 5 - width, size.height}, backgroundColor);
  drawRectangle(canvas, size, {0, size.height - 5, size.width, 5}, backgroundColor);
}

auto TextRendererJapanese::drawLineSmall(array_span<u32> canvas, Size size, array_view<u8> text, u32 width) -> void {
  drawRectangle(canvas, size, {0, 0, size.width, size.height}, 0x0000c0);
  const Offset base = {5, (size.height - 12) / 2 + 4};

  u32 address = 0;
  u32 x = 0;
  u32 y = 0;
  const u32 bank = 0;
  while(address < text.size()) {
    u8 byte = text[address++];
    if(byte >= 0x00 && byte <= 0x28) {
      //dakuten
      drawCharacter(canvas, size, {base.x + x, base.y + y - 9}, textPalette, bank, 0x31);
      drawCharacter(canvas, size, {base.x + x, base.y + y - 0}, textPalette, bank, 0x33 + byte);
      x += 8;
      continue;
    }
    if(byte >= 0x29 && byte <= 0x32) {
      //handakuten
      drawCharacter(canvas, size, {base.x + x, base.y + y - 9}, textPalette, bank, 0x32);
      drawCharacter(canvas, size, {base.x + x, base.y + y - 0}, textPalette, bank, 0x29 + byte);
      x += 8;
      continue;
    }
    if(byte >= 0x33 && byte <= 0xef) {
      //kana
      drawCharacter(canvas, size, {base.x + x, base.y + y}, textPalette, bank, byte);
      x += 8;
      continue;
    }
    if(byte >= 0xf0) break;
  }

  drawRectangle(canvas, size, {0, 0, size.width, 5}, backgroundColor);
  drawRectangle(canvas, size, {0, 0, 5, size.height}, backgroundColor);
  drawRectangle(canvas, size, {5 + width, 0, size.width - 5 - width, size.height}, backgroundColor);
  drawRectangle(canvas, size, {0, size.height - 5, size.width, 5}, backgroundColor);
}

//

TextRendererEnglish::TextRendererEnglish() {
  ScriptEncoder::load();
}

auto TextRendererEnglish::drawCharacter(array_span<u32> canvas, Size size, Offset base, array_view<u32> palette, u8 character) -> void {
  auto input = FontEncoder::character(character);
  for(u32 py : range(context.height)) {
    for(u32 px : range(context.width)) {
      if(base.x + px >= size.width ) continue;
      if(base.y + py >= size.height) continue;
      if(u8 color = input[py * context.width + px]) {
        canvas[(base.y + py) * size.width + (base.x + px)] = 255 << 24 | palette[color];
      }
    }
  }
}

auto TextRendererEnglish::drawScript(array_span<u32> canvas, Size size, Script& script, u16 block, const string& text) -> void {
  auto& pointer = script.pointers[block];
  drawDialogueBox(canvas, size, pointer.opaque(true), pointer.height(3));

  textPalette = normalPalette;
  Offset base = {8, 10};
  u32 index = 0;
  u32 x = 0;
  u32 y = 0;
  u32 line = 0;
  while(true) {
    auto read = TextEncoder::read(text, index);
    if(read.isTerminal()) break;
    if(read.isLineFeed()) {
      x  = 0;
      y += 16;
      if(++line % pointer.height(3) == 0) {
        drawDialogueBox(canvas, size, pointer.opaque(true), pointer.height(3), line / pointer.height(3));
        y += 16;
      }
      continue;
    }
    if(read.isCommand()) {
      if(read.command == "font" && read.argument == "normal") {
        textPalette = normalPalette;
        continue;
      }
      if(read.command == "font" && read.argument == "yellow") {
        textPalette = yellowPalette;
        continue;
      }
      if(read.command == "center") {
        auto width = ScriptEncoder::lineWidth(text, index);
        if(width && *width <= 240) x += (240 - *width) / 2;
        continue;
      }
      if(read.command == "right") {
        auto width = ScriptEncoder::lineWidth(text, index);
        if(width && *width <= 240) x += (240 - *width);
        continue;
      }
      if(read.command == "option") {
        x += 12;
        continue;
      }
      if(auto name = ScriptEncoder::names.find(read.command)) {
        TextEncoder::resetKerning();
        u32 index = 0;
        string text = read.command;
        maybe<u32> target;
        if(*name <= 9) {
          //draw a hinting rectangle to show the maximum size of a dynamic name
          drawRectangle(canvas, size, {base.x + x, base.y + y + 13, 66, 1}, nameColor);
          target = x + 66;
        } else if(auto nameWidth = ScriptEncoder::lineWidth(text)) {
          //draw a hinting rectangle to show that a name tag has been used here
          drawRectangle(canvas, size, {base.x + x, base.y + y + 13, *nameWidth, 1}, nameColor);
        }
        while(true) {
          read = TextEncoder::read(text, index);
          if(read.isCharacter()) {
            x -= read.kerning;
            drawCharacter(canvas, size, {base.x + x, base.y + y}, textPalette, read.decoded);
            x += read.width;
            continue;
          }
          break;
        }
        if(target) x = *target;
        TextEncoder::resetKerning();
        continue;
      }
      continue;
    }
    if(read.isCharacter()) {
      x -= read.kerning;
      drawCharacter(canvas, size, {base.x + x, base.y + y}, textPalette, read.decoded);
      x += read.width;
      continue;
    }
    break;
  }
}

auto TextRendererEnglish::drawLine(array_span<u32> canvas, Size size, const string& text, u32 width) -> bool {
  drawRectangle(canvas, size, {0, 0, size.width, size.height}, 0x0000c0);
  const Offset base = {5, (size.height - 8) / 2};

  textPalette = normalPalette;
  u32 index = 0;
  u32 x = 0;
  u32 y = 0;
  while(true) {
    auto read = TextEncoder::read(text, index);
    if(read.isTerminal()) break;
    if(read.isLineFeed()) break;
    if(read.isCommand()) {
      if(read.command == "icon") {
        u8 icon = read.argument.natural();
        drawCharacter(canvas, size, {base.x + x, base.y + y}, textPalette, 0x70 + icon);
        x += 9;
        continue;
      }
      if(read.command == "font" && read.argument == "normal") {
        textPalette = normalPalette;
        continue;
      }
      if(read.command == "font" && read.argument == "yellow") {
        textPalette = yellowPalette;
        continue;
      }
      if(read.command == "right") {
        auto textWidth = ScriptEncoder::lineWidth(text, index);
        if(textWidth && *textWidth <= width) x = width - *textWidth;
      }
      if(read.command == "space") {
        TextEncoder::resetKerning();
        x += read.argument.natural();
        continue;
      }
      continue;
    }
    if(read.isCharacter()) {
      x -= read.kerning;
      drawCharacter(canvas, size, {base.x + x, base.y + y}, textPalette, read.decoded);
      x += read.width;
      continue;
    }
    break;
  }

  drawRectangle(canvas, size, {0, 0, size.width, 5}, backgroundColor);
  drawRectangle(canvas, size, {0, 0, 5, size.height}, backgroundColor);
  drawRectangle(canvas, size, {5 + width, 0, size.width - 5 - width, size.height}, backgroundColor);
  drawRectangle(canvas, size, {0, size.height - 5, size.width, 5}, backgroundColor);

  return x <= width;
}
