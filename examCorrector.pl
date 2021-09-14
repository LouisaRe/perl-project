#! /usr/bin/env perl

use v5.34;

use warnings;
use diagnostics;
use experimental 'signatures';

use Data::Show;
use Text::Trim;
use Text::Levenshtein qw(distance);
use Lingua::StopWords qw(getStopWords);
use Array::Utils qw(:all);

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::IO;


################################################################################
#Properties

#files
my ($solutionFile, @examFiles)                  = @ARGV;

#read & check all files
my ($examFileLines_ref, $solutionAllQAs_ref)    = readFile($solutionFile, 0);
my ($examResults_ref, $wrongAnsweredQ_ref)      = checkExamFiles();
my $lengthLongestFileName                       = calculateLongestFileName(@examFiles);

#reports
reportResults           (scalar(keys %{$solutionAllQAs_ref}), $examResults_ref, $lengthLongestFileName);
reportCohortPerformence (scalar(keys %{$solutionAllQAs_ref}), $examResults_ref);
reportMissingElements   ($examResults_ref);
reportNotExpected       (scalar(keys %{$solutionAllQAs_ref}), $examResults_ref, $lengthLongestFileName);
reportPossibleMisconduct($wrongAnsweredQ_ref, scalar( %{ %{$solutionAllQAs_ref}{"section1"} -> {"answers"}}), $lengthLongestFileName);

################################################################################
#Subroutines

