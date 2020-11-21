#include "tools.hpp"
#include "compressor.hpp"
#include "decompressor.hpp"
#include "font-encoder.hpp"

FontEncoder largeFont;
FontEncoder smallFont;
FontEncoder fixedFont;

auto rebuildMenuFont() -> void {
  vector<u8> output = decompressLZ77({rom.data() + 0x2e0020, rom.size() - 0x2e0020});

  vector<u8> palette = {0,1,2,3};
  auto replace = [&](u8 source, u8 target) -> void {
    u8 sx = source % 16, sy = source / 16;
    u8 tx = target % 16, ty = target / 16;
    memory::fill(output.data() + (ty * 16 + tx) * 16, 16);
    auto character = fixedFont.character(sy * 16 + sx);
    for(u8 py : range(8)) {
      for(u8 px : range(8)) {
        u8 pixel = character[py * 8 + px];
        u8 color = palette[pixel];
        u32 offset = (ty * 16 + tx) * 16 + (py * 2);
        output[offset + 0] |= bool(color & 1) << 7 - px;
        output[offset + 1] |= bool(color & 2) << 7 - px;
      }
    }
  };

  //'A' - 'Z' (for the name entry screen)
  for(uint index : range(26)) {
    replace(0x01 + index, 0xb9 + index);
  }

  //'a' - 'z' (for the name entry screen)
  for(u8 index : range(26)) {
    replace(0x1b + index, 0x87 + index);
  }

  //'0' - '9' (for single-digit numbers; eg x# counters)
  for(u8 index : range(10)) {
    replace(0x36 + index, 0x01 + index);
  }

  replace(0x35, 0xae);  //'-'
  replace(0x40, 0x86);  //'.'
  replace(0x4e, 0xf1);  //'Up' arrow
  replace(0x4f, 0xf2);  //'Down' arrow
  replace(0x48, 0xe7);  //'*'
  replace(0x52, 0xe6);  //'Lv.'
  replace(0x53, 0xe2);  //'HP'
  replace(0x54, 0xe3);
  replace(0x55, 0xe4);  //'MP'
  replace(0x56, 0xe5);
  replace(0x57, 0xeb);  //'SP'
  replace(0x58, 0xec);
  replace(0x5f, 0x29);  //'|'

  //window border tiles
  replace(0x90, 0xf8);
  replace(0x91, 0xf9);
  replace(0x92, 0xfa);
  replace(0x93, 0xfb);
  replace(0x94, 0xfc);
  replace(0x95, 0xfd);
  replace(0x96, 0xfe);
  replace(0x97, 0xeb);
  replace(0x98, 0xec);

  file::write({pathEN, "binaries/fonts/font-menu-data.bin"}, compressLZ77(0x00, output));
}

auto rebuildFieldFont() -> void {
  vector<u8> output;
  output.resize(16 * 13 * 16);
  memory::copy(output.data(), rom.data() + 0x08a000, output.size());

  vector<u8> palette = {0,1,2,3};
  auto replace = [&](u8 source, u8 target) -> void {
    target -= 0x30;  //0x00-0x2f are (han)dakuten encodings and not in the font tiledata
    u8 sx = source % 16, sy = source / 16;
    u8 tx = target % 16, ty = target / 16;
    memory::fill(output.data() + (ty * 16 + tx) * 16, 16);
    auto character = fixedFont.character(sy * 16 + sx);
    for(u8 py : range(8)) {
      for(u8 px : range(8)) {
        u8 pixel = character[py * 8 + px];
        u8 color = palette[pixel];
        u32 offset = (ty * 16 + tx) * 16 + (py * 2);
        output[offset + 0] |= bool(color & 1) << 7 - px;
        output[offset + 1] |= bool(color & 2) << 7 - px;
      }
    }
  };

  //static tiles
  replace(0x52, 0xf6);  //'LV'
  replace(0x53, 0xf7);  //'HP'
  replace(0x54, 0xf8);
  replace(0x55, 0xf9);  //'MP'
  replace(0x56, 0xfa);
  replace(0x57, 0xfb);  //'SP'
  replace(0x58, 0xfc);

  file::write({pathEN, "binaries/fonts/font-field-data.bin"}, output);
}

