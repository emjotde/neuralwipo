#!/bin/perl
#
# Usgae: paste trainset.src trainset.dst trainset.xx | perl addTagesAndYearForNmt.pl
#
use strict;
use warnings;

use Data::Dumper;

binmode STDIN,"utf8";
binmode STDOUT,"utf8";
binmode STDERR,"utf8";

my $precId="";
my $bestYear;
my $opt_ipc='';

if (defined($ARGV[0]) and $ARGV[0] eq '-ipc') {
    shift; $opt_ipc=1;
}
my @ipcs=();
while (<>) {
    my ($src,$dst,$id,@rest) = split(/\t/);
    #print Dumper(\@rest);
    if ($rest[0] =~ /^0-0\#/ && $src =~ /^\#c/) {
        $src =~ s/^\#c/#t/g; $src=$src." #T|U";
        $dst =~ s/^\#c/#t/g; $dst=$dst." #T|U";
    }
    my $json='';
    if ($id ne $precId) {
        $precId=$id;
        @ipcs=();
        if    ($#rest >=2 && $rest[2]=~ /^{.*,/) {
            $json=$rest[2];
        }
        elsif ($#rest >=3 && $rest[3]=~ /^{.*,/) {
            $json=$rest[3];
        }
        elsif ($#rest >=4 && $rest[4]=~ /^{.*,/) {
            $json=$rest[4];
        }
        if ($json) {
            # Fix a badly generated Json
            if ($json=~/,[a-zA-Z]+:\"/) {
                $json=~s/(^|,)([a-zA-Z][a-zA-Z_0-9]*):\"/$1\"$2\":\"/g;
            }
            # try to get the filling date
            my @y=();
            for my $field ('AD','DP','DG','srcfllDate','srcpubDate','srcgrtDate','dstfllDate','dstpubDate','dstgrtDate') {
                if (my ($year) = ($json=~/\"$field\":\"([0-9]{4,4})/i)) {
                    push @y, $year;
                }
            }
            ($bestYear)=sort @y;
            if (! defined $bestYear) {
                die "no best year in $json";
            }
            if ($opt_ipc) {
                for my $field ('IC','IPC','srcipc','dstipc') {
                    if (my ($i1) = ($json=~/\"$field\":\"([^\"]+)\"/i)) {
                        push @ipcs, split(/,/,$i1);
                    }
                    elsif (my ($im) = ($json=~/\"$field\":\[\"([^\]]+)\"\]/i)) {
                        push @ipcs,split(/\",\"/,$im);
                    }
                }
                if ($#ipcs >=0) {
                    my %i=();
                    foreach my $ipc (@ipcs) {
                        if (my ($main,$letter) = ($ipc =~ /^([A-Z][0-9][0-9]) *([A-Z])/) ) {
                            $i{$main}=1; $i{$main.$letter}=1;
                        }
                    }
                    @ipcs = sort keys %i;
                }
            }
        }
    }

    $src = addAnnots($src, $bestYear, 1, @ipcs);
    $dst = addAnnots($dst, $bestYear, 0, @ipcs);
    print "$src\t$dst\t$id\t", join("\t",@rest);
}

sub addAnnots {
    my ($s, $year, $source) = @_;
    $_=$s;
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
    if ($source) {
        foreach my $k (sort keys %A) {
            if ($k =~ /#/) {
                $_.=" %seg=$k";
            }
            else {
                $_.=" %dom=$k";
            }
        }
        if (defined $year && $year) {
            $_.=" %year=$year";
        }

        if ($opt_ipc) {
            for my $ipc (@ipcs) {
                $_ .= " %ipc=$ipc";
            }
        }
    }

    return $_;
}
