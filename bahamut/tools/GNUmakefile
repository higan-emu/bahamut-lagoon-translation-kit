build := optimized
flags += -I../.. -Wno-narrowing

nall.path := ../../nall
include $(nall.path)/GNUmakefile

hiro.path := ../../hiro
include $(hiro.path)/GNUmakefile

define linkWithNall
  @$(compiler) -o out/$1 obj/$1.o $(options)
endef

define linkWithHiro
  @$(compiler) -o out/$1 $(hiro.objects) obj/$1.o $(hiro.options) $(options)
endef

objects := base56 checksum compressor decompressor
objects += font-encoder font-extractor font-kerner
objects += list-editor list-encoder list-extractor
objects += script-editor script-encoder script-extractor
objects += string-scanner
objects := $(objects:%=obj/%.o)

all: $(hiro.objects) $(objects)
	$(call linkWithNall,base56)
	$(call linkWithNall,checksum)
	$(call linkWithNall,compressor)
	$(call linkWithNall,decompressor)
	$(call linkWithNall,font-encoder)
	$(call linkWithNall,font-extractor)
	$(call linkWithNall,font-kerner)
	$(call linkWithHiro,list-editor)
	$(call linkWithNall,list-encoder)
	$(call linkWithNall,list-extractor)
	$(call linkWithHiro,script-editor)
	$(call linkWithNall,script-encoder)
	$(call linkWithNall,script-extractor)
	$(call linkWithNall,string-scanner)

obj/base56.o:           base56.cpp
obj/checksum.o:         checksum.cpp
obj/compressor.o:       compressor.cpp
obj/decompressor.o:     decompressor.cpp
obj/font-encoder.o:     font-encoder.cpp
obj/font-extractor.o:   font-extractor.cpp
obj/font-kerner.o:      font-kerner.cpp
obj/list-editor.o:      list-editor.cpp
obj/list-encoder.o:     list-encoder.cpp
obj/list-extractor.o:   list-extractor.cpp
obj/script-editor.o:    script-editor.cpp
obj/script-encoder.o:   script-encoder.cpp
obj/script-extractor.o: script-extractor.cpp
obj/string-scanner.o:   string-scanner.cpp

build:
	out/base56
	out/font-encoder
	out/list-encoder
	out/script-encoder
	cd ../source && bass main.asm
#	out/checksum

patch:
	cd ../source && bass main.asm
	$(call delete,../en/rom/bahamut-en-patch.bps)
	beat -create:bps ../en/rom/bahamut-en-patch.bps ../jp/rom/bahamut-jp.sfc ../en/rom/bahamut-en.sfc

clean:
	$(call delete,obj/*)
	$(call delete,out/*)

erase:
	$(call rdelete,../en/binaries)
	$(call rdelete,../en/kerning)

-include obj/*.d
