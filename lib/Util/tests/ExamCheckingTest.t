use 5.34.0;
use warnings;

use Test::More;

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::ExamChecking;
use Util::IO;


plan(tests => 5);

#####################################################

#given:
my   $solutionFile         =  "../../../masterFiles/master_file_1.txt";
my   @examFiles            = ("../../../exam1/student_3correct_swaped_sections.txt",
                              "../../../exam1/student_3correct_perfect.txt",
                              "../../../exam1/student_3correct_good_but_edited_answers.txt",
                              "../../../exam1/student_3correct_excellent.txt",
                              "../../../exam1/student_2correct.txt",
                              "../../../exam1/student_2correct_because_question_deleter.txt",
                              "../../../exam1/student_1correct_swaped_questions.txt",
                              "../../../exam1/student_1correct_deleted2sections.txt",
                              "../../../exam1/student_1correct_because_deleter.txt",
                              "../../../exam1/student_0correct_lazy_no_checks.txt",
                              "../../../exam1/student_0correct_horrible.txt",
                              "../../../exam1/student_0correct_horrible_cheater.txt");

my ( $examFileLines_ref,                                    #this prop is tested in IOTest.t
     $solutionAllQAs_ref )  = readFile($solutionFile);      #this prop is tested in IOTest.t

my ( $examResults_ref, 
     $wrongAnsweredQ_ref )  = checkExamFiles(\@examFiles, $solutionAllQAs_ref);


#####################################################
# Test 1 - 4: test $allQAs_ref

my $EXPECTED_EXAMRESULTS_REF = {
      answeredQ  => {
                      "../../../exam1/student_0correct_horrible.txt"                 => 3,
                      "../../../exam1/student_0correct_horrible_cheater.txt"         => 3,
                      "../../../exam1/student_0correct_lazy_no_checks.txt"           => 0,
                      "../../../exam1/student_1correct_because_deleter.txt"          => 3,
                      "../../../exam1/student_1correct_deleted2sections.txt"         => 1,
                      "../../../exam1/student_1correct_swaped_questions.txt"         => 3,
                      "../../../exam1/student_2correct.txt"                          => 3,
                      "../../../exam1/student_2correct_because_question_deleter.txt" => 2,
                      "../../../exam1/student_3correct_excellent.txt"                => 3,
                      "../../../exam1/student_3correct_good_but_edited_answers.txt"  => 3,
                      "../../../exam1/student_3correct_perfect.txt"                  => 3,
                      "../../../exam1/student_3correct_swaped_sections.txt"          => 3,
                      "total"                                                        => 30,
                    },
      correctAns => {
                      "../../../exam1/student_0correct_horrible.txt"                 => 0,
                      "../../../exam1/student_0correct_horrible_cheater.txt"         => 0,
                      "../../../exam1/student_0correct_lazy_no_checks.txt"           => 0,
                      "../../../exam1/student_1correct_because_deleter.txt"          => 1,
                      "../../../exam1/student_1correct_deleted2sections.txt"         => 1,
                      "../../../exam1/student_1correct_swaped_questions.txt"         => 1,
                      "../../../exam1/student_2correct.txt"                          => 2,
                      "../../../exam1/student_2correct_because_question_deleter.txt" => 1,
                      "../../../exam1/student_3correct_excellent.txt"                => 3,
                      "../../../exam1/student_3correct_good_but_edited_answers.txt"  => 3,
                      "../../../exam1/student_3correct_perfect.txt"                  => 3,
                      "../../../exam1/student_3correct_swaped_sections.txt"          => 3,
                      "total"                                                        => 18,
                    },
      missedEl   => {
                      "../../../exam1/student_0correct_horrible_cheater.txt"         => ["Section 2 - Missing answer \t\t: Dr Damian Conway\n"],
                      "../../../exam1/student_1correct_because_deleter.txt"          => [
                                                                                          "Section 2 - Missing question \t\t: 2. The lecturer for this class is:\n",
                                                                                          "            Used instead \t\t: 2. The lecturer for this class:\n",
                                                                                          "Section 2 - Missing answer \t\t: Dr Theodor Seuss Geisel\n",
                                                                                          "Section 2 - Missing answer \t\t: Dr Who\n",
                                                                                        ],
                      "../../../exam1/student_1correct_deleted2sections.txt"         => [
                                                                                          "Section 2 - Missing question \t\t: 2. The lecturer for this class is:\n",
                                                                                          "Section 3 - Missing question \t\t: 3. The correct way to answer each question is:\n",
                                                                                        ],
                      "../../../exam1/student_1correct_swaped_questions.txt"         => [
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Aussies for Europeans\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Python for Slytherins\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Perl for Programmers and Other Crazy People\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Perl for Programmers\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Programming for Pearlers\n",
                                                                                          "Section 3 - Missing answer \t\t: To put an X in the box beside the correct answer\n",
                                                                                          "Section 3 - Missing answer \t\t: To delete the correct answer\n",
                                                                                          "Section 3 - Missing answer \t\t: To delete the box beside the correct answer\n",
                                                                                          "Section 3 - Missing answer \t\t: To put an smiley-face emoji in the box beside the correct answer\n",
                                                                                          "Section 3 - Missing answer \t\t: To put an X in every box, except the one beside the correct answer\n",
                                                                                        ],
                      "../../../exam1/student_2correct_because_question_deleter.txt" => [
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Perl for Programmers\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Perl for Programmers and Other Crazy People\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Programming for Pearlers\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Aussies for Europeans\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Python for Slytherins\n",
                                                                                          "Section 2 - Missing answer \t\t: Dr Who\n",
                                                                                          "Section 3 - Missing question \t\t: 3. The correct way to answer each question is:\n",
                                                                                        ],
                      "../../../exam1/student_3correct_excellent.txt"                => [
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Aussies for Europeans\n",
                                                                                          "            Used instead \t\t: Introduction to Aussies is ru Europeans\n",
                                                                                          "Section 1 - Missing answer \t\t: Introduction to Programming for Pearlers\n",
                                                                                          "            Used instead \t\t: Introduction to Programming u Pearlers\n",
                                                                                        ],
                      "../../../exam1/student_3correct_good_but_edited_answers.txt"  => [
                                                                                          "Section 3 - Missing answer \t\t: To delete the box beside the correct answer\n",
                                                                                          "            Used instead \t\t: To delete the bix beside the correct answer\n",
                                                                                          "Section 3 - Missing answer \t\t: To delete the correct answer\n",
                                                                                          "Section 3 - Missing answer \t\t: To put an X in the box beside the correct answer\n",
                                                                                          "            Used instead \t\t: To put rt is X in  the box beside the correct answer\n",
                                                                                        ],
                    }
};

