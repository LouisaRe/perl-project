package Util::ExamChecking;

use v5.34;
use strict;
use experimental 'signatures';
use Exporter::Attributes 'import';

use Text::Trim;
use Lingua::StopWords qw(getStopWords);
use Text::Levenshtein qw(distance);

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::IO;

################################################################################


sub checkExamFiles : Exported ($examFiles_ref, $solutionAllQAs_ref){

    my %examResults = ();
    my %wrongAnsweredQ = ();

    FILE:
    for my $file (@{$examFiles_ref}){

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
                push( $examResults{"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Missing question \t\t: $solQ\n");
                if($minQDistance/length($solQNormalized) <= 0.1){
                    push( $examResults{"missedEl"} -> {$file} -> @* , "            Used instead \t\t: ${$bestFitSection}{'question'}\n");
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
                        push( $examResults{"missedEl"} -> {$file} -> @* , "Section $sectNrSol - Missing answer \t\t: $sa\n");
                        if($minADistance/length($solANormalized) <= 0.1){
                            push( $examResults{"missedEl"} -> {$file} -> @* , "            Used instead \t\t: $bestFitA\n");
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
                            push( $wrongAnsweredQ{$file} -> {$sectNrSol} -> @*, $sa);
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
        $examResults{"correctAns"}{$file}    = $correctCounter;
        $examResults{"correctAns"}{"total"} += $correctCounter;
        $examResults{"answeredQ"}{$file}     = $answeredQCounter;
        $examResults{"answeredQ"}{"total"}  += $answeredQCounter;       
    }

    return (\%examResults, \%wrongAnsweredQ);
}


#################################################################
# Internal subroutines

sub findBestMatchingExamQuestion($allQAs_ref, $solQNormalized){

    my $minQDistance    = 1000;
    my $bestFitSection;

    EXAM_SECTION:
    for my $sectNrExam (1 .. scalar(keys %{$allQAs_ref})){

        my $examQNormalized = normalize(${$allQAs_ref}{"section$sectNrExam"}{"question"});
        my $distance        = distance($solQNormalized, $examQNormalized);

        if($distance < $minQDistance){
            $minQDistance   = $distance;
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
        my $distance        = distance($solANormalized, $examANormalized);

        if($distance < $minADistance){
            $minADistance   = $distance;
            $bestFitA       = $ea;
        }

        last EXAM_ANSWER if($distance == 0);

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

sub normalize($text){
    if($text){
        # to lowercase + remove spaces at start/end
        my $result = trim(lc($text));

        # remove stopwords
        my $stopwords = getStopWords('en'); # https://metacpan.org/pod/Lingua::StopWords
        $result = join('', grep( { !$stopwords->{$_} } split(/(\W+?)/, $result)  )  );

        # remove spaces
        $result =~ s{\s\s+}{ }xg;
        
        return $result;
    }else{
        return "";
    }
}

1; #return true at the end of the module