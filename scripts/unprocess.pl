use strict;

while(<STDIN>) {
  chomp;
  s/@@ //g;
  s/([\(\[])\s/$1/g;
  s/\s([\)\]])/$1/g;
  print "$_\n";
}