auto rebuildCombatFont() -> void {
  vector<u8> output;
  output.resize(16 * 28 * 32);
  memory::copy(output.data(), rom.data() + 0x261b40, output.size());

  vector<u8> palette;
  auto replace = [&](u8 source, u16 target) -> void {
    u8 sx = source % 16, sy = source / 16;
    u8 tx = target % 16, ty = target / 16;
    memory::fill(output.data() + (ty * 16 + tx) * 32, 32);
    auto character = fixedFont.character(sy * 16 + sx);
    for(u8 py : range(8)) {
      for(u8 px : range(8)) {
        u8 pixel = character[py * 8 + px];
        u8 color = palette[pixel];
        u32 offset = (ty * 16 + tx) * 32 + (py * 2);
        output[offset +  0] |= bool(color & 1) << 7 - px;
        output[offset +  1] |= bool(color & 2) << 7 - px;
        output[offset + 16] |= bool(color & 4) << 7 - px;
        output[offset + 17] |= bool(color & 8) << 7 - px;
      }
    }
  };

  palette = {4,1,2,3};
  replace(0x50, 0x010);  //'All'
  replace(0x51, 0x011);
  replace(0x59, 0x00d);  //'HP'
  replace(0x5a, 0x00e);
  replace(0x5b, 0x00b);  //'MP'
  replace(0x5c, 0x00c);
  replace(0x5d, 0x01c);  //'SP'
  replace(0x5e, 0x01d);
  replace(0x52, 0x0cf);  //'Lv.'
  replace(0x60, 0x16c);  //'EXP'
  replace(0x61, 0x16d);
  replace(0x5f, 0x004);  //'|'

  replace(0x70, 0x16a);  //'STR' (strength)
  replace(0x71, 0x16b);
  replace(0x72, 0x16e);  //'VIT' (vitality)
  replace(0x73, 0x16f);
  replace(0x74, 0x170);  //'DEX' (dexterity)
  replace(0x75, 0x171);
  replace(0x76, 0x172);  //'INT' (intelligence)
  replace(0x77, 0x173);
  replace(0x78, 0x174);  //'WIS' (wisdom)
  replace(0x79, 0x175);
  replace(0x80, 0x176);  //'CHA' (character)
  replace(0x81, 0x177);
  replace(0x82, 0x178);  //'AFF' (affection)
  replace(0x83, 0x179);
  replace(0x84, 0x17a);  //'TIM' (timidity)
  replace(0x85, 0x17b);
  replace(0x86, 0x17c);  //'COR' (corruption)
  replace(0x87, 0x17d);
  replace(0x88, 0x17e);  //'MUT' (mutation)
  replace(0x89, 0x17f);

  palette = {4,5,6,3};
  replace(0x52, 0x0cc);  //'Lv. up!'
  replace(0x53, 0x0cd);
  replace(0x54, 0x0ce);

  //copy "Potion" icon which is used on the dragon feeding screen.
  //this is so that the 12-tile item icon range can be used for tiledata.
  memory::copy(output.data() + 0x169 * 32, output.data() + 0x027 * 32, 32);

  file::write({pathEN, "binaries/fonts/font-combat-data.bin"}, output);
}

