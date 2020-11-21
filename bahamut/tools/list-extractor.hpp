#pragma once

#include "text-extractor.hpp"

struct ListExtractor : TextExtractor {
  enum class Type : uint {
    Fixed,
    Linear,
    Pointer,
    Defeats,
    Inline,
  };
  enum class Font : uint {
    Large,
    Small,
  };
  struct List {
    string category;
    string name;
    Type type;
    Font font;
    u32 address;
    u32 count;
    u32 size;
    u32 width;
  };
  vector<List> lists;
  mutable vector<string> names;
  mutable vector<u32> addresses;

  ListExtractor();
  auto find(const string& name) const -> List;

  auto toUnicode(array_view<u8> input) const -> string;
  auto toUnicode(const vector<vector<u8>>& input) const -> vector<string>;

  auto extract(u32& address, u32 limit = 0) const -> vector<u8>;
  auto extract(const List& list) const -> vector<vector<u8>>;

  auto extractFixed  (u32 address, u32 count, u32 size) const -> vector<vector<u8>>;
  auto extractLinear (u32 address, u32 count) const -> vector<vector<u8>>;
  auto extractPointer(u32 address, u32 count) const -> vector<vector<u8>>;
  auto extractDefeats(u32 address, u32 count) const -> vector<vector<u8>>;
  auto extractInline () const -> vector<vector<u8>>;
};

ListExtractor::ListExtractor() {
  //combat strings
  lists.append({"lists", "combat-05", Type::Linear, Font::Large, 0x1e1d7b, 5, 0, 240});

  //strings meant to represent lists of things
  lists.append({"lists", "classes",    Type::Fixed,   Font::Small, 0x2f6360,  15,  8,  64});
  lists.append({"lists", "commands",   Type::Pointer, Font::Small, 0x00e121,  24,  0, 240});
  lists.append({"lists", "defeats",    Type::Defeats, Font::Large, 0x1a8000,  33,  0, 240});
  lists.append({"lists", "dragons",    Type::Fixed,   Font::Small, 0x2f63d8,  60,  8,  72});
  lists.append({"lists", "enemies",    Type::Fixed,   Font::Small, 0x2f1f50, 170,  8,  72});
  lists.append({"lists", "items",      Type::Fixed,   Font::Small, 0x2f3ca0, 128,  9,  72});
  lists.append({"lists", "names",      Type::Fixed,   Font::Small, 0x2f0380,  40,  8,  64});
  lists.append({"lists", "techniques", Type::Fixed,   Font::Small, 0x2f5920, 256,  8,  64});
  lists.append({"lists", "terrains",   Type::Fixed,   Font::Large, 0x070460,  40, 10,  96});

  //strings meant as descriptions; split from one large 630-entry list into sub-categories
  lists.append({"descriptions", "items",      Type::Pointer, Font::Large, 0x2e35f1 + 2 *   0, 128, 0, 216});
  lists.append({"descriptions", "techniques", Type::Pointer, Font::Large, 0x2e35f1 + 2 * 128, 256, 0, 240});
  lists.append({"descriptions", "ranges",     Type::Pointer, Font::Large, 0x2e35f1 + 2 * 384, 192, 0, 192});
  lists.append({"descriptions", "chapters",   Type::Pointer, Font::Large, 0x2e35f1 + 2 * 576,  40, 0, 240});
  lists.append({"descriptions", "strings",    Type::Pointer, Font::Large, 0x2e35f1 + 2 * 616,  14, 0, 240});

  //strings not meant for direct translation, but rather for reference
  lists.append({"strings", "combat", Type::Linear, Font::Small, 0x01db03, 19, 0,  72});
  lists.append({"strings", "field",  Type::Linear, Font::Large, 0x00ecea, 83, 0, 240});
  lists.append({"strings", "menu",   Type::Inline, Font::Small, 0x2e0000,  0, 0,   0});
}

auto ListExtractor::find(const string& name) const -> List {
  for(auto& list : lists) {
    if(list.name == name) return list;
  }
  error("failed to find list: ", name);
  throw;
}

auto ListExtractor::toUnicode(array_view<u8> input) const -> string {
  string output;
  u8 bank = 0;
  while(input) {
    u8 byte = *input++;
    if(byte >= 0x00 && byte <= 0xef) {
      output.append(character(bank, byte));
      continue;
    }
    if(byte >= 0xf0 && byte <= 0xf3) {
      bank = byte & 3;
      continue;
    }
    if(byte == 0xf4 && input) {
      if(!names) {
        ListExtractor extractor;
        names = extractor.toUnicode(extractor.extract(extractor.find("names")));
      }
      if(*input < names.size()) {
        output.append("{", names[*input++], "}");
      }
      continue;
    }
    if(byte == 0xf6) {
      output.append("{technique}");
      continue;
    }
    if(byte == 0xf8) {
      output.append("{dragon}");
      continue;
    }
    if(byte == 0xf9) {
      output.append("{integer2}");
      continue;
    }
    if(byte == 0xfc && input) {
      output.append("{pause:", hex(*input++, 2L), "}");
      continue;
    }
    if(byte == 0xfd) {
      output.append("{wait}");
      continue;
    }
    if(byte == 0xfe) break;
    if(byte == 0xff) break;
    warning("ListExtractor::toUnicode(): unrecognized byte: ", hex(byte, 2L));
  }
  if(addresses) {
    u32 address = 0xc00000 + (addresses.takeFirst() & 0x3fffff);
    output.prepend("{", hex(address, 6L), "}");
  }
  //8x8 maps 0xd2 to ":", 12x12 maps 0xd2 to "."
  //this replaces "." with ":" (todo: handle this better somehow)
  output.replace("\xef\xbc\x8e", "\xef\xbc\x9a");
  return output;
}

