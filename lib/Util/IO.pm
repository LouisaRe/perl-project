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
    my %allAnswers          = ();
    my %allCorrectAnswers   = ();

    # helper properties
    my $introText           = 1;
    my $questionNumber      = 1;
    my $answerNumber        = 1;
    my %currentAnswerSet    = ();

    state $LINE_REGEX       = qr{ ^ _+ $ }xms;
    state $ANSWER_REGEX     = qr{ ^ \s* \[ .* \] }xms;

    LINE:
    while(my $line = readline($f)){
        #intro text
        if($introText){
            push(@examFileLines, $line) if $createExamFileLines;
            if($line =~ $LINE_REGEX){ #end of intro-section
                $introText = 0;
            }
        }

        #read and save new answer
        elsif($line =~ $ANSWER_REGEX){
            readAndSaveNewAnswer(\%currentAnswerSet, \$line, \$answerNumber, \$questionNumber ,\%allCorrectAnswers, \%allAnswers);
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

    return (\@examFileLines, \%allAnswers, \%allCorrectAnswers);
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

sub readAndSaveNewAnswer($currentAnswerSet_ref, $line_ref, $answerNumber_ref, $questionNumber_ref, $allCorrectAnswers_ref, $allAnswers_ref){
    my $bracketsStart   = index(${$line_ref}, "[");
    my $bracketsEnd     = index(${$line_ref}, "]");
    my $bracketSize     = $bracketsEnd - $bracketsStart + 1;
    my $bracket         = trim(substr(${$line_ref}, $bracketsStart, $bracketSize));
    my $answer          = trim(substr(${$line_ref}, $bracketsEnd+1)); #https://metacpan.org/pod/Text::Trim

    state $CORRECT_ANSWER_REGEX = qr{ ^ \[ \S+ \] }xms;
    
    if($bracket =~ $CORRECT_ANSWER_REGEX){ # save correct answer
        $allCorrectAnswers_ref -> {"question".${$questionNumber_ref}} = $answer
        # push(%{$allCorrectAnswers_ref}, $answer);
    }

    ${$currentAnswerSet_ref}{"answer".${$answerNumber_ref}++} = $answer;
    push( $allAnswers_ref -> {"question".${$questionNumber_ref}} -> @*, $answer)
}

1; #return true at the end of the module