package TestFor::Server;
use Test::Class::Moose;
use App::ProxyMate::Server;
use Data::Dumper;
use Carp;
use AnyEvent;

use Helper qw(cvt); # This is really imported as AE::cvt


sub test_new_class {

	ok 1, "Success in fail";
}

1;
