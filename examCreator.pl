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

    my %solutions;
    my $questionNumber = 1;
    my $answerNumber = 0;
    my %currentAnswerSet;

    my $infoText = 1;

    while(my $line = readline()){
        #Intro-Text
        if($infoText){
            print({$tf} $line);
            if(index($line, "_") >= 0){
                $infoText = 0;
            }
        }
        #neue Frage
        elsif(index($line, "_") >= 0){
            #vorherige Antworten printen
            if($questionNumber != 0 and keys(%currentAnswerSet) != 0){
                #currentAnswerSet printen (da hash -> automatisch)
                for my $a (keys %currentAnswerSet){
                    say({$tf} "\t[ ] $currentAnswerSet{$a}");
                }
                %currentAnswerSet = ();
            }

            $questionNumber++;

            print({$tf} $line); # _____ printen
        }
        #neue Antwort
        elsif(index($line, "[") >= 0){
            my $bracketsStart   = index($line, "[");
            my $bracketsEnd     = index($line, "]");
            my $bracketSize     = $bracketsEnd - $bracketsStart + 1;

            my $correctness     = trim(substr($line, $bracketsStart, $bracketSize));
            my $answer          = trim(substr($line, $bracketsEnd+1)); #https://metacpan.org/pod/Text::Trim
            
            $currentAnswerSet{"answer ".$answerNumber++} = $answer;
            $solutions{$questionNumber} = "Hallo";
        }
        #nur übertragen
        else{
            if(keys(%currentAnswerSet) != 0){ #Linie nach Fragenset -> erst Fragenset printen
                for my $a (keys %currentAnswerSet){
                    say({$tf} "\t[ ] $currentAnswerSet{$a}");
                }
                %currentAnswerSet = ();
            } 
            print({$tf} $line);
        }
    }


    close($ff);
    close($tf);
}