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
  if(c == '%' ) return 0x50;
  if(c == 0xc3a4) return 0x51;  //umlaut a
//if(c == 0xc3ab) return 0x--;  //umlaut e
//if(c == 0xc3af) return 0x--;  //umlaut i
  if(c == 0xc3b6) return 0x52;  //umlaut o
  if(c == 0xc3bc) return 0x53;  //umlaut u
  return nothing;
}

auto toEncoded(u32 c) -> maybe<u8> {
  if(c == ' ') return 0xef;
  if(c >= 'A' && c <= 'Z') return c - 'A' + 0xb9;
  if(c >= 'a' && c <= 'z') return c - 'a' + 0x74;
  if(c == '-') return 0xae;
  if(c >= '0' && c <= '9') return c - '0' + 0xaf;
  if(c == '.' ) return 0x8e;
  if(c == ',' ) return 0x8f;
  if(c == '?' ) return 0x90;
  if(c == '!' ) return 0x91;
  if(c == '\'') return 0x92;
  if(c == '\"') return 0x93;
  if(c == ':' ) return 0x94;
  if(c == ';' ) return 0x95;
  if(c == '*' ) return 0x96;
  if(c == '+' ) return 0x97;
  if(c == '/' ) return 0x98;
  if(c == '(' ) return 0x99;
  if(c == ')' ) return 0x9a;
  if(c == '^' ) return 0x9b;  //en-question
  if(c == '~' ) return 0x9c;  //en-dash
  if(c == '_' ) return 0x9d;  //en-space
  if(c == '%' ) return 0x9e;
  if(c == 0xc3a4) return 0x9f;  //umlaut a
//if(c == 0xc3ab) return 0x--;  //umlaut e
//if(c == 0xc3af) return 0x--;  //umlaut i
  if(c == 0xc3b6) return 0xa0;  //umlaut o
  if(c == 0xc3bc) return 0xa1;  //umlaut u
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
  if(c == 0x50) return '%';
  if(c == 0x51) return 0xc3a4;  //umlaut a
//if(c == 0x--) return 0xc3ab;  //umlaut e
//if(c == 0x--) return 0xc3af;  //umlaut i
  if(c == 0x52) return 0xc3b6;  //umlaut o
  if(c == 0x53) return 0xc3bc;  //umlaut u
  return nothing;
}
