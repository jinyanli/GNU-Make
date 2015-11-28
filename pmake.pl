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

#get filename
my $filename = "Makefile";
$filename = $ARGV[0] if $opts{'f'};
print $filename."\n";

#get user target
my $len=@ARGV;
print "length: $len\n";
if ($len>=2){
 my $user_target = $ARGV[1];
 print "$user_target\n";
}

my %macro_hash;
my %target_hash;
my %command_hash;
my $current_target;



push @ARGV, "-" unless @ARGV;

open my $file, "<$filename" or warn "$filename: $!\n" and next;
while (defined (my $line = <$file>)) {
      chomp $line;
      $current_target = &parse_line($line,\%macro_hash,\%target_hash,
                                          \%command_hash,$current_target);
      #printf "%s\n", $line;
      print "\n";
}

#function for parsing each line
sub parse_line {
   my ($line,$macro_hash_ref,$target_hash_ref,
                                   $command_hash_ref,$current_target)=@_;
     
     #if the line is not comment
     if($line !~ /^#.+/){
        
         #put target as key and prerequisites as value in hash
         if($line =~ /\s*(\S+)\s*:.*/ and $line !~ /\t\s*.+/) {            
            my $target=$1;
            print "$target : ";
            $current_target=$target;

            #if the target have prerequisites
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
         elsif($line =~ /\t\s*(.+)/){
            my $command=$1;
         }

      }

}

#say Dumper(%target_hash);
close $file;


