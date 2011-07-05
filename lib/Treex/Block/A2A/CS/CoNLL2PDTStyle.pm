package Treex::Block::A2A::CS::CoNLL2PDTStyle;
use Moose;
use Treex::Core::Common;
use utf8;
extends 'Treex::Block::A2A::CoNLL2PDTStyle';



#------------------------------------------------------------------------------
# Reads the Czech tree, converts morphosyntactic tags to the PDT tagset,
# converts deprel tags to afuns, transforms tree to adhere to PDT guidelines.
#------------------------------------------------------------------------------
sub process_zone
{
    my $self = shift;
    my $zone = shift;
    my $a_root = $self->SUPER::process_zone($zone);
}



#------------------------------------------------------------------------------
# Convert dependency relation tags to analytical functions.
# http://ufal.mff.cuni.cz/pdt2.0/doc/manuals/cz/a-layer/html/ch03s02.html
#------------------------------------------------------------------------------
sub deprel_to_afun
{
    my $self = shift;
    my $root = shift;
    my @nodes = $root->get_descendants();
    foreach my $node (@nodes)
    {
        my $deprel = $node->conll_deprel();
        my $afun = $deprel;
        if($afun =~ s/_M$//)
        {
            $node->set_is_member(1);
        }
        $node->set_afun($afun);
    }
}



1;



=over

=item Treex::Block::A2A::CS::CoNLL2PDTStyle

Converts PDT (Prague Dependency Treebank) trees from CoNLL to the style of
the Prague Dependency Treebank. The structure of the trees should already
adhere to the PDT guidelines because the CoNLL trees come from PDT. Some
minor adjustments to the analytical functions may be needed while porting
them from the conll/deprel attribute to afun. Morphological tags will be
decoded into Interset and converted back to the 15-character positional tags
of PDT.

=back

=cut

# Copyright 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
