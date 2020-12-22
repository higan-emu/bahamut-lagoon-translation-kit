//this is a tool to test that the compressor works correctly.
//it decompresses all scripts, then compresses them, then compares to the original data.

#include "tools.hpp"
#include "decompressor.hpp"
#include "compressor.hpp"

auto nall::main() -> void {
  if(auto input = decompressLZ77({rom.data() + 0x2e0020, rom.size() - 0x2e0020})) {
    auto output = compressLZ77(rom[0x2e0020], input);
    print(input.size(), "\n");
    print(output.size(), "\n");
    auto result = decompressLZ77(output);
    print(input == result, "\n");
    if(input != result) {
      for(u32 index : range(result.size())) {
        if((index & 15) == 0) print(hex(index, 4L), "  ");
        print(hex(result[index], 2L), " ");
        if((index & 15) == 15) print("\n");
      }
      print("\n");
    }
    print("\n");
    if(memory::compare(rom.data() + 0x2e0020, 2745, output.data(), output.size())) {
      array_view<u8> x{rom.data() + 0x2e0020, 2745};
      array_view<u8> y{output.data(), 2745};
      for(u32 index : range(2745)) {
        if((index & 15) == 0) print(hex(index, 4L), "  ");
        print(hex(y[index], 2L));
        if(x[index] != y[index]) print("*"); else print(" ");
        if((index & 15) == 15) print("\n");
      }
      print("\n");
    }
    print("\n");
  }

  for(u32 block : range(256)) {
    u32 offset = read24(rom, 0x1a8000 + block * 3) - 0xc00000;

    if(auto input = decompressLZSS({rom.data() + offset, rom.size() - offset})) {
      if(input.size() < 0x20) continue;
      auto output = compressLZSS(input);
      auto result = decompressLZSS(output);

      print(hex(offset), "\n");
      print(input.size(), "\n");
      print(output.size(), "\n");
      print(result.size(), "\n");
      print(input == result, "\n");
      if(input != result) {
        for(u32 index : range(output.size())) {
          if((index & 15) == 0) print(hex(index, 4L), "  ");
          print(hex(output[index], 2L), " ");
          if((index & 15) == 15) print("\n");
        }
        return print("\n");
      }
      print("\n");
    }
  }

  for(u32 block : range(33)) {
    u32 offset = read24(rom, 0x07140f + block * 3) - 0xc00000;

    if(auto input = decompressLZSS({rom.data() + offset, rom.size() - offset})) {
      if(input.size() < 0x20) continue;
      auto output = compressLZSS(input);
      auto result = decompressLZSS(output);

      print(hex(offset), "\n");
      print(input.size(), "\n");
      print(output.size(), "\n");
      print(result.size(), "\n");
      print(input == result, "\n");
      if(input != result) {
        for(u32 index : range(output.size())) {
          if((index & 15) == 0) print(hex(index, 4L), "  ");
          print(hex(output[index], 2L), " ");
          if((index & 15) == 15) print("\n");
        }
        return print("\n");
      }
      print("\n");
    }
  }
}
