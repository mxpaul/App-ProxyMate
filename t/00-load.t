#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::ProxyMate' ) || print "Bail out!\n";
}

diag( "Testing App::ProxyMate $App::ProxyMate::VERSION, Perl $], $^X" );
