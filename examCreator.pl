#! /usr/bin/env perl

use v5.34;

use warnings;
use diagnostics;
use experimental 'signatures';
use Text::Trim;

################################################################################
#Properties

#time stamp
my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); # https://perldoc.perl.org/functions/localtime
my  $customTimeStamp = sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec); # https://perldoc.perl.org/functions/sprintf

#files
our $solutionFile    = $ARGV[0];
my  $examFile        = "$customTimeStamp-$solutionFile";


createExamFile($solutionFile, $examFile);


################################################################################
#Functions

sub createExamFile($fromFile, $toFile){
    
    open(my $ff, '<', $fromFile)    or die "$fromFile: $!";
    open(my $tf, '>', $toFile  ) or die "$toFile: $!";

    state $questionNumber = 1;
    state $answerNumber = 1;
    state %currentAnswerSet;
    state @allCorrectAnswers;
    state $introText = 1;

    state $LINE_REGEX   = qr{ ^ _+ $ }xms;
    state $ANSWER_REGEX = qr{ ^ \s* \[ .* \] }xms;

    while(my $line = readline()){
        #intro text
        if($introText){
            print({$tf} $line);
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
            printAllPossibleAnswers(\%currentAnswerSet, $tf);
            print({$tf} $line);
            if($line =~ $LINE_REGEX){ #end of current question-section
                $questionNumber++;
                $answerNumber = 1;
            }
        }
    }

    close($ff);
    close($tf);

    return @allCorrectAnswers;
}


sub printAllPossibleAnswers($currentAnswerSet_ref, $toFile_ref){
    if(keys(%{$currentAnswerSet_ref}) != 0){
        for my $key (keys %{$currentAnswerSet_ref}){
            say({$toFile_ref} "\t[ ] ${$currentAnswerSet_ref}{$key}");
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