# TEST (1) questions:
is_deeply(\%{$examResults_ref -> {"answeredQ"}}, \%{$EXPECTED_EXAMRESULTS_REF -> {"answeredQ"}}, "number of answered questions per file");

# TEST (2) answers:
is_deeply(\%{$examResults_ref -> {"correctAns"}}, \%{$EXPECTED_EXAMRESULTS_REF -> {"correctAns"}}, "number of correct answers per file");


# sort array because missing elements are in random order
EXPECTED_ELEMENTS:
for my $file (keys %{$EXPECTED_EXAMRESULTS_REF -> {"missedEl"}}){
     @{$EXPECTED_EXAMRESULTS_REF -> {"missedEl"} -> {$file}} = sort(@{$EXPECTED_EXAMRESULTS_REF -> {"missedEl"} -> {$file}});
}
GIVEN_ELEMENTS:
for my $file (keys %{$examResults_ref -> {"missedEl"}}){
     @{$examResults_ref -> {"missedEl"} -> {$file}} = sort(@{$examResults_ref -> {"missedEl"} -> {$file}});
}

# TEST (3) sorted missing elements-arrays:
is_deeply(\%{$examResults_ref -> {"missedEl"}}, \%{$EXPECTED_EXAMRESULTS_REF -> {"missedEl"}}, "same missing elements per file");

# TEST (4) overall structure:
is_deeply($examResults_ref, $EXPECTED_EXAMRESULTS_REF, "overall structure of hash examResults (Per file: nr of questions, nr of correct answers, missed elements");


#####################################################
# Test 5 - ..: test $wrongAnsweredQ

my $EXPECTED_WRONG_ANSWERED_Q_REF = {
      "../../../exam1/student_0correct_horrible.txt"         => {
                                                                  1 => [
                                                                         "Introduction to Perl for Programmers and Other Crazy People",
                                                                         "Introduction to Programming for Pearlers",
                                                                       ],
                                                                  2 => ["Dr Theodor Seuss Geisel"],
                                                                  3 => ["To delete the box beside the correct answer"],
                                                                },
      "../../../exam1/student_0correct_horrible_cheater.txt" => {
                                                                  1 => [
                                                                         "Introduction to Perl for Programmers and Other Crazy People",
                                                                       ],
                                                                  2 => ["Dr Theodor Seuss Geisel"],
                                                                  3 => ["To delete the box beside the correct answer"],
                                                                },
      "../../../exam1/student_1correct_because_deleter.txt"  => {
                                                                  1 => ["Introduction to Programming for Pearlers"],
                                                                  3 => ["To delete the correct answer"],
                                                                },
      "../../../exam1/student_2correct.txt"                  => { 3 => ["To delete the correct answer"] }
};

# sort array because wrongly checked answeres are in random order
EXPECTED_WRONG_A:
for my $file (keys %{$EXPECTED_WRONG_ANSWERED_Q_REF}){
     for my $sectNr (keys %{$EXPECTED_WRONG_ANSWERED_Q_REF -> {$file}}){
          @{$EXPECTED_WRONG_ANSWERED_Q_REF -> {$file} -> {$sectNr}} = sort(@{$EXPECTED_WRONG_ANSWERED_Q_REF -> {$file} -> {$sectNr}});
     }
}
GIVEN_WRONG_A:
for my $file (keys %{$wrongAnsweredQ_ref}){
     for my $sectNr (keys %{$wrongAnsweredQ_ref -> {$file}}){
          @{$wrongAnsweredQ_ref -> {$file} -> {$sectNr}} = sort(@{$wrongAnsweredQ_ref -> {$file} -> {$sectNr}});
     }
}

# TEST (5) overall structure:
is_deeply($wrongAnsweredQ_ref, $EXPECTED_WRONG_ANSWERED_Q_REF, "overall structure of hash wrongAnsweredQ (Per file: section, wrongly checked answers in section");

#####################################################

done_testing();