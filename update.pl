#!/usr/bin/perl

use strict;
use feature 'say';

$| = 1;

require './_subs.pl';

our $DATA_FOLDER = $ENV{LOCAL_DIR};
my $update_base = $ARGV[1] || !(-e "$DATA_FOLDER/department_tree.json" && -e "$DATA_FOLDER/courses.json");

if($update_base) {
	fetchBaseData(
		sub {
			my($ccnt,$dcnt) = @_;
			print "\rfetching colleges & departments list... (cole: $ccnt, dept: $dcnt)";
		}
	); say "OK";

	fetchCourseData_OldApi(
		sub {
			my($c,$a) = @_;
			print "\rupdating course... ($c/$a)";
		}
	); say "OK";
	fetchCourseExtra_NewApi(
		sub {
			my($c,$a) = @_;
			print "\rupdating extra info... ($c/$a)";
		}
	); say "OK";
} else {
	loadBaseData("$DATA_FOLDER/department_tree.json");

	loadCourseData("$DATA_FOLDER/courses.json");
	fetchCourseData_OldApi(
		sub {
			my($c,$a) = @_;
			print "\rupdating course... ($c/$a)";
		}
	); say "OK";
}

saveBaseData("$DATA_FOLDER/department_tree.json");
saveCourseData("$DATA_FOLDER/courses.json");
