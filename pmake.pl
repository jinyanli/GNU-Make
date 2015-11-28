#!/usr/bin/perl
# Jinyan Li jli134@ucsc.eud

use Data::Dumper;
use feature 'say';
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
#print $filename."\n";

my %macro_hash;
my %target_hash;
my %cmd_hash;

my $previous_target;



push @ARGV, "-" unless @ARGV;

open my $file, "<$filename" or warn "$filename: $!\n" and next;
while (defined (my $line = <$file>)) {
      chomp $line;
      $previous_target = &parse_line($line,\%macro_hash,\%target_hash,
                                          \%cmd_hash,$previous_target);
      #printf "%s\n", $line;
      print "\n";
}

sub parse_line {
   my ($line,$macro_hash_ref,$target_hash_ref,
                                   $cmd_hash_ref,$prev_target)=@_;
     
     #if the line is not comment
     if($line !~ /^#.+/){

         #put target as key and prerequisites as value in hash
         if($line =~ /\s*(\S+)\s*:.*/ and $line !~ /\t\s*.+/) {            
            my $target=$1;
            print "$target : ";

            if($line=~/.+:\s+(.+)/){
               my @prerequisite=split(" ",$1);
               print "@prerequisite";
               my %target_hash1;
               $target_hash_ref->{$target} = [@prerequisite];
               #say Dumper($target_hash_ref);
            }else{
               $target_hash_ref->{$target}="";
            }
         }
         #put corresponding command in hash
         elseif

      }

}
#say Dumper(%target_hash);
close $file;


