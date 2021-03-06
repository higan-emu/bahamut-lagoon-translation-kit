#include "tools.hpp"
#include "decompressor.hpp"
#include "font-encoder.hpp"
#include "list-encoder.hpp"

auto nall::main() -> void {
  directory::create({pathEN, "binaries/lists/"});

  { ListEncoder encoder;
    encoder.load("font-small", 8, 8);

    vector<u8> bpp2 = {0,1,2,3};
    encoder.toSmall<2,0>("bpp2", bpp2, 8, "lists",   "classes");
    encoder.toSmall<2,1>("bpp2", bpp2, 9, "lists",   "commands");
    encoder.toSmall<2,0>("bpp2", bpp2, 8, "lists",   "dragons");
    encoder.toSmall<2,0>("bpp2", bpp2, 8, "lists",   "enemies");
    encoder.toSmall<2,1>("bpp2", bpp2, 9, "lists",   "items");
    encoder.toSmall<2,0>("bpp2", bpp2, 8, "lists",   "names");
    encoder.toSmall<2,1>("bpp2", bpp2, 8, "lists",   "techniques");
    encoder.toSmall<2,0>("bpp2", bpp2, 0, "strings", "bpp2");
    encoder.toSmall<2,0>("bpp2", bpp2, 8, "strings", "chapters");
    encoder.toSmall<2,0>("bpp2", bpp2, 5, "strings", "parties");
    encoder.toSmall<2,0>("bpp2", bpp2, 3, "dynamic", "costsMP");
    encoder.toSmall<2,0>("bpp2", bpp2, 3, "dynamic", "costsSP");
    encoder.toSmall<2,0>("bpp2", bpp2, 3, "dynamic", "counts");
    encoder.toSmall<2,0>("bpp2", bpp2, 3, "dynamic", "levels");
    encoder.toSmall<2,0>("bpp2", bpp2, 4, "dynamic", "levels4");
    encoder.toSmall<2,0>("bpp2", bpp2, 2, "dynamic", "quantities");
    encoder.toSmall<2,0>("bpp2", bpp2, 3, "dynamic", "stats");

    vector<u8> bpp4 = {0,1,2,3};
    encoder.toSmall<4,0>("bpp4", bpp4, 8, "lists",   "classes");
    encoder.toSmall<4,0>("bpp4", bpp4, 8, "lists",   "dragons");
    encoder.toSmall<4,0>("bpp4", bpp4, 9, "lists",   "items");
    encoder.toSmall<4,0>("bpp4", bpp4, 8, "lists",   "names");
    encoder.toSmall<4,0>("bpp4", bpp4, 8, "lists",   "techniques");
    encoder.toSmall<4,0>("bpp4", bpp4, 0, "strings", "bpp4");
    encoder.toSmall<4,0>("bpp4", bpp4, 8, "strings", "chapters");
    encoder.toSmall<4,0>("bpp4", bpp4, 3, "dynamic", "levels");
    encoder.toSmall<4,0>("bpp4", bpp4, 3, "dynamic", "stats");

    vector<u8> bpo4 = {4,1,2,3};
    encoder.toSmall<4,0>("bpo4", bpo4, 9, "lists",   "commands");
    encoder.toSmall<4,0>("bpo4", bpo4, 8, "lists",   "enemies");
    encoder.toSmall<4,0>("bpo4", bpo4, 9, "lists",   "items");
    encoder.toSmall<4,0>("bpo4", bpo4, 8, "lists",   "names");
    encoder.toSmall<4,0>("bpo4", bpo4, 8, "lists",   "techniques");
    encoder.toSmall<4,0>("bpo4", bpo4, 0, "strings", "bpo4");
    encoder.toSmall<4,0>("bpo4", bpo4, 9, "strings", "field");
    encoder.toSmall<4,0>("bpo4", bpo4, 8, "strings", "menu");
    encoder.toSmall<4,0>("bpo4", bpo4, 3, "dynamic", "levels");
    encoder.toSmall<4,0>("bpo4", bpo4, 3, "dynamic", "stats");

    vector<u8> bpa4 = {4,5,6,3};
    encoder.toSmall<4,0>("bpa4", bpa4, 8, "lists",   "names");
    encoder.toSmall<4,0>("bpa4", bpa4, 3, "dynamic", "costsMP");
    encoder.toSmall<4,0>("bpa4", bpa4, 3, "dynamic", "costsSP");
    encoder.toSmall<4,0>("bpa4", bpa4, 3, "dynamic", "counts");
    encoder.toSmall<4,0>("bpa4", bpa4, 3, "dynamic", "stats");

    vector<u8> bpb4 = {4,8,9,3};
    encoder.toSmall<4,0>("bpb4", bpb4, 3, "dynamic", "costsMP");
    encoder.toSmall<4,0>("bpb4", bpb4, 3, "dynamic", "costsSP");
    encoder.toSmall<4,0>("bpb4", bpb4, 3, "dynamic", "counts");

    vector<u8> bph4 = {0,9,10,11};
    encoder.toSmall<4,0>("bph4", bph4, 0, "strings", "bph4");
    encoder.toSmall<4,0>("bph4", bph4, 8, "strings", "chapters");

    vector<u8> bpi4 = {0,13,14,15};
    encoder.toSmall<4,0>("bpi4", bpi4, 3, "dynamic", "costsMP");
    encoder.toSmall<4,0>("bpi4", bpi4, 4, "dynamic", "stats");

    vector<u8> bpd4 = {0,5,6,3};
    encoder.toSmall<4,0>("bpd4", bpd4, 4, "dynamic", "stats");
  }

  { ListEncoder encoder;
    encoder.load("font-credits", 12, 13);

    vector<u8> bpp2 = {0,1,3,2};
    encoder.toLarge("bpp2", bpp2, "strings", "opening");
    encoder.toLarge("bpp2", bpp2, "strings", "ending");
  }

  { ListEncoder encoder;
    encoder.load("font-large", 8, 11);  //used to determine tile widths for strings

    encoder.toText<0>("text",   0, "strings",      "chapters");
    encoder.toText<0>("text", 240, "lists",        "combat");
    encoder.toText<0>("text", 240, "lists",        "defeats");
    encoder.toText<0>("text",   0, "lists",        "dragons");
    encoder.toText<0>("text",   0, "lists",        "enemies");
    encoder.toText<0>("text",   0, "lists",        "items");
    encoder.toText<0>("text",   0, "lists",        "names");
    encoder.toText<0>("text",   0, "lists",        "techniques");
    encoder.toText<0>("text",  96, "lists",        "terrains");
    encoder.toText<0>("text", 192, "lists",        "triggers");
    encoder.toText<0>("text", 216, "descriptions", "descriptions");
  }
}
