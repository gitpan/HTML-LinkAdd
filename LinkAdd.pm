#! perl -w

package HTML::LinkAdd;
our $VERSION = 0.1;

use strict;
use HTML::TokeParser;
use Data::Dumper;

=pod

=head1 NAME

HTML::LinkAdd - add hyperlinks to phrases in HTML documents

=head1 DESCRIPTION

A simple object that accepts a class reference, a path to a file, and a hash of text-phrase/link-URLs,
and supplies a method to hyperlink the supplied phrases to the supplied URLs, and a method to save the file.

=head1 PRIVATE CLASS CONSTANTS

=item debug

Set to true if you are ....

=cut

our $debug = 1;

=head1 CONSTRUCTOR (new)

Accepts class reference, returns HTML::Analyse::Docuemnt object, with the following slots:

=item PUBLIC words

Hash where keys are words encountered, values are number of instances encountered by this object to date, with the added weight (see below).

=item PRIVATE context_w

Context weight for the word being processed, +/- any changes made in processing.

=item PRIVATE INPUT

A string of HTML input.

=item PUBLIC output

A string of HTML output.

=cut

sub new { my ($class,$filename) = (shift,shift);
	# Test parameters are valid
	warn "HTML::LinkAdd::new requires both class and filename as paramters"
		and return undef if not defined $filename;
	warn "HTML::LinkAdd::new  requires both class and filename as paramters"
		and return undef  if not defined $class or not defined $filename;
	warn "HTML::LinkAdd::new unable to find file <$filename> for input!"
		and return if !-e $filename;

	# Define object
	my $self 			= {};
	bless $self,$class;

	$self->{words} 		= {};
	$self->{context_w} 	= 1;	# Weight factor gained from current context
	$self->{INPUT} 		= [];	# A tokenised (TokeParser generated) copy of the HTML input

	# Load HTML here (not in TokeParser) so we can keep a copy.
	open IN, $filename or warn "HTML::LinkAdd::new  requires both class and filename as paramters" and return undef;
		@_ = <IN>;
	close IN;
	$self->{INPUT} = join '',@_;		# Copy the HTML document to self for possible later use

	return $self;
}


=head2 PUBLIC METHOD dump

Dumps the contents of $self

=cut

sub dump { my $self = shift;
	# simple procedural interface
	print Dumper($self);
}



=head1 PUBLIC METHOD hyperlink

Modify HTML by adding hyperlinks around specified words.

Text to hyperlink should passed as keys of a hash, with
relative values being the URLs the links should point to.

Sets the C<output> slot and returns its contents.

=cut

sub hyperlink { my $self = shift;
	my %args;
	# Take parameters and place in object slot HREFS as text/URL pairs
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	%{$self->{HREFS}} = %args;
	warn "HTML::LinkAdd::hyperilnk requires a hash (or ref to such) as parameter." and return undef if length %args<2;

	# Clear the output slot
	$self->{output} = '';

	# Create new TokeParser and parse all text, comparing HTML against keys of our targets
	my $p = new HTML::TokeParser ( \$self->{INPUT} )
		or warn "Counldn't make TokeParser!" and return undef;
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
	return $self->{output};
}


=head1 PUBLIC METHOD save

Saves the object's C<output> slot to filename passed as scalar.

Returns undef on failure.

=cut

sub save { my ($self,$filename) = (shift,shift);
	warn "HTML::LinkAdd::save requires a filename as parameter 1" and return undef if not defined $filename;
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
	my $instance = new HTML::LinkAdd('input.html');
	$instance->hyperlink('the clocks were striking thirteen'=>'footnotes.html#OrwellG-1');
	$instance ->save ('output.html');

=head1 AUTHOR

Lee Goddard C<lgoddard@cpan.org>
01/05/2001 London, UK

=head1 COPYRIGHT

Copyright (C) Lee Goddard. All Rights Reserved.
This is free software and you may use, abuse, amend and distribute under the same
terms as Perl itself.


