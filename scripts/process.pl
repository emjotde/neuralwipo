use strict;
use Getopt::Long;

my $SOURCE = 0;
GetOptions(
  source => \$SOURCE,
);

while(<STDIN>) {
    chomp;
    my @annots = m/\|(\S+)/g;
    my @prefix = m/^(\#\S)/g;
    push(@annots, @prefix);
    my %A = map { $_ => 1 } @annots;
    delete $A{U};
    s/\|\S+//g;
    s/^\#\S//g;
    s/\#\S$//g;
    s/\s+/ /g;
    s/^\s+|\s+$//g;
    s/([\(\[])(\S)/$1 $2/g;
    s/(\S)([\)\]])/$1 $2/g;
    print $_;
    if($SOURCE) {
      print " %$_" foreach(sort keys %A);
    }
    print "\n";
}
