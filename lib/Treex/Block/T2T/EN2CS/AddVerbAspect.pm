package Treex::Block::T2T::EN2CS::AddVerbAspect;
use Moose;
use Treex::Moose;
extends 'Treex::Core::Block';




use Lexicon::CS::Aspect;

Readonly my %TECTO_ASPECT_OF => ( 'P' => 'cpl', 'I' => 'proc', 'B' => 'proc' );    # obouvidova pokladam za nedokonava

sub get_verb_aspect {
    my $lemma = shift;
    return $TECTO_ASPECT_OF{ Lexicon::CS::Aspect::get_verb_aspect($lemma) };
}

sub process_document {

    my ( $self, $document ) = @_;

    foreach my $bundle ( $document->get_bundles() ) {
        my $t_root = $bundle->get_tree('TCzechT');

        foreach my $t_node ( grep { ( $_->get_attr('gram/sempos') || "" ) =~ /^v/ } $t_root->get_descendants ) {
            $t_node->set_attr( 'gram/aspect', get_verb_aspect( $t_node->t_lemma ) );
        }
    }
}

1;

=over

=item Treex::Block::T2T::EN2CS::AddVerbAspect

Fill the grammateme of aspect according to the verb t_lemma which comes
from the lexical transfer.

=back

=cut

# Copyright 2008 Zdenek Zabokrtsky

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
