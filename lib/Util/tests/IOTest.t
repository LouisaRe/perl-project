use 5.34.0;
use warnings;

use Test::More;

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::IO;

plan(tests => 32);

#####################################################

#given:
my ($examFileLines_ref, $allQAs_ref) = readFile("../../../masterFiles/master_file_1.txt");

#####################################################
# Test 1: test $allQAs_ref

#expected:
my $EXPECTED_ALLQAS_REF = {
    section1 => {
        question    =>  "1. The name of this class is:",
        answers     => {
                        "Introduction to Perl for Programmers"                            => 1,
                        "Introduction to Perl for Programmers and Other Crazy People"     => '',
                        "Introduction to Programming for Pearlers"                        => '',
                        "Introduction to Aussies for Europeans"                           => '',
                        "Introduction to Python for Slytherins"                           => ''
                        }
    },
    section2        => {
        question    =>  "2. The lecturer for this class is:",
        answers     => {
                        "Dr Theodor Seuss Geisel"   => '',
                        "Dr Sigmund Freud"          => '',
                        "Dr Victor von Doom"        => '',
                        "Dr Damian Conway"          => 1,
                        "Dr Who"                    => ''
                        }
    },
    section3        => {
        question    =>  "3. The correct way to answer each question is:",
        answers     => {
                        "To put an X in every box, except the one beside the correct answer"    => '',
                        "To put an smiley-face emoji in the box beside the correct answer"      => '',
                        "To delete the box beside the correct answer"                           => '',
                        "To delete the correct answer"                                          => '',
                        "To put an X in the box beside the correct answer"                      => 1
                        }
    }
};

# TEST (1) hash allQAs:
is_deeply($allQAs_ref, $EXPECTED_ALLQAS_REF, "hash structure of allQAs (contains all sections with question and answers and if the answer is checked)");

#####################################################
# Test 2 - 32: test $examFileLines_ref

#expected:
my @EXPECTED_EXAMFILELINES = split(/(?<=\n)/,
    "Complete this exam by placing an 'X' in the box beside each correct
answer, like so:

    [ ] This is not the correct answer
    [ ] This is not the correct answer either
    [ ] This is an incorrect answer
    [X] This is the correct answer
    [ ] This is an irrelevant answer

Scoring: Each question is worth 2 points.
         Final score will be: SUM / 10

Warning: Each question has only one correct answer. Answers to
         questions for which two or more boxes are marked with an 'X'
         will be scored as zero.

________________________________________________________________________________

1. The name of this class is:
\t[ ] Introduction to Perl for Programmers
\t[ ] Introduction to Perl for Programmers and Other Crazy People
\t[ ] Introduction to Programming for Pearlers
\t[ ] Introduction to Aussies for Europeans
\t[ ] Introduction to Python for Slytherins
________________________________________________________________________________
2. The lecturer for this class is:
\t[ ] Dr Theodor Seuss Geisel
\t[ ] Dr Sigmund Freud
\t[ ] Dr Victor von Doom
\t[ ] Dr Damian Conway
\t[ ] Dr Who

________________________________________________________________________________


3. The correct way to answer each question is:

\t[ ] To put an X in every box, except the one beside the correct answer
\t[ ] To put an smiley-face emoji in the box beside the correct answer
\t[ ] To delete the box beside the correct answer
\t[ ] To delete the correct answer
\t[ ] To put an X in the box beside the correct answer

________________________________________________________________________________
"
);

# sort because answers are in random order
my $sortedExamFileLines_ref;
@{$sortedExamFileLines_ref}       = sort(@{$examFileLines_ref});
my @SORTED_EXPECTED_EXAMFILELINES = sort(@EXPECTED_EXAMFILELINES);


# TEST (2) sorted arrays:
is_deeply($sortedExamFileLines_ref, \@SORTED_EXPECTED_EXAMFILELINES, "all exam file lines are present");

# TEST (3-32) lines that shouldn't be in random order:
for my $line (0..18,24..25,31..36,42..44){
    is(@{$examFileLines_ref}[$line], @EXPECTED_EXAMFILELINES[$line], "exam file line $line is in correct position (all lines except answers)");
}

#####################################################

done_testing();