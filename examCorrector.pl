#! /usr/bin/env perl

use v5.34;

use warnings;
use diagnostics;
use experimental 'signatures';

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::IO;
use Util::Reporting;
use Util::ExamChecking;


################################################################################
#Properties

# files (params)
my ( $solutionFile, 
     @examFiles )           = @ARGV;

# get all file infos (read & check all files)
my ( $examFileLines_ref, 
     $solutionAllQAs_ref )   = readFile($solutionFile, 0);
my ( $examResults_ref, 
     $wrongAnsweredQ_ref )   = checkExamFiles(\@examFiles, $solutionAllQAs_ref);
my   $lengthLongestFileName  = calculateLongestFileName(\@examFiles);
my   $totalQuestions         = scalar(keys %{$solutionAllQAs_ref});

# reports
reportResults               (\@examFiles, $totalQuestions, $examResults_ref, $lengthLongestFileName );
reportNotExpected           (\@examFiles, $totalQuestions, $examResults_ref, $lengthLongestFileName );
reportCohortPerformence     (\@examFiles, $totalQuestions, $examResults_ref                         );
reportMissingElements       (\@examFiles,                  $examResults_ref                         );
reportPossibleMisconduct    ($wrongAnsweredQ_ref, scalar( %{ %{$solutionAllQAs_ref}{"section1"} -> {"answers"}}), $lengthLongestFileName);