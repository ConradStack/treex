package Treex::Block::A2A::DE::CoNLL2PDTStyle;
use Moose;
use Treex::Core::Common;
use utf8;
extends 'Treex::Block::A2A::CoNLL2PDTStyle';



#------------------------------------------------------------------------------
# Reads the German tree, converts morphosyntactic tags to the PDT tagset,
# converts deprel tags to afuns, transforms tree to adhere to PDT guidelines.
#------------------------------------------------------------------------------
sub process_zone
{
    my $self = shift;
    my $zone = shift;
    my $a_root = $self->SUPER::process_zone($zone, 'conll2009');
}



#------------------------------------------------------------------------------
# Convert dependency relation tags to analytical functions.
# less /net/data/conll/2007/ar/doc/README
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
        # PADT defines some afuns that were not defined in PDT.
        # PredE = existential predicate
        # PredC = conjunction as the clause's head
        # PredP = preposition as the clause's head
        if($afun =~ m/^Pred[ECP]$/)
        {
            $afun = 'Pred';
        }
        # Ante = anteposition
        elsif($afun eq 'Ante')
        {
            $afun = 'Apos';
        }
        # AuxE = emphasizing expression
        # AuxM = modifying expression
        elsif($afun =~ m/^Aux[EM]$/)
        {
            $afun = 'AuxZ';
        }
        # _ = excessive token esp. due to a typo
        elsif($afun eq '_')
        {
            $afun = '';
        }
        $node->set_afun($afun);
    }
}



1;



=over

=item Treex::Block::A2A::DE::CoNLL2PDTStyle

Converts Tiger trees from CoNLL to the style of
the Prague Dependency Treebank.
Morphological tags will be
decoded into Interset and to the 15-character positional tags
of PDT.

=back

=cut

# Copyright 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
