package HTML::LinkAdd;
our $VERSION = 0.12;	# Removed more extrenious code form HTML::Analysis

use strict;
use warnings;
use HTML::TokeParser;

=head1 NAME

HTML::LinkAdd - add hyperlinks to phrases in HTML documents

=head1 DESCRIPTION

A simple object that accepts a class reference, a path to a file, and a hash of text-phrase/link-URLs,
and supplies a method to hyperlink the supplied phrases to the supplied URLs, and a method to save the file.

=head1 DEPENDENCIES

	strict
	warning
	HTML::TokeParser

=head1 CONSTRUCTOR (new)

Accepts class reference, some HTML, and a hash of phrases and hyperlinks.
The HTML may be a filename passed as a scalar, or a reference to a scalar thast is literal HTML.

Returns a scalar that is the updated HTML input.

=item PUBLIC output

A string of HTML output.

=item PRIVATE INPUT

A string of HTML input.

=cut

sub new { my ($class,$input) = (shift,shift);
	# Lets HTML::TokeParser handle the input file/string checks:-
	warn "HTML::LinkAdd::new called without a class ref?" and return undef unless defined $class;
	warn "Useage: new $class (\$path_to_file or \\\$HTML)" and return undef if not defined $input;

	my %args;
	my $self = {};
	$self->{INPUT} = $input; 	# Oh, someone may find it useful
	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	# Take parameters and place in object slot HREFS as text/URL pairs
	warn "$class\;;new requires a hash (or ref to such) as parameter." and return undef if length %args<2;
	%{$self->{HREFS}} = %args;
	# Clear the output slot
	$self->{output} = '';
	bless $self,$class;

	# Create new TokeParser and parse all text, comparing HTML against keys of our targets
	my $p = new HTML::TokeParser ( $self->{INPUT} )
		or warn "Counldn't instantiate HTML::TokeParser!\n$!" and return undef;
	my $token;

	while ($token = $p->get_token and not (@$token[1] eq 'html' and @$token[0] eq 'E') ){
		if (@$token[0] eq 'T') {
			# If we got a text node, loop over every word
			foreach my $key ( keys %{$self->{HREFS}} ) {
				if (exists $self->{HREFS}->{$key} and @$token[1] =~ m/\Q$key\E/sg){
					my $subs = "<A href=\"" . $self->{HREFS}->{$key} . "\">$key</A>";
					@$token[1] =~ s/\Q$key\E/$subs/sg;
				}
			}
		};

		# Add the perhaps-processed token to the relevant slot
		my $literal;
		if    (@$token[0] eq 'S') { $literal = @$token[4]; }
		elsif (@$token[0] eq 'E') { $literal = @$token[2]; }
		else                      { $literal = @$token[1]; }
		$self->{output} .= $literal;
	} # End while
	return $self;
}


=head1 PUBLIC METHOD hyperlink

Returns the hyperlinked HTML docuemnt constructed by...the constructor.

=cut

sub hyperlinked { return $_[0]->{output} }


=head1 PUBLIC METHOD save

Saves the object's C<output> slot to filename passed as scalar.

Returns undef on failure, C<1> on success.

=cut

sub save { my ($self,$filename) = (shift,shift);
	warn "HTML::LinkAdd::save requires a filename as parameter 1" and return undef unless defined $filename;
	local *OUT;
	open OUT, ">$filename"
		or warn "HTML::LinkAdd::save could not open the file <$filename> for writing.\n$!" and return undef;
		print OUT $self->{output};
	close OUT;
	return 1;
}

1;	# Return cleanly


__END__;

=head1 SYNOPSIS

	use HTML::LinkAdd;
	my $page = new HTML::LinkAdd('testinput1.html',
		{'the clocks were striking thirteen'=>'footnotes.html#OrwellG-1'}
	);
	warn $page -> hyperlinked;
	$page ->save ('output.html');

=head1 CAVEATS

Is only as limited as HTML::TokeParse (see L<HTML::TokeParse>).

=head1 TODO

=item *

Add support for linking images by source or C<ID>.

=head1 AUTHOR

Lee Goddard C<lgoddard@cpan.org>
01/05/2001 London, UK

=head1 COPYRIGHT

Copyright (C) Lee Goddard. All Rights Reserved.
This is free software and you may use, abuse, amend and distribute under the same
terms as Perl itself.