sub checkExamFiles(){

    my $examResults_ref;
    my $wrongAnsweredQ_ref;

    FILE:
    for my $file (@examFiles){

        my $correctCounter                    = 0;
        my $answeredQCounter                  = 0;
        my ($examFileLines_ref, $allQAs_ref)  = readFile($file, 0);

        ##############################################
        #Question Check

        SOL_SECTION:
        for my $sectNrSol (1 .. scalar(keys %{$solutionAllQAs_ref})){

            my $solQ                            = ${$solutionAllQAs_ref}{'section'.$sectNrSol}{'question'};
            my $solQNormalized                  = normalize($solQ);
            my ($minQDistance, $bestFitSection) = findBestMatchingExamQuestion($allQAs_ref, $solQNormalized);

            # fill missed elements array
            if($minQDistance > 0){
                push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Missing question \t\t: $solQ");
                if($minQDistance/length($solQNormalized) <= 0.1){
                    push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Used instead \t\t: ${$bestFitSection}{'question'}");
                }
            }

            ##############################################
            #Answer Check

            # only look at answers of relevant questions (distance no more than 10% of the length)
            if($minQDistance/length($solQNormalized) <= 0.1){ 

                my %solAOfCurrQ      = % {%{ %{$solutionAllQAs_ref}{"section$sectNrSol"} }{"answers"}};
                my %examAOfCurrQ     = % {%{ $bestFitSection }{"answers"}};
                my $numberCheckedA   = 0;
                my $correctAChecked  = 0;

                SOL_ANSWER:
                for my $sa (keys %solAOfCurrQ){

                    my $solANormalized              = normalize($sa);
                    my ($minADistance, $bestFitA)   = findBestMatchingExamAnswer(\%examAOfCurrQ, $solANormalized);

                    # fill missed elements array
                    if($minADistance > 0){
                        push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Missing answer \t\t: $sa\n");
                        if($minADistance/length($solANormalized) <= 0.1){
                            push($examResults_ref -> {"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Used instead \t\t: $bestFitA\n");
                        }
                    }
                    
                    # Is the correct answer checked?
                    if($minADistance/length($solANormalized) <= 0.1){ 
                        # set correct answer checked flag
                        if($solAOfCurrQ{$sa} == 1 && $examAOfCurrQ{$bestFitA} == 1){
                            $correctAChecked = 1;
                        }
                        # save wrongly checked answer
                        if($solAOfCurrQ{$sa} == 0 && $examAOfCurrQ{$bestFitA} == 1){
                            push( $wrongAnsweredQ_ref -> {$file} -> {$sectNrSol} -> @*, $sa);
                        }
                    }
                }

                $numberCheckedA += countCheckedAnswersPerSection(\%examAOfCurrQ);

                # award points for this section
                if($correctAChecked && $numberCheckedA == 1){
                    $correctCounter++;
                }

                # update additional information
                if($numberCheckedA > 0){
                    $answeredQCounter++;
                }
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

    return ($examResults_ref, $wrongAnsweredQ_ref);
}


sub findBestMatchingExamQuestion($allQAs_ref, $solQNormalized){

    my $minQDistance    = 1000;
    my $bestFitSection;

    EXAM_SECTION:
    for my $sectNrExam (1 .. scalar(keys %{$allQAs_ref})){

        my $examQNormalized = normalize(${$allQAs_ref}{"section$sectNrExam"}{"question"});
        my $distance        = calculateDistance($solQNormalized, $examQNormalized);

        if($distance < $minQDistance){
            $minQDistance = $distance;
            $bestFitSection = ${$allQAs_ref}{"section$sectNrExam"};
        }

        last EXAM_SECTION if($distance == 0);
        
    }
    return ($minQDistance, $bestFitSection);
}


sub findBestMatchingExamAnswer($examAOfCurrQ_ref, $solANormalized){

    my $minADistance    = 1000;
    my $bestFitA;

    EXAM_ANSWER:
    for my $ea (keys %{$examAOfCurrQ_ref}){

        my $examANormalized = normalize($ea);
        my $ansDistance     = calculateDistance($solANormalized, $examANormalized);

        if($ansDistance < $minADistance){
            $minADistance = $ansDistance;
            $bestFitA = $ea;
        }

        last EXAM_ANSWER if($ansDistance == 0);

    }
    return ($minADistance, $bestFitA);
}


sub countCheckedAnswersPerSection($examAOfCurrQ_ref){

    my $numberCheckedA = 0;

    EXAM_ANSWER:
    for my $ea (keys %{$examAOfCurrQ_ref}){
        if(%{$examAOfCurrQ_ref}{$ea} == 1){
            $numberCheckedA++;
        }
    }

    return $numberCheckedA;
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

sub reportResults($totalQuestions, $examResults_ref, $lengthLongestFileName){

    say("\n________RESULTS________\n");

    # print results
    for my $file (@examFiles){
        say(equalLength($file, $lengthLongestFileName)." \t: ".${$examResults_ref}{'correctAns'}{$file}."/$totalQuestions");
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
sub reportNotExpected($totalQuestions, $examResults_ref, $lengthLongestFileName){

    say("________BELOW EXPECTATION________ \n");

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
            say( equalLength($file, $lengthLongestFileName) ." \t: ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions (not passed -> reached grade: " . sprintf("%.2f", $grade) . ")" );
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

sub reportPossibleMisconduct($wrongAnsweredQ_ref, $nrOfAPerQ, $lengthLongestFileName){
    say("\n________POSSIBLE ACADEMIC MISCONDUCT________ \nnumber of same wrong answers (cheating probability in %)\n");
    
    my $remainingWrongAnsweredQ_ref = {%$wrongAnsweredQ_ref};
    my $noCheating = 1;
    my $nrOfSameWrongA = 0;

    CURRENT_FILE:
    for my $currFile ( keys %{$wrongAnsweredQ_ref} ){

        delete($remainingWrongAnsweredQ_ref -> {$currFile});

        COMPAIR_FILE:
        for my $compairFile ( keys %{$remainingWrongAnsweredQ_ref} ){

            $nrOfSameWrongA = 0;
            
            CURRENT_SECTION:
            for my $currSection ( keys % {$wrongAnsweredQ_ref -> {$currFile}} ){


                COMPAIR_SECTION:
                for my $compairSection ( keys % {$remainingWrongAnsweredQ_ref -> {$compairFile}} ){

                    if($currSection eq $compairSection){

                        if( !array_diff($wrongAnsweredQ_ref -> {$currFile} -> {$currSection} -> @*, $remainingWrongAnsweredQ_ref -> {$compairFile} -> {$compairSection} -> @*) ) {
                            $nrOfSameWrongA++;
                            $noCheating = 0;
                        }
                    }
                }
            }

            my $nCurrent = scalar( % {$wrongAnsweredQ_ref -> {$currFile}} );
            my $nCompair = scalar (% {$remainingWrongAnsweredQ_ref -> {$compairFile}} );
            my $x = $nrOfSameWrongA; 
            my $p = 1/($nrOfAPerQ-1);

            if($nrOfSameWrongA != 0){
                say("     ".equalLength($currFile, $lengthLongestFileName) ."\t $nrOfSameWrongA (". calculateCheatingProbability($x, $nCurrent, $p) ."%)\n"
                ." and ".equalLength($compairFile, $lengthLongestFileName) ."\t $nrOfSameWrongA (". calculateCheatingProbability($x, $nCompair, $p) ."%)\n");
            }
        }
    }

    if($noCheating){
        say "No one seems to have cheated :)";
    }
}

sub calculateCheatingProbability($x, $n, $p){
    my $k = $x;
    my $kWithMaxP = int(($n+1)*$p);
    my $result;
    if($k <= $kWithMaxP){
        $result = binomialDistribution($x, $n, $p);
    }else{
        $result = 1-binomialDistribution($x, $n, $p);
    }
    return sprintf( "%.1f" ,$result*100);
}

sub binomialDistribution($x, $n, $p){
    my $k = $x;
    return binomial($n, $k) * ($p**$k) * ((1 - $p)**($n-$k));
}

sub binomial($n, $k) { #https://rosettacode.org/wiki/Evaluate_binomial_coefficients#Perl
    my $r = 1;

    for my $koeff (1 .. $k) { 
        $r *= $n--; 
        $r /= $koeff;
    }
    return $r;
}

sub equalLength($string, $length){
    $string .= (" " x ($length - length($string)));
    return $string; 
}

sub calculateLongestFileName(@examFiles){
    my $lengthLongestName = 0;
    for my $file (@examFiles){
        if(length($file) > $lengthLongestName){
            $lengthLongestName = length($file);
        }
    }
    return $lengthLongestName;
}
