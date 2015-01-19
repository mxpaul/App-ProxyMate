package App::ProxyMate::Server;

use strict;
use warnings;

use Mouse;
use Carp;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Util qw(guard fh_nonblocking );
use Socket qw(AF_INET6 AF_INET SOCK_STREAM SOL_SOCKET SO_REUSEADDR);


has host                 => (is=>'rw',);
has port                 => (is=>'rw',);
has state                => (is=>'rw', default => sub { return {} } );
has on_client_connection => (is=>'rw',);

no Mouse;
__PACKAGE__->meta->make_immutable;

sub listen{
	my $self = shift;

	unless ( defined $self->host) {
		$self->host( $AnyEvent::PROTOCOL{ipv4} < $AnyEvent::PROTOCOL{ipv6} && AF_INET6 ? "::" : "0" );
	}

	my $ipn = parse_address $self->host
		or Carp::croak "cannot parse '".$self->{host}."' as host address";

	my $af = address_family $ipn;

	Carp::croak("bind: want INET or INET6 address") unless $af == AF_INET || $af == AF_INET6;

	my %state;
	socket $state{fh}, $af, SOCK_STREAM, 0
		or Carp::croak "bind/socket: $!";

	setsockopt $state{fh}, SOL_SOCKET, SO_REUSEADDR, 1
		or Carp::croak "bind/so_reuseaddr: $!"
			unless AnyEvent::WIN32; # work around windows bug

	unless ($self->{port} =~ /^\d*$/) {
		$self->{port} =  (getservbyname $self->{port}, "tcp")[2] 
	 		or Carp::croak "$self->{port}: service unknown";
	}

	bind $state{fh}, AnyEvent::Socket::pack_sockaddr ($self->port, $ipn )
		or Carp::croak "bind: $!";

	fh_nonblocking( $state{fh}, 1);

	my $len;
	$len ||= 128;

	listen $state{fh}, $len
		or Carp::croak "listen: $!";

	$self->state(\%state);
	# TODO: maybe return guard to clean up state as Mark does in AnyEvent::Socket

}

sub accept{
	my $self = shift;
	my $state = $self->state;

	$state->{aw} = AE::io $state->{fh}, 0, sub {
		# this closure keeps $state alive
		while ($state->{fh} && (my $peer = accept my $fh, $state->{fh})) {
			fh_nonblocking $fh, 1; # POSIX requires inheritance, the outside world does not

			my ($service, $host) = AnyEvent::Socket::unpack_sockaddr $peer;
			$self->on_client_connection && $self->on_client_connection->($fh, $host, $service);
		}
	};

}

1;
