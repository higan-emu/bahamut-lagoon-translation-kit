#pragma once

#include "decompressor.hpp"
#include "text-extractor.hpp"
#include "list-extractor.hpp"

const u32 tableChapter = 0x1a8000;
const u32 tableField   = 0x07140f;

struct Pointer {
  maybe< u16> source;    //location of pointer to text
         u16  target;    //location of text
          u8  terminal;  //end of string marker for this pointer: 0xfd or 0xff
  maybe<  u8> ycoord;    //Y coordinate of dialogue box (in tiles; eg / 8)
  maybe<  u8> height;    //number of text lines for this dialogue block
  maybe<bool> opaque;    //0 = transparent (no window decoration); 1 = opaque (draw window decoration)
};

struct Candidate {
   u16 source;      //location of pointer to text
  bool suspicious;  //set for fuzzier pointer matches for additional analysis
};

struct Script : TextExtractor {
  enum class Mode : u32 { Chapter, Field } mode;
  u8 index;         //the index into the chapter or field tables
  vector<u8> data;  //the decompressed data; data.size() is the *decompressed* size of the block
  u32 address;      //the location of the compressed data in the ROM
  u16 size;         //the *compressed* size of the data block in the ROM
  u16 base;         //base is a decompressed data offset used only by field scripts (always 0 for chapters)
  u16 origin;       //blocks are always encoded as {commands, text}; origin is the start of the text
  vector<Pointer> pointers;  //a list of information on every text string in this script
  vector<string> names;      //used to decode the 0xf4 name command to Japanese Unicode text

  Script();
  auto label(maybe<u16> block = nothing) const -> string;
  auto loadChapter(u8 index) -> bool;
  auto loadField(u8 index) -> bool;
  auto findPointer(u16 offset) -> maybe<Candidate>;
  auto findTerminal(u16 offset) -> maybe<u16>;
  auto findTarget(u16 offset) -> maybe<u16>;
  auto analyze() -> bool;
  auto findOrphaned() -> void;
  auto insertOverlapped() -> void;
  auto append(u16 source, u16 target, u8 terminal) -> void;
  auto extractString(u16 offset) -> string;
  auto extract() -> string;
};

Script::Script() {
  ListExtractor extractor;
  names = extractor.toUnicode(extractor.extract(extractor.find("names")));
}

//generate a label for the current script for debugging purposes
auto Script::label(maybe<u16> block) const -> string {
  string output = {mode == Mode::Chapter ? "Chapter " : "Field ", hex(index, 2L)};
  if(block) output.append(" Block ", 1 + *block);
  return output;
}

auto Script::loadChapter(u8 index) -> bool {
  mode = Mode::Chapter;
  this->index = index;

  address = read24(rom, tableChapter + index * 3) - 0xc00000;
  data = decompressLZSS({rom.data() + address, rom.size() - address}, &size);
  if(!data) return false;
  base = 0;

  vector<u16> candidates;
  u16 offset = 0;
  while(offset + 3 < data.size()) {
     u8 prefix = data[offset++];
    u16 pointer = read16(data, offset);
    if(pointer >= data.size()) continue;  //ignore pointers that are out of range
    if(pointer < offset + 2) continue;    //text always appears after pointers

    //0x37 pointers terminate strings with either 0xff or 0xfd
    if(prefix == 0x37) {
      if(!candidates.find(pointer)) candidates.append(pointer);
    }

    //0x08 and 0x09 pointers terminate strings with only 0xfd
    if(prefix == 0x08 || prefix == 0x09) {
      if(!candidates.find(pointer)) {
        for(u32 address = pointer; address < data.size(); address++) {
          if(data[address] == 0xfd) { candidates.append(pointer); break; }
          if(data[address] == 0xff) break;
        }
      }
    }
  }
  candidates.sort();
  if(!candidates) return false;

  vector<u16> results;
  u32 item = 0;
  while(item + 1 < candidates.size()) {
    u32 offset = candidates[item];
    u32 length = 0;
    while(offset < data.size()) {
      u8 byte = data[offset++];
      if(byte == 0xfd || byte == 0xff) break;
      length++;
    }
    u32 distance = candidates[item + 1] - (candidates[item] + length);
    if(length > 1 && distance < 16) results.append(candidates[item]);
    item++;
  }
  if(!results) return false;

  origin = results.first();
  return true;
}

