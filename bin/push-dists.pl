#!/usr/bin/env perl

use strict;
use warnings;
use URI;
use Data::Dumper;
use Net::FTP;
use Github::Import;
use Archive::Any;
use Sort::Versions;

@ARGV or die "Usage: perl $0 ftp_URL_to_author_dir_on_CPAN_mirror"
    . "  GitHub_Username GitHub_Pass\n";

-d 'temp'
    and die "I need to create and make use of 'temp' directory but"
    . " there's already a directory named 'temp' here\n";

my ( $ftp_url, $GitUser, $GitPass ) = @ARGV;

$ftp_url = URI->new( $ftp_url );

my $ftp = Net::FTP->new( $ftp_url->host, Passive => 1, Debug => 1 )
    or die "Cannot connect to ${\ $ftp_url->host}: $@";

$ftp->login('anonymous', '-anonymous@')
    or die 'Cannot login ' . $ftp->message;

$ftp->cwd( $ftp_url->path )
    or die 'Cannot change working directory ' . $ftp->message;

my @auth_files;
my $start_push = 1;
for ( grep /\.gz$/, $ftp->ls ) {
#     next unless /POE-Component-WWW-WebDevout-BrowserSupportInfo-0.01.tar.gz/;
#     $start_push = 1
#         if /\QPOE-Component-IRC-Plugin-YouTube-MovieFindStore-0.02.tar.gz/;

    next unless $start_push;
    push @auth_files, $_;
}


mkdir 'temp';
chdir 'temp';

process_files( $ftp, @auth_files );

chdir '../';

exit;

sub process_files {
    my ( $ftp, @files ) = @_;

    # If we got more than one version of a module; get rid of older ones
    @files = sort {
        my ($na, $va) = $a =~ /(.+)-(\d.+)/;
        my ($nb, $vb) = $b =~ /(.+)-(\d.+)/;
        $na cmp $nb || versioncmp($va, $vb);
    } @files;

    my %old;
    my $re = qr/([^.]+)-/;
    for ( 0 .. $#files-1) {
        my $name      = ($files[ $_   ] =~ /$re/)[0];
        my $next_name = ($files[ $_+1 ] =~ /$re/)[0];
        next
            unless defined $name and defined $next_name;

        $old{ $files[$_] } = 1
            if $name eq $next_name;
    }

    @files = grep !$old{ $_ }, @files;

    for ( @files ) {
        print "\n\nProcessing $_\n";
        # for some weird reason; using Net::FTP to get the files didn't go over so well...
        `wget ftp://cpan.mirror.rafal.ca/pub/CPAN/authors/id/Z/ZO/ZOFFIX/$_`;

        my $ar = Archive::Any->new( $_ );
        my ( $distro_dir ) = $ar->files;
        Archive::Any->new( $_ )->extract;
#
        my $repo_dir = $distro_dir =~ s/-[^-]+$//r;

        ## Use this line if you mess up and need to delete a ton of repos:
#         `curl -uUSER:PASS -X "DELETE" https://api.github.com/repos/USER/$repo_dir`;

        chdir $distro_dir;
        `git init`;
        `git add --all`;
        `git commit -am 'first commit'`;
        `curl -u '$GitUser':'$GitPass' https://api.github.com/user/repos -d '{"name":"$repo_dir"}'`;
        `git remote add origin git\@github.com:$GitUser/$repo_dir.git`;
        `git push origin master`;
        chdir '../';
    }

}

__END__









