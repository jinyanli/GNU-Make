NAME
	pmake — perl implementation of gmake

SYNOPSIS
  pmake [-d] [-n] [-f makefile] [target]

DESCRIPTION
  The pmake utility executes a list of shell commands associated with each target,
  typically to create or update files of the same name. The Makefile contains
  entries that describe how to bring a target up to date with respect to those on
  which it depends, which are called prerequisites.

OPTIONS
  The following options are supported. All options must precede all operands,
  and all options are scanned by Getopt::Std::getopts (perldoc).

-d Displays the reasons why make chooses to rebuild a target. This option
  prints debug information, or nothing at all. Output is readable only to
  the implementor.

-n Non-execution mode. Prints commands, but does not execute them.

-f Makefile
  Specifies the name of the Makefile to use. If not specified, tries to use
  ./Makefile. If neither of those files exists, exits with an error message.

OPERANDS
  The following operand is recognized.
  
  target
  An attempt is made to build each target in sequence in the order they are
  given on the command line. If no target is specified, the first target in
  the makefile is built. This is usually, but not necessarily, the target all.
