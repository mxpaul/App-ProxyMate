use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::ProxyMate',
	AUTHOR           => q{Maxim Polyakov <mmonk@cpan.org>},
	VERSION_FROM     => 'lib/App/ProxyMate.pm',
	ABSTRACT_FROM    => 'lib/App/ProxyMate.pm',
	LICENSE          => 'Artistic_2_0',
	PL_FILES         => {},
	MIN_PERL_VERSION => 5.006,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 0,
		'ExtUtils::Manifest'  => 0,
	},
	BUILD_REQUIRES => {
		'Test::More'              => 0,
		'Test::Class::Moose'      => 0,
		'AnyEvent::MockTCPServer' => 0,
	},
	PREREQ_PM => {
		'Mouse'                   => 0,
		'AnyEvent::Socket'        => 0,
		'AnyEvent::Handle'        => 0,
		'AnyEvent'                => 0,
		#'ABC'              => 1.6,
		#'Foo::Bar::Module' => 5.0401,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'App-ProxyMate-*' },
);