auto rebuildTitleFont() -> void {
  u32 offset = 0x289a4f;
  auto tiles = decompressLZSS({rom.data() + offset, rom.size() - offset});
  //tiles  0-11 are for the "(C) Square" logo and cannot be used
  //tiles 16-27, though blank, are similarly reserved as the menu sprites are 16x16 in size
  memory::fill(tiles.data() + 12 * 32, tiles.size() - 12 * 32);  //clear all other tiles

  Decode::BMP bitmap(string{pathEN, "fonts/font-title.bmp"});
  if(bitmap.width() != 48 || bitmap.height() != 64) error("failed to load font-title.bmp");
  auto data = bitmap.data();

  auto copy = [&](u8 source, u8 target) {
    u8 sx = source % 16;
    u8 sy = source / 16;
    u8 offset = 0;
    for(u32 py : range(8)) {
      for(u32 px : range(8)) {
        u32 pixel = data[(sy * 8 + py) * 48 + (sx * 8 + px)];
        u32 color = 0;
        switch(pixel & 0xffffff) {
        case 0x555555: color = 1; break;
        case 0xaaaaaa: color = 2; break;
        case 0xffffff: color = 3; break;
        }
        tiles[target * 32 + offset +  0] |= bool(color & 1) << 7 - px;
        tiles[target * 32 + offset +  1] |= bool(color & 2) << 7 - px;
        tiles[target * 32 + offset + 16] |= bool(color & 4) << 7 - px;
        tiles[target * 32 + offset + 17] |= bool(color & 8) << 7 - px;
      }
      offset += 2;
    }
  };

  //"New Game"
  copy(0x00, 0x20); copy(0x10, 0x30);
  copy(0x01, 0x21); copy(0x11, 0x31);
  copy(0x02, 0x22); copy(0x12, 0x32);
  copy(0x03, 0x23); copy(0x13, 0x33);
  copy(0x04, 0x24); copy(0x14, 0x34);
  copy(0x05, 0x25); copy(0x15, 0x35);

  //"Continue"
  copy(0x20, 0x26); copy(0x30, 0x36);
  copy(0x21, 0x27); copy(0x31, 0x37);
  copy(0x22, 0x28); copy(0x32, 0x38);
  copy(0x23, 0x29); copy(0x33, 0x39);
  copy(0x24, 0x2a); copy(0x34, 0x3a);
  copy(0x25, 0x2b); copy(0x35, 0x3b);

  //"Resume"
  copy(0x40, 0x0c); copy(0x50, 0x1c);
  copy(0x41, 0x0d); copy(0x51, 0x1d);
  copy(0x42, 0x0e); copy(0x52, 0x1e);
  copy(0x43, 0x0f); copy(0x53, 0x1f);

  //"Ex-Play"
  copy(0x60, 0x2c); copy(0x70, 0x3c);
  copy(0x61, 0x2d); copy(0x71, 0x3d);
  copy(0x62, 0x2e); copy(0x72, 0x3e);
  copy(0x63, 0x2f); copy(0x73, 0x3f);

  file::write({pathEN, "binaries/fonts/font-title-data.bin"}, compressLZSS(tiles));
}

auto rebuildFailedFont() -> void {
  u32 offset = 0x2ab798;
  auto tiles = decompressLZ77({rom.data() + offset, rom.size() - offset});

  memory::fill(tiles.data() + 0x8e * 32, 64);
  memory::fill(tiles.data() + 0x9e * 32, 64);
  memory::fill(tiles.data() + 0xae * 32, 64);
  memory::fill(tiles.data() + 0xbe * 32, 64);
  memory::fill(tiles.data() + 0xce * 32, 64);
  memory::fill(tiles.data() + 0xde * 32, 64);

  Decode::BMP bitmap(string{pathEN, "fonts/font-failed.bmp"});
  if(bitmap.width() != 32 || bitmap.height() != 24) error("failed to load font-failed.bmp");
  auto data = bitmap.data();

  auto copy = [&](u8 source, u8 target) {
    u8 sx = source % 16;
    u8 sy = source / 16;
    u8 offset = 0;
    for(u32 py : range(8)) {
      for(u8 px : range(8)) {
        u32 pixel = data[(sy * 8 + py) * 32 + (sx * 8 + px)];
        u32 color = 0;
        switch(pixel & 0xffffff) {
        case 0x555555: color = 1; break;
        case 0xaaaaaa: color = 2; break;
        case 0xffffff: color = 3; break;
        }
        tiles[target * 32 + offset +  0] |= bool(color & 1) << 7 - px;
        tiles[target * 32 + offset +  1] |= bool(color & 2) << 7 - px;
        tiles[target * 32 + offset + 16] |= bool(color & 4) << 7 - px;
        tiles[target * 32 + offset + 17] |= bool(color & 8) << 7 - px;
      }
      offset += 2;
    }
  };

  copy(0x00, 0x8e);
  copy(0x01, 0x8f);
  copy(0x10, 0x9e);
  copy(0x11, 0x9f);
  copy(0x20, 0xae);
  copy(0x21, 0xaf);
  copy(0x02, 0xbe);
  copy(0x03, 0xbf);
  copy(0x12, 0xce);
  copy(0x13, 0xcf);
  copy(0x22, 0xde);
  copy(0x23, 0xdf);

  file::write({pathEN, "binaries/fonts/font-failed-data.bin"}, compressLZ77(0x06, tiles));
}

