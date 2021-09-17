#! /usr/bin/env perl

use v5.34;

use warnings;
use diagnostics;
use experimental 'signatures';
use Data::Show;


use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::IO;

################################################################################

#files (params)
my ($solutionFile, $examPath) = @ARGV;

#time stamp
my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); # https://perldoc.perl.org/functions/localtime
my  $customTimeStamp = sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec); # https://perldoc.perl.org/functions/sprintf

#ensure correct target path and fileNames:
if(defined($examPath)){
    $examPath =~ s{/$}{}xg;
    $examPath =~ s{^/}{}xg;
    $examPath .= "/";
}else{
    $examPath = "";
}
my $solutionFileName = $solutionFile;  
   $solutionFileName =~ s{^ (?: .+? /)* }{}xms;
my $examFile         = "$examPath$customTimeStamp-$solutionFileName";

# read solution file
my ($examFileLines_ref, $allQAs_ref) = readFile($solutionFile);
# create exam file
createExamFile($examFile, @{$examFileLines_ref});