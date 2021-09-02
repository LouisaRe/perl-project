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
my ($solutionFile, @examFiles)                  = @ARGV;
my ($examFileLines_ref, $solutionAllQAs_ref)    = readFile($solutionFile, 0);

checkExamFiles();

################################################################################
#Subroutines

sub checkExamFiles(){
    my $report_ref;

    #additional information
    my $totalNrOfAnsweredQuestions                           =  0;
    my ($minAnsweredQuestions, $nrOfMinAnsweredQuestions)    = (scalar(keys %{$solutionAllQAs_ref}), 0);
    my ($maxAnsweredQuestions, $nrOfMaxAnsweredQuestions)    = (0, 0);
    my $totalNrOfCorrectAns                  =  0;
    my ($minCorrectAns, $nrOfMinCorrectAns)  = (scalar(keys %{$solutionAllQAs_ref}), 0);
    my ($maxCorrectAns, $nrOfMaxCorrectAns)  = (0, 0);

    say("\n________RESULTS________\n");
    FILE:
    for my $file (@examFiles){
        my $correctCounter      = 0;
        my $answeredQesCounter  = 0;

        my ($examFileLines_ref, $allQAs_ref) = readFile($file, 0);

        SECTION:
        for my $sectNr (1 .. scalar(keys %{$solutionAllQAs_ref})){

            # same question?
            my $solQ    = ${$solutionAllQAs_ref}{"section$sectNr"}{"question"};
            my $examQ   = ${$allQAs_ref}{"section$sectNr"}{"question"};

            if( defined $solQ && not defined $examQ){
                push($report_ref -> {$file} -> @* , "Section $sectNr - Missing question \t: $solQ");
            }
            
            my %solA                = % {%{ %{$solutionAllQAs_ref}{"section$sectNr"} }{"answers"}};
            my %examA               = % {%{ %{$allQAs_ref        }{"section$sectNr"} }{"answers"}};
            my $numberCheckedA      = 0;
            my $correctAnsChecked   = 0;
            ANSWER:
            for my $a (keys %solA){
                
                #count checked answers per section
                if(defined($examA{$a}) && $examA{$a} eq 1){
                    $numberCheckedA++;
                }

                # Is the correct answer checked?
                if($solA{$a} eq 1 && $solA{$a} eq $examA{$a}){
                    $correctAnsChecked++;
                    $correctCounter++;
                }

                # same answer set?
                next ANSWER if exists $examA{$a}; # find missing element
                push($report_ref -> {$file} -> @* , "Section $sectNr - Missing answer \t: $a\n");
    
            }
            # remove the just given point again, if there were too many checked answers.
            if($correctAnsChecked && $numberCheckedA > 1){
                $correctCounter--;
            }
            #update additional information
            if($numberCheckedA > 0){
                $answeredQesCounter++;
            }
        }
        # print results
        say("$file \t $correctCounter/".scalar(keys %{$solutionAllQAs_ref}) );

        #update additional information

        $totalNrOfAnsweredQuestions += $answeredQesCounter;

        if($answeredQesCounter < $minAnsweredQuestions){
            $minAnsweredQuestions       = $answeredQesCounter;
            $nrOfMinAnsweredQuestions   = 1;
        }elsif($answeredQesCounter == $minAnsweredQuestions){
            $nrOfMinAnsweredQuestions++;
        }

        if($answeredQesCounter > $maxAnsweredQuestions){
            $maxAnsweredQuestions       = $answeredQesCounter;
            $nrOfMaxAnsweredQuestions   = 1;
        }elsif($answeredQesCounter == $maxAnsweredQuestions){
            $nrOfMaxAnsweredQuestions++;
        }

        $totalNrOfCorrectAns += $correctCounter;

        if($correctCounter < $minCorrectAns){
            $minCorrectAns      = $correctCounter;
            $nrOfMinCorrectAns  = 1;
        }elsif($correctCounter == $minCorrectAns){
            $nrOfMinCorrectAns++;
        }

        if($correctCounter > $maxCorrectAns){
            $maxCorrectAns      = $correctCounter;
            $nrOfMaxCorrectAns  = 1;
        }elsif($correctCounter == $maxCorrectAns){
            $nrOfMaxCorrectAns++;
        }
    }

    # print report
    say("\n________MISSING ELEMENTS________ \n");
    for my $file (keys %{$report_ref}){
        say "$file:";
        say %{$report_ref}{$file} -> @*;
    }   

    reportAdditionalInfo(
        scalar(@examFiles),

        $totalNrOfAnsweredQuestions, 
        $minAnsweredQuestions, $nrOfMinAnsweredQuestions,
        $maxAnsweredQuestions, $nrOfMaxAnsweredQuestions,

        $totalNrOfCorrectAns,
        $minCorrectAns, $nrOfMinCorrectAns,
        $maxCorrectAns, $nrOfMaxCorrectAns);
}


sub reportAdditionalInfo($totalExams, 
                        
                        $totalNrOfAnsweredQuestions, 
                        $minAnsweredQuestions, $nrOfMinAnsweredQuestions,
                        $maxAnsweredQuestions, $nrOfMaxAnsweredQuestions,

                        $totalNrOfCorrectAns, 
                        $minCorrectAns, $nrOfMinCorrectAns,
                        $maxCorrectAns, $nrOfMaxCorrectAns){

    my $averageQuestionsAns = $totalNrOfAnsweredQuestions/$totalExams;
    my $averageCorrectAns   = $totalNrOfCorrectAns/$totalExams;

    say("________ADDITIONAL INFORMATION________ ");

    say("\nAverage number of answered questions \t: $averageQuestionsAns");
    say("Minimum " . ("\t" x 4) . ": $minAnsweredQuestions ($nrOfMinAnsweredQuestions student" . ($nrOfMinAnsweredQuestions != 1 ? "s" : "") . ")");
    say("Maximum " . ("\t" x 4) . ": $maxAnsweredQuestions ($nrOfMaxAnsweredQuestions student" . ($nrOfMaxAnsweredQuestions != 1 ? "s" : "") . ")");

    say("\nAverage number of correct answers \t: $averageCorrectAns");
    say("Minimum " . ("\t" x 4) . ": $minCorrectAns ($nrOfMinCorrectAns student" . ($nrOfMinCorrectAns != 1 ? "s" : "") . ")");
    say("Maximum " . ("\t" x 4) . ": $maxCorrectAns ($nrOfMaxCorrectAns student" . ($nrOfMaxCorrectAns != 1 ? "s" : "") . ")");
}