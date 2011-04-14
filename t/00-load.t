#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Clutch' ) || print "Bail out!
";
}

diag( "Testing Test::Clutch $Test::Clutch::VERSION, Perl $], $^X" );
