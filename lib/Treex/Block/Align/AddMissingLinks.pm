package Treex::Block::Align::AddMissingLinks;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

use Treex::Tool::Depfix::CS::DiacriticsStripper;
use Treex::Tool::Lexicon::CS;

has 'layer' => (
    is      => 'ro',
    isa     => 'Treex::Type::Layer',
    default => 'a'
);

has '+language' => ( required => 1 );

has 'target_language' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'target_selector' => (
    is      => 'ro',
    isa     => 'Str',
    default => ''
);

has 'alignment_type' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'intersection'
);

has 'alignment_type_new' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => undef
);

has 'log_to_console' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

sub process_start {
    my ($self) = @_;

    if ( !defined $self->alignment_type_new ) {
        $self->set_alignment_type_new( $self->alignment_type );
    }

    return;
}

sub process_bundle {
    my ( $self, $bundle ) = @_;

    # source nodes
    my $source_tree_root =
      $bundle->get_tree( $self->language, $self->layer, $self->selector );
    my $source_nodes = $self->get_descendants_hash($source_tree_root);

    # target nodes
    my $target_tree_root =
      $bundle->get_tree( $self->target_language, $self->layer,
        $self->target_selector );
    my $target_nodes = $self->get_descendants_hash($target_tree_root);

    # remove those that are aligned
    foreach my $source_node_id ( keys %$source_nodes ) {
        my $source_node = $source_nodes->{$source_node_id};
        my @aligned_nodes =
          $source_node->get_aligned_nodes_of_type( $self->alignment_type );
        if (@aligned_nodes) {
            delete $source_nodes->{$source_node_id};
            foreach my $target_node (@aligned_nodes) {
                delete $target_nodes->{ $target_node->id };
            }
        }
    }

    # add new links
    my @source_nodes_ordered   = $self->sort_descendants_hash($source_nodes);
    my @target_nodes_ordered   = $self->sort_descendants_hash($target_nodes);
    my $unaligned_target_nodes = @target_nodes_ordered;
  OUTER: foreach my $source_node (@source_nodes_ordered) {
        foreach my $target_node (@target_nodes_ordered) {
            if ( $self->nodes_match( $source_node, $target_node ) ) {

                # add link
                $source_node->add_aligned_node( $target_node,
                    $self->alignment_type_new );
                $self->logfix( "New link: "
                      . $source_node->form . " --> "
                      . $target_node->form );

                # update structures
                delete $source_nodes->{ $source_node->id };
                delete $target_nodes->{ $target_node->id };
                @target_nodes_ordered =
                  $self->sort_descendants_hash($target_nodes);

                # go to next source node
                next OUTER;
            }
        }
    }
    if ( $unaligned_target_nodes != @target_nodes_ordered ) {
        $self->logfix( "Reduced number of unaligned target nodes from "
              . $unaligned_target_nodes . " to "
              . @target_nodes_ordered );
    }

    return;
}

sub get_descendants_hash {
    my ( $self, $root ) = @_;

    my @descendants_array = $root->get_descendants();
    my %descendants_hash  = ();

    foreach my $descendant (@descendants_array) {
        $descendants_hash{ $descendant->id } = $descendant;
    }

    return \%descendants_hash;
}

sub sort_descendants_hash {
    my ( $self, $hash ) = @_;

    my @sorted = sort { $a->ord <=> $b->ord } values %$hash;

    return @sorted;
}

sub nodes_match {
    my ( $self, $node1, $node2 ) = @_;

    my $lemma1 =
      Treex::Tool::Depfix::CS::DiacriticsStripper::strip_diacritics(
        Treex::Tool::Lexicon::CS::truncate_lemma( lc( $node1->lemma ), 1 ) );
    my $lemma2 =
      Treex::Tool::Depfix::CS::DiacriticsStripper::strip_diacritics(
        Treex::Tool::Lexicon::CS::truncate_lemma( lc( $node2->lemma ), 1 ) );
    my $form1 = Treex::Tool::Depfix::CS::DiacriticsStripper::strip_diacritics(
        lc( $node1->form ) );
    my $form2 = Treex::Tool::Depfix::CS::DiacriticsStripper::strip_diacritics(
        lc( $node2->form ) );

    my $nodes_match =
         ( $lemma1 eq $lemma2 )
      || ( $form1  eq $form2 )
      || ( $form1  eq $lemma2 )
      || ( $lemma1 eq $form2 );

    return $nodes_match;
}

sub logfix {
    my ( $self, $msg ) = @_;

    if ( $self->log_to_console ) {
        log_info $msg;
    }

    return;
}

1;

=head1 NAME 

Treex::Block::Align::AddMissingLinks
- try to guess some missing alignment links in intersection alignment

=head1 DESCRIPTION

Tries to fix alignment on the given C<layer>
(a-layer by default).

Adds links between nodes of matching form/lemma.
The lemmas are truncated using L<Treex::Tool::Lexicon::CS::truncate_lemma>,
and both forms and lemmas are lowercased
and their diacritics are stripped.
If then a match is found among the forms and lemmas,
a new alignment link is created between these nodes.

Assumes the links go from C<language>_C<selector>
to C<target_language>_C<target_selector>
and are of type C<alignment_type>.

Does not touch nodes that already have an alignment link.

Is intended to be used with the intersection alignment
but can be used with any aligment type.

=head1 PARAMETERS

=over

=item layer

The layer, most probably C<a> or C<t>. The default is C<a>.

=item language

The source language. Required.

=item selector

The source selector. The default is empty.

=item target_language

The target language. Required.

=item target selector

The target selector. The default is empty.

=item alignment_type

The type of alignment to use.
Actually this is regarded as a regular expression,
so you can use multiple alignments at once
(in such case, be sure to set C<alignment_type_new> as well).

B<Caveats>: if the value given is a substring of another alignment type
(eg. C<'type'> is a substring of C<'type.2'>),
all such alignments will be used (as all of them match the regex)!
If this is not desirable, set C<'^type$'> as C<alignment_type> 
and C<'type'> as C<alignment_type_new> !

The default value is C<intersection>.

=item alignment_type_new

The type of alignment to set for new links. Defaults to C<alignment_type>.

=back

=head1 AUTHOR

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 by Institute of Formal and Applied Linguistics,
Charles University in Prague

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

