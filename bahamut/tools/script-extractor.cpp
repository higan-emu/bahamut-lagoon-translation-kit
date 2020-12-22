#include "tools.hpp"
#include "decompressor.hpp"
#include "script-extractor.hpp"

auto nall::main() -> void {
  directory::create({pathJP, "scripts/"});
  directory::create({pathJP, "scripts/chapters/"});
  directory::create({pathJP, "scripts/fields/"});
  directory::create({pathJP, "scripts/lists/"});

  for(u32 index : range(256)) {
    Script script;
    if(!script.loadChapter(index)) continue;
    if(!script.analyze()) continue;
    if(auto content = script.extract()) {
      file::write({pathJP, "scripts/chapters/chapter-", hex(index, 2L), ".txt"}, content);
    }
  }

  for(u32 index : range(33)) {
    Script script;
    if(!script.loadField(index)) continue;
    if(!script.analyze()) continue;
    if(auto content = script.extract()) {
      file::write({pathJP, "scripts/fields/field-", hex(index, 2L), ".txt"}, content);
    }
  }
}
