use strict;
use Data::Dumper;

my $last = "";
my @lastline;
my %lastannot;
while (<STDIN>) {
    chomp;
    my ($src, $trg, $id, $aln, $domtext, @rest) = split(/\t/, $_);
    my @annot = $src =~ m/(%\S+=\S+)/g;
    $src =~ s/\s*(%\S+=\S+)\s*//g;

    if ($last and $last ne "$src\t$trg") {
        my ($src, $trg, $id, $aln, $domtext, @rest) = @lastline;
        $src .= " $_" foreach(sort keys %lastannot);
        print "$src\t$trg\t$id\t$aln\t$domtext\t", join("\t", @rest), "\n";
        %lastannot = ();
    }

    foreach my $a (@annot) {
        $lastannot{$a} = 1;
    }

    $last = "$src\t$trg";
    @lastline = ($src, $trg, $id, $aln, $domtext, @rest);
}
my ($src, $trg, $id, $aln, $domtext, @rest) = @lastline;
$src .= " $_" foreach(sort keys %lastannot);
print "$src\t$trg\t$id\t$aln\t$domtext\t", join("\t", @rest), "\n";
%lastannot = ();

