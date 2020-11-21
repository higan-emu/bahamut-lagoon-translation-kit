#include "tools.hpp"
#include "decompressor.hpp"
#include "font-encoder.hpp"
#include "list-encoder.hpp"

auto nall::main() -> void {
  directory::create({pathEN, "binaries/lists/"});

  { ListEncoder encoder;
    encoder.load("font-small", 8, 8);

    vector<u8> bpp2 = {0,1,2,3};
    encoder.toTiles<2,0>("bpp2", bpp2, 8, "lists",   "classes");
    encoder.toTiles<2,1>("bpp2", bpp2, 9, "lists",   "commands");
    encoder.toTiles<2,0>("bpp2", bpp2, 9, "lists",   "dragons");
    encoder.toTiles<2,0>("bpp2", bpp2, 9, "lists",   "enemies");
    encoder.toTiles<2,1>("bpp2", bpp2, 9, "lists",   "items");
    encoder.toTiles<2,0>("bpp2", bpp2, 8, "lists",   "names");
    encoder.toTiles<2,1>("bpp2", bpp2, 8, "lists",   "techniques");
    encoder.toTiles<2,0>("bpp2", bpp2, 0, "strings", "bpp2");
    encoder.toTiles<2,0>("bpp2", bpp2, 8, "strings", "chapters");
    encoder.toTiles<2,0>("bpp2", bpp2, 9, "strings", "field");
    encoder.toTiles<2,0>("bpp2", bpp2, 0, "strings", "menu");
    encoder.toTiles<2,0>("bpp2", bpp2, 5, "strings", "parties");
    encoder.toTiles<2,0>("bpp2", bpp2, 2, "dynamic", "costs");
    encoder.toTiles<2,0>("bpp2", bpp2, 3, "dynamic", "counts");
    encoder.toTiles<2,0>("bpp2", bpp2, 3, "dynamic", "levels");
    encoder.toTiles<2,0>("bpp2", bpp2, 3, "dynamic", "stats");

    vector<u8> bpp4 = {0,1,2,3};
    encoder.toTiles<4,0>("bpp4", bpp4, 8, "lists",   "classes");
    encoder.toTiles<4,0>("bpp4", bpp4, 9, "lists",   "dragons");
    encoder.toTiles<4,0>("bpp4", bpp4, 9, "lists",   "items");
    encoder.toTiles<4,0>("bpp4", bpp4, 8, "lists",   "names");
    encoder.toTiles<4,0>("bpp4", bpp4, 8, "lists",   "techniques");
    encoder.toTiles<4,0>("bpp4", bpp4, 0, "strings", "bpp4");
    encoder.toTiles<4,0>("bpp4", bpp4, 8, "strings", "chapters");
    encoder.toTiles<4,0>("bpp4", bpp4, 0, "strings", "saves");
    encoder.toTiles<4,0>("bpp4", bpp4, 3, "dynamic", "levels");
    encoder.toTiles<4,0>("bpp4", bpp4, 3, "dynamic", "stats");

    vector<u8> bpo4 = {4,1,2,3};
    encoder.toTiles<4,0>("bpo4", bpo4, 9, "lists",   "commands");
    encoder.toTiles<4,0>("bpo4", bpo4, 9, "lists",   "enemies");
    encoder.toTiles<4,0>("bpo4", bpo4, 9, "lists",   "items");
    encoder.toTiles<4,0>("bpo4", bpo4, 8, "lists",   "names");
    encoder.toTiles<4,0>("bpo4", bpo4, 8, "lists",   "techniques");
    encoder.toTiles<4,0>("bpo4", bpo4, 0, "strings", "bpo4");
    encoder.toTiles<4,0>("bpo4", bpo4, 9, "strings", "field");
    encoder.toTiles<4,0>("bpo4", bpo4, 8, "strings", "menu");
    encoder.toTiles<4,0>("bpo4", bpo4, 2, "dynamic", "costs");
    encoder.toTiles<4,0>("bpo4", bpo4, 3, "dynamic", "counts");
    encoder.toTiles<4,0>("bpo4", bpo4, 3, "dynamic", "levels");
    encoder.toTiles<4,0>("bpo4", bpo4, 3, "dynamic", "stats");

    vector<u8> bpa4 = {4,5,6,3};
    encoder.toTiles<4,0>("bpa4", bpa4, 8, "lists",   "names");
    encoder.toTiles<4,0>("bpa4", bpa4, 3, "dynamic", "stats");

    vector<u8> bpi4 = {0,13,14,15};
    encoder.toTiles<4,0>("bpi4", bpi4, 3, "dynamic", "stats");

    vector<u8> bpd4 = {0,5,6,3};
    encoder.toTiles<4,0>("bpd4", bpd4, 3, "dynamic", "stats");
  }

  { ListEncoder encoder;
    encoder.load("font-large", 8, 12);  //used to determine tile widths for strings

    encoder.toText<0>("text", 240, "lists",        "defeats");
    encoder.toText<0>("text",   0, "lists",        "dragons");
    encoder.toText<0>("text",   0, "lists",        "enemies");
    encoder.toText<0>("text",   0, "lists",        "items");
    encoder.toText<0>("text",   0, "lists",        "names");
    encoder.toText<0>("text",   0, "lists",        "techniques");
    encoder.toText<0>("text",  96, "lists",        "terrains");
    encoder.toText<0>("text", 216, "descriptions", "descriptions");
  }
}
