#!/usr/bin/env perl
package TestFor::TCPClient;
use Test::Class::Moose;
use App::ProxyMate::TCPClient;
#use App::ProxyMate::TCPConnection;
use Data::Dumper;
use Carp;
use AnyEvent;

use Helper::MockServer;
use Helper qw(cvt); # This is really imported as AE::cvt

has request_string => ( is=> 'rw', default=> 'HELLO');
has reply_string   => ( is=> 'rw', default=> 'BYE' );


sub test_connection {
	my $self     = shift;
	my $mockserv = Helper::MockServer->new(connection => [
		[ code => sub { 'hey' }, 'received connect' ],
	]);

	my ($host, $port) = $mockserv->server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $cv = AE::cvt 1;
	$client->connect( sub { 
			my $first_arg = shift;
			ok($first_arg, "Connect callback receives something which is true on success");
			$cv->send;
		}
	);

	$cv->recv;
}


sub test_send_data_to_server {
	my $self     = shift;

	my $mockserv = Helper::MockServer->new(connection => [
		[ recv => $self->request_string, 'wait for "HELLO"' ],
		[ send => $self->reply_string, 'send "BYE"' ],
	]);
	my ($host, $port) = $mockserv->server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	$client->connect( sub {
		my $cl = shift;
		fail 'client object should be passed into callback on successful connection' unless ref $cl eq ref $client;
		$cl->send($self->request_string);
	});

	$mockserv->server->finished_cv->recv;

}

sub test_receive_data_from_server {
	my $self     = shift;

	my $mockserv = Helper::MockServer->new(connection => [
		[ send => $self->reply_string, 'send "BYE"' ],
	]);
	my ($host, $port) = $mockserv->server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $read_cv = AE::cvt 1;
	$client->on_read( sub { $read_cv->send(@_); });

	$client->connect( sub { BAIL_OUT("Connection failed, which is impossible!!!") unless $_[0]; } );
	$mockserv->server->finished_cv->recv;
	my ($received_data) = $read_cv->recv;
	is($received_data, $self->reply_string, 'Received data from server via on_read callback');

}

sub test_basic_error_handling {
	my $self     = shift;

	my $mockserv = Helper::MockServer->new(connection => [
		[ recv => $self->request_string, 'wait for "HELLO"' ],
	]);
	my ($host, $port) = $mockserv->server->connect_address;
	my $client = App::ProxyMate::TCPClient->new( host=>$host, port=>$port);

	my $cv = AE::cvt 1;
	$client->on_client_gone( $cv );

	$client->connect( sub {
		my $cl = shift;
		fail 'client object should be passed into callback on successful connection' unless ref $cl eq ref $client;
		$cl->send($self->request_string);
		}
	);
	$mockserv->server->finished_cv->recv; # server closed connection at this point
	$client->send('TRY TALK TO GONE CLIENT');

	my ( $msg )	= $cv->recv;
	ok($msg && length($msg), 'error message passed into client_gone callback') ;
	ok(!ref $msg, 'scalar message passed into client_gone callback') ;

}

1;
