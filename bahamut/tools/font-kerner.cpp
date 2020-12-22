#include "tools.hpp"
#include "font-kerner.hpp"
#include "font-encoder.hpp"

auto generateBitmap(string name, u32 width, u32 height) -> void {
  FontEncoder font;
  font.load(name, width, height);
  u32 count = min(180, font.size());

  vector<u32> bitmap;
  u32 bitmapWidth  = count * (1 + width * 2);
  u32 bitmapHeight = count * (1 + height);
  u32 bitmapPitch  = bitmapWidth * sizeof(u32);
  bitmap.resize(bitmapWidth * bitmapHeight);

  vector<u32> palette = {0x000000, 0xffffff, 0xaaaaaa, 0x555555};
  for(u32 lhs : range(font.size())) {
    auto ldata = font.character(lhs);
    u8 lwidth = font.width(lhs);
    for(u32 rhs : range(font.size())) {
      if(lhs >= count || rhs >= count) continue;
      auto rdata = font.character(rhs);
      u8 rwidth = font.width(rhs);
      u8 kerning = font.kerning(rhs, lhs);
      u32 base = (lhs * (1 + height)) * bitmapWidth + (rhs * (1 + width * 2));
      for(u32 py : range(height)) {
        for(u32 px : range(lwidth)) {
          if(auto color = ldata[py * width + px]) {
            bitmap[base + (py * bitmapWidth + px)] = palette[color];
          }
        }
      }
      for(u32 py : range(height)) {
        for(u32 px : range(rwidth)) {
          if(auto color = rdata[py * width + px]) {
            auto pixel = bitmap[base + (py * bitmapWidth + px) + lwidth - kerning];
            if(pixel && pixel != palette[color]) {
            //warning(name, " kerning collisition detected betweeen ", char(*toAscii(lhs)), " and ", char(*toAscii(rhs)));
            //warning(hex(pixel, 6), " -> ", hex(palette[color], 6), "\n");
            }
            bitmap[base + (py * bitmapWidth + px) + lwidth - kerning] = palette[color];
          }
        }
      }
      for(u32 py : range(height + 1)) {
        bitmap[base + py * bitmapWidth + width * 2] = 0xaa0000;
      }
    }
    for(u32 px : range(bitmapWidth)) {
      bitmap[(lhs * (1 + height) + height) * bitmapWidth + px] = 0xaa0000;
    }
  }

  Encode::BMP::create({pathEN, "kerning/", name, ".bmp"}, bitmap.data(), bitmapPitch, bitmapWidth, bitmapHeight, false);
}

auto nall::main() -> void {
  directory::create({pathEN, "kerning/"});
  generateBitmap("font-large", 8, 11);
  generateBitmap("font-small", 8,  8);
}
