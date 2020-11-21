build := optimized
flags += -I../.. -Wno-narrowing

nall.path := ../../nall
include $(nall.path)/GNUmakefile

hiro.path := ../../hiro
include $(hiro.path)/GNUmakefile

define compile
  $(info Compiling $1.cpp ...)
  @$(compiler.cpp) -o out/$1 $1.cpp $(flags) $(options)
endef

define compileWithHiro
  $(info Compiling $1.cpp ...)
  @$(compiler.cpp) -o obj/$1.o -c $1.cpp $(flags)
  @$(compiler) -o out/$1 $(hiro.objects) obj/$1.o $(options) $(hiro.options)
endef

programs += $(hiro.objects)
programs += base56 compressor decompressor
programs += font-encoder font-extractor font-kerner
programs += list-editor list-encoder list-extractor
programs += script-editor script-encoder script-extractor

all: $(programs)

base56:
	$(call compile,base56)

compressor:
	$(call compile,compressor)

decompressor:
	$(call compile,decompressor)

font-encoder:
	$(call compile,font-encoder)

font-extractor:
	$(call compile,font-extractor)

font-kerner:
	$(call compile,font-kerner)

list-editor: $(hiro.objects)
	$(call compileWithHiro,list-editor)

list-encoder:
	$(call compile,list-encoder)

list-extractor:
	$(call compile,list-extractor)

script-editor: $(hiro.objects)
	$(call compileWithHiro,script-editor)

script-encoder:
	$(call compile,script-encoder)

script-extractor:
	$(call compile,script-extractor)

clean:
	$(call delete,obj/*)
	$(call delete,out/*)

cleanup:
	$(call rdelete,../en/binaries)
	$(call rdelete,../en/kerning)

-include obj/*.d
