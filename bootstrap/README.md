## Steps to setup perl environment in HOME directory

### Install local::lib

    sudo yum install perl-CPAN

    wget http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/local-lib-2.000015.tar.gz

    tar -zxf local-lib-2.000015.tar.gz && cd cd local-lib-2.000015

    perl Makefile.PL --bootstrap

    make install

    echo '[ $SHLVL -eq 1 ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >>~/.bashrc

    source ~/.bashrc

### Install *cpanm*

    curl -L https://cpanmin.us | perl - --sudo App::cpanminus 

### Remove local-lib sources

    cd .. && rm -rf local-lib-*

### Install required perl modules

    sudo yum install gcc

This may be useful: sudo chown `whoami` ~/perl5 -R

    cpanm Mouse
    cpanm Time::HiRes
    cpanm Test::Class::Moose
    cpanm AnyEvent
    cpanm AnyEvent::MockTCPServer

