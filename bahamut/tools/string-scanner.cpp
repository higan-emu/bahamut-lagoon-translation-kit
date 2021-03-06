#include "tools.hpp"

auto scan(u32 target) -> void {
  auto candidate = [&](u32 address, u32 stride, u32 size) {
    if(size == 2) {
      return;
      print(terminal::color::gray ("16-bit candidate [", stride, "] ", hex(0xc00000 + address, 6L), " => ", hex(target, 6L)));
    }
    if(size == 3) {
      print(terminal::color::green("24-bit candidate [", stride, "] ", hex(0xc00000 + address, 6L), " => ", hex(target, 6L)));
    }
    print(" { ");
    u32 counter = 0;
    for(u8 index : range(13)) {
      if(index % stride == 0) {
        print(terminal::color::white(hex(rom[address + index], 2L), " "));
        if(++counter == size) break;
      } else {
        print(terminal::color::gray (hex(rom[address + index], 2L), " "));
      }
    }
    print("}\n");
  };

  for(u32 stride : range(8)) {
    for(u32 address : range(rom.size() - 16)) {
      if(rom[address + stride * 0] != u8(target >>  0)) continue;
      if(rom[address + stride * 1] != u8(target >>  8)) continue;
      candidate(address, stride, 2);
      if(rom[address + stride * 2] != u8(target >> 16)) continue;
      candidate(address, stride, 3);
    }
  }

  for(u32 address : range(rom.size() - 16)) {
    if(rom[address] != 0xa9 && rom[address] != 0xa2 && rom[address] != 0xa0) continue;
    if(rom[address + 1] != u8(target >> 0)) continue;
    if(rom[address + 2] != u8(target >> 8)) continue;
    string type = "???";
    if(rom[address] == 0xa9) type = "lda";
    if(rom[address] == 0xa2) type = "ldx";
    if(rom[address] == 0xa0) type = "ldy";
    print(terminal::color::green("16-bit load    [", type, "] ", hex(0xc00000 + address, 6L), " => ", hex(target, 6L), "\n"));
  }
}

auto sram() -> void {
  auto rom = file::read({pathJP, "rom/bahamut-jp.sfc"});
  u32 count = 0;
  for(u32 address : range(rom.size() - 4)) {
    u8 byte = rom[address + 0];
    u8 page = rom[address + 2];
    u8 bank = rom[address + 3];
    if(bank != 0x30) continue;
    if(page < 0x60 || page > 0x7f) continue;
    if(byte == 0x0f || byte == 0x1f  //ora
    || byte == 0x2f || byte == 0x3f  //and
    || byte == 0x4f || byte == 0x5f  //eor
    || byte == 0x6f || byte == 0x7f  //adc
    || byte == 0x8f || byte == 0x9f  //sta
    || byte == 0xaf || byte == 0xbf  //lda
    || byte == 0xcf || byte == 0xdf  //cmp
    || byte == 0xef || byte == 0xff  //sbc
    || byte == 0x5c || byte == 0x22  //jml, jsl
    ) {
      print(hex(0xc00000 + address, 6L), "\n");
      count++;
    }
  }
  print(count, "\n");
}

auto hdma() -> void {
  auto rom = file::read({pathJP, "rom/bahamut-jp.sfc"});
  u32 count = 0;
  for(u32 address : range(rom.size() - 4)) {
    u8 d0 = rom[address + 0];
    u8 d1 = rom[address + 1];
    u8 d2 = rom[address + 2];
    u8 d3 = rom[address + 3];
    if(d0 != 0x8f) continue;  //sta.l
    if(d1 >= 0x0c) continue;  //$00-$0b
    if(d2 != 0x56) continue;  //$56
    if(d3 != 0x7e) continue;  //$7e
    print(hex(0xc00000 + address, 6L), "\n");
    count++;
  }
  print(count, "\n");
}

auto nall::main() -> void {
  scan(0xc0ed7b);  //"????????????????????????????????????"
  scan(0xc0ed88);  //"?????????????????????????????????"
//scan(0xc0edab);  //"?????????"
//scan(0xc0edae);  //"?????????"
  scan(0xc0ee89);  //"??????????????????????????????"
  scan(0xc0ee94);  //"?????????????????????????????????"
  scan(0xc0eeac);  //"????????????????????????"
  scan(0xc0eeb5);  //"????????????????????????"
//scan(0xc0eed6);  //"?????????????????????"
  scan(0xc0eede);  //"???????????????"
  scan(0xc0ef23);  //"?????????????????????????????????????????????"
  scan(0xc0ef77);  //"???????????????????????????"
//scan(0xc0efbc);  //"????????????????????????"

  scan(0xc1db03);  //"?????????????????????"
  scan(0xc1db0b);  //"????????????????????????"
  scan(0xc1db14);  //"????????????????????????"
//scan(0xc1db3c);  //"??????"
//scan(0xc1db3f);  //"????????????"
  scan(0xc1db44);  //"??????????????????????????????"
  scan(0xc1db86);  //"????????????"

  scan(0xee6f89);  //"?????????" + "?????????"
  scan(0xee7087);  //"?????????" + "?????????"

//sram();
//hdma();
}
