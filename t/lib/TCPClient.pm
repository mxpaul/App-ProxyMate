#!/usr/bin/env perl

package TestFor::TCPClient;
use Test::Class::Moose;
use App::ProxyMate::TCPClient;
use AnyEvent::MockTCPServer qw/:all/;
use Data::Dumper;

#has server=> (is =>'rw');

#sub startup {
#	my $self = shift;
#
#}

sub test_connection {
	my $self= shift;

	my $cv = AE::cv;
	my $t; $t=AE::timer 0.1,0, sub { $cv->send('timeout'); undef $t };

	my $server = AnyEvent::MockTCPServer->new(connections =>
		[ # Expected connections sequence
			[ # first connection
				[ code => sub { $cv->send('done') }, 'send "done" with condvar' ],
			],
		],
	);

	my ($host, $port) = $server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $callback_called;
	$client->connect( sub { 
			$callback_called = 1;
		}
	);

	my $msg = $cv->recv;
	is($msg,'done', 'Connect received in mock tcp server');
	is($callback_called,1, 'TCPClient called its callback on connect');
	
}

1;
