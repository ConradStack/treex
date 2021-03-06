package Treex::Block::A2T::EN::FixEitherOr;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_ttree {
    my ( $self, $t_root ) = @_;

    foreach my $or (
        grep { $_->t_lemma =~ /^n?or$/ }
        $t_root->get_descendants
        )
    {

        my ($either) = grep { $_->t_lemma =~ /^n?either$/ } $or->get_descendants
            or next;

        foreach my $child ( $either->get_children ) {    #there should be none, but who knows...
            $child->set_parent( $either->get_parent );
        }

        # tlemmas such as 'either_or' are created
        $or->set_t_lemma( $either->t_lemma . "_" . $or->t_lemma );
        $or->add_aux_anodes( $either->get_anodes );
        $or->set_functor('DISJ');
        $or->set_nodetype('coap');
        $either->remove();

        #        print $or->t_lemma."\t". $or->get_address."\n";
    }

    return 1;
}

1;

=over

=item Treex::Block::A2T::EN::FixEitherOr

Creates a single t-node from 'either' and 'or' pair (as well as from neither/or
and neither/nor).

=back

=cut

# Copyright 2010 Zdenek Zabokrtsky

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
