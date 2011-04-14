use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Clutch',
    license             => 'perl',
    dist_author         => q{Fraser Tweedale <frase@frase.id.au>},
    dist_version_from   => 'lib/Test/Clutch.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Test-Clutch-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
