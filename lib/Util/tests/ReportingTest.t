use 5.34.0;
use warnings;
use experimental 'signatures';

use Test::More;

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::ExamChecking;
use Util::IO;
use Util::Reporting;

plan(tests => 5);

#####################################################
# GIVEN:

my   $solutionFile         =  "testingFiles/masterFiles/master_file_1.txt";
my   @examFiles            = ("testingFiles/exam1/student_3correct_swaped_sections.txt",
                              "testingFiles/exam1/student_3correct_perfect.txt",
                              "testingFiles/exam1/student_3correct_good_but_edited_answers.txt",
                              "testingFiles/exam1/student_3correct_excellent.txt",
                              "testingFiles/exam1/student_2correct.txt",
                              "testingFiles/exam1/student_1correct_because_question_deleter.txt",
                              "testingFiles/exam1/student_1correct_swaped_questions.txt",
                              "testingFiles/exam1/student_1correct_deleted2sections.txt",
                              "testingFiles/exam1/student_1correct_because_deleter.txt",
                              "testingFiles/exam1/student_0correct_lazy_no_checks.txt",
                              "testingFiles/exam1/student_0correct_horrible.txt",
                              "testingFiles/exam1/student_0correct_horrible_cheater.txt");

my ( $examFileLines_ref,                                    #this prop is tested in IOTest.t
     $solutionAllQAs_ref )  = readFile($solutionFile);      #this prop is tested in IOTest.t

my ( $examResults_ref,                                                              #this prop is tested in ExamCheckingTest.t
     $wrongAnsweredQ_ref )  = checkExamFiles(\@examFiles, $solutionAllQAs_ref);     #this prop is tested in ExamCheckingTest.t

my   $lengthLongestFileName  = calculateLongestFileName(\@examFiles);
my   $totalQuestions         = scalar(keys %{$solutionAllQAs_ref});


sub removeHorizontalSpaces($array_ref){
    for my $r (@{$array_ref}){
        $r =~ s{\h}{}g;
    }
}

#####################################################
# Test 1: test report results

my @EXPECTED_RESULTS = (
"",
"________RESULTS________",
"",
"testingFiles/exam1/student_3correct_swaped_sections.txt         \t: 3/3",
"testingFiles/exam1/student_3correct_perfect.txt                 \t: 3/3",
"testingFiles/exam1/student_3correct_good_but_edited_answers.txt \t: 3/3",
"testingFiles/exam1/student_3correct_excellent.txt               \t: 3/3",
"testingFiles/exam1/student_2correct.txt                         \t: 2/3",
"testingFiles/exam1/student_1correct_because_question_deleter.txt\t: 1/3",
"testingFiles/exam1/student_1correct_swaped_questions.txt        \t: 1/3",
"testingFiles/exam1/student_1correct_deleted2sections.txt        \t: 1/3",
"testingFiles/exam1/student_1correct_because_deleter.txt         \t: 1/3",
"testingFiles/exam1/student_0correct_lazy_no_checks.txt          \t: 0/3",
"testingFiles/exam1/student_0correct_horrible.txt                \t: 0/3",
"testingFiles/exam1/student_0correct_horrible_cheater.txt        \t: 0/3");


# get output of report
my $output;
open(my $outputFileHandle, '>', \$output) or die;
my $oldFileHandle = select $outputFileHandle;
reportResults(\@examFiles, $totalQuestions, $examResults_ref, $lengthLongestFileName);
select $oldFileHandle;
close $outputFileHandle;

#remove horizontal spaces and sort (order is not important for the result)
my @results = sort(split(/\n/, $output));
removeHorizontalSpaces(\@results);
@EXPECTED_RESULTS = sort(@EXPECTED_RESULTS);
removeHorizontalSpaces(\@EXPECTED_RESULTS);

# TEST (1) result report
is_deeply(\@results, \@EXPECTED_RESULTS, "result report");

#####################################################
# Test 2: test report not expected

