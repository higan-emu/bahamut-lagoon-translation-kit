//this tool decompresses all compressed data and stores it to disk.

#include "tools.hpp"
#include "decompressor.hpp"

auto decompressLZ77(const string& filename, u32 offset) -> void {
  array_view<u8> input{rom.data() + offset, rom.size() - offset};
  if(auto data = decompressLZ77(input)) {
    file::write(filename, data);
    print(hex(data.size(), 6L), "  ", filename, "\n");
  }
}

auto decompressLZSS(const string& filename, u32 offset) -> void {
  array_view<u8> input{rom.data() + offset, rom.size() - offset};
  if(auto data = decompressLZSS(input)) {
    if(data.size() < 32) return;  //too small to contain useful data
    file::write(filename, data);
    print(hex(data.size(), 6L), "  ", filename, "\n");
  }
}

auto extractTitleScreen() -> void {
  vector<u32> palette = {
    0x000000, 0x777777, 0xbbbbbb, 0xffffff,
    0x111111, 0x222222, 0x333333, 0x444444,
    0x555555, 0x666666, 0x888888, 0x999999,
    0xaaaaaa, 0xcccccc, 0xdddddd, 0xeeeeee,
  };

  u32 offset = 0x289a4f;
  auto input = decompressLZSS({rom.data() + offset, rom.size() - offset});

  vector<u32> output;
  u32 width  = 128;
  u32 height =  32;
  output.resize(width * height);

  for(u32 tile : range((width / 8) * (height / 8))) {
    u32 tx = (tile & 15) * 8;
    u32 ty = (tile >> 4) * 8;
    for(u32 py : range(8)) {
      u32 address = tile * 32;
      u8 data0 = input[address + py * 2 +  0];
      u8 data1 = input[address + py * 2 +  1];
      u8 data2 = input[address + py * 2 + 16];
      u8 data3 = input[address + py * 2 + 17];
      for(u32 px : range(8)) {
        u8 color = 0;
        color += (data0 & 0x80 >> px) ? 1 : 0;
        color += (data1 & 0x80 >> px) ? 2 : 0;
        color += (data2 & 0x80 >> px) ? 4 : 0;
        color += (data3 & 0x80 >> px) ? 8 : 0;
        output[(ty + py) * width + (tx + px)] = palette[color];
      }
    }
  }

  Encode::BMP::create({pathJP, "images/title-screen.bmp"}, output.data(), width * sizeof(u32), width, height, false);
}

auto extractConclusionScreen() -> void {
  vector<u32> palette = {
    0x0000, 0x7fff, 0x3cc7, 0x38a6,
    0x3085, 0x2c64, 0x2423, 0x1800,
    0x722d, 0x69ec, 0x61cb, 0x598a,
    0x556a, 0x4d29, 0x4508, 0x6f73,
  };
  for(auto& color : palette) {
    u8 r = color >>  0 & 31;
    u8 g = color >>  5 & 31;
    u8 b = color >> 10 & 31;
    r = r << 3 | r >> 2;
    g = g << 3 | g >> 2;
    b = b << 3 | b >> 2;
    color = r << 16 | g << 8 | b << 0;
  }

  u32 offset = 0x06e000;
  auto input = decompressLZ77({rom.data() + offset, rom.size() - offset});

  vector<u32> output;
  u32 width  = 128;
  u32 height =  64;
  output.resize(width * height);

  for(u32 tile : range((width / 8) * (height / 8))) {
    u32 tx = (tile & 31) * 8;
    u32 ty = (tile >> 5) * 8;
    if(tx & 128) { ty |= 32; tx &= 127; }
    for(u32 py : range(8)) {
      u32 address = tile * 32;
      u8 data0 = input[address + py * 2 +  0];
      u8 data1 = input[address + py * 2 +  1];
      u8 data2 = input[address + py * 2 + 16];
      u8 data3 = input[address + py * 2 + 17];
      for(u32 px : range(8)) {
        u8 color = 0;
        color += (data0 & 0x80 >> px) ? 1 : 0;
        color += (data1 & 0x80 >> px) ? 2 : 0;
        color += (data2 & 0x80 >> px) ? 4 : 0;
        color += (data3 & 0x80 >> px) ? 8 : 0;
        output[(ty + py) * width + (tx + px)] = palette[color];
      }
    }
  }

  Encode::BMP::create({pathJP, "images/conclusion.bmp"}, output.data(), width * sizeof(u32), width, height, false);
}

auto extractEndingScreen() -> void {
  u32 offset = 0x28dd33;
  auto input = decompressLZSS({rom.data() + offset, rom.size() - offset});

  vector<u32> palette = {
    0x000000, 0xffffff, 0xaaaaaa, 0x555555,
  };

  vector<u32> output;
  u32 width  = 128;
  u32 height =  16;
  output.resize(width * height);

  for(u32 tile : range((width / 8) * (height / 8))) {
    u32 tx = (tile & 15) * 8;
    u32 ty = (tile >> 4) * 8;
    for(u32 py : range(8)) {
      u32 address = tile * 32;
      u8 data0 = input[address + py * 2 + 0];
      u8 data1 = input[address + py * 2 + 1];
      for(u32 px : range(8)) {
        u8 color = 0;
        color += (data0 & 0x80 >> px) ? 1 : 0;
        color += (data1 & 0x80 >> px) ? 2 : 0;
        output[(ty + py) * width + (tx + px)] = palette[color];
      }
    }
  }

  Encode::BMP::create({pathJP, "images/ending-screen.bmp"}, output.data(), width * sizeof(u32), width, height, false);
}

auto nall::main() -> void {
  directory::create({pathJP, "binaries/"});
  directory::create({pathJP, "binaries/chapters/"});
  directory::create({pathJP, "binaries/fields/"});
  directory::create({pathJP, "binaries/menu/"});
  directory::create({pathJP, "binaries/other/"});
  directory::create({pathJP, "images/"});

  for(u32 block : range(256)) {
    u32 offset = read24(rom, 0x1a8000 + block * 3) - 0xc00000;
    decompressLZSS({pathJP, "binaries/chapters/chapter-", hex(block, 2L), ".bin"}, offset);
  }

  for(u32 block : range(33)) {
    u32 offset = read24(rom, 0x07140f + block * 3) - 0xc00000;
    decompressLZSS({pathJP, "binaries/fields/field-", hex(block, 2L), ".bin"}, offset);
  }

  decompressLZ77({pathJP, "binaries/menu/font.bin"}, 0x2e0020);
  decompressLZSS({pathJP, "binaries/other/title-screen.bin"}, 0x289a4f);
  decompressLZSS({pathJP, "binaries/other/ending-screen.bin"}, 0x28dd33);
  decompressLZ77({pathJP, "binaries/other/failed.bin"}, 0x2ab798);
  decompressLZ77({pathJP, "binaries/other/conclusion.bin"}, 0x06e000);
  decompressLZ77({pathJP, "binaries/other/conclusion.map"}, 0x06eab2);

  extractTitleScreen();
  extractConclusionScreen();
  extractEndingScreen();
}
