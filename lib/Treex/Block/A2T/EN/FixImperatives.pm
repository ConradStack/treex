package Treex::Block::A2T::EN::FixImperatives;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_ttree {
    my ( $self, $t_root ) = @_;

    foreach my $tnode ( grep { $_->formeme eq "v:fin" } $t_root->get_echildren ) {
        my $anode = $tnode->get_lex_anode;

        next if ( $tnode->sentmod || '' ) eq 'inter';
        next if not $anode or $anode->tag ne "VB";
        next if grep { $_->tag     eq "MD" } $tnode->get_aux_anodes;
        next if grep { $_->formeme eq "n:subj" } $tnode->get_echildren;

        $tnode->set_attr( 'gram/verbmod', 'imp' );
        $tnode->set_sentmod('imper');

        my $perspron = $tnode->create_child;
        $perspron->shift_before_node($tnode);

        $perspron->set_t_lemma('#PersPron');
        $perspron->set_functor('ACT');
        $perspron->set_formeme('n:subj');    # !!! elided?
        $perspron->set_nodetype('complex');
        $perspron->set_attr( 'gram/sempos', 'n.pron.def.pers' );
        $perspron->set_attr( 'gram/number', 'pl' );                # default: vykani
        $perspron->set_attr( 'gram/gender', 'anim' );
        $perspron->set_attr( 'gram/person', '2' );

    }

    return 1;
}

1;

=over

=item Treex::Block::A2T::EN::FixImperatives

Imperatives are recognized (at least some of), and provided with
a new PersPron node and corrected gram/verbmod value.

=back

=cut

# Copyright 2010 Zdenek Zabokrtsky

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
