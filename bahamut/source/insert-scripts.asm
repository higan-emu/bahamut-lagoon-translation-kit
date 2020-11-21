namespace chapter {
  macro insert(id) {
    variable index   = ${id}
    variable address = 0
    address = address | read($1a8000 + index * 3) <<  0
    address = address | read($1a8001 + index * 3) <<  8
    address = address | read($1a8002 + index * 3) << 16
    seek(address); insert "../en/binaries/chapters/chapter-{id}.bin"
  }
  insert(00);insert(01);insert(02);insert(03);insert(04);insert(05);insert(06);insert(07)
  insert(08);insert(09);insert(0a);insert(0b);insert(0c);insert(0d);insert(0e);insert(0f)
  insert(10);insert(11);insert(12);insert(13);insert(14);insert(1e);insert(1f);insert(23)
  insert(25);insert(27);insert(28);insert(29);insert(2a);insert(2c);insert(2d);insert(2e)
  insert(2f);insert(30);insert(31);insert(32);insert(33);insert(3e);insert(3f);insert(40)
  insert(41);insert(42);insert(43);insert(44);insert(46);insert(48);insert(49);insert(4b)
  insert(4c);insert(4d);insert(4e);insert(50);insert(d0);insert(d1);insert(d2);insert(d3)
  insert(d4);insert(d5);insert(d6);insert(d7);insert(f3);insert(f4);insert(f5);insert(f6)
  insert(f7)
}

namespace field {
  macro insert(id) {
    variable index   = ${id}
    variable address = 0
    address = address | read($07140f + index * 3) <<  0
    address = address | read($071410 + index * 3) <<  8
    address = address | read($071411 + index * 3) << 16
    seek(address); insert "../en/binaries/fields/field-{id}.bin"
  }
  insert(00);insert(01);insert(02);insert(03);insert(04);insert(05);insert(06);insert(07)
  insert(08);insert(09);insert(0a);insert(0b);insert(0c);insert(0d);insert(0e);insert(0f)
  insert(10);insert(11);insert(12);insert(13);insert(14);insert(15);insert(16);insert(17)
  insert(18);insert(19);insert(1a);insert(1b);insert(1c);insert(1d);insert(1e);insert(1f)
}

namespace script {
  seek(textCursor)
  insert "../en/binaries/script/script.bin"
  textCursor = pc()
}
