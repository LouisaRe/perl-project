use 5.34.0;
use warnings;

use Test::More;

use lib "/Users/louisa/fhnw/perl/final_project/lib";
use Util::ExamChecking;

plan(tests => 32);

#####################################################

#given:
my   $solutionFile          = "../../../masterFiles/master_file_1.txt"
     @examFiles             = "../../../exam1/student_*.txt"

my ( $examFileLines_ref, 
     $solutionAllQAs_ref )  = readFile($solutionFile, 0);
my ( $examResults_ref, 
     $wrongAnsweredQ_ref )  = checkExamFiles(\@examFiles, $solutionAllQAs_ref);


#####################################################
# Test 1: test $allQAs_ref



#####################################################

done_testing();