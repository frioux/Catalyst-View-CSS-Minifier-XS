package Catalyst::View::CSS::Minifier::XS;

# ABSTRACT: Minify your served CSS files

use Moose;
extends 'Catalyst::View';

use CSS::Minifier::XS qw/minify/;
use Path::Class::File;
use URI;

has stash_variable => (
   is => 'ro',
   isa => 'Str',
   default => 'css',
);

has path => (
   is => 'ro',
   isa => 'Str',
   default => 'css',
);

has subinclude => (
   is => 'ro',
   isa => 'Bool',
   default => undef,
);

sub process {
   my ($self,$c) = @_;

   my $original_stash = $c->stash->{$self->stash_variable};
   my @files = $self->_expand_stash($original_stash);

   $c->res->content_type('text/css');

   push @files, $self->_subinclude($c, $original_stash, @files);

   my $home = $self->config->{INCLUDE_PATH} || $c->path_to('root');
   @files = map {
      $_ =~ s/\.css//;
      Path::Class::File->new( $home, $self->path, "$_.css" );
   } grep { defined $_ && $_ ne '' } @files;

   my @output = $self->_combine_files($c, \@files);

   $c->res->body( $self->_minify($c, \@output) );
}

sub _subinclude {
   my ( $self, $c, $original_stash, @files ) = @_;

   return unless $self->subinclude && $c->request->headers->referer;

   unless ( $c->request->headers->referer ) {
      $c->log->debug('javascripts called from no referer sending blank');
      $c->res->body( q{ } );
      $c->detach();
   }

   my $referer = URI->new($c->request->headers->referer);

   if ( $referer->path eq '/' ) {
      $c->log->debug(q{we can't take css from index as it's too likely to enter an infinite loop!});
      return;
   }

   $c->forward('/'.$referer->path);
   $c->log->debug('css taken from referer : '.$referer->path);

   return $self->_expand_stash($c->stash->{$self->stash_variable})
      if $c->stash->{$self->stash_variable} ne $original_stash;
}

sub _minify {
   my ( $self, $c, $output ) = @_;

   if ( @{$output} ) {
      return $c->debug
         ? join q{ }, @{$output}
         : minify(join q{ }, @{$output} )
   } else {
      return q{ };
   }
}

sub _combine_files {
   my ( $self, $c, $files ) = @_;

   my @output;
   for my $file (@{$files}) {
      $c->log->debug("loading css file ... $file");
      open my $in, '<', $file;
      for (<$in>) {
         push @output, $_;
      }
      close $in;
   }
   return @output;
}

sub _expand_stash {
   my ( $self, $stash_var ) = @_;

   if ( $stash_var ) {
      return ref $stash_var eq 'ARRAY'
         ? @{ $stash_var }
	 : split /\s+/, $stash_var;
   }

}


=head1 SYNOPSIS

 # creating MyApp::View::CSS
 ./script/myapp_create.pl view CSS CSS::Minifier::XS

 # in your controller file, as an action
 sub css : Local {
    my ( $self, $c ) = @_;

    # load root/css/style1.css and root/css/style2.css
    $c->stash->{css} = [qw/style1 style2/];

    $c->forward("View::CSS");
 }

 # in your html template use
 <link rel="stylesheet" type="text/css" media="screen" href="/css" />

=head1 DESCRIPTION

Use your minified css files as a separated catalyst request. By default they
are read from C<< $c->stash->{css} >> as array or string.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{css} >>

=item path

sets a different path for your css files

default : css

=item subinclude

setting this to true will take your css files (stash variable) from your referer
action

 # in your controller
 sub action : Local {
    my ( $self, $c ) = @_;

    # load exclusive.css only when /action is loaded
    $c->stash->{css} = "exclusive";
 }

This could be very dangerous since it's using
C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the
index action!

default : false

=back

=cut

=head1 SEE ALSO

L<Catalyst> , L<Catalyst::View>, L<CSS::Minifier::XS>

=head1 AUTHOR

Ivan Drinchev C<< <drinchev at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-css-minifier-xs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-CSS-Minifier-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ivan Drinchev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
