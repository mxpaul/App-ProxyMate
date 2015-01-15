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

sub test_send_data_to_server {

	my ($request_string, $reply_string) = ('HELLO', 'BYE' );

	my $server = AnyEvent::MockTCPServer->new(connections =>
		[ # Expected connections sequence
			[ # first connection
				[ recv => $request_string, 'wait for "HELLO"' ],
				[ send => $reply_string, 'send "BYE"' ],
			],
		],
	);

	my ($host,$port) = $server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $send_hello_on_connect; $send_hello_on_connect = sub {
		my $cl = shift;
		fail 'client object should be passed into callback on successful connection' unless ref $cl eq ref $client;
		$cl->send($request_string);
	};

	$client->connect( $send_hello_on_connect );
	$server->finished_cv->recv;

}

sub test_receive_data_from_server {

	my ($request_string, $reply_string) = ('HELLO', 'BYE' );

	my $server = AnyEvent::MockTCPServer->new(connections =>
		[ # Expected connections sequence
			[ # first connection
				[ send => $reply_string, 'send "BYE"' ],
			],
		],
	);

	my ($host,$port) = $server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);
	my $read_cv = AE::cv;
	$client->on_read( sub {
			warn 'on_read called';
			my $data = shift;
			$read_cv->send($data);
		}
	);

	$client->connect( sub { BAIL_OUT("Connection failed, which is impossible!!!") unless $_[0]; warn 'Connected'; } );
	$server->finished_cv->recv;
	warn 'Server completed its sequence';
	my $received_data = $read_cv->recv;
	is($received_data, $reply_string, 'Received data from server via on_read callback');

}

sub test_basic_error_handling {
	my ($request_string, $reply_string) = ('HELLO', 'BYE' );

	my $server = AnyEvent::MockTCPServer->new(connections =>
		[ # Expected connections sequence
			[ # first connection
				[ recv => $request_string, 'wait for "HELLO"' ],
			],
		],
	);

	my ($host,$port) = $server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $cv = AE::cv;
	$client->on_client_gone( $cv );

	$client->connect( sub {
		my $cl = shift;
		fail 'client object should be passed into callback on successful connection' unless ref $cl eq ref $client;
		$cl->send($request_string);
		}
	);
	$server->finished_cv->recv; # server closed connection at this point
	$client->send('TRY TALK TO GONE CLIENT');

	my ( $msg )	= $cv->recv;
	ok($msg && length($msg), 'error message passed into client_gone callback') ;
	ok(!ref $msg, 'scalar message passed into client_gone callback') ;
	#diag "client gone error msg: $msg";

}

1;
