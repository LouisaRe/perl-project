package Util::IO;

use v5.34;
use strict;
use experimental 'signatures';
use Text::Trim;
use Exporter::Attributes 'import';

################################################################################
#Subroutines

# This function reads in a given file and returns an array with converted 
# lines for the exam file and another array with all correct answers.
# If the second parameter is 0 the lines for the exam file won't be created.
sub readFile : Exported ($file, $createExamFileLines = 1){
    my $f;
    open($f, '<', $file)    or die "$file: $!";
    # return properties
    my @examFileLines       = ();
    my %allQAs              = ();
    # my %allCorrectAnswers   = ();

    # helper properties
    my $introText           = 1;
    my $sectionNumber       = 1;
    my $questionNumber;
    my $answerNumber        = 1;
    my %currentAnswerSet    = ();

    state $SECTIONEND_REGEX = qr{ ^ _+ $ }xms;
    state $ANSWER_REGEX     = qr{ ^ \s* \[ .* \] }xms;
    state $QUESTION_REGEX   = qr{ ^ ([0-9]+) [[:punct:]] .* $}xms; #todo questions that are longer than 1 line

    LINE:
    while(my $line = readline($f)){
        #intro text
        if($introText){
            push(@examFileLines, $line) if $createExamFileLines;
            if($line =~ $SECTIONEND_REGEX){ #end of intro-section
                $introText = 0;
            }
        }

        #read and save new answer
        elsif($line =~ $ANSWER_REGEX){
            readAndSaveNewAnswer(\%currentAnswerSet, \$line, \$answerNumber, \$sectionNumber , \%allQAs);
        }

        #print lines
        else{
            pushAllPossibleAnswers(\%currentAnswerSet, \@examFileLines, $createExamFileLines);
            push(@examFileLines, $line) if $createExamFileLines;
            if($line =~ $SECTIONEND_REGEX){ #end of current question-section
                $sectionNumber++;
                $answerNumber = 1;
            }
            elsif($line =~ $QUESTION_REGEX){
                $questionNumber = $1;
                $allQAs{"section".$questionNumber}{"question"} = $line;
            }
        }
    }

    close($f);

    return (\@examFileLines, \%allQAs);
}


sub pushAllPossibleAnswers($currentAnswerSet_ref, $examFileLines_ref, $createExamFileLines){
    if(keys(%{$currentAnswerSet_ref}) != 0){
            if($createExamFileLines){
                ANSWER:
                for my $key (keys %{$currentAnswerSet_ref}){
                push(@{$examFileLines_ref}, "\t[ ] ${$currentAnswerSet_ref}{$key}\n");
            }
        }
        %{$currentAnswerSet_ref} = ();
    }
}

sub readAndSaveNewAnswer($currentAnswerSet_ref, $line_ref, $answerNumber_ref, $sectionNumber_ref, $allQAs_ref){
    my $bracketsStart   = index(${$line_ref}, "[");
    my $bracketsEnd     = index(${$line_ref}, "]");
    my $bracketSize     = $bracketsEnd - $bracketsStart + 1;
    my $bracket         = trim(substr(${$line_ref}, $bracketsStart, $bracketSize)); #todo: bracket aus regex auslesen

    my $answer          = trim(substr(${$line_ref}, $bracketsEnd+1)); #https://metacpan.org/pod/Text::Trim
    my $correctness     = 0;

    state $CORRECT_ANSWER_REGEX = qr{ ^ \[ \S+ \] }xms;
    
    if($bracket =~ $CORRECT_ANSWER_REGEX){ # save correct answer
        $correctness = 1;
    }

    ${$currentAnswerSet_ref}{"answer".${$answerNumber_ref}++} = $answer;

    $allQAs_ref -> {"section".${$sectionNumber_ref}} -> {"answers"} -> {$answer} = $correctness;
}

1; #return true at the end of the module

# section_-> {
#     question => ...,

    # answers -> {
                # text => correctness,
                # text => correctness
    # },

# }