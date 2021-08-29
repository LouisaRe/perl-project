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
    
    open(my $ff, '<', $fromFile)     or die "$fromFile: $!";
    open(my $tf, '>', $toFile  )     or die "$toFile: $!";

    my $questionNumber = 1;
    my %currentAnswerSet;
    my $introText = 1;

    while(my $line = readline()){

        #intro text
        if($introText){
            print({$tf} $line);
            if(index($line, "_") == 0){ #end of intro-section
                $introText = 0;
            }
        }

        #read and save new answer
        elsif(index($line, "[") >= 0){
            readAndSaveNewAnswer(\%currentAnswerSet, \$line)
        }

        #print lines
        else{
            printAllPossibleAnswers(\%currentAnswerSet, $tf);
            print({$tf} $line);
            if(index($line, "_") == 0){ #end of current question-section
                $questionNumber++;
            }
        }
    }

    close($ff);
    close($tf);
}


sub printAllPossibleAnswers($currentAnswerSet_ref, $toFile_ref){
    if(keys(%{$currentAnswerSet_ref}) != 0){ 
        for my $b (keys %{$currentAnswerSet_ref}){
            say({$toFile_ref} "\t[ ] ${$currentAnswerSet_ref}{$b}");
        }
        %{$currentAnswerSet_ref} = ();
    }
}

sub readAndSaveNewAnswer($currentAnswerSet_ref, $line_ref){
    state $answerNumber = 0;

    my $bracketsStart   = index(${$line_ref}, "[");
    my $bracketsEnd     = index(${$line_ref}, "]");
    my $bracketSize     = $bracketsEnd - $bracketsStart + 1;
    my $answer          = trim(substr(${$line_ref}, $bracketsEnd+1)); #https://metacpan.org/pod/Text::Trim

    ${$currentAnswerSet_ref}{"answer ".$answerNumber++} = $answer;
}