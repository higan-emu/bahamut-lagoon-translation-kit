#include "tools.hpp"
#include "font-extractor.hpp"

auto extractLargeFont() -> void {
  FontExtractor font;
  font.extractLarge();

  vector<u32> palette = {0x000000, 0xffffff};
  Encode::BMP::create({pathJP, "fonts/font-large.bmp"},
    font.encodeBitmap(palette).data(), font.bitmapPitch(), font.bitmapWidth(), font.bitmapHeight(), false
  );
}

auto extractMenuFont() -> void {
  FontExtractor font;
  font.extractMenu();

  vector<u32> palette = {0x000000, 0xffffff, 0xaaaaaa, 0x555555};
  Encode::BMP::create({pathJP, "fonts/font-menu.bmp"},
    font.encodeBitmap(palette).data(), font.bitmapPitch(), font.bitmapWidth(), font.bitmapHeight(), false
  );
}

auto extractFieldFont() -> void {
  FontExtractor font;
  font.extractField();

  vector<u32> palette = {0x000000, 0xffffff, 0xaaaaaa, 0x555555};
  Encode::BMP::create({pathJP, "fonts/font-field.bmp"},
    font.encodeBitmap(palette).data(), font.bitmapPitch(), font.bitmapWidth(), font.bitmapHeight(), false
  );
}

auto extractCombatFont() -> void {
  FontExtractor font;
  font.extractCombat();

  //colors 0-6 valid; colors 7-15 unknown
  vector<u32> palette = {
    0x000000, 0xffffff, 0xaaaaaa, 0x555555,
    0x000055, 0xffff00, 0xaaaa00, 0x777777,
    0x888888, 0x999999, 0xaaaaaa, 0xbbbbbb,
    0xcccccc, 0xdddddd, 0xeeeeee, 0xffffff,
  };
  Encode::BMP::create({pathJP, "fonts/font-combat.bmp"},
    font.encodeBitmap(palette).data(), font.bitmapPitch(), font.bitmapWidth(), font.bitmapHeight(), false
  );
}

auto extractStatsFont() -> void {
  FontExtractor font;
  font.extractStats();

  vector<u32> palette = {
    0x000000, 0x111111, 0x222222, 0x333333,
    0x444444, 0x555555, 0x666666, 0x777777,
    0x888888, 0x999999, 0xaaaaaa, 0xbbbbbb,
    0xcccccc, 0xdddddd, 0xeeeeee, 0xffffff,
  };
  Encode::BMP::create({pathJP, "fonts/font-stats.bmp"},
    font.encodeBitmap(palette).data(), font.bitmapPitch(), font.bitmapWidth(), font.bitmapHeight(), false
  );
}

auto nall::main() -> void {
  directory::create({pathJP, "fonts/"});
  extractLargeFont();
  extractMenuFont();
  extractFieldFont();
  extractCombatFont();
  extractStatsFont();
}
