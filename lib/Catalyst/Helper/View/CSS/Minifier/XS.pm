package Catalyst::Helper::View::CSS::Minifier::XS;

use strict;

=head1 NAME

Catalyst::Helper::View::CSS::Minifier::XS - Helper for CSS::Minifier::XS views

=head1 SYNOPSIS

    script/create.pl view CSS CSS::Minifier::XS

=head1 DESCRIPTION

Helper for CSS::Minifier::XS views

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::View::CSS::Minifier::XS';

1;