auto rebuildConclusionFont() -> void {
  u32 offset = 0x06e000;
  auto tiles = decompressLZ77({rom.data() + offset, rom.size() - offset});

  memory::fill(tiles.data() + 0x60 * 32, 10 * 32);
  memory::fill(tiles.data() + 0x70 * 32, 10 * 32);

  Decode::BMP bitmap(string{pathEN, "fonts/font-conclusion.bmp"});
  if(bitmap.width() != 80 || bitmap.height() != 16) error("failed to load font-conclusion.bmp");
  auto data = bitmap.data();

  auto copy = [&](u8 source, u8 target) {
    u8 sx = source % 16;
    u8 sy = source / 16;
    u8 offset = 0;
    for(u32 py : range(8)) {
      for(u8 px : range(8)) {
        u32 pixel = data[(sy * 8 + py) * 80 + (sx * 8 + px)];
        u32 color = 0;
        switch(pixel & 0xffffff) {
        case 0x555555: color = 7; break;
        case 0xaaaaaa: color = 4; break;
        case 0xffffff: color = 1; break;
        }
        if(color == 0) color = 8 + (py / 2);
        tiles[target * 32 + offset +  0] |= bool(color & 1) << 7 - px;
        tiles[target * 32 + offset +  1] |= bool(color & 2) << 7 - px;
        tiles[target * 32 + offset + 16] |= bool(color & 4) << 7 - px;
        tiles[target * 32 + offset + 17] |= bool(color & 8) << 7 - px;
      }
      offset += 2;
    }
  };

  for(u32 index : range(10)) copy(index + 0x00, index + 0x60);
  for(u32 index : range(10)) copy(index + 0x10, index + 0x70);

  file::write({pathEN, "binaries/fonts/font-conclusion-data.bin"}, compressLZ77(0x00, tiles));
}

auto rebuildConclusionMap() -> void {
  u32 offset = 0x06eab2;
  auto tilemap = decompressLZ77({rom.data() + offset, rom.size() - offset});

  auto write = [&](u32 offset, u8 index) -> void {
    tilemap[offset + 0x000] = index + 0x00;
    tilemap[offset + 0x040] = index + 0x10;
    tilemap[offset + 0x080] = index + 0x20;
    tilemap[offset + 0x0c0] = index + 0x30;
    tilemap[offset + 0x100] = index + 0x40;
    tilemap[offset + 0x140] = index + 0x50;
  };

  //"Player Win" => "Player Won"
  write(0x1018, 0x0d);
  write(0x1238, 0x0d);
  write(0x1418, 0x0d);
  write(0x1638, 0x0d);

  file::write({pathEN, "binaries/fonts/font-conclusion-map.bin"}, compressLZ77(0x03, tilemap));
}

auto nall::main() -> void {
  directory::create({pathEN, "binaries/fonts/"});

  largeFont.load("font-large",8,12);
  smallFont.load("font-small",8, 8);
  fixedFont.load("font-fixed",8, 8);

  file::write({pathEN, "binaries/fonts/font-large-normal.bin"}, largeFont.encodeCharacters({0,1,0,2}));
  file::write({pathEN, "binaries/fonts/font-large-yellow.bin"}, largeFont.encodeCharacters({0,3,0,2}));
  file::write({pathEN, "binaries/fonts/font-large-sprite.bin"}, largeFont.encodeCharacters({0,1,0,3}));
  file::write({pathEN, "binaries/fonts/font-small-data.bin"  }, smallFont.encodeCharacters({0,1,2,3}));

  file::write({pathEN, "binaries/fonts/font-large-widths.bin"}, largeFont.encodeWidths());
  file::write({pathEN, "binaries/fonts/font-small-widths.bin"}, smallFont.encodeWidths());

  file::write({pathEN, "binaries/fonts/font-large-kernings.bin"}, largeFont.encodeKernings());
  file::write({pathEN, "binaries/fonts/font-small-kernings.bin"}, smallFont.encodeKernings());

  rebuildMenuFont();
  rebuildFieldFont();
  rebuildCombatFont();
  rebuildTitleFont();
  rebuildFailedFont();
  rebuildConclusionFont();
  rebuildConclusionMap();
}
