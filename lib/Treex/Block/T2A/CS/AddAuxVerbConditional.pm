package TCzechT_to_TCzechA::Add_auxverb_conditional;

use utf8;
use 5.008;
use strict;
use warnings;

use base qw(TectoMT::Block);

use utf8;

my %condit_numberperson2form = (
    'S1' => 'bych',
    'S2' => 'bys',
    'P1' => 'bychom',
    'P2' => 'byste',
);

sub process_bundle {
    my ( $self, $bundle ) = @_;

    foreach my $t_node ( $bundle->get_tree('TCzechT')->get_descendants() ) {
        process_tnode($t_node);
    }
    return;
}

sub process_tnode {
    my ($t_node) = @_;

    # We want to process only conditionals that don't have
    # 'conditional conjunctions' "aby", "kdyby" in the formeme.
    my $verbmod = $t_node->get_attr('gram/verbmod') || '';
    return if $verbmod ne 'cdn';
    return if $t_node->get_attr('formeme') =~ /(aby|kdyby)/;

    my $a_node   = $t_node->get_lex_anode();
    my $new_node = $a_node->create_child(
        {   attributes => {
                'm/lemma'         => 'být',
                'afun'            => 'AuxV',
                'morphcat/pos'    => 'V',
                'morphcat/subpos' =>, 'c',
                }
        }
    );

    my $person = $a_node->get_attr('morphcat/person')           || '';
    my $number = $a_node->get_attr('morphcat/number')           || '';
    my $form   = $condit_numberperson2form{ $number . $person } || 'by';
    $new_node->set_attr( 'm/form', $form );
    $t_node->add_aux_anodes($new_node);
    $new_node->shift_before_node($a_node);

    #TODO set a_node tense to past?
    $a_node->set_attr( 'morphcat/subpos', 'p' );
    return;
}

1;

=over

=item TCzechT_to_TCzechA::Add_auxverb_conditional

Add auxiliaries such as by/bys/bychom... expressing conditional verbmod.

=back

=cut

# Copyright 2008-2009 Zdenek Zabokrtsky, Martin Popel

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
