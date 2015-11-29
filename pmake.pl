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
print "filename: $filename\n";

#get user target
my $len=@ARGV;
#print "length: $len\n";
if ($len>=2){
 my $user_target = $ARGV[1];
 print "target: $user_target\n";
}

my %macro_hash;
my %target_hash;
my %command_hash;
my $current_target;



push @ARGV, "-" unless @ARGV;

#function for parsing each line
sub parse_line {
     my ($line,$macro_hash_ref,$target_hash_ref,
                       $command_hash_ref,$current_target_ref)=@_;
     
     #if the line is not comment
     if($line !~ /^#.+/){
 
         #if the line is a marco put it into hash       
         if ($line =~ /\s*(\S+)\s*=\s+(.+)/){
            my @values = split(" ", $2);
            $macro_hash_ref->{$1} = [@values];
        }

         #put target as key and prerequisites as value in hash
         if($line =~ /\s*(\S+)\s*:.*/ and $line !~ /\t\s*.+/) {            
            my $target=$1;
            #print "$target : ";
            $$current_target_ref=$target;

            #if the target have prerequisites
            if($line=~/.+:\s+(.+)/){
               my @prerequisite=split(" ",$1);
               #print "@prerequisite";
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
            my @command_split;
            if(exists $command_hash_ref->{$current_target}){
              @command_split=split(" ",$command);
              push(@{$command_hash_ref->
                    {$current_target}}, (@command_split,"\n"));

            }
            else {
              $command_hash_ref->{$current_target} = ();
              @command_split=split(" ",$command);
              push(@{$command_hash_ref->
                    {$current_target}}, (@command_split,"\n"));

            }             
         }
      }
}

sub macro_sub{   
    my @value_list = @{$_[0]};
    my $macro_hash_ref = $_[1];
    my $count=0;
    foreach my $value (@value_list){
      if ($value =~ /\$\{([^\}]+)\}/){
          splice @value_list, $count, 1,
                     @{$macro_hash_ref->{$1}};          
       }
      $count++;
    }
    return @value_list;
}


#main function
open my $file, "<$filename" or warn "$filename: $!\n" and next;
while (defined (my $line = <$file>)) {
      chomp $line;
      &parse_line($line,\%macro_hash,\%target_hash,
                              \%command_hash,\$current_target);
      #printf "%s\n", $line;
      #print "\n";
}

#replace macro values that are marco with real values
foreach my $macro_key (keys %macro_hash){
    my @macro_values = @{$macro_hash{$macro_key}};
    #print "$macro_key : @macro_values\n";
    @macro_values = &macro_sub(\@macro_values,\%macro_hash);
    print "$macro_key : @macro_values\n";
    $macro_hash{$macro_key} = [@macro_values];
}


=pod
print "-------------------\n";
my $href3=\%macro_hash;
print "-------------macro--------------\n";
say Dumper($href3);
my $href=\%target_hash;
print "-------------target-------------\n";
say Dumper($href);
my $href2=\%command_hash;
print "------------command-------------\n";
say Dumper($href2);
=cut
close $file;


