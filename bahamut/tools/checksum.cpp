//this corrects the generated ROM checksum.
//it should be run *after* invoking bass to build a ROM.
//(bass can technically do this itself, but not very efficiently.)

#include "tools.hpp"

auto nall::main() -> void {
  auto rom = file::read({pathEN, "rom/bahamut-en.sfc"});
  if(rom.size() != 0x800000) error("failed to read bahamut-en.sfc");

  u16 checksum = 0;
  for(auto& byte : rom) checksum += byte;
  u16 inverted = checksum ^ 0xffff;

  write16(rom, 0x00ffdc, inverted);
  write16(rom, 0x00ffde, checksum);

  write16(rom, 0x40ffdc, inverted);
  write16(rom, 0x40ffde, checksum);

  file::write({pathEN, "rom/bahamut-en.sfc"}, rom);

  u16 verify = 0;
  for(auto& byte : rom) verify += byte;
  if(checksum != verify) error("checksum failure");
}
