#! /usr/bin/env perl

use v5.34;

use warnings;
use diagnostics;
use experimental 'signatures';

use Data::Show;
use Text::Trim;
use Text::Levenshtein qw(distance);
use Lingua::StopWords qw( getStopWords );

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
        my $answeredQCounter                  = 0;
        my ($examFileLines_ref, $allQAs_ref)  = readFile($file, 0);

        ##############################################
        #Question Check

        SOL_SECTION:
        for my $sectNrSol (1 .. scalar(keys %{$solutionAllQAs_ref})){
            my $solQNormalized  = normalize(${$solutionAllQAs_ref}{"section$sectNrSol"}{"question"});
            my $minQDistance    = 1000;
            my $bestFitSection;

            # find best matching exam question
            EXAM_SECTION:
            for my $sectNrExam (1 .. scalar(keys %{$allQAs_ref})){

                my $examQNormalized = normalize(${$allQAs_ref}{"section$sectNrExam"}{"question"});

                my $distance = calculateDistance($solQNormalized, $examQNormalized);

                if($distance < $minQDistance){
                    $minQDistance = $distance;
                    $bestFitSection = ${$allQAs_ref}{"section$sectNrExam"};
                }

                last EXAM_SECTION if($distance == 0);
                
            }

            # fill missed elements array
            if($minQDistance > 0){
                push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Missing question \t: ${$solutionAllQAs_ref}{'section'.$sectNrSol}{'question'}");
                if($minQDistance/length($solQNormalized) <= 0.1){
                    push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Used instead \t: ${$bestFitSection}{'question'}");
                }
            }

            ##############################################
            #Answer Check

            # only look at answers of relevant questions
            if($minQDistance/length($solQNormalized) <= 0.1){ 

                my %solAnsOfCurrQ       = % {%{ %{$solutionAllQAs_ref}{"section$sectNrSol"} }{"answers"}};
                my %examAnsOfCurrQ      = % {%{ $bestFitSection }{"answers"}};
                my $numberCheckedA      = 0;
                my $correctAChecked     = 0;

                SOL_ANSWER:
                for my $sa (keys %solAnsOfCurrQ){

                    my $solANormalized  = normalize($sa);
                    my $minADistance    = 1000;
                    my $bestFitA;

                    # find best matching question answers
                    EXAM_ANSWER:
                    for my $ea (keys %examAnsOfCurrQ){

                        my $examANormalized       = normalize($ea);
                        my $ansDistance = calculateDistance($solANormalized, $examANormalized);

                        if($ansDistance < $minADistance){
                            $minADistance = $ansDistance;
                            $bestFitA = $ea;
                        }

                        last EXAM_ANSWER if($ansDistance == 0);

                    }

                    # fill missed elements array
                    if($minADistance > 0){
                        push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Missing answer \t: $sa\n");
                    
                        if($minADistance/length($solANormalized) <= 0.1){
                            push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Used instead \t: $bestFitA\n");
                        }
                    }
                    
                    # Is the correct answer checked?
                    if($minADistance/length($solANormalized) <= 0.1){ 
                        if($solAnsOfCurrQ{$sa} == 1 && $examAnsOfCurrQ{$bestFitA} == 1){
                            $correctAChecked = 1;
                        }
                    }
                }

                EXAM_ANSWER:
                for my $ea (keys %examAnsOfCurrQ){

                    #count checked answers per section
                    if($examAnsOfCurrQ{$ea} == 1){
                        $numberCheckedA++;
                    }
    
                }

                # Award points for this section
                if($correctAChecked && $numberCheckedA == 1){
                    $correctCounter++;
                }

                #update additional information
                if($numberCheckedA > 0){
                    $answeredQCounter++;
                }
                $numberCheckedA = 0;
            }
        }

        ##############################################
        # File/Total Infos

        #save / update results
        ${$examResults_ref}{"correctAns"}{$file}    = $correctCounter;
        ${$examResults_ref}{"correctAns"}{"total"} += $correctCounter;
        ${$examResults_ref}{"answeredQ"}{$file}     = $answeredQCounter;
        ${$examResults_ref}{"answeredQ"}{"total"}  += $answeredQCounter;       
    }

    return $examResults_ref;
}

################################################################################
#inexact matching

sub normalize($text){
    if($text){
        #to lowercase + remove spaces at start/end
        my $result = trim(lc($text));

        #remove stopwords
        my $stopwords = getStopWords('en'); # https://metacpan.org/pod/Lingua::StopWords
        $result = join ' ', grep { !$stopwords->{$_} } split(' ', $result);

        #remove spaces
        $result =~ s{\s\s+}{ }xg; #TODO

        return $result;
    }else{
        return "";
    }
}

sub calculateDistance($solText, $examText){
    return distance($solText, $examText);
}

################################################################################
#report subroutines

sub reportResults($totalQuestions, $examResults_ref){

    say("\n________RESULTS________\n");

    # print results
    for my $file (@examFiles){
        say($file." \t: ".${$examResults_ref}{'correctAns'}{$file}."/$totalQuestions");
    }
}

sub reportCohortPerformence($totalQuestions, $examResults_ref){

    my ($minAweredQ , $nrOfMinAnsweredQ) = ($totalQuestions    , 0);
    my ($maxAnsweredQ , $nrOfMaxAnsweredQ) = (0                  , 0);

    my ($minCorrectA  , $nrOfMinCorrectA)  = ($totalQuestions    , 0);
    my ($maxCorrectA  , $nrOfMaxCorrectA)  = (0                  , 0);

    FILE:
    for my $file (@examFiles){
        my $answeredQ   = ${$examResults_ref}{'answeredQ'}{$file};
        my $correctA    = ${$examResults_ref}{'correctAns'}{$file};

        #answered questions:
        if( $answeredQ < $minAweredQ ){
            $minAweredQ       = $answeredQ;
            $nrOfMinAnsweredQ   = 1;
        }
        elsif( $answeredQ == $minAweredQ ){
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
    say("Minimum " . ("\t" x 4) . ": $minAweredQ ($nrOfMinAnsweredQ student" . ($nrOfMinAnsweredQ != 1 ? "s" : "") . ")");
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