auto Script::loadField(u8 index) -> bool {
  mode = Mode::Field;
  this->index = index;

  address = read24(rom, tableField + index * 3) - 0xc00000;
  data = decompressLZSS({rom.data() + address, rom.size() - address}, &size);
  if(data.size() < 2) return false;
  base = read16(data, 0);

  vector<u16> candidates;
  u16 offset = 0x300;
  while(offset + 3 < data.size()) {
     u8 prefix = data[offset++];
    u16 pointer = read16(data, offset) + base;
    if(pointer >= data.size()) continue;  //ignore pointers that are out of range
    if(pointer < offset + 2) continue;    //text always appears after pointers

    //0x26 pointers terminate strings with only 0xff
    if(prefix == 0x26) {
      if(!candidates.find(pointer)) candidates.append(pointer);
    }
  }
  candidates.sort();
  if(!candidates) return false;

  origin = candidates.first();
  return true;
}

auto Script::findPointer(u16 target) -> maybe<Candidate> {
  u16 offset = (mode == Mode::Chapter ? 0x000 : 0x300);
  while(offset < origin) {
    u16 pointer = read16(data, offset) + base;
    if(pointer != target) { offset++; continue; }

    if(mode == Mode::Chapter) {
      if(data[offset - 1] == 0x37) return Candidate{offset, 0};
      if(data[offset - 2] == 0x38 && data[offset - 1] == 0x08) return Candidate{offset, 0};
      if(data[offset - 2] == 0x38 && data[offset - 1] == 0x09) return Candidate{offset, 0};
      //0x08 and 0x09 pointers without a matching 0x38 prefix are marked as suspicious.
      //in other words, they might not be valid pointers, so further analysis is necessary later on.
      if(data[offset - 1] == 0x08) return Candidate{offset, 1};
      if(data[offset - 1] == 0x09) return Candidate{offset, 1};
    }
    if(mode == Mode::Field) {
      if(data[offset - 1] == 0x26) return Candidate{offset, 0};
    }
    offset++;
  }
  return nothing;
}

//scan forward to find the end of a string
auto Script::findTerminal(u16 offset) -> maybe<u16> {
  while(offset < data.size()) {
    if(mode == Mode::Chapter) {
      if(data[offset] == 0xff) return offset;
      if(data[offset] == 0xfd) return offset;
    }
    if(mode == Mode::Field) {
      if(data[offset] == 0xff) return offset;
    }
    offset++;
  }
  return nothing;
}

//scan backward to find the beginning of a string
auto Script::findTarget(u16 offset) -> maybe<u16> {
  maybe<u16> found;
  while(offset >= origin) {
    if(mode == Mode::Chapter) {
      if(data[offset] == 0xff) { found = offset; break; }
      if(data[offset] == 0xfd) { found = offset; break; }
    }
    if(mode == Mode::Field) {
      if(data[offset] == 0xff) { found = offset; break; }
    }
    offset--;
  }
  if(found) {
    if(data[*found + 1] == 0xfe) return *found + 2;
    if(data[*found + 1] == 0xef && data[*found + 2] == 0xfe) return *found + 3;
    return *found + 1;
  }
  return nothing;
}

auto Script::analyze() -> bool {
  if(mode == Mode::Chapter && index == 0xfa) return true;

  pointers.reset();
  u16 offset = origin;
  while(offset < data.size()) {
    if(auto pointer = findPointer(offset)) {
      if(auto terminal = findTerminal(offset)) {
        if(u16 length = *terminal - offset) {
          //in practice, this finds orphaned blocks of text that lack valid pointers.
          //once found, it scans backward to find the origins of each text block.
          if(pointer->suspicious) {
            if(auto target = findTarget(offset)) {
              if(offset != *target) {
                debug(label(pointers.size()), ": ", hex(offset, 4L), " => ", hex(*target, 4L));
                offset = *target;
              }
            }
          }
          append(pointer->source, offset, data[*terminal]);
          //ensure every string can accept a 4-byte pointer redirect command:
          if(length < 4) warning("short pointer [", length, "] detected");
        }
        offset = *terminal;
      }
    }
    offset++;
  }
  findOrphaned();
  insertOverlapped();
  sort(pointers.data(), pointers.size(), [&](auto lhs, auto rhs) -> bool {
    return lhs.target < rhs.target;
  });
  return true;
}

