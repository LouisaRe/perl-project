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

#files
our $solutionFile    = shift(@ARGV);
our @examFiles       = @ARGV;

my ($examFileLines_ref, $solutionAllAnswers_ref, $solutionAllCorrectAnswers_ref) = readFile($solutionFile, 0);

checkExamFiles();

################################################################################
#Subroutines

sub checkExamFiles(){
    my $report_ref;

    for my $file (@examFiles){
        my $correctCounter = 0;
        my $incorrectCounter = 0;

        my ($examFileLines_ref, $allAnswers_ref, $allCorrectAnswers_ref) = readFile($file, 0);

        for my $questNr (1 .. scalar(keys %{$solutionAllAnswers_ref})){
            # same question?
            # push($report_ref -> {$file} -> @* , "Missing question: ");

            # same answer set?
            if(%{$allAnswers_ref}{"question$questNr"} -> @* ne %{$solutionAllAnswers_ref}{"question$questNr"} -> @* ){ # Not same answer set
                for my $a ( %{$solutionAllAnswers_ref}{"question$questNr"} -> @* ) {
                    my %answers = map { $_ => undef } %{$allAnswers_ref}{"question$questNr"} -> @*; # convert array to hash
                    next if exists $answers{$a}; # find missing element
                    push($report_ref -> {$file} -> @* , "Missing answer: $a\n");
                }
            }

            # Is answer correct?
            if(%{$solutionAllCorrectAnswers_ref}{"question$questNr"} eq %{$allCorrectAnswers_ref}{"question$questNr"}){
                $correctCounter++;
            }else{
                $incorrectCounter++;
            }
        }

        # print results
        say("$file \t $correctCounter/".%{$solutionAllCorrectAnswers_ref});
    }

    # print report
    for my $file (keys %{$report_ref}){
        say "\n$file:";
        say %{$report_ref}{$file} -> @*;
    }   
}