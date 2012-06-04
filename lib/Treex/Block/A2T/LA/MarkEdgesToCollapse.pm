package Treex::Block::A2T::LA::MarkEdgesToCollapse;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::A2T::MarkEdgesToCollapse';

sub _is_infinitive {
    my ( $self, $modal, $infinitive ) = @_;

    # In English, infinitives cannot precede modals
    #return 0 if $infinitive->precedes($modal);

    # "To serve(tag=VB,afun=Sb,parent=should) as subject infinitive clause
    #  should not be considered being part of modal construction."
    return 0 if $infinitive->afun eq 'Sb';

    # $infinitive (or one of its descendants) must have infinitive tag (5th position of AGDT tag is n)
    # "You can(tag=MD) go(tag=VB,parent=can)."
    # "It could(tag=MD) be(tag=VB,parent=done) done(tag=VBN,parent=could)."
    # "It could(tag=MD) have(tag=VB,parent=been) been(tag=VBN,parent=done) done(tag=VBN,parent=could)."
    return 1 if $infinitive->tag =~ /^....n/;
    return 1 if $infinitive->tag =~ /^VB[NG]/
            && any { $self->_is_infinitive( $modal, $_ ) }
               grep { $_->edge_to_collapse } $infinitive->get_children();

    # "be able(tag=JJ,parent=be) to" for simplicity, "able" is treated as infinitive
    return 1 if $infinitive->lemma eq 'able';
    return 0;
}

# Return 1 if $modal is a modal verb with regards to its $infinitive child
override is_modal => sub {
    my ( $self, $modal, $infinitive ) = @_;

    # Check if $infinitive is the lexical verb with which the modal should merge.
    return 0 if !$self->_is_infinitive( $modal, $infinitive );

    # "Standard" modals
    # (no inflection -s in the 3rd pers, cannot form participles)
    # Note that "will" is marked as AuxV (and not considered a modal), so it is
    # under the main verb and it is marked as auxiliary in is_aux_to_parent.
    return 1 if $modal->lemma =~ /^(can|cannot|could|may|might|must|shall|should|would)$/;

    # "Semi-modals"
    # (not stricly modal in the sense of English grammar, but expressing modality)
    # These take a long infinitive form with the particle "to".
    # "You have to(tag=TO, parent=go) go(parent=have)."
    if ( $modal->lemma =~ /^(have|ought|want)$/ || lc( $modal->form ) eq 'going' ) {
        my $first_child = $infinitive->get_children( { first_only => 1 } );
        return 1 if $first_child && $first_child->lemma eq 'to';
    }

    # "be able to VB" (border-case semi-modal)
    # multi word, so both the edges must be collapsed to parent
    return 1 if $modal->lemma eq 'be' && $infinitive->lemma eq 'able';
    return 1 if $modal->lemma eq 'able';

    return 0;
};

override is_aux_to_parent => sub {
    my ( $self, $node ) = @_;

    # Reuse base-class language independent rules
    my $base_result = super();
    return $base_result if defined $base_result;

    # TODO: mark cases when a node does not have afun=Aux*,
    # but still should collapse to parent.
    # This is language specific, e.g. in English:
    # RP  = adverb particle ("up, off, out,...")
    # EX  = existential "there"
    # POS = possessive "'s"
    #return 1 if $node->tag =~ /^(RP|EX|POS)$/;

    return 0;
};

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::A2T::LA::MarkEdgesToCollapse

=head1 DESCRIPTION

This block prepares a-trees for transformation into t-trees by filling in
two attributes: C<is_auxiliary> and C<edge_to_collapse>.
Each node marked as I<auxiliary> will not be present at the t-layer as a t-node.
It will collapse to its I<lexical> node according to C<edge_to_collapse>.
Generally, prepositions, subordinating conjunctions, and modal verbs
collapse to one of their children.
Other auxiliary nodes (aux verbs, determiners, commas,...) collapse to their parent.
Before applying this block, afun values must be filled (especially Aux* and Coord).

This block contains language specific rules for Latin
and it is derived from L<Treex::Block::A2T::MarkEdgesToCollapse>.

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
