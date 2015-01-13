#!/usr/bin/env perl

package TestFor::TCPClient;
use Test::Class::Moose;
use App::ProxyMate::TCPClient;
use AnyEvent::MockTCPServer qw/:all/;
use Data::Dumper;
use Carp;


sub mockserv_exitonconnect{

	my $cv = AE::cv;
	my $t; $t=AE::timer 0.1,0, sub { $cv->send('timeout'); undef $t; BAIL_OUT( "tcp mock server exited for timeout, fix this!") };

	my $server = AnyEvent::MockTCPServer->new(connections =>
		[ # Expected connections sequence
			[ # first connection
				[ code => sub { $cv->send('done') }, 'send "done" with condvar' ],
			],
		],
	);

	return ($server->connect_address, $cv);
	
}

sub test_connection {
	my $self= shift;

	my ($host, $port, $cv) = $self->mockserv_exitonconnect();
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $callback_called;
	$client->connect( sub { 
			my $first_arg = shift;
			ok($first_arg, "Connect callback receives soething which is true on success");
			$callback_called = 1;
		}
	);

	my $msg = $cv->recv;
	is($msg,'done', 'Connect received in mock tcp server');
	is($callback_called,1, 'TCPClient called its callback on connect');
	
}

1;
