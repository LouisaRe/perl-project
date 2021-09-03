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

my $examResults_ref = checkExamFiles();

reportResults           (scalar(keys %{$solutionAllQAs_ref}), $examResults_ref);
reportCohortPerformence (scalar(keys %{$solutionAllQAs_ref}), $examResults_ref);
reportMissingElements   ($examResults_ref);
reportNotExpected       (scalar(keys %{$solutionAllQAs_ref}), $examResults_ref);



################################################################################
#Subroutines

sub checkExamFiles(){

    my $examResults_ref;

    FILE:
    for my $file (@examFiles){
        my $correctCounter                    = 0;
        my $answeredQesCounter                = 0;
        my ($examFileLines_ref, $allQAs_ref)  = readFile($file, 0);

        SECTION:
        for my $sectNr (1 .. scalar(keys %{$solutionAllQAs_ref})){

            # same question?
            my $solQ    = ${$solutionAllQAs_ref}{"section$sectNr"}{"question"};
            my $examQ   = ${$allQAs_ref}{"section$sectNr"}{"question"};

            if( defined $solQ && not defined $examQ){
                push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNr - Missing question \t: $solQ");
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
                push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNr - Missing answer \t: $a\n");
    
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

        #save / update results
        ${$examResults_ref}{"correctAns"}{$file}    = $correctCounter;
        ${$examResults_ref}{"correctAns"}{"total"} += $correctCounter;
        ${$examResults_ref}{"answeredQ"}{$file}     = $answeredQesCounter;
        ${$examResults_ref}{"answeredQ"}{"total"}  += $answeredQesCounter;       
    }

    return $examResults_ref;
}

################################################################################
#report subroutines

sub reportResults($totalQuestions, $examResults_ref){

    say("\n________RESULTS________\n");

    # print results
    for my $file (@examFiles){
        say("$file \t: ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions");
    }
}

sub reportCohortPerformence($totalQuestions, $examResults_ref){

    my ($minAnsweredQ , $nrOfMinAnsweredQ) = ($totalQuestions    , 0);
    my ($maxAnsweredQ , $nrOfMaxAnsweredQ) = (0                  , 0);

    my ($minCorrectA  , $nrOfMinCorrectA)  = ($totalQuestions    , 0);
    my ($maxCorrectA  , $nrOfMaxCorrectA)  = (0                  , 0);

    FILE:
    for my $file (@examFiles){
        my $answeredQ   = ${$examResults_ref}{'answeredQ'}{$file};
        my $correctA    = ${$examResults_ref}{'correctAns'}{$file};

        #answered questions:
        if( $answeredQ < $minAnsweredQ ){
            $minAnsweredQ       = $answeredQ;
            $nrOfMinAnsweredQ   = 1;
        }
        elsif( $answeredQ == $minAnsweredQ ){
            $nrOfMinAnsweredQ++;
        }
        if( $answeredQ > $maxAnsweredQ ){
            $maxAnsweredQ       = $answeredQ;
            $nrOfMaxAnsweredQ   = 1;
        }
        elsif( $answeredQ == $maxAnsweredQ ){
            $nrOfMaxAnsweredQ++;
        }

        #correct answers
        if( $correctA < $minCorrectA ){
            $minCorrectA       = $correctA;
            $nrOfMinCorrectA   = 1;
        }
        elsif( $correctA == $minCorrectA ){
            $nrOfMinCorrectA++;
        }
        if( $correctA > $maxCorrectA ){
            $maxCorrectA       = $correctA;
            $nrOfMaxCorrectA   = 1;
        }
        elsif( $correctA == $maxCorrectA ){
            $nrOfMaxCorrectA++;
        }
    }

    say("\n________COHORT PERFORMENCE________\n");

    say("Average number of answered questions \t: " . sprintf("%.1f" , ${$examResults_ref}{"answeredQ"}{"total"} / scalar(@examFiles) ));
    say("Minimum " . ("\t" x 4) . ": $minAnsweredQ ($nrOfMinAnsweredQ student" . ($nrOfMinAnsweredQ != 1 ? "s" : "") . ")");
    say("Maximum " . ("\t" x 4) . ": $maxAnsweredQ ($nrOfMaxAnsweredQ student" . ($nrOfMaxAnsweredQ != 1 ? "s" : "") . ")");

    say("\nAverage number of correct answers \t: " . sprintf("%.1f" , ${$examResults_ref}{"correctAns"}{"total"} / scalar(@examFiles) ));
    say("Minimum " . ("\t" x 4) . ": $minCorrectA ($nrOfMinCorrectA student" . ($nrOfMinCorrectA != 1 ? "s" : "") . ")");
    say("Maximum " . ("\t" x 4) . ": $maxCorrectA ($nrOfMaxCorrectA student" . ($nrOfMaxCorrectA != 1 ? "s" : "") . ")");
}

# Print out all exams that have a grade < 3.75, and so didn't pass the test.
# In addition print all passed exams that are in the bottom 25% of all exams.
sub reportNotExpected($totalQuestions, $examResults_ref){

    say("\n________BELOW EXPECTATION________ \n");

    my $nrBottom25 = sprintf('%.0f' , (scalar(@examFiles) / 4)) // 1;
    my @lowestResults = ();
    for my $file (@examFiles){
        push(@lowestResults , ${$examResults_ref}{'correctAns'}{$file} );
    }
    @lowestResults = sort {$a <=> $b} (@lowestResults);
    @lowestResults = splice (@lowestResults, 0, $nrBottom25);

    for my $file (@examFiles){
        my $grade = ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions * 5 + 1;
        if($grade < 3.75){
            say( "$file \t: ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions (not passed -> reached grade: " . sprintf("%.2f", $grade) . ")" );
        }else{
            for my $lowR (@lowestResults){
                if($lowR == ${$examResults_ref}{'correctAns'}{$file}){
                    say( "$file \t: ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions (bottom 25% of cohort)");
                }
            }
        }
    }
}

sub reportMissingElements($examResults_ref){
    say("\n________MISSING ELEMENTS________ \n");

    for my $file (@examFiles){
        if($examResults_ref -> {"missedEl"} -> {$file}){
            say "$file:";
            say $examResults_ref -> {"missedEl"} -> {$file} -> @*;
        }
    }
}