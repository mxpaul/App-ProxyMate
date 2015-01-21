package TestFor::Server;
use Test::Class::Moose;
use App::ProxyMate::Server;
use Data::Dumper;
use Carp;
use AnyEvent;
use AnyEvent::Socket;
use Socket qw(inet_ntoa);

use Helper qw(cvt); # This is really defined as AE::cvt, Helper not exporting anything

sub test_bind_listen_accept {
	my $self = shift;

	my ($host,$port) = Helper::free_host_port;

	my $server = App::ProxyMate::Server->new(host=>$host, port=>$port);

	eval { $server->listen }; ok(!$@, "bind succeed with no exceptions: $@");

	eval { tcp_server $host, $port, sub {}; }; ok ($@, "Can't bind to same host port");

	my $server_ready = AE::cvt 1;
	$server->on_client_connection($server_ready);
	$server->accept;

	my $client_ready = AE::cvt 1;
	tcp_connect $host,$port, $client_ready;

	
	my $server_fh = $server_ready->recv;
	ok ($server_fh, "Server received connect $host:$port");

	my $client_fh = $client_ready->recv;
	ok ($client_fh, "Client able to connect to $host:$port");

}

sub test_server_talk_to_client {
	my ($host,$port) = Helper::free_host_port;

	my ($srv_client_host, $srv_client_port);

	my $server = App::ProxyMate::Server->new(host=>$host, port=>$port);
	$server->on_client_connection( sub {
			my $fh = shift or fail 'Server receives valid file handle on client connect';
			(my $netint_host, $srv_client_port) = @_;
			my $client_ip = inet_ntoa($netint_host);
			my $bytes = syswrite($fh,'HELLO', 5,0);
			is ($bytes,5, 'Server able talk to client');
		}
	);
	$server->listen; $server->accept;

	my $cv = AE::cvt 1;
	tcp_connect $host,$port, sub {
		my $fh = shift or fail ('Client handle not valid');	
		
		my $rw; $rw = AE::io $fh, 0, sub {
			my $bytes = sysread($fh, my $data, 16);
			undef $rw;
			$cv->send($data);
		};
	};
	my ($data) = $cv->recv;
	is($data, 'HELLO', 'Client received message');


}

1;
