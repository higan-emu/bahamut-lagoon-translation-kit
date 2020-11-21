#pragma once

auto decompressBlockLZ77(array_view<u8>& input) -> vector<u8> {
  vector<u8> output;
  output.resize(256 * 1024);

  u32 source = 0;
  u32 target = 0;

  while(true) {
    u8 lo = input[source++];
    if(lo == 0x1a || lo == 0x1b) {
      u16 hi = read16(input, source);
      source += 2;
      if(hi == 0x0100) {
        //end decompression
        break;
      } else if(hi) {
        //11:6 dictionary entry
        u16 offset = (hi >> 8) | (hi & 0xc0) << 2 | (lo & 1) << 10;
        u16 length = (hi & 0x3f);
        if(offset > target) return {};  //bad block

        while(length--) {
          output[target] = output[target - offset];
          target++;
        }
      } else {
        //byte copy
        output[target++] = lo;
      }
    } else {
      //byte copy
      output[target++] = lo;
    }
  }

  input += source;
  output.resize(target);
  return output;
}

auto decompressLZ77(array_view<u8> input) -> vector<u8> {
  u8 mode = *input++;

  if(mode == 0x00) {
    auto data = decompressBlockLZ77(input);
    return data;
  }

  if(mode == 0x03) {
    auto lower = decompressBlockLZ77(input);
    input += 2;  //ignored by decompressor
    auto upper = decompressBlockLZ77(input);
    vector<u8> data;
    data.resize(lower.size() * 2);
    for(u32 address : range(lower.size())) {
      data[address * 2] = lower[address];
    }
    u16 source = 0;
    u16 target = 0;
    u8 mode = upper[source++];
    if(mode != 0x04) error("unsupported 0x03 mode: ", hex(mode, 2L));
    u8 base = 0x20;  //can be any value; set by program code prior to calling decompressor
    u16 length = read16(upper, source);
    if(length != lower.size() >> 2) error("interleave size mismatch");
    source += 2;
    do {
      u8 fields = upper[source++];
      data[target + 1] = base | fields << 6 & 0xc0;
      data[target + 3] = base | fields << 4 & 0xc0;
      data[target + 5] = base | fields << 2 & 0xc0;
      data[target + 7] = base | fields << 0 & 0xc0;
      target += 8;
    } while(--length);
    return data;
  }

  if(mode == 0x06) {
    auto lower = decompressBlockLZ77(input);
    input += 2;  //ignored by decompressor
    auto upper = decompressBlockLZ77(input);
    if(lower.size() != upper.size()) {
      error("interleave size mismatch: ", hex(lower.size(), 4L), " != ", hex(upper.size(), 4L));
    }
    vector<u8> data;
    data.resize(lower.size() + upper.size());
    for(u32 address : range(lower.size())) {
      data[address * 2 + 0] = lower[address];
      data[address * 2 + 1] = upper[address];
    }
    return data;
  }

  error("unsupported decompression mode: ", hex(mode, 2L));
  return {};
}

auto decompressLZSS(array_view<u8> input, u16* compressedSize = nullptr) -> vector<u8> {
  vector<u8> output;
  output.resize(256 * 1024);

  u32 source = 0;
  u32 target = 0;

  u16 size = read16(input, source) + 2;  //first size adds two to account for itself
  source += 2;

  //first block is always assumed to encode at least eight bytes
  u8 remaining = 8;
  while(true) {
    while(source < size) {
      u8 flags = input[source++];

      while(remaining--) {
        if(flags & 1) {
          //12:4 dictionary entry
          u16 pair = read16(input, source);
          source += 2;

          u16 offset = (pair & 0xfff);
          u16 length = (pair >> 12) + 3;
          //out-of-bounds pointes denote bad blocks
          if(offset > target) return {};

          while(length--) {
            output[target] = output[target - offset];
            target++;
          }
        } else {
          //byte copy
          output[target++] = input[source++];
        }
        flags >>= 1;
      }

      remaining = 8;
    }

    //it is likely a programming oversight that this is not & 0x07
    //no good blocks will store a value here > 7
    remaining = input[source++] & 0x3f;
    if(!remaining) break;  //end of decompression

    //additional blocks remaining
    size = read16(input, source);
    source += 2;
    //subsequent sizes do not add two to account for themselves
  }

  if(compressedSize) *compressedSize = source;
  output.resize(target);
  return output;
}