my @EXPECTED_EXPECTATIONS = (
"",
"________BELOW EXPECTATION________",
"",
"testingFiles/exam1/student_0correct_horrible.txt                     : 0/3 (not passed -> reached grade: 1.00)",
"testingFiles/exam1/student_0correct_horrible_cheater.txt             : 0/3 (not passed -> reached grade: 1.00)",
"testingFiles/exam1/student_0correct_lazy_no_checks.txt               : 0/3 (not passed -> reached grade: 1.00)",
"testingFiles/exam1/student_1correct_because_deleter.txt              : 1/3 (not passed -> reached grade: 2.67)",
"testingFiles/exam1/student_1correct_deleted2sections.txt             : 1/3 (not passed -> reached grade: 2.67)",
"testingFiles/exam1/student_1correct_swaped_questions.txt             : 1/3 (not passed -> reached grade: 2.67)",
"testingFiles/exam1/student_1correct_because_question_deleter.txt     : 1/3 (not passed -> reached grade: 2.67)");


# get output of report
$output = "";
open($outputFileHandle, '>', \$output) or die;
$oldFileHandle = select $outputFileHandle;
reportNotExpected(\@examFiles, $totalQuestions, $examResults_ref, $lengthLongestFileName );
select $oldFileHandle;
close $outputFileHandle;

#remove horizontal spaces and sort (order is not important for the result)
my @expectations = sort(split(/\n/, $output));
removeHorizontalSpaces(\@expectations);
@EXPECTED_EXPECTATIONS = sort(@EXPECTED_EXPECTATIONS);
removeHorizontalSpaces(\@EXPECTED_EXPECTATIONS);

# TEST (2) below expectation report
is_deeply(\@expectations, \@EXPECTED_EXPECTATIONS, "expectations report");

#####################################################
# Test 3: test cohort performace

my @EXPECTED_PERFORMANCE = (
"",
"________COHORT PERFORMENCE________",
"",
"Average number of answered questions    : 2.5",
"Minimum                                 : 0 (1 student)",
"Maximum                                 : 3 (9 students)",
"",
"Average number of correct answers       : 1.5",
"Minimum                                 : 0 (3 students)",
"Maximum                                 : 3 (4 students)");


# get output of reportResults
$output = "";
open($outputFileHandle, '>', \$output) or die;
$oldFileHandle = select $outputFileHandle;
reportCohortPerformence(\@examFiles, $totalQuestions, $examResults_ref);
select $oldFileHandle;
close $outputFileHandle;

#remove horizontal spaces and sort (order is not important for the result)
my @performace = sort(split(/\n/, $output));
removeHorizontalSpaces(\@performace);
@EXPECTED_PERFORMANCE = sort(@EXPECTED_PERFORMANCE);
removeHorizontalSpaces(\@EXPECTED_PERFORMANCE);

# TEST (3) below expectation report
is_deeply(\@performace, \@EXPECTED_PERFORMANCE, "cohort performace report");

#####################################################
# Test 4: test missing elements

