package Catalyst::View::CSS::Minifier::XS;

use warnings;
use strict;

use base qw/Catalyst::View/;

our $VERSION = '0.02';

use NEXT;
use Carp qw/croak/;
use CSS::Minifier::XS qw/minify/;
use Path::Class::File;
use Catalyst::Exception;
use URI;

=head1 NAME

Catalyst::View::CSS::Minifier::XS - Minify your multiple CSS files and use them with Catalyst.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

	# creating MyApp::View::CSS
    ./script/myapp_create.pl view CSS CSS::Minifier::XS

	# in your controller file, as an action
    sub css : Local {
		my ( $self, $c ) = @_;	
		
		$c->stash->{css} = [qw/style1 style2/]; # loads root/css/style1.css and root/css/style2.css
	
		$c->forward("View::CSS");
    }
	
	# in your html template use
	<link rel="stylesheet" type="text/css" media="screen" href="/css" />

=head1 DESCRIPTION

Use your minified css files as a separated catalyst request. By default they are read from C<< $c->stash->{css} >> as array or string.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{css} >>

=item path

sets a different path for your css files

default : css

=item subinclude

setting this to true will take your css files (stash variable) from your referer action

	# in your controller 
	sub action : Local {
		my ( $self, $c ) = @_;
		
		$c->stash->{css} = "exclusive"; # loads exclusive.css only when /action is loaded
	}

This could be very dangerous since it's using C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the index action!

default : false

=back

=cut

__PACKAGE__->mk_accessors(qw(stash_variable path subinclude));

sub new {
	my($class, $c, $arguments) = @_;
    my $self = $class->NEXT::new($c);
	my %config = ( stash_variable => 'css', path => 'css', subinclude => 0, %$arguments );
	for my $field ( keys %config ) {
		if ( $self->can($field) ) {
			$self->$field( $config{$field} );
		} else {
			$c->log->debug("Unknown config parameter '$field'");
		}
	}
	return $self;
}

sub process {
    my ($self,$c) = @_;
			
	my $path = $self->path;	
	my $variable = $self->stash_variable;	
	my @files = ();	

	my $original_stash = $c->stash->{$variable};
	
	# turning stash variable into @files
	if ( $c->stash->{$variable} ) {
		@files = ( ref $c->stash->{$variable} eq 'ARRAY' ? @{ $c->stash->{$variable} } : split /\s+/, $c->stash->{$variable} );	
	}
	
	# No referer we won't show anything
	if ( ! $c->request->headers->referer ) {		
		$c->log->debug("css called from no referer sending blank");
		$c->res->content_type("text/css");
		$c->res->body( " " );			
		$c->detach();
	}
	
	# If we have subinclude ON then we should run the action and see what it left behind
	if ( $self->subinclude ) {
		my $base = $c->request->base;
		if ( $c->request->headers->referer ) {			
			my $referer = URI->new($c->request->headers->referer);			
			if ( $referer->path ne "/" ) {
				$c->forward("/".$referer->path);
				$c->log->debug("css taken from referer : ".$referer->path);
				if ( $c->stash->{$variable} ne $original_stash ) {
					# adding other files returned from $c->forward to @files ( if any )
					push @files, ( ref $c->stash->{$variable} eq 'ARRAY' ? @{ $c->stash->{$variable} } : split /\s+/, $c->stash->{$variable} );	
				}
			} else {
				# well for now we can't get css files from index, because it's indefinite loop
				$c->log->debug("we can't take css from index, it's too dangerous!");
			}			
		}
	}
	
	my $home = $self->config->{INCLUDE_PATH} || $c->path_to('root');
	
	@files = map {
		my $file = $_;
		$file =~ s/\.css$//;
		Path::Class::File->new( $home, "$path", "$file.css" );		
	} @files;
	
	# combining the files
	my @output;
	for my $file ( @files ) {
		$c->log->debug("loading css file ... $file");
		open(IN, "<$file");
		for ( <IN> ) {
			push @output, $_;
		}
		close(IN);
	}

	$c->res->content_type("text/css");
	if ( @output ) {
		# minifying them if any files loaded at all
		$c->res->body( minify(join(" ", @output)) );	
	} else {
		$c->res->body( " " );	
	}
}


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

1; # End of Catalyst::View::CSS::Minifier::XS
