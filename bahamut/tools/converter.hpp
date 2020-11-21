#pragma once

auto toDecoded(u32 c) -> maybe<u8> {
  if(c == ' ') return 0x00;
  if(c >= 'A' && c <= 'Z') return c - 'A' + 0x01;
  if(c >= 'a' && c <= 'z') return c - 'a' + 0x1b;
  if(c == '-') return 0x35;
  if(c >= '0' && c <= '9') return c - '0' + 0x36;
  if(c == '.' ) return 0x40;
  if(c == ',' ) return 0x41;
  if(c == '?' ) return 0x42;
  if(c == '!' ) return 0x43;
  if(c == '\'') return 0x44;
  if(c == '\"') return 0x45;
  if(c == ':' ) return 0x46;
  if(c == ';' ) return 0x47;
  if(c == '*' ) return 0x48;
  if(c == '+' ) return 0x49;
  if(c == '/' ) return 0x4a;
  if(c == '(' ) return 0x4b;
  if(c == ')' ) return 0x4c;
  if(c == '^' ) return 0x4d;  //en-question
  if(c == '~' ) return 0x4e;  //en-dash
  if(c == '_' ) return 0x4f;  //en-space
  if(c == 0xc3a4) return 0x60;  //umlaut a
  if(c == 0xc3ab) return 0x61;  //umlaut e
  if(c == 0xc3af) return 0x62;  //umlaut i
  if(c == 0xc3b6) return 0x63;  //umlaut o
  if(c == 0xc3bc) return 0x64;  //umlaut u
  return nothing;
}

auto toEncoded(u32 c) -> maybe<u8> {
  if(c == ' ') return 0xef;
  if(c >= 'A' && c <= 'Z') return c - 'A' + 0xb9;
  if(c >= 'a' && c <= 'z') return c - 'a' + 0x87;
  if(c == '-') return 0xae;
  if(c >= '0' && c <= '9') return c - '0' + 0xaf;
  if(c == '.' ) return 0x86;
  if(c == ',' ) return 0x85;
  if(c == '?' ) return 0x84;
  if(c == '!' ) return 0x83;
  if(c == '\'') return 0x82;
  if(c == '\"') return 0x81;
  if(c == ':' ) return 0x80;
  if(c == ';' ) return 0x7f;
  if(c == '*' ) return 0x7e;
  if(c == '+' ) return 0x7d;
  if(c == '/' ) return 0x7c;
  if(c == '(' ) return 0x7b;
  if(c == ')' ) return 0x7a;
  if(c == '^' ) return 0x79;  //en-question
  if(c == '~' ) return 0x78;  //en-dash
  if(c == '_' ) return 0x77;  //en-space
  if(c == 0xc3a4) return 0x33;  //umlaut a
  if(c == 0xc3ab) return 0x34;  //umlaut e
  if(c == 0xc3af) return 0x35;  //umlaut i
  if(c == 0xc3b6) return 0x36;  //umlaut o
  if(c == 0xc3bc) return 0x37;  //umlaut u
  return nothing;
}

auto toAscii(u8 c) -> maybe<u32> {
  if(c == 0x00) return ' ';
  if(c >= 0x01 && c <= 0x1a) return c - 0x01 + 'A';
  if(c >= 0x1b && c <= 0x34) return c - 0x1b + 'a';
  if(c == 0x35) return '-';
  if(c >= 0x36 && c <= 0x3f) return c - 0x36 + '0';
  if(c == 0x40) return '.';
  if(c == 0x41) return ',';
  if(c == 0x42) return '?';
  if(c == 0x43) return '!';
  if(c == 0x44) return '\'';
  if(c == 0x45) return '\"';
  if(c == 0x46) return ':';
  if(c == 0x47) return ';';
  if(c == 0x48) return '(';
  if(c == 0x49) return '+';
  if(c == 0x4a) return '/';
  if(c == 0x4b) return '(';
  if(c == 0x4c) return ')';
  if(c == 0x4d) return '^';
  if(c == 0x4e) return '~';
  if(c == 0x4f) return '_';
  if(c == 0x60) return 0xc3a4;
  if(c == 0x61) return 0xc3ab;
  if(c == 0x62) return 0xc3af;
  if(c == 0x63) return 0xc3b6;
  if(c == 0x64) return 0xc3bc;
  return nothing;
}