my @EXPECTED_MISS_EL = (
"",
"________MISSING ELEMENTS________ ",
"",
"testingFiles/exam1/student_0correct_horrible_cheater.txt:",
"Section 2 - Missing answer              : Dr Damian Conway",
"",
"testingFiles/exam1/student_1correct_because_deleter.txt:",
"Section 2 - Missing question            : 2. The lecturer for this class is:",
"            Used instead                : 2. The lecturer for this class:",
"Section 2 - Missing answer              : Dr Who",
"Section 2 - Missing answer              : Dr Theodor Seuss Geisel",
"",
"testingFiles/exam1/student_1correct_because_question_deleter.txt:",
"Section 1 - Missing answer              : Introduction to Python for Slytherins",
"Section 1 - Missing answer              : Introduction to Perl for Programmers",
"Section 1 - Missing answer              : Introduction to Perl for Programmers and Other Crazy People",
"Section 1 - Missing answer              : Introduction to Programming for Pearlers",
"Section 1 - Missing answer              : Introduction to Aussies for Europeans",
"Section 2 - Missing answer              : Dr Who",
"Section 3 - Missing question            : 3. The correct way to answer each question is:",
"",
"testingFiles/exam1/student_1correct_deleted2sections.txt:",
"Section 2 - Missing question            : 2. The lecturer for this class is:",
"Section 3 - Missing question            : 3. The correct way to answer each question is:",
"",
"testingFiles/exam1/student_1correct_swaped_questions.txt:",
"Section 1 - Missing answer              : Introduction to Python for Slytherins",
"Section 1 - Missing answer              : Introduction to Perl for Programmers",
"Section 1 - Missing answer              : Introduction to Perl for Programmers and Other Crazy People",
"Section 1 - Missing answer              : Introduction to Programming for Pearlers",
"Section 1 - Missing answer              : Introduction to Aussies for Europeans",
"Section 3 - Missing answer              : To put an X in the box beside the correct answer",
"Section 3 - Missing answer              : To put an X in every box, except the one beside the correct answer",
"Section 3 - Missing answer              : To put an smiley-face emoji in the box beside the correct answer",
"Section 3 - Missing answer              : To delete the correct answer",
"Section 3 - Missing answer              : To delete the box beside the correct answer",
"",
"testingFiles/exam1/student_3correct_excellent.txt:",
"Section 1 - Missing answer              : Introduction to Programming for Pearlers",
"            Used instead                : Introduction to Programming u Pearlers",
"Section 1 - Missing answer              : Introduction to Aussies for Europeans",
"            Used instead                : Introduction to Aussies is ru Europeans",
"",
"testingFiles/exam1/student_3correct_good_but_edited_answers.txt:",
"Section 3 - Missing answer              : To delete the box beside the correct answer",
"            Used instead                : To delete the bix beside the correct answer",
"Section 3 - Missing answer              : To delete the correct answer",
"Section 3 - Missing answer              : To put an X in the box beside the correct answer",
"            Used instead                : To put rt is X in  the box beside the correct answer");


# get output of reportResults
$output = "";
open($outputFileHandle, '>', \$output) or die;
$oldFileHandle = select $outputFileHandle;
reportMissingElements(\@examFiles, $examResults_ref);
select $oldFileHandle;
close $outputFileHandle;

#remove horizontal spaces and sort (order is not important for the result)
my @missEl = sort(split(/\n/, $output));
removeHorizontalSpaces(\@missEl);
@EXPECTED_MISS_EL = sort(@EXPECTED_MISS_EL);
removeHorizontalSpaces(\@EXPECTED_MISS_EL);

# TEST (4) missed elements report
is_deeply(\@missEl, \@EXPECTED_MISS_EL, "missed elements report");

#####################################################
# Test 5: test possible misconduct

my @EXPECTED_MISCONDUCT = (
"",
"________POSSIBLE ACADEMIC MISCONDUCT________",
"number of same wrong answers/ wrong answered questions in total (cheating probability in %)",
"",
"     testingFiles/exam1/student_2correct.txt                              1/1 (75.0%)",
" and testingFiles/exam1/student_1correct_because_deleter.txt              1/2 (62.5%)",
"",
"     testingFiles/exam1/student_0correct_horrible_cheater.txt             2/3 (85.9%)",
" and testingFiles/exam1/student_0correct_horrible.txt                     2/3 (85.9%)");


# get output of reportResults
$output = "";
open($outputFileHandle, '>', \$output) or die;
$oldFileHandle = select $outputFileHandle;
reportPossibleMisconduct($wrongAnsweredQ_ref, scalar( %{ %{$solutionAllQAs_ref}{"section1"} -> {"answers"}}), $lengthLongestFileName);
select $oldFileHandle;
close $outputFileHandle;

# remove horizontal spaces and sort (order is not important for the result)
# also remove 'and' because files are computed in random order
my @misConduct = sort(split(/\n/, $output));
removeHorizontalSpaces(\@misConduct);
for my $r (@misConduct){
        $r =~ s{^"and"}{}g;
}

@EXPECTED_MISCONDUCT = sort(@EXPECTED_MISCONDUCT);
removeHorizontalSpaces(\@EXPECTED_MISCONDUCT);
for my $r (@EXPECTED_MISCONDUCT){
        $r =~ s{^"and"}{}g;
}

# TEST (5) possible misconduct report
is_deeply(\@missEl, \@EXPECTED_MISS_EL, "possible misconduct report");

#####################################################

done_testing();