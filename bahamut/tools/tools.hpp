#pragma once

#include <nall/nall.hpp>
#include <nall/primitives.hpp>
#include <nall/terminal.hpp>
#include <nall/encode/bmp.hpp>
#include <nall/decode/bmp.hpp>
using namespace nall;

namespace Command {
  static constexpr u8 StyleNormal = 0xf0;
  static constexpr u8 StyleItalic = 0xf1;  //8x11 font
  static constexpr u8 StyleTiny   = 0xf1;  // 8x8 font
  static constexpr u8 ColorNormal = 0xf2;
  static constexpr u8 ColorYellow = 0xf3;
  static constexpr u8 Name        = 0xf4;
  static constexpr u8 Redirect    = 0xf5;
  static constexpr u8 AlignLeft   = 0xf6;
  static constexpr u8 AlignCenter = 0xf7;
  static constexpr u8 AlignRight  = 0xf8;
  static constexpr u8 AlignSkip   = 0xf9;
  static constexpr u8 Reserved0   = 0xfa;
  static constexpr u8 Reserved1   = 0xfb;
  static constexpr u8 Pause       = 0xfc;
  static constexpr u8 Wait        = 0xfd;
  static constexpr u8 LineFeed    = 0xfe;
  static constexpr u8 Terminal    = 0xff;
}

//defined individually by each tool
namespace nall { auto main() -> void; }

template<typename... P> auto debug(P&&... p) -> void {
#if defined(BUILD_DEBUG)
  print(terminal::color::gray("debug: "), forward<P>(p)..., "\n");
  #if defined(PLATFORM_WINDOWS)
  string location = {Path::program(), "debug.txt"};
  auto fp = file::open(location, file::mode::modify);
  if(!fp) fp = file::open(location, file::mode::write);
  fp.seek(fp.size());
  fp.print("[", chrono::local::datetime(), "] ", forward<P>(p)..., "\n");
  #endif
#endif
}

template<typename... P> auto warning(P&&... p) -> void {
  print(terminal::color::yellow("warning: "), forward<P>(p)..., "\n");
  #if defined(PLATFORM_WINDOWS)
  string location = {Path::program(), "warnings.txt"};
  auto fp = file::open(location, file::mode::modify);
  if(!fp) fp = file::open(location, file::mode::write);
  fp.seek(fp.size());
  fp.print("[", chrono::local::datetime(), "] ", forward<P>(p)..., "\n");
  #endif
}

template<typename... P> auto error(P&&... p) -> void {
  print(terminal::color::red("error: "), forward<P>(p)..., "\n");
  #if defined(PLATFORM_WINDOWS)
  string location = {Path::program(), "errors.txt"};
  auto fp = file::open(location, file::mode::modify);
  if(!fp) fp = file::open(location, file::mode::write);
  fp.seek(fp.size());
  fp.print("[", chrono::local::datetime(), "] ", forward<P>(p)..., "\n");
  #endif
  exit(-1);
}

const string pathEN = {Location::dir(Location::dir(Path::program())), "en/"};
const string pathJP = {Location::dir(Location::dir(Path::program())), "jp/"};

template<typename T> auto read8(const T& data, u32 address) -> u8 {
  if(address >= data.size()) return 0;
  return data[address];
}

template<typename T> auto read16(const T& data, u32 address) -> u16 {
  u16 value = 0;
  value |= read8(data, address + 0) << 0;
  value |= read8(data, address + 1) << 8;
  return value;
}

template<typename T> auto read24(const T& data, u32 address) -> u32 {
  u32 value = 0;
  value |= read8(data, address + 0) <<  0;
  value |= read8(data, address + 1) <<  8;
  value |= read8(data, address + 2) << 16;
  return value;
}

template<typename T> auto write8(T& data, u32 address, u8 value) -> void {
  if(address >= data.size()) return;
  data[address] = value;
}

template<typename T> auto write16(T& data, u32 address, u16 value) -> void {
  write8(data, address + 0, value >> 0);
  write8(data, address + 1, value >> 8);
}

template<typename T> auto write24(T& data, u32 address, u32 value) -> void {
  write8(data, address + 0, value >>  0);
  write8(data, address + 1, value >>  8);
  write8(data, address + 2, value >> 16);
}

vector<u8> rom;

//load the Japanese ROM
auto romLoad() -> bool {
  rom = file::read({pathJP, "rom/bahamut-jp.sfc"});
  if(!rom) error("rom/bahamut-jp.sfc not found");
  if(rom.size() != 0x300000) error("rom/bahamut-jp.sfc size incorrect");
  string hash = "a98eb5f0521746e6ce6d208591e86d366b6e0479d96474bfff43856fe8cfec12";
  if(Hash::SHA256(rom).digest() != hash) error("rom/bahamut-jp.sfc hash incorrect");
  return (bool)rom;
}

#include <nall/main.hpp>
auto nall::main(Arguments) -> void {
  romLoad();
  main();
}
