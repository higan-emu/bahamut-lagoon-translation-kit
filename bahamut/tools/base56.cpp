#include "tools.hpp"

auto products() -> void {
  auto fp = file::open({pathEN, "binaries/base56/base56-products.bin"}, file::mode::write);
  for(u64 index : range(11)) {
    for(u64 value : range(56)) {
      u64 encoded = value >> 3;
      for(u64 multiplier : range(index)) encoded *= 7;
      encoded = encoded << 33 | value % 8 << 3 * index;
      fp.writel(encoded, 8L);
    }
  }
}

auto quotients() -> void {
  auto fp = file::open({pathEN, "binaries/base56/base56-quotients.bin"}, file::mode::write);
  for(u32 dividend : range(7 * 256)) {
    fp.write(dividend / 7);
  }
}

auto remainders() -> void {
  auto fp = file::open({pathEN, "binaries/base56/base56-remainders.bin"}, file::mode::write);
  for(u32 dividend : range(7 * 256)) {
    fp.write(dividend % 7);
  }
}

auto names() -> void {
  auto fp = file::open({pathEN, "binaries/base56/base56-names.bin"}, file::mode::write);
  auto names = string::read({pathEN, "scripts/lists/names.txt"}).split("\n");
  for(u32 index : range(10)) {
    auto name = names[index];
    u64 encoded = 0;
    u64 mul = 0;
    u64 bit = 0;
    for(u32 offset : range(11)) {
      u8 encoding = 55;
      if(offset < name.size()) encoding = name[offset];
      switch(encoding) {
      case ' ': encoding =  0; break;
      case 'A' ... 'Z': encoding = encoding - 'A' +  1; break;
      case 'a' ... 'z': encoding = encoding - 'a' + 27; break;
      case '-': encoding = 53; break;
      case '.': encoding = 54; break;
      default:  encoding = 55; break;
      }
      mul = mul * 7 + encoding / 8;
      bit = bit * 8 | encoding & 7;
    }
    fp.writel(mul << 33 | bit, 8L);
  }
}

auto nall::main() -> void {
  directory::create({pathEN, "binaries/base56/"});
  products();
  quotients();
  remainders();
  names();
}
