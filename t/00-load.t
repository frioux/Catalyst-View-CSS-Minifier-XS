#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::CSS::Minifier::XS' );
}

diag( "Testing Catalyst::View::CSS::Minifier::XS $Catalyst::View::CSS::Minifier::XS::VERSION, Perl $], $^X" );
