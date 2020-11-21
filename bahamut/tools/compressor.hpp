#pragma once

auto compressBlockLZ77(array_view<u8> input) -> vector<u8> {
  vector<u8> output;
  output.resize(256 * 1024, 0x00);

  u32 source = 0;
  u32 target = 0;

  while(source < input.size()) {
    u32 longestOffset = 0;
    u32 longestLength = 0;
    for(u32 window = 1; window < 2048; window++) {
      u32 length = 0;
      while(true) {
        if(length >= 63) break;  //maximum dictionary length
        if(source + length >= input.size()) break;  //do not read past end of input buffer
        if(source + length < window) break;  //do not read past start of sliding window
        if(input[source + length] != input[source + length - window]) break;  //stop at first mismatch
        length++;
      }
      if(length >= longestLength) {
        longestOffset = window;
        longestLength = length;
      }
    }
    if(longestLength >= 4) {
      output[target++] = 0x1a | (longestOffset >> 10 & 1);
      output[target++] = (longestLength & 0x3f) | (longestOffset >> 2 & 0xc0);
      output[target++] = (longestOffset & 0xff);
      source += longestLength;
    } else {
      u8 byte = input[source++];
      output[target++] = byte;
      if(byte == 0x1a || byte == 0x1b) {
        output[target++] = 0x00;
        output[target++] = 0x00;
      }
    }
  }

  output[target++] = 0x1b;
  output[target++] = 0x00;
  output[target++] = 0x01;
  output.resize(target);
  return output;
}

auto compressLZ77(u8 mode, array_view<u8> input) -> vector<u8> {
  vector<u8> data;

  if(mode == 0x00) {
    data.append(0x00);
    data.append(compressBlockLZ77(input));
    return data;
  }

  if(mode == 0x03) {
    vector<u8> lower;
    lower.resize(input.size() >> 1);
    for(u32 address : range(lower.size())) {
      lower[address] = input[address * 2];
    }
    vector<u8> upper;
    upper.resize(3 + (data.size() >> 3));
    upper[0] = 0x04;  //mode
    upper[1] = (upper.size() - 3) >> 0;
    upper[2] = (upper.size() - 3) >> 8;
    for(u32 address : range(upper.size())) {
      u8 byte = 0x00;
      byte |= (input[lower.size() + address * 8 + 1] >> 6) << 0;
      byte |= (input[lower.size() + address * 8 + 3] >> 6) << 2;
      byte |= (input[lower.size() + address * 8 + 5] >> 6) << 4;
      byte |= (input[lower.size() + address * 8 + 7] >> 6) << 6;
      upper[3 + address] = byte;
    }
    data.append(0x03);
    data.append(compressBlockLZ77(lower));
    data.append(0x00);
    data.append(0x03);
    data.append(compressBlockLZ77(upper));
    return data;
  }

  if(mode == 0x06) {
    vector<u8> lower;
    vector<u8> upper;
    lower.resize(input.size() >> 1);
    upper.resize(input.size() >> 1);
    for(u32 address : range(input.size() >> 1)) {
      lower[address] = input[address * 2 + 0];
      upper[address] = input[address * 2 + 1];
    }
    data.append(0x06);
    data.append(compressBlockLZ77(lower));
    data.append(0x00);
    data.append(0x06);
    data.append(compressBlockLZ77(upper));
    return data;
  }

  return {};
}

auto compressLZSS(array_view<u8> input) -> vector<u8> {
  vector<u8> output;
  output.resize(256 * 1024, 0xff);  //default all unassigned flag bits to set

  struct Codepoint {
    u16 offset = 0;
     u8 length = 1;
     u8 byte = 0x00;
  };
  vector<Codepoint> codepoints;

  u32 offset = 0;
  while(offset < input.size()) {
    Codepoint codepoint;
    codepoint.byte = input[offset];
    for(u32 window = 1; window < 4096; window++) {
      u32 length = 0;
      while(true) {
        if(length >= 15 + 3) break;  //maximum dictionary length
        if(offset + length >= input.size()) break;  //do not read past end of input buffer
        if(offset + length < window) break;  //do not read past start of sliding window
        if(input[offset + length] != input[offset + length - window]) break;  //stop at first mismatch
        length++;
      }
      if(length >= codepoint.length && length >= 3) {
        codepoint.offset = window;
        codepoint.length = length;
      }
    }
    codepoints.append(codepoint);
    offset += codepoint.length;
  }

  //the first flag block must encode eight codepoints, even if the input size is smaller
  while(codepoints.size() < 8) {
    Codepoint codepoint;
    codepoints.append(codepoint);
  }

  u32 origin = 0;
  u32 target = 2;

  while(codepoints) {
    u32 flag = target++;

    for(u32 bit : range(8)) {
      if(!codepoints) continue;
      auto codepoint = codepoints.takeFirst();
      if(codepoint.length < 3) {
        output[flag] &= ~(1 << bit);
        output[target++] = codepoint.byte;
      } else {
        uint16_t code = codepoint.length - 3 << 12 | codepoint.offset;
        output[target++] = code >> 0;
        output[target++] = code >> 8;
      }
    }

    if(codepoints.size() >= 8) continue;

    //for an unknown reason, only the first block adds 2 to size when decompressing ...
    output[origin + 0] = target - (!origin ? 2 : 0) >> 0;
    output[origin + 1] = target - (!origin ? 2 : 0) >> 8;
    output[target++] = codepoints.size();
    origin = target;
    target += 2;

    if(!codepoints) break;
  }

  output.resize(target - 2);
  return output;
}
