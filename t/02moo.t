use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::Requires Moo => 2.00;
use Test::Fatal;

{
	package Local::Class;
	
	use Moo;
	use BiggerLib ":all";
	
	has small => (is => "ro", isa => SmallInteger);
	has big   => (is => "ro", isa => BigInteger);
}

is(
	exception { "Local::Class"->new(small => 9, big => 12) },
	undef,
	"some values that should pass their type constraint",
);

like(
	exception { "Local::Class"->new(small => 100) },
	qr{^isa check for "small" failed: 100 is too big},
	"direct violation of type constraint",
);

like(
	exception { "Local::Class"->new(small => 5.5) },
	qr{^isa check for "small" failed: value "5.5" did not pass type constraint "Integer"},
	"violation of parent type constraint",
);

like(
	exception { "Local::Class"->new(small => "five point five") },
	qr{^isa check for "small" failed: 'five point five' doesn't look like a number},
	"violation of grandparent type constraint",
);

like(
	exception { "Local::Class"->new(small => []) },
	qr{^isa check for "small" failed: is not a string},
	"violation of great-grandparent type constraint",
);

done_testing;