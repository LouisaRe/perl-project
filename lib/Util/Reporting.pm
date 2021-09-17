package Util::Reporting;

use v5.34;
use strict;
use experimental 'signatures';
use Exporter::Attributes 'import';
use Array::Utils qw(:all);

################################################################################
#Exported Subroutines

sub reportResults : Exported ($examFiles_ref, $totalQuestions, $examResults_ref, $lengthLongestFileName){

    say("\n________RESULTS________\n");

    # print results
    for my $file (@{$examFiles_ref}){
        say(equalLength($file, $lengthLongestFileName)." \t: ".${$examResults_ref}{'correctAns'}{$file}."/$totalQuestions");
    }
}


sub reportCohortPerformence : Exported ($examFiles_ref, $totalQuestions, $examResults_ref){

    my ($minAnsweredQ , $nrOfMinAnsweredQ) = ($totalQuestions    , 0);
    my ($maxAnsweredQ , $nrOfMaxAnsweredQ) = (0                  , 0);

    my ($minCorrectA  , $nrOfMinCorrectA)  = ($totalQuestions    , 0);
    my ($maxCorrectA  , $nrOfMaxCorrectA)  = (0                  , 0);

    FILE:
    for my $file (@{$examFiles_ref}){
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

    # for positioning of output
    my $longestString = length("Average number of answered questions ");
    
    say("\n________COHORT PERFORMENCE________\n");

    say(equalLength("Average number of answered questions ", $longestString) ." \t: ". sprintf("%.1f" , ${$examResults_ref}{"answeredQ"}{"total"} / scalar(@{$examFiles_ref}) ));
    say(equalLength("Minimum "                             , $longestString) ." \t: ". "$minAnsweredQ ($nrOfMinAnsweredQ student" . ($nrOfMinAnsweredQ != 1 ? "s" : "") . ")");
    say(equalLength("Maximum "                             , $longestString) ." \t: ". "$maxAnsweredQ ($nrOfMaxAnsweredQ student" . ($nrOfMaxAnsweredQ != 1 ? "s" : "") . ")");

    say(equalLength("\nAverage number of correct answers " , $longestString) ." \t: ". sprintf("%.1f" , ${$examResults_ref}{"correctAns"}{"total"} / scalar(@{$examFiles_ref}) ));
    say(equalLength("Minimum "                             , $longestString) ." \t: ". "$minCorrectA ($nrOfMinCorrectA student" . ($nrOfMinCorrectA != 1 ? "s" : "") . ")");
    say(equalLength("Maximum "                             , $longestString) ." \t: ". "$maxCorrectA ($nrOfMaxCorrectA student" . ($nrOfMaxCorrectA != 1 ? "s" : "") . ")");
}


sub reportMissingElements: Exported ($examFiles_ref, $examResults_ref){
    say("\n________MISSING ELEMENTS________ \n");

    for my $file (@{$examFiles_ref}){
        if($examResults_ref -> {"missedEl"} -> {$file}){
            say "$file:";
            say $examResults_ref -> {"missedEl"} -> {$file} -> @*;
        }
    }
}


# Print out all exams that have a grade < 3.75, and so didn't pass the test.
# In addition print all passed exams that are in the bottom 25% of all exams.
sub reportNotExpected : Exported ($examFiles_ref, $totalQuestions, $examResults_ref, $lengthLongestFileName){

    say("\n________BELOW EXPECTATION________ \n");

    my $nrBottom25 = sprintf('%.0f' , (scalar(@{$examFiles_ref}) / 4)) // 1;
    my @lowestResults = ();
    for my $file (@{$examFiles_ref}){
        push(@lowestResults , ${$examResults_ref}{'correctAns'}{$file} );
    }
    @lowestResults = sort {$a <=> $b} (@lowestResults);
    @lowestResults = splice (@lowestResults, 0, $nrBottom25);

    for my $file (@{$examFiles_ref}){
        my $grade = ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions * 5 + 1;
        if($grade < 3.75){
            say( equalLength($file, $lengthLongestFileName) ." \t: ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions (not passed -> reached grade: " . sprintf("%.2f", $grade) . ")" );
        }else{
            for my $lowR (@lowestResults){
                if($lowR == ${$examResults_ref}{'correctAns'}{$file}){
                    say( equalLength($file, $lengthLongestFileName) ." \t: ${$examResults_ref}{'correctAns'}{$file}/$totalQuestions (bottom 25% of cohort)");
                }
            }
        }
    }
}


sub reportPossibleMisconduct : Exported ($wrongAnsweredQ_ref, $nrOfAPerQ, $lengthLongestFileName){
    say("\n________POSSIBLE ACADEMIC MISCONDUCT________ \nnumber of same wrong answers/ wrong answered questions in total (cheating probability in %)\n");

    my $remainingWrongAnsweredQ_ref = {%$wrongAnsweredQ_ref};
    my $noCheating = 1;
    my $nrOfSameWrongA = 0;

    CURRENT_FILE:
    for my $currFile ( keys %{$wrongAnsweredQ_ref} ){

        delete($remainingWrongAnsweredQ_ref -> {$currFile});

        COMPAIR_FILE:
        for my $compairFile ( keys %{$remainingWrongAnsweredQ_ref} ){

            $nrOfSameWrongA = 0;
            my $nrOfSectCurrFile = scalar(keys %{ $wrongAnsweredQ_ref -> {$currFile}} );
            my $nrOfSectCompairFile = scalar(keys %{ $remainingWrongAnsweredQ_ref -> {$compairFile}} );
            
            CURRENT_SECTION:
            for my $currSection ( keys % {$wrongAnsweredQ_ref -> {$currFile}} ){


                COMPAIR_SECTION:
                for my $compairSection ( keys % {$remainingWrongAnsweredQ_ref -> {$compairFile}} ){

                    if($currSection eq $compairSection){

                        if( !array_diff($wrongAnsweredQ_ref -> {$currFile} -> {$currSection} -> @*, $remainingWrongAnsweredQ_ref -> {$compairFile} -> {$compairSection} -> @*) ) {
                            $nrOfSameWrongA++;
                            $noCheating = 0;
                        }
                        last COMPAIR_SECTION;
                    }
                }
            }

            my $nCurrent = scalar( % {$wrongAnsweredQ_ref -> {$currFile}} );
            my $nCompair = scalar (% {$remainingWrongAnsweredQ_ref -> {$compairFile}} );
            my $x = $nrOfSameWrongA; 
            my $p = 1/($nrOfAPerQ-1);

            if($nrOfSameWrongA != 0){
                say("     ".equalLength($currFile, $lengthLongestFileName) ."\t $nrOfSameWrongA/$nrOfSectCurrFile (". calculateCheatingProbability($x, $nCurrent, $p) ."%)\n"
                ." and ".equalLength($compairFile, $lengthLongestFileName) ."\t $nrOfSameWrongA/$nrOfSectCompairFile (". calculateCheatingProbability($x, $nCompair, $p) ."%)\n");
            }
        }
    }

    if($noCheating){
        say "No one seems to have cheated :)\n";
    }
}

sub calculateLongestFileName : Exported ($examFiles_ref){
    my $lengthLongestName = 0;
    for my $file (@{$examFiles_ref}){
        if(length($file) > $lengthLongestName){
            $lengthLongestName = length($file);
        }
    }
    return $lengthLongestName;
}

#################################################################
# Internal subroutines

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
    if(length($string) < $length){
        $string .= (" " x ($length - length($string)));
    }
    return $string; 
}

1; #return true at the end of the module