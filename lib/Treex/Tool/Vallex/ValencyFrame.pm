package Treex::Tool::Vallex::ValencyFrame;

use Moose;
use Treex::Core::Common;
use Treex::Core::Resource qw(require_file_from_share);
use MooseX::ClassAttribute;
use XML::LibXML;
use Treex::Tool::Vallex::FrameElement;

# Fill the default valency lexicon path here (where vallex.xml is located)
Readonly my $DEFAULT_LEXICON_PATH => 'data/resources/pdt_vallex/';

# The lemma of the current valency frame
has 'lemma' => ( isa => 'Str', is => 'ro', required => 1 );

# The part of speech
has 'pos' => ( isa => 'Str', is => 'ro', required => 1 );

# The individual frame elements (Treex::Tool::Vallex::FrameElement)
has 'elements' => ( isa => 'ArrayRef', is => 'ro', required => 1 );

# The language ID (two character string)
has 'language' => ( isa => 'Str', is => 'ro', required => 1 );

# The ID of the frame in the lexicon
has 'id' => ( isa => 'Str', is => 'ro' );

# the lexicon name, such as C<vallex.xml>
has 'lexicon' => ( isa => 'Str', is => 'ro' );

# A hash map of all the frame elements, according to their functor
has '_element_map' => ( isa => 'HashRef', is => 'ro', builder => '_build_element_map', lazy_build => 1 );

# Loaded valency dictionaires cache
class_has '_loaded_dicts' => ( isa => 'HashRef', is => 'rw', default => sub { {} } );

# This serves mainly for converting the lexicon + id into lemma, pos and elements.
around 'BUILDARGS' => sub {

    my $orig = shift;
    my $self = shift;

    # Build a hash reference
    my $params = $self->$orig(@_);

    # Find in the valency dictionary and parse
    if ( ( $params->{id} or $params->{ord} ) and $params->{lexicon} ) {

        my $xc = _get_xpath_context( $params->{lexicon} );
        my ($frame_xml) = $params->{id}
            ? $xc->findnodes( '//frame[@id=\'' . $params->{id} . '\'][1]' )
            : $xc->findnodes( '(//frame)[' . $params->{ord} . ']' );

        if ( !$frame_xml ) {
            log_warn( "The specified valency frame ID was not found: " . ( $params->{id} ? $params->{id} : $params->{ord} ) );
        }

        # Fill in lemma and POS (convert their format to correspond to usual TectoMT conventions)
        $params->{lemma} = $frame_xml->parentNode->parentNode->getAttribute('lemma');
        $params->{lemma} =~ s/ /_/g;
        $params->{pos} = lc( $frame_xml->parentNode->parentNode->getAttribute('POS') );
        if ( $params->{pos} eq 'a' ) {
            $params->{pos} = 'adj';
        }

        # Fill in valency members
        $params->{elements} = [];
        foreach my $element ( $frame_xml->getElementsByTagName('element') ) {
            push( @{ $params->{elements} }, Treex::Tool::Vallex::FrameElement->new( xml => $element, language => $params->{language} ) );
        }
    }
    else {
        $params->{lemma} =~ s/ /_/g;
        if ( $params->{pos} !~ /^(n|v|adj|adv)$/ ) {
            log_warn("Non-standard POS for a valency frame, should be n, v, adj or adv.");
        }
    }

    # Otherwise keep the user-set members and die if some of them are missing
    return $params;
};

# This is able to load the valency lexicon into the memory, or to retrieve an already loaded one.
# The XPath context for the lexicon is returned, as this is what's needed for the search by id or order
sub _get_xpath_context {

    my ($lexicon_name) = @_;
    my $xc;

    if ( !Treex::Tool::Vallex::ValencyFrame->_loaded_dicts->{$lexicon_name} ) {
        my $lexicon = XML::LibXML->load_xml( location => require_file_from_share($DEFAULT_LEXICON_PATH . $lexicon_name ));
        $lexicon->indexElements();
        Treex::Tool::Vallex::ValencyFrame->_loaded_dicts->{$lexicon_name} = XML::LibXML::XPathContext->new($lexicon);
    }
    return Treex::Tool::Vallex::ValencyFrame->_loaded_dicts->{$lexicon_name};
}

# This constructs the hashmap of the frame elements by their functor
sub _build_element_map {

    my ($self) = @_;
    my %map;

    foreach my $param ( @{ $self->elements } ) {
        $map{ $param->functor } = $param;
    }
    return \%map;
}

