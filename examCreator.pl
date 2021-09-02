#! /usr/bin/env perl

use v5.34;

use warnings;
use diagnostics;
use experimental 'signatures';
use Data::Show;


use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::IO;

################################################################################
#Properties

#time stamp
my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); # https://perldoc.perl.org/functions/localtime
my  $customTimeStamp = sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec); # https://perldoc.perl.org/functions/sprintf

#files
my $solutionFile     = $ARGV[0];
my  $examFile        = "$customTimeStamp-$solutionFile";


my ($examFileLines_ref, $allQAs_ref) = readFile($solutionFile);
createExamFile($examFile, @{$examFileLines_ref});

################################################################################
#Subroutines

#This function writes the content of the @examFileLines into the file
sub createExamFile($file, @examFileLines){

    open(my $f, '>', $file  ) or die "$file: $!";

    for my $line (@examFileLines){
        print({$f} $line);
    }

    close($f);
}

