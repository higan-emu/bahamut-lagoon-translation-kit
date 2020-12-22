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
  for(u32 address : range(0x400000)) {
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

auto nall::main() -> void {
  scan(0xc0ed7b);  //"プレイヤーフェイズです。"
  scan(0xc0ed88);  //"エネミーフェイズです。"
//scan(0xc0edab);  //"えがら"
//scan(0xc0edae);  //"ポーズ"
  scan(0xc0ee89);  //"ゲームオーバーです。"
  scan(0xc0ee94);  //"シナリオクリアーです。"
  scan(0xc0eeac);  //"ひみかつらせしか"
  scan(0xc0eeb5);  //"　ずぜちいいょい"
//scan(0xc0eed6);  //"うごけません。"
  scan(0xc0eede);  //"になった。"
  scan(0xc0ef23);  //"技ＮＯ？？パワー？？地ＩＤ？？"
  scan(0xc0ef77);  //"行動不能状態です。"
//scan(0xc0efbc);  //"に進化しました。"

  scan(0xc1db03);  //"ＧＥＴ　ＥＸＰ"
  scan(0xc1db0b);  //"ＧＥＴ　ＩＴＥＭ"
  scan(0xc1db14);  //"ＧＥＴ　ＧＯＬＤ"
//scan(0xc1db3c);  //"スカ"
//scan(0xc1db3f);  //"ぶんしん"
  scan(0xc1db44);  //"「レベルがたらんぞ」"
  scan(0xc1db86);  //"うにうに"

  scan(0xee6f89);  //"ＭＰ：" + "ＳＰ："
  scan(0xee7087);  //"ＭＰ：" + "ＳＰ："

//sram();
}