auto ListExtractor::toUnicode(const vector<vector<u8>>& input) const -> vector<string> {
  vector<string> output;
  for(auto& encoded : input) output.append(toUnicode(encoded));
  return output;
}

auto ListExtractor::extract(u32& address, u32 limit) const -> vector<u8> {
  vector<u8> output;
  u8 bank = 0;
  u32 target = limit ? address + limit : rom.size();
  while(address < target) {
    u8 byte = rom[address++];
    if(byte >= 0x00 && byte <= 0xf3) {
      output.append(byte);
      continue;
    }
    if(byte == 0xf4 && address + 1 < target) {
      output.append(byte);
      output.append(rom[address++]);
      continue;
    }
    if(byte == 0xf6 && address < target) {
      output.append(byte);
      address++;
      continue;
    }
    if(byte == 0xf8 && address < target) {
      output.append(byte);
      address++;
      continue;
    }
    if(byte == 0xf9 && address + 1 < target) {
      output.append(byte);
      address += 2;
      continue;
    }
    if(byte == 0xfc && address < target) {
      output.append(byte);
      output.append(rom[address++]);
      continue;
    }
    if(byte == 0xfd) {
      output.append(byte);
      continue;
    }
    if(byte == 0xfe) break;
    if(byte == 0xff) break;
    warning("ListExtractor::extract(): unrecognized byte: ", hex(byte, 2L));
  }
  return output;
}

auto ListExtractor::extract(const List& list) const -> vector<vector<u8>> {
  addresses.reset();
  switch(list.type) {
  case Type::Fixed:   return extractFixed  (list.address, list.count, list.size);
  case Type::Linear:  return extractLinear (list.address, list.count);
  case Type::Pointer: return extractPointer(list.address, list.count);
  case Type::Defeats: return extractDefeats(list.address, list.count);
  case Type::Inline:  return extractInline ();
  }
  return {};
}

auto ListExtractor::extractFixed(u32 origin, u32 count, u32 size) const -> vector<vector<u8>> {
  vector<vector<u8>> output;
  for(u32 entry : range(count)) {
    u32 address = origin + entry * size;
    output.append(extract(address, size));
  }
  return output;
}

auto ListExtractor::extractLinear(u32 address, u32 count) const -> vector<vector<u8>> {
  vector<vector<u8>> output;
  for(u32 entry : range(count)) {
    addresses.append(address);
    output.append(extract(address));
  }
  return output;
}

auto ListExtractor::extractPointer(u32 table, u32 count) const -> vector<vector<u8>> {
  vector<vector<u8>> output;
  for(u32 entry : range(count)) {
    u32 address = table & 0xff0000 | read16(rom, table);
    output.append(extract(address));
    table += 2;
  }
  return output;
}

auto ListExtractor::extractDefeats(u32 table, u32 count) const -> vector<vector<u8>> {
  vector<vector<u8>> output;
  for(u32 entry : range(count)) {
    u32 origin = table + (0x80 + entry) * 3;
    u32 offset = read24(rom, origin) - 0xc00000;
    u16 base = read16(rom, offset + 2);
    if(rom[offset + base] == 0xff) {
      addresses.append(offset + base);
      output.append(vector<u8>{});
      continue;
    }
    u16 pointer = read16(rom, offset + base + 2);
    offset += pointer;
    addresses.append(offset);
    output.append(extract(offset));
  }
  return output;
}

//scan for inlined strings inside bank $ee (used by the 8x8 menu system)
//format: jsr $4a1e; dw shiftjis, $ffff; code:
//the $ee4a1e function adjusts the stack pointer to return to 'code:'
auto ListExtractor::extractInline() const -> vector<vector<u8>> {
  vector<vector<u8>> output;
  for(u32 address = 0x2e0000; address <= 0x2effff;) {
    u32 compare = read24(rom, address);
    //scan for "jsr $4a1e" instructions (calls to print inline strings)
    if(compare != 0x4a1e20) {
      address++;
      continue;
    }
    addresses.append(address);
    address += 3;
    vector<u8> string;
    while(address <= 0x2effff) {
      u16 word = read16(rom, address);

      //end of string marker
      if(u8(word) == 0xff) break;

      //space short-circuit (not in lookup-table)
      if(word == 0x4081) {
        string.append(0xef);
        address += 2;
        continue;
      }

      //scan for 16-bit entry in shift-JIS lookup table
      u32 table = 0x2e4ae8;
      while(table <= 0x2effff) {
        u16 compare = read16(rom, table);
        if(compare == word  ) break;  //match found
        if(compare == 0xffff) break;  //match not found
        table += 2;
      }
      if(read16(rom, table) == 0xffff) {
        warning("shift-JIS entry not found: ", hex(word, 4L));
        break;
      }

      //the encoded output byte is the 16-bit index into the table
      u8 byte = (table - 0x2e4ae8) / 2;
      if(byte <= 0xef) {
        string.append(byte);
        address += 2;
        continue;
      }

      warning("control byte detected: ", hex(byte, 2L));
      break;
    }
    output.append(string);
  }
  return output;
}
