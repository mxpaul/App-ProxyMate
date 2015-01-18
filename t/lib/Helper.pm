#!/usr/bin/env perl
package Helper;

use strict;
use warnings;

use AnyEvent;

sub AE::cvt(;$){
	my $after = shift || 1;
	my $cv; 
	my $t = AE::timer $after,0, sub { $cv->croak('condvar timed out'); };
	$cv = AE::cv sub { undef $t };
	return $cv;
}

1;
