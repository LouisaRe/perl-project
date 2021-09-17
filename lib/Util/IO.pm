package Util::IO;

use v5.34;
use strict;
use experimental 'signatures';
use Text::Trim; #https://metacpan.org/pod/Text::Trim
use Exporter::Attributes 'import';

################################################################################
#Exported Subroutines

# This subroutine reads in a given file and returns:
# @return: @examFileLines - an array with converted lines for the exam file 
#                          (If the second parameter is 0 the lines for the exam file won't be created.)
# @return: %allQAs - a hash that stores all sections with the question-text and the answers (text and if checked)
#                           Hash structure:
#                           {   sectionNR => {  question => text,
#                                               answers  => {  text => isChecked,
#                                                              text => isChecked,
#                                                               ...
#                                                           }
#                                             },
#                               ... 
#                           }
sub readFile : Exported ($file, $createExamFileLines = 1){
    
    #############################
    #PROPERTIES

    # return properties
    my @examFileLines       = (); # all lines for an empty student exam (with random answer order)
    my %allQAs              = (); # all sections with the question-text and the answers (text and if checked)

    # helper properties
    my $introText           = 1; # flag that is set to 0 if the intro section is read in.
    my $sectionNumber       = 1; 
    my $answerNumber        = 1;
    my %currentAnswerSet    = (); # all answer-texts of the current section
    my $lastLine; # "sectionEnd" / "answer" / "question"
    my $lastAnswerText      = "";

    # regex
    state $SECTION_END_REGEX = qr{ ^ _+ $ }xms;
    state $ANSWER_REGEX      = qr{ ^ \s* \[ .* \] }xms;
    state $QUESTION_REGEX    = qr{ ^ [0-9]+ [[:punct:]] .* $}xms;
    state $CONTINUE_REGEX    = qr{ .* \w .* }xms;

    #############################

    open(my $f, '<', $file) or die "$file: $!";

    LINE:
    while(my $line = readline($f)){
        #intro text
        if($introText){
            push(@examFileLines, $line) if $createExamFileLines;
            if(trim($line) =~ $SECTION_END_REGEX){ #end of intro-section
                $introText = 0;
                $lastLine = "sectionEnd";
            }
        }

        #read and save new answer
        elsif($line =~ $ANSWER_REGEX){
            $lastAnswerText = readAndSaveNewAnswer(\%currentAnswerSet, \$line, \$answerNumber, \$sectionNumber , \%allQAs);
            $lastLine = "answer";
        }
        #read and save rest of previous answer (if answer is longer than 1 line)
        elsif(trim($line) =~ $CONTINUE_REGEX && not(trim($line) =~ $SECTION_END_REGEX) && $lastLine eq "answer"){ 
            updatelastAnswer(\%currentAnswerSet, \$line, \$answerNumber, \$sectionNumber , \%allQAs, $lastAnswerText);
            $lastLine = "answer";
        }

        #print lines
        else{
            pushAllPossibleAnswersToExamFileLines(\%currentAnswerSet, \@examFileLines, $createExamFileLines);
            push(@examFileLines, $line) if $createExamFileLines;
            if(trim($line) =~ $SECTION_END_REGEX){ #end of current question-section
                $sectionNumber++;
                $answerNumber = 1;
                $lastLine = "sectionEnd";
            }
            #question
            elsif($line =~ $QUESTION_REGEX){
                $line =~ s{\n}{}xg; #delete \n
                $allQAs{"section".$sectionNumber}{"question"} = $line;
                $lastLine = "question";
            }
            #read and save rest of previous question (if question is longer than 1 line)
            elsif(trim($line) =~ $CONTINUE_REGEX && $lastLine eq "question"){ 
                $allQAs{"section".$sectionNumber}{"question"} .= " ".trim($line);
                $lastLine = "question";
            }
        }
    }

    close($f);

    return (\@examFileLines, \%allQAs);
}


#This subroutine writes the content of the @examFileLines into the file
sub createExamFile : Exported ($file, @examFileLines){

    open(my $f, '>', $file  ) or die "$file: $!";

    for my $line (@examFileLines){
        print({$f} $line);
    }

    close($f);

    say "$file has been created.";
}

#################################################################
# Internal subroutines

# this subroutine pushes all possible answers for the current section into the array examFileLines 
# in random order and with empty brackets.
sub pushAllPossibleAnswersToExamFileLines($currentAnswerSet_ref, $examFileLines_ref, $createExamFileLines){
    if(keys(%{$currentAnswerSet_ref}) != 0){
        if($createExamFileLines){
            ANSWER:
            for my $answer (keys %{$currentAnswerSet_ref}){
                push(@{$examFileLines_ref}, "\t[ ] ${$currentAnswerSet_ref}{$answer}\n");
            }
        }
        %{$currentAnswerSet_ref} = ();
    }
}

# This subroutine stores the answer text and whether the answer was checked or not in the following structures:
# %currentAnswerSet and %allQAs.
# @returns: $answerText
sub readAndSaveNewAnswer($currentAnswerSet_ref, $line_ref, $answerNumber_ref, $sectionNumber_ref, $allQAs_ref){
    #split bracket and answer text
    my $bracket     = ${$line_ref};
    $bracket        =~ s{^\] .*}{\]}xms; #delete text after bracket
    $bracket        = trim($bracket);
    my $answerText  = ${$line_ref};
    $answerText     =~ s{\[ .*? \]}{}xg; #delete bracket
    $answerText     = trim($answerText);
    
    state $ANSWER_IS_CHECKED_REGEX = qr{ ^ \[ \S+? \] }xms;

    #save answerText (key) and if it isChecked (value) in structures
    ${$currentAnswerSet_ref}{"answer".${$answerNumber_ref}++} = $answerText;
    $allQAs_ref -> {"section".${$sectionNumber_ref}} -> {"answers"} -> {$answerText} = ($bracket =~ $ANSWER_IS_CHECKED_REGEX);
    return $answerText; #for further use, if the answer text is not yet finished
}

# This subroutine updates the last answer with the rest of the answer (which was on a new line)
# %currentAnswerSet and %allQAs are updated.
sub updatelastAnswer($currentAnswerSet_ref, $line_ref, $answerNumber_ref, $sectionNumber_ref, $allQAs_ref, $lastAnswerText){
    my $answerText = trim(${$line_ref});
    my $answerIsChecked = $allQAs_ref -> {"section".${$sectionNumber_ref}} -> {"answers"} -> {$lastAnswerText};

    #update structures
    ${$currentAnswerSet_ref}{"answer".(${$answerNumber_ref}-1)} .= " ".$answerText;
    $allQAs_ref -> {"section".${$sectionNumber_ref}} -> {"answers"} -> {$lastAnswerText." ".$answerText} = $answerIsChecked;

    #delete old entry
    delete($allQAs_ref -> {"section".${$sectionNumber_ref}} -> {"answers"} -> {$lastAnswerText});
}

1; #return true at the end of the module