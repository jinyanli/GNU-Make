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
my $arglen=@ARGV;
#print "length: $len\n";

my $default_target="";
my @target_list;
if ($arglen>=2){ 
   for(my $i=0; $i<@ARGV-1; $i++){
      push(@target_list,$ARGV[$i+1]);      
   }
print "target list: @target_list\n";
}



my %macro_hash;

#hold target prerequisites
my %target_hash;
my %command_hash;
my $current_target;

#array to hold targets that have prerequisite
my @prereq_target;


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
            $current_target=$target;
            if ($default_target eq "") {
                $default_target = $target;
            }
            #if the target have prerequisites
            if($line=~/.+:\s+(.+)/){
               my @prerequisite=split(" ",$1);
               #print "@prerequisite";
               my %target_hash1;
               $target_hash_ref->{$target} = [@prerequisite];
               #say Dumper($target_hash_ref);
               push(@prereq_target,$target);
            }else{
               $target_hash_ref->{$target}="";
            }
         }

         #put corresponding command in hash
         elsif($line =~ /\t\s*(.+)/){
            my $command=$1;
            my @command_split;
            if(exists $command_hash_ref->{$current_target}){
              #print "cmdhash : $current_target\n";
              @command_split=split(" ",$command);
              push(@{$command_hash_ref->
                    {$current_target}}, (@command_split,"\n"));

            }
            else {
              #print "cmdhash : $current_target\n";
              $command_hash_ref->{$current_target} = ();
              @command_split=split(" ",$command);
              push(@{$command_hash_ref->
                    {$current_target}}, (@command_split,"\n"));

            }             
         }
      }
}

#function for macro substitution
sub macro_sub{   
    my @value_list = @{$_[0]};
    my $macro_hash_ref = $_[1];
    my $count=0;
    foreach my $value (@value_list){
      if ($value =~ /\${([^}]+)\}/){
          splice @value_list, $count, 1,
                     @{$macro_hash_ref->{$1}};          
       }
      $count++;
    }
    return @value_list;
}

sub percent_sub {
    my $extension;
    foreach my $target (keys %target_hash){
        if ($target =~ /^%(.+)/){
            $extension = $1;
            foreach my $macro (keys %macro_hash){
                my @values = @{$macro_hash{$macro}};
                foreach my $value (@values){
                    if ($value =~ /((\w*)($extension)$)/){
                        $value =~ s/(.*)\..*/$1/;
                        my $target = $value . $extension;
                        my $key =  "%" . $extension;
                        my $prerequisites = @{$target_hash{$key}}[0];
                        $prerequisites =~ s/^.//;
                        $prerequisites = $value . $prerequisites;
                        my @cmd_list = @{$command_hash{$key}};
                        map {$_=$prerequisites if $_ =~ /\$</} @cmd_list;
                        $target_hash{$target} = [$prerequisites];
                        $command_hash{$target} = [@cmd_list];
                     }
                }
            } 
        }
    }
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
    #print "$macro_key : @macro_values\n";
    $macro_hash{$macro_key} = [@macro_values];
}

#replace macros in targets, prerequistes and command 
#print "------replace macros in targets and prerequistes------\n";
foreach my $target (keys %target_hash){
    #print "$target\n";
    my $target_replacement=$target;
    if($target=~/\${([^}]+)\}/){
       $target_replacement=@{$macro_hash{$1}}[0];
    }

    if(($target_hash{$target}) ne ''){
      #print "$target_hash{$target}\n"; 
      my @prereq_list=@{$target_hash{$target}};
      #print "$target : @prereq_list\n";
      @prereq_list=&macro_sub(\@prereq_list,\%macro_hash);
      #print "@prereq_list\n";
      delete $target_hash{$target};
      @{$target_hash{$target_replacement}}= @prereq_list;
   }
   if(exists ($command_hash{$target})){
      if(($command_hash{$target}) ne ''){      
         my @cmd_list = @{$command_hash{$target}};
         #print "@cmd_list\n";
         @cmd_list = &macro_sub(\@cmd_list,\%macro_hash);
         delete $command_hash{$target};
         @{$command_hash{$target_replacement}} = @cmd_list;
      }
   }
}

#replace %target
&percent_sub();

my @total_target;
if($arglen>1){
 push(@total_target,@target_list);
}else{
 push(@total_target,$default_target);
}

#print "total targets: @total_target\n";
my @ordered_targets;
for my $target (@total_target){
  if (exists $target_hash{$target}){
      if($target_hash{$target} ne ""){
         my @prereq = @{$target_hash{$target}};
         #push prerequisites to @ordered_targets
         &get_prerequisites(\@prereq);
     }
    push(@ordered_targets, $target);
  }
}
#print "ordered_targets: @ordered_targets\n";

#execute commands 
print "------------execute commands-------------\n";
foreach my $target (@ordered_targets){
    if (exists $command_hash{$target}){
    }
}

sub get_prerequisites {
    my @pre_list = @{$_[0]};
    foreach my $tar (@pre_list){
        if (exists $target_hash{$tar}){
           if($target_hash{$tar} ne ""){
               my @pass_pre = @{$target_hash{$tar}};
               &get_prerequisites(\@pass_pre);
            }
               push(@ordered_targets, $tar);           
        }
    }
}
=pod
print "-------------------\n";
my $href3=\%macro_hash;
print "-------------macro--------------\n";
say Dumper($href3);
=cut
my $href=\%target_hash;
print "-------------target prerequistes-------------\n";
say Dumper($href);

my $href2=\%command_hash;
print "------------command-------------\n";
say Dumper($href2);


close $file;


