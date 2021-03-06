package Treex::Block::T2T::EN2CS::FixMoney;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

my %CURRENCY = (
    '$'   => 'dolar',
    'HUF' => 'forint',
    '£'  => 'libra',
);

sub process_tnode {
    my ( $self, $t_node ) = @_;

    if ( $CURRENCY{ $t_node->t_lemma } ) {

        # rehang the currency node
        my $value_tnode = $t_node->get_children( { following_only => 1, first_only => 1 } );
        if ($value_tnode) {
            foreach my $child ( $t_node->get_children ) {
                $child->set_parent($value_tnode) if $child ne $value_tnode;
            }
            $value_tnode->set_parent( $t_node->get_parent );
            $t_node->set_parent($value_tnode);
            $value_tnode->set_formeme( $t_node->formeme );
            if ( $t_node->is_member ) {
                $t_node->set_is_member(0);
                $value_tnode->set_is_member(1);
            }
        }

        # change t_lemma and formeme of the currency node
        $t_node->set_t_lemma( $CURRENCY{ $t_node->t_lemma } );
        $t_node->set_t_lemma_origin('rule-FixMoney');
        $t_node->set_attr('mlayer_pos', 'N');
        $t_node->set_formeme('n:2');
        $t_node->set_formeme_origin('rule-FixMoney');
        $t_node->set_gram_number('pl');

        # shift the currency after nodes expressing value (numbers, million, billion, m)
        my $next_node = $t_node->get_next_node;
        my $last_value_node;
        while ( $next_node && $next_node->t_lemma =~ /^([\d,\.\ ]+|mili[oó]n|miliarda|m)$/ ) {
            $last_value_node = $next_node;
            $next_node       = $next_node->get_next_node;
        }
        $t_node->shift_after_node($last_value_node) if defined $last_value_node;
    }
    return;
}

1;

=encoding utf8

=over

=item Treex::Block::T2T::EN2CS::FixMoney

Rehangs the children of currency node (e.g. "$") to the value node (e.g. "500").
Translates e.g. "$" to "dolar".
Changes the word order.

=back

=cut

# Copyright 2010 David Marecek
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
