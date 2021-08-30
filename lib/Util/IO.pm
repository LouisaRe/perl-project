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
    
    open(my $f, '<', $file)    or die "$file: $!";

    state @examFileLines    = ();
    state @allCorrectAnswers;

    state $introText        = 1;
    state $questionNumber   = 1;
    state $answerNumber     = 1;
    state %currentAnswerSet;

    state $LINE_REGEX       = qr{ ^ _+ $ }xms;
    state $ANSWER_REGEX     = qr{ ^ \s* \[ .* \] }xms;

    while(my $line = readline()){
        #intro text
        if($introText){
            push(@examFileLines, $line) if $createExamFileLines;
            if($line =~ $LINE_REGEX){ #end of intro-section
                $introText = 0;
            }
        }

        #read and save new answer
        elsif($line =~ $ANSWER_REGEX){
            readAndSaveNewAnswer(\%currentAnswerSet, \$line, \$answerNumber, \@allCorrectAnswers);
        }

        #print lines
        else{
            pushAllPossibleAnswers(\%currentAnswerSet, \@examFileLines, $createExamFileLines);
            push(@examFileLines, $line) if $createExamFileLines;
            if($line =~ $LINE_REGEX){ #end of current question-section
                $questionNumber++;
                $answerNumber = 1;
            }
        }
    }

    close($f);

    return (\@examFileLines, \@allCorrectAnswers);
}


sub pushAllPossibleAnswers($currentAnswerSet_ref, $examFileLines_ref, $createExamFileLines){
    if(keys(%{$currentAnswerSet_ref}) != 0){
            if($createExamFileLines){
                for my $key (keys %{$currentAnswerSet_ref}){
                push(@{$examFileLines_ref}, "\t[ ] ${$currentAnswerSet_ref}{$key}\n");
            }
        }
        %{$currentAnswerSet_ref} = ();
    }
}

sub readAndSaveNewAnswer($currentAnswerSet_ref, $line_ref, $answerNumber_ref, $allCorrectAnswers_ref){
    my $bracketsStart   = index(${$line_ref}, "[");
    my $bracketsEnd     = index(${$line_ref}, "]");
    my $bracketSize     = $bracketsEnd - $bracketsStart + 1;
    my $bracket         = trim(substr(${$line_ref}, $bracketsStart, $bracketSize));
    my $answer          = trim(substr(${$line_ref}, $bracketsEnd+1)); #https://metacpan.org/pod/Text::Trim

    state $CORRECT_ANSWER_REGEX = qr{ ^ \[ \S+ \] }xms;
    
    if($bracket =~ $CORRECT_ANSWER_REGEX){ # save correct answer
        push(@{$allCorrectAnswers_ref}, $answer);
    }

    ${$currentAnswerSet_ref}{"answer".${$answerNumber_ref}++} = $answer;
}

1; #return true at the end of the module