//after analyzing the script, this runs through to look for any text without matching pointers.
auto Script::findOrphaned() -> void {
  auto orphan = [&](u16 offset, u16 target) -> void {
    if(target < offset) return;
    u16 length = target - offset;
    if(length <= 4) return;
    debug(label(), " 0x", hex(offset, 4L), " orphaned string => ", length);

    Pointer pointer;
    pointer.target = offset;
    if(auto terminal = findTerminal(offset)) {
      pointer.terminal = data[*terminal];
      pointers.append(pointer);
    }
  };

  auto skipTerminal = [&](u16& offset) -> void {
    while(offset < data.size()) {
      if(mode == Mode::Chapter) {
        if(data[offset] == 0xff) { offset++; continue; }
        if(data[offset] == 0xfd) { offset++; continue; }
      }
      if(mode == Mode::Field) {
        if(data[offset] == 0xff) { offset++; continue; }
      }
      if(data[offset] == 0xfe) { offset++; continue; }
      if(data[offset] == 0xef && data(offset + 1, 0x00) == 0xfe) { offset += 2; continue; }
      break;
    }
  };

  u16 offset = origin;
  for(auto& pointer : pointers) {
    skipTerminal(offset);
    orphan(offset, pointer.target);
    offset = pointer.target;
    if(auto terminal = findTerminal(offset)) {
      offset = *terminal;
    }
  }
  skipTerminal(offset);
  orphan(offset, data.size());
}

//the original game overlapped a text pointer exactly one time. handle this case manually here.
auto Script::insertOverlapped() -> void {
  //$0182 => "明日の見えない、ぼくたちには知るよしもないんだな………だけど……"
  //$01da => "…だけど……"
  if(mode == Mode::Chapter && index == 0xf7) {
    Pointer pointer;
    pointer.source   = 0x01da;
    pointer.target   = 0x04aa;
    pointer.terminal = 0xfd;
    pointers.append(pointer);
  }
}

auto Script::append(u16 source, u16 target, u8 terminal) -> void {
  Pointer pointer;
  pointer.source   = source;
  pointer.target   = target;
  pointer.terminal = terminal;

  //try to determine information about how the text is presented onscreen for text-renderer.hpp.
  //the control codes to set the window properties can appear anywhere, and we can't always find it.
  //when they cannot be determined, these properties are left as maybe<type> = nothing.

  //0x34 (y-coordinate in tiles) (height in tiles)
  auto set34 = [&](u8 ycoordIndex, u8 heightIndex) -> void {
    u8 ycoord = data[source - ycoordIndex];
    u8 height = data[source - heightIndex];
    if(ycoord < 28) pointer.ycoord = ycoord;
    if(height == 2) pointer.height = 1;
    if(height == 4) pointer.height = 2;
    if(height == 6) pointer.height = 3;
    if(height == 8) pointer.height = 4;
  };

  //0x35 (opacity [whether to draw window decoration or not])
  auto set35 = [&](u8 opaqueIndex) -> void {
    u8 opaque = data[source - opaqueIndex];
    if(opaque == 0) pointer.opaque = 0;
    if(opaque == 1) pointer.opaque = 1;
  };

  //many times the window properties appear immediately before pointers to text.
  if(source >=  6 && data[source - 6] == 0x34) set34(5,4);
  if(source >=  2 && data[source - 3] == 0x35) set35(2);

  //sometimes multiple text blocks are printed in a row.
  //this will propagate the properties forward from previous text blocks.
  if(source >= 10 && data[source - 2] == 0x38 && data[source - 5] == 0x37 && pointers) {
    pointer.ycoord = pointers.last().ycoord;
    pointer.height = pointers.last().height;
    pointer.opaque = pointers.last().opaque;
  }

  pointers.append(pointer);
}

auto Script::extractString(u16 offset) -> string {
  string output;

  u8 bank = 0;
  while(offset < data.size()) {
    u8 byte = data[offset++];

    if(byte <= 0xef) {
      output.append(TextExtractor::character(bank, byte));
      continue;
    }
    if(byte == 0xf0) { bank = 0; continue; }
    if(byte == 0xf1) { bank = 1; continue; }
    if(byte == 0xf2) { bank = 2; continue; }
    if(byte == 0xf3) { bank = 3; continue; }
    if(byte == 0xf4) {
      bank = 0;
      u8 name = data[offset++];
      if(name < names.size()) {
        output.append("{", names[name], "}");
        continue;
      }
    }
    if(byte == 0xfc) {
      byte = data[offset++];
      output.append("{pause:", hex(byte, 2L), "}");
      continue;
    }
    if(byte == 0xfd) {
      if(mode == Mode::Chapter) break;
      if(mode == Mode::Field) {
        output.append("{wait}");
        continue;
      }
    }
    if(byte == 0xfe) {
      output.append("\n");
      continue;
    }
    if(byte == 0xff) break;
    warning("unknown command detected: 0x", hex(byte, 2L));
  }

  return output;
}

auto Script::extract() -> string {
  string output;

  for(auto& pointer : pointers) {
    string tag = {"{", hex(pointer.target, 4L), "}\n"};
    string text = extractString(pointer.target);
    output.append(tag, text, text ? "\n" : "", "{end}\n\n");
  }

  return output;
}
