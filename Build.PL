use 5.006;
use strict; use warnings;
use Module::Build;

my $builder = Module::Build->new(
    sign              => 1,
    module_name       => 'Games::Domino',
    license           => 'perl',
    dist_author       => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    dist_version_from => 'lib/Games/Domino.pm',
    add_to_cleanup    => [ 'Games-Domino-*' ],
    build_requires    => {
        'Test::More'  => 0,
        'Mouse'       => '0.93',
        'List::Util'  => '1.25',
    },
);

$builder->create_build_script();