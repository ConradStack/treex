package Treex::Block::T2T::EN2CS::AddVerbAspect;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

use Treex::Tool::Lexicon::CS::Aspect;

my %TECTO_ASPECT_OF = ( 'P' => 'cpl', 'I' => 'proc', 'B' => 'proc' );    # obouvidova pokladam za nedokonava

sub get_verb_aspect {
    my $lemma = shift;
    return $TECTO_ASPECT_OF{ Treex::Tool::Lexicon::CS::Aspect::get_verb_aspect($lemma) };
}

sub process_tnode {
    my ( $self, $t_node ) = @_;

    if ( ( $t_node->gram_sempos || "" ) =~ /^v/ ) {
        $t_node->set_gram_aspect( get_verb_aspect( $t_node->t_lemma ) );
    }
    return;
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
