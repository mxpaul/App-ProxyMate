#!/usr/bin/env perl
#============================================================
package Extended::Mock::Server;
use Mouse;
use Carp;
use AnyEvent;
#use AnyEvent::Socket;
#use AnyEvent::Handle;


has timeout => (is=> 'rw', default => 1); 
has timer   => (is=> 'rw',); 
has server  => (is=> 'rw',); 

sub BUILD {
	my $self = shift;

	$self->timer( AE::timer $self->timeout,0, sub { undef $self->timer; fail( "tcp mock server exited for timeout") } );

	$self->server (AnyEvent::MockTCPServer->new(connections =>
		[ # Expected connections sequence
			[ # first connection
				[ code => sub { 'hey' }, 'received connect' ],
			],
		],
	));

}

sub cvt {
	my $after = shift // 1;
	my $cv = AE::cv;
	my $t; $t = AE::timer $after,0, sub { $cv->send( undef, 'condvar timed out'); };
	$cv->cb(sub { $t = undef });
	return $cv;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

#============================================================
package TestFor::TCPClient;
use Test::Class::Moose;
use App::ProxyMate::TCPClient;
use AnyEvent::MockTCPServer qw/:all/;
use Data::Dumper;
use Carp;


sub test_connection {
	my $self     = shift;
	my $mockserv = Extended::Mock::Server->new();

	my ($host, $port) = $mockserv->server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $cv = AE::cv;
	#my $cv = Extended::Mock::Server->cvt();
	$client->connect( sub { 
			my $first_arg = shift;
			ok($first_arg, "Connect callback receives soething which is true on success");
			$cv->send;
		}
	);

	$cv->recv;
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
