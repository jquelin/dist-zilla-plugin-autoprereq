use 5.010;
use strict;
use warnings;

package Dist::Zilla::Plugin::AutoPrereq;
# ABSTRACT: automatically extract prereqs from your modules

use Dist::Zilla::Util;
use Moose;
use MooseX::Has::Sugar;
use Perl::PrereqScanner 0.100521;
use PPI;
use Version::Requirements 0.100520;
use version;

with 'Dist::Zilla::Role::FixedPrereqs';

# -- attributes

# skiplist - a regex
has skip => ( ro, predicate=>'has_skip' );


# -- public methods

sub prereq {
    my $self = shift;
    my $files = $self->zilla->files;

    my $req = Version::Requirements->new;

    my @modules;
    foreach my $file ( @$files ) {
        # parse only perl files
        next unless $file->name    =~ /\.(?:pm|pl|t)$/i
            || $file->content =~ /^#!(?:.*)perl(?:$|\s)/;

        # store module name, to trim it from require list later on
        my $module = $file->name;
        $module =~ s{^lib/}{};
        $module =~ s{\.pm$}{};
        $module =~ s{/}{::}g;
        push @modules, $module;

        # parse a file, and merge with existing prereqs
        my $file_req = Perl::PrereqScanner->new->scan_string($file->content);

        $req->add_requirements($file_req);
    }

    # remove prereqs shipped with current dist
    $req->clear_requirement($_) for @modules;

    # remove prereqs from skiplist
    if ( $self->has_skip && $self->skip ) {
        my $skip = $self->skip;
        my $re   = qr/$skip/;

        foreach my $k ( $req->required_modules ) {
            $req->clear_requirement($k) if $k =~ $re;
        }
    }

    # we're done, return what we've found
    return $req->as_string_hash;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=begin Pod::Coverage

prereq

=end Pod::Coverage

=head1 SYNOPSIS

In your F<dist.ini>:

    [AutoPrereq]
    skip = ^Foo|Bar$


=head1 DESCRIPTION

This plugin will extract loosely your distribution prerequisites from
your files.

The extraction may not be perfect but tries to do its best. It will
currently find the following prereqs:

=over 4

=item * plain lines beginning with C<use> or C<require> in your perl
modules and scripts. This includes minimum perl version.

=item * regular inheritance declated with the C<base> and C<parent>
pragamata.

=item * L<Moose> inheritance declared with the C<extends> keyword.

=item * L<Moose> roles included with the C<with> keyword.

=back

If some prereqs are not found, you can still add them manually with the
L<Dist::Zilla::Plugin::Prereq> plugin.

It will trim the following pragamata: C<strict>, C<warnings>, C<base>
and C<lib>. However, C<parent> is kept, since it's not in a core module.

It will also trim the modules shipped within your dist.

The module accept the following options:

=over 4

=item * skip: a regex that will remove any matching modules found
from prereqs.

=back



=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-AutoPrereq>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-AutoPrereq>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-autoprereq>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-AutoPrereq>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-AutoPrereq>

=back

