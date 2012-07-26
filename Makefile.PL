use 5.006;
use strict; use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Games::Domino',
    AUTHOR        => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM  => 'lib/Games/Domino.pm',
    ABSTRACT_FROM => 'lib/Games/Domino.pm',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Games-Domino-*' },
    PREREQ_PM     => {
        'Test::More' => 0,
        'Mouse'      => '0.93',
        'List::Util' => '1.25',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
);