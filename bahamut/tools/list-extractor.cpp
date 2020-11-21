#include "tools.hpp"
#include "list-extractor.hpp"

auto nall::main() -> void {
  directory::create({pathJP, "scripts/lists/"});
  directory::create({pathJP, "scripts/descriptions/"});
  directory::create({pathJP, "scripts/strings/"});

  ListExtractor listExtractor;
  for(auto& list : listExtractor.lists) {
    auto encoded = listExtractor.extract(list);
    auto unicode = listExtractor.toUnicode(encoded);
    file::write({pathJP, "scripts/", list.category, "/", list.name, ".txt"}, unicode.merge("\n").append("\n"));
  }
}