# Return the frame element with the specified functor, or undef
sub functor {
    my ( $self, $functor ) = @_;

    return $self->_element_map->{$functor};
}

# Convert the frame to a string
sub to_string {
    my ($self) = @_;

    return $self->lemma . '-' . $self->pos . ': ' . join( ' ', map { $_->to_string } @{ $self->elements } );
}

1;
__END__

=encoding utf-8

=head1 NAME 

Treex::Tool::Vallex::ValencyFrame

=head1 DESCRIPTION

This represents a single valency frame of a tectogrammatical node, containing its lemma, part of speech
and the individual elements (as L<Treex::Tool::Vallex::FrameElement> objects). A valency frame may be created
either directly using the values, or from an XML valency dictionary, such as the 
L<PDT-Vallex|http://ufal.mff.cuni.cz/pdt2.0/data/pdt-vallex/vallex.xml> Czech valency lexicon. 

=head1 SYNOPSIS

    # create a frame from scratch
    my $frame = Treex::Tool::Vallex::ValencyFrame->new({lemma => 'hlad', pos => 'n', elements => [], language => 'cs' });

    # create a frame from the valency dictionary
    $frame = Treex::Tool::Vallex::ValencyFrame->new( {ord => 3, lexicon => 'vallex.xml', language => 'cs'} );
    $frame = Treex::Tool::Vallex::ValencyFrame->new( {id => 'v-w3f1', lexicon => 'vallex.xml', language => 'cs'} );
    
    # print the frame
    $frame->to_string();

    # access the individual frame elements (Treex::Tool::Vallex::FrameElement)  
    my $element = $frame->functor('ACT');
    $element = $frame->elements()->[0];

=head1 METHODS

=over

=item C<elements>

    $element = $frame->elements->[0];

A direct access to all elements of the valency frame (as an array of L<Treex::Tool::Vallex::FrameElement> objects).

=item C<functor>

    $element = $frame->functor('ACT');
    
This returns a L<Treex::Tool::Vallex::FrameElement> object which represents the element of this valency
frame with the given functor, or undef, if no such functor is found in the frame.

=item C<id>

The id of the valency frame in the valency lexicon, such as C<v-w3f1> (if creating the frame from scratch, this may be blank).

=item C<language>

The language of the valency frame (two-character code, such as C<cs>).

=item C<lemma>

The lemma for this valency frame. The lemmas are normalized according to the PDT/TectoMT t-layer convention
(with underscores instead of spaces).

=item C<lexicon>

The name of the valency lexicon, such as C<vallex.xml>, usually taken directly from the C<val_frame.rf>
attribute of a t-node.

=item C<new>

    $frame = Treex::Tool::Vallex::ValencyFrame->new({lemma => 'hlad', pos => 'n', elements => [], language => 'cs' });
    $frame = Treex::Tool::Vallex::ValencyFrame->new( {ord => 3, lexicon => 'vallex.xml', language => 'cs'} );
    $frame = Treex::Tool::Vallex::ValencyFrame->new( {id => 'v-w3f1', lexicon => 'vallex.xml', language => 'cs'} );

This creates a new valency frame. It may be created either from scratch, using some pre-filled values,
or directly from the valency lexicon data.

If the frame is created using pre-filled values, the C<lemma>, C<pos>, C<elements> and C<language> must be given.
The C<id> and C<lexicon> are left blank.

If the frame is created using the lexicon, the C<lexicon> name and C<id> from the C<val_Frame.rf> must be given,
or the C<lexicon> name and C<ord> -- order of the frame globally within the lexicon. If C<ord> is given, it is then
converted to the frame C<id>. All the other values, i.e. C<lemma>, C<pos> and C<elements>, are then filled in from the
valency lexicon. 

=item C<pos>

The semantic part of speech (sempos) for this valency frame. The standard values are: I<n>, I<adj>, I<v>, I<adv>.  

=item C<to_string>

This returns a string version of the valency frame in a format that corresponds to the following example:

    adaptovat-v: ACT[n:1] PAT[n:4] (ORIG[n:z+2]) (EFF[n:do+2, n:na+4])

The lemma and POS stand at the beginning and are separated with a dash. Then, after a colon, the list of all frame
elements follows (according to the string versions of the individual frame elements).   

=back

=head1 TODO

=over

=item *

Keep also links to all frames with the same language, lexicon and ID and do not instantiate them repeatedly?

=item *

Somehow get rid of the compulsory Vallex path specification in a code constant (C<DEFAULT_LEXICON_PATH>)?

=item *

The possibility to create frame elements from strings?

=back

=head1 AUTHOR

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
