use strict;
use feature 'say';
use utf8;
use open qw/:std :utf8/;

use JSON qw/from_json to_json encode_json decode_json/;
use XML::Parser;
use Data::Dumper;
	$Data::Dumper::Indent=1;	# indent mode 1
# use HTML::TreeBuilder::LibXML;						# these two lines are optional
# 	HTML::TreeBuilder::LibXML->replace_original();	# replace HTML::TreeBuilder::XPath->new

use lib './lib';
use DefaultAgent;

our %LANG = (TW => "zh-TW", EN => "en-US");
our $ncu_api_root = "https://api.cc.ncu.edu.tw/course/v1";
our $ncu_api_token = $ENV{NCU_API_TOKEN};
our $ncu_api_header = {
	"Accept-Language" => $LANG{TW},
	"X-NCU-API-TOKEN" => $ncu_api_token,
};
our $course_endpoint = "https://cis.ncu.edu.tw/Course/main/support/course.xml";
our $course_header = {
	"Accept-Language" => $LANG{TW},
};

our %i18nmap = (
	type => {
		required => "必修",
		elective => "選修",
	},
);
our %re_i18nmap; {
	%{$re_i18nmap{$_}} = reverse %{$i18nmap{$_}} for(keys %i18nmap);
}

our %department_tree;
our %courses;

our $agent = new DefaultAgent;
our $xmlparser = new XML::Parser(Style => "Objects");

sub fetchBaseData {
	my($callback) = @_;

	my $error_counter = 0;
	my($ccnt, $dcnt) = (0, 0);

	&$callback($ccnt, $dcnt) if(defined $callback);

	my $resp = $agent->GET($ncu_api_root."/colleges", $ncu_api_header);
	my $result = decode_json($resp->decoded_content);

	for my $r(@$result) {
		my $college_id = $r->{id};
		$department_tree{$college_id} = {
			name => $r->{name}
		};

		my $resp = $agent->GET($ncu_api_root."/colleges/".$college_id."/departments", $ncu_api_header);

		if(!$resp->is_success) {
			say STDERR "HTTP GET error code: ", $resp->code;
			say STDERR "HTTP GET error message: ", $resp->message;
			if(++$error_counter>3) {
				say STDERR "too much errors!";
				die "retrieve extra course info failed too many times, abort.";
			}
			redo;
		}

		my $result = decode_json($resp->decoded_content);
		for my $r(@$result) {
			my $department_id = $r->{id};
			$department_tree{$college_id}{departments}{$department_id} = {
				name => $r->{name}
			};
			$dcnt++;
		}
		$ccnt++;
		&$callback($ccnt, $dcnt) if(defined $callback);
	}

	return 1;
}

sub fetchCourseData_OldApi {
	my($callback) = @_;

	my $error_counter = 0;
	my($processed_count, $total_courses) = (0, '?');

	&$callback($processed_count, $total_courses) if(defined $callback);

	for my $college_id(keys %department_tree) {
		for my $department_id(keys %{$department_tree{$college_id}{departments}}) {
			my $resp = $agent->GET($course_endpoint."?id=".$department_id, $course_header);

			if(!$resp->is_success) {
				say STDERR "HTTP GET error code: ", $resp->code;
				say STDERR "HTTP GET error message: ", $resp->message;
				if(++$error_counter>3) {
					say STDERR "too much errors!";
					die "retrieve extra course info failed too many times, abort.";
				}
				redo;
			}

			my $raw_xml = $resp->decoded_content;
			utf8::decode($raw_xml);
			my $xml = $xmlparser->parsestring($raw_xml);
			my @arr = grep {$_->isa('Course')} @{$xml->[0]->{Kids}};

			for my $course(@arr) {
				my $no = 0+$course->{SerialNo};
				# warn $no if(defined $courses{$no});

				$courses{$no} = {
					serialNo => 0+$course->{SerialNo},
					classNo => $course->{ClassNo},
					name => $course->{Title},
					teachers => [split /,\s*/, $course->{Teacher}],
					credit => 0+$course->{credit},
					passwordCard => lc $course->{passwordCard},
					times => [
						map {$a=$_; $a=~s/(.)(.)/$1-$2/; $a} split /,/, $course->{ClassTime}
					],
					admitCnt => 0+$course->{admitCnt},
					limitCnt => 0+$course->{limitCnt},
					waitCnt => 0+$course->{waitCnt},

					type => $courses{$no}->{type},	# preserve type

					colecode => $college_id,
					deptcode => $department_id,
				};

				$processed_count++;
			}

			&$callback($processed_count, $total_courses) if(defined $callback);
		}
	}

	return 1;
}

sub fetchCourseExtra_NewApi {
	my($callback) = @_;

	my $error_counter = 0;
	my($processed_count, $total_courses) = (0, scalar(keys %courses));

	&$callback($processed_count, $total_courses) if(defined $callback);

	for my $college_id(keys %department_tree) {
		for my $department_id(keys %{$department_tree{$college_id}{departments}}) {
			my $resp = $agent->GET($ncu_api_root."/departments/".$department_id."/courses", $ncu_api_header);

			if(!$resp->is_success) {
				say STDERR "HTTP GET error code: ", $resp->code;
				say STDERR "HTTP GET error message: ", $resp->message;
				if(++$error_counter>3) {
					say STDERR "too much errors!";
					die "retrieve extra course info failed too many times, aborted.";
				}
				redo;
			}

			my $result = decode_json($resp->decoded_content);
			for my $r(@$result) {
				my $no = 0+$r->{serialNo};
				$courses{$no}{type} = $re_i18nmap{type}{$r->{type}}
					if(exists $courses{$no});

				$processed_count++;
			}

			&$callback($processed_count, $total_courses) if(defined $callback);
		}
	}

	return 1;
}

sub loadBaseData {
	my($file) = @_;
	my $cdata = from_json(slurp($file));
	%department_tree = %{$cdata->{department_tree}};
	say "base data loaded. <$file";
}

sub saveBaseData {
	my($file) = @_;
	open(my $OUT, ">", $file);
	print $OUT to_json({LAST_UPDATE_TIME=>time, department_tree=>\%department_tree});
	close($OUT);
	say "department_tree saved. >$file";
}

sub loadCourseData {
	my($file) = @_;
	my $cdata = from_json(slurp($file));
	%courses = %{$cdata->{courses}};
	say "courses data loaded. <$file";
}

sub saveCourseData {
	my($file) = @_;
	open(my $OUT, ">", $file);
	print $OUT to_json({LAST_UPDATE_TIME=>time, courses=>\%courses});
	close($OUT);
	say "courses data saved. >$file";
}

sub slurp {
	my $content;
	open(my $fh, '<', $_[0]) or die $!; {
		local $/;
		$content = <$fh>;
	}
	close($fh);
	$content;
}

# sub deflate_newapi_times {
# 	CORE::state $newapi_timemapping = [
# 		'1','2','3','4','Z',
# 		'5','6','7','8','9',
# 		'A','B','C','D'
# 	];

# 	my $ret = [];
# 	for my $day(keys %{$_[0]}) {
# 		for my $hour(@{$_[0]->{$day}}) {
# 			push @$ret, $day."-".$newapi_timemapping->[$hour-1];
# 		}
# 	}

# 	return $ret;
# }

sub make_cookie {
	join "", map {"$_=$_[0]->{$_};"} keys %{$_[0]};
}

sub objdump {
	Data::Dumper->Dump([@_]);
}
