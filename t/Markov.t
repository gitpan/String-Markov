use 5.012;
use Storable qw(dclone);
use Test::Deep;
use Test::Exception;
use Test::Most;


use utf8;
use open qw(:encoding(utf8) :std);

my $smkv = 'String::Markov';

require_ok($smkv);

my $mc = new_ok($smkv);
can_ok($mc, qw(
	split_line
	add_sample
	sample_next_state
	generate_sample
));

# Check defaults
my %attr_def = (
	normalize => 'C',
	do_chomp  =>  1,
	null      =>  "\0",
	order     =>  2,
	split_sep => '',
	join_sep  => '',
);

while (my ($attr, $def) = each %attr_def) {
	is ( $mc->$attr, $def, "default $attr");
}

my $hello_str = "Hello, world!";
for (1..3) {
	my $mc2 = dclone($mc);
	#is_deeply($mc, $mc2, "clonable #$_");
	$mc->add_sample($hello_str);
	ok(!eq_deeply($mc, $mc2), "add_sample() actually changes internal state #$_");
	is($mc->generate_sample, $hello_str, "Only generate data that's been seen #$_");
	is($mc->sample_next_state('H', 'e'), 'l', "Unique state produces result #$_");
	is($mc->sample_next_state('z', 'z'), undef, "Novel state produces undef #$_");
}

my @r = $mc->generate_sample();
is_deeply(\@r, [split('', $hello_str)], "generate_sample() can return array");

# Note: first "ᾅ" is normalized, second is not
my $snowman = "Hello, ☃ᾅᾅ!";
for (1..10) {
	my $mc2 = dclone($mc);
	#is_deeply($mc, $mc2, "clonable (Unicode) #$_");
	$mc->add_sample($snowman);
	ok(!eq_deeply($mc, $mc2), "add_sample() actually changes internal state (Unicode) #$_");
	like($mc->generate_sample, qr/^Hello, (?:world|☃ᾅᾅ)!$/, "Only generate data that's been seen & normalized (Unicode) #$_");
	is($mc->sample_next_state('l', 'o'), ',', "Unique state produces result (Unicode) #$_");
	is($mc->sample_next_state('☃', 'ᾅ'), 'ᾅ', "Unique state produces normalized result (Unicode) #$_");
	is($mc->sample_next_state('z', 'z'), undef, "Novel state produces undef (Unicode) #$_");
}

throws_ok( sub { $mc->sample_next_state       }, qr/wrong amount/i, 'Complain about not enough state');
throws_ok( sub { $mc->sample_next_state(1..3) }, qr/wrong amount/i, 'Complain about too much state');

####################
    $mc = undef;
####################

my %attr_ovr = (
	normalize => 'D',
	do_chomp  =>  0,
	null      =>  '!',
	order     =>  1,
	split_sep =>  ' ',
	join_sep  =>  '.',
);

$mc = new_ok($smkv, [%attr_ovr]);
while (my ($attr, $ovr) = each %attr_ovr) {
	is ( $mc->$attr, $ovr, "overridden $attr");
}

my $words  = "Here are some words";
my $rwords = "Here.are.some.words";
for (1..3) {
	my $mc2 = dclone($mc);
	#is_deeply($mc, $mc2, "clonable #$_");
	$mc->add_sample($words);
	ok(!eq_deeply($mc, $mc2), "add_sample() actually changes internal state (non-default) #$_");
	is($mc->generate_sample, $rwords, "Join with join_sep #$_");
	is($mc->sample_next_state('Here'), 'are', "Unique state produces result (non-default) #$_");
	is($mc->sample_next_state('what'), undef, "Novel state produces undef (non-default) #$_");
}

$mc->add_sample(['Here are', 'some words']);
is($mc->sample_next_state('Here are'), 'some words', "Manually splitting samples works");

####################
    $mc = undef;
####################

$mc = new_ok($smkv, [do_chomp => 1]);
lives_ok( sub { $mc->add_files('t/twolines.txt') }, 'Adding file list');
is($mc->generate_sample, "One bit of text.", "chomp works");

$mc = new_ok($smkv, [do_chomp => 0]);
lives_ok( sub { $mc->add_files('t/twolines.txt') }, 'Adding file list');
is($mc->generate_sample, "One bit of text.\n", "skipping chomp works");

done_testing();

