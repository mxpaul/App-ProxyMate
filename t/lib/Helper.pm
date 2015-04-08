#!/usr/bin/env perl
package Helper;

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Socket;

sub AE::cvt(;$){
	my $after = shift || 1;
	my $cv; 
	my $t = AE::timer $after,0, sub { $cv->croak('condvar timed out'); };
	$cv = AE::cv sub { undef $t };
	return $cv;
}

sub free_host_port {
	my $host = shift//'127.0.0.1';

	my $cv = AE::cv;
	my $guard=tcp_server( $host, undef, sub{ }, $cv );

	(undef,$host,my $port) = $cv->recv;
	undef $guard;
	return ( $host,$port);

}

1;
