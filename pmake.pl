#!/usr/bin/perl
# Jinyan Li jli134@ucsc.eud

use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);

$0 =~ s|.*/||;
my $status = 0;
END { exit $status; }
$SIG{__WARN__} = sub {print STDERR "$0: @_"; $status = 1};
$SIG{__DIE__} = sub {warn @_; $status = 1; exit};

my %opts;
getopts "dnf", \%opts;

my $filename = "Makefile";
$filename = $ARGV[0] if $opts{'f'};
print $filename."\n";

my %macro_hash;
my %target_hash;

push @ARGV, "-" unless @ARGV;

open my $file, "<$filename" or warn "$filename: $!\n" and next;
   while (defined (my $line = <$file>)) {
      chomp $line;
      printf "%6d  ", $. if $opts{'n'};
      printf "%s\n", $line;
   }

close $file;


