#pragma once

struct TextExtractor {
  TextExtractor();
  auto character(u8 bank, u8 character) const -> string;

private:
  vector<u32> tables[4];
};

//load the Japanese character tables
TextExtractor::TextExtractor() {
  for(u32 index : range(4)) {
    auto data = string::read({pathJP, "tables/table-bank", index, ".txt"});
    if(data.size() != 784) error("failed to load character tables");

    auto lines = data.split("\n");
    if(lines.size() != 17) error("failed to parse character tables");

    tables[index].resize(256);
    for(u32 y : range(16)) {
      if(lines[y].size() != 48) error("failed to parse character tables");

      for(u32 x : range(16)) {
        tables[index][y * 16 + x]  = (u8)lines[y][x * 3 + 0] <<  0;
        tables[index][y * 16 + x] |= (u8)lines[y][x * 3 + 1] <<  8;
        tables[index][y * 16 + x] |= (u8)lines[y][x * 3 + 2] << 16;
      }
    }
  }
}

auto TextExtractor::character(u8 bank, u8 character) const -> string {
  string output;
  output.append(char(tables[bank][character] >>  0 & 0xff));
  output.append(char(tables[bank][character] >>  8 & 0xff));
  output.append(char(tables[bank][character] >> 16 & 0xff));
  return output;
}
