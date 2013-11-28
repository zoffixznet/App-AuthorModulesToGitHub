use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::AuthorModulesToGitHub',
    license             => 'Artistic_2_0',
    dist_author         => q{Zoffix Znet <zoffix@cpan.org>},
    dist_version_from   => 'lib/App/AuthorModulesToGitHub.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'           => 1.26,
        'URI'            => 1.59,
        'Net::FTP'       => 2.78,
        'Github::Import' => 0.07,
        'Archive::Any'   => 0.0932,
        'Sort::Versions' => 1.5,
    },
    add_to_cleanup     => [ 'App-AuthorModulesToGitHub-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
