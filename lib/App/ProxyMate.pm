package App::ProxyMate;

use 5.006;
use strict;
use warnings FATAL => 'all';


use Mouse;
no Mouse;
__PACKAGE__->meta->make_immutable;

=head1 NAME

App::ProxyMate - proxy of proxies with persistant connection pool

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS



    use App::ProxyMate;

    my $app = App::ProxyMate->new($dependency_container);
    ...

=head1 EXPORT

Nothing for now


=head1 AUTHOR

Maxim Polyakov, C<< <mmonk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-proxymate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ProxyMate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT




=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Maxim Polyakov.


=cut

1; # End of App::ProxyMate
