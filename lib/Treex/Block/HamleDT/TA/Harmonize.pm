package Treex::Block::HamleDT::TA::Harmonize;
use Moose;
use Treex::Core::Common;
use utf8;
extends 'Treex::Block::HamleDT::HarmonizePDT';

has iset_driver =>
(
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    default       => 'ta::tamiltb',
    documentation => 'Which interset driver should be used to decode tags in this treebank? '.
                     'Lowercase, language code :: treebank code, e.g. "cs::pdt".'
);

#------------------------------------------------------------------------------
# Reads the TamilTB CoNLL trees, converts morphosyntactic tags to the positional
# tagset and transforms the tree to adhere to the HamleDT guidelines.
#------------------------------------------------------------------------------
sub process_zone
{
    my $self = shift;
    my $zone = shift;
    my $root = $self->SUPER::process_zone($zone);
}

#------------------------------------------------------------------------------
# Different source treebanks may use different attributes to store information
# needed by Interset drivers to decode the Interset feature values. By default,
# the CoNLL 2006 fields CPOS, POS and FEAT are concatenated and used as the
# input tag. If the morphosyntactic information is stored elsewhere (e.g. in
# the tag attribute), the Harmonize block of the respective treebank should
# redefine this method. Note that even CoNLL 2009 differs from CoNLL 2006.
#------------------------------------------------------------------------------
sub get_input_tag_for_interset
{
    my $self   = shift;
    my $node   = shift;
    # Even though we read the Tamil treebank converted to the CoNLL-X format,
    # we only need the contents of the POS column because the original
    # positional tag is stored there.
    return $node->conll_pos();
}

#------------------------------------------------------------------------------
# Convert dependency relation labels.
# http://ufal.mff.cuni.cz/pdt2.0/doc/manuals/cz/a-layer/html/ch03s02.html
#------------------------------------------------------------------------------
sub convert_deprels
{
    my $self  = shift;
    my $root  = shift;
    my @nodes = $root->get_descendants();
    foreach my $node (@nodes)
    {
        ###!!! We need a well-defined way of specifying where to take the source label.
        ###!!! Currently we try three possible sources with defined priority (if one
        ###!!! value is defined, the other will not be checked).
        my $deprel = $node->deprel();
        $deprel = $node->afun() if(!defined($deprel));
        $deprel = $node->conll_deprel() if(!defined($deprel));
        $deprel = 'NR' if(!defined($deprel));
        if($deprel =~ s/_M$//)
        {
            $node->set_is_member(1);
        }
        # The Apos tag in TamilTB is used differently from other Prague treebanks!
        # No members are expected under Apos! Instead, Apos denotes the appositional
        # modifier.
        if($deprel eq 'Apos')
        {
            ###!!! The Apos in Tamil Treebank denotes the hypotactic apposition
            ###!!! and we could simply relabel it with the HamleDT label for
            ###!!! hypotactic apposition, i.e., 'Apposition'. However, it is not
            ###!!! clear whether the label is used in situations comparable to
            ###!!! appositions in other Prague treebanks. Moreover, we would
            ###!!! have to make sure that the relation goes left-to-right (in
            ###!!! TamilTB it goes usually right-to-left). Therefore we now
            ###!!! convert it just to Atr.
            #$deprel = 'Apposition';
            $deprel = 'Atr';
        }
        # Certain TamilTB-specific deprels are not part of the HamleDT label set.
        # Adverbial complements and adjuncts are merged to just adverbials.
        if($deprel =~ m/^(AAdjn|AComp)$/)
        {
            $deprel = 'Adv';
        }
        # Adjectival participial or adjectivalized verb.
        # Most often attached to nouns.
        elsif($deprel eq 'AdjAtr')
        {
            $deprel = 'Atr';
        }
        # Part of a word.
        elsif($deprel eq 'CC')
        {
            if($node->parent()->get_iset('pos') eq 'verb')
            {
                $deprel = 'AuxT';
            }
            else
            {
                $deprel = 'Atr';
            }
        }
        # Complement other than attaching to verbs.
        elsif($deprel eq 'Comp')
        {
            $deprel = 'Atr';
        }
        $node->set_deprel($deprel);
    }
}



#------------------------------------------------------------------------------
# Catches possible annotation inconsistencies, especially in coordination.
# This method will be called right after converting the deprels to the
# harmonized label set, but before any tree transformations.
#------------------------------------------------------------------------------
sub fix_annotation_errors
{
    my $self  = shift;
    my $root  = shift;
    my @nodes = $root->get_descendants({ordered => 1});
    foreach my $node (@nodes)
    {
        # Fix members outside coordination.
        # The Apos tag in TamilTB is used differently from other Prague treebanks! No members are expected under Apos!
        if($node->is_member() && $node->parent()->deprel() ne 'Coord')
        {
            my $parent = $node->parent();
            if($parent->form() eq 'um' || $parent->deprel() eq 'AuxX')
            {
                $parent->set_deprel('Coord');
            }
            else
            {
                my $solved = 0;
                my $rs1 = $node->get_right_neighbor();
                if($rs1 && $rs1->form() eq '-')
                {
                    my $rs2 = $rs1->get_right_neighbor();
                    if($rs2->is_member())
                    {
                        $node->set_parent($rs1);
                        $rs2->set_parent($rs1);
                        $rs1->set_deprel('Coord');
                        $solved = 1;
                    }
                }
                if(!$solved)
                {
                    $node->set_is_member(undef);
                }
            }
        }
        # Fix coordination without conjuncts or apposition without members.
        my @children = $node->children();
        if($node->deprel() =~ m/^(Coord|Apos)$/ && !any {$_->is_member()} (@children))
        {
            if(scalar(@children)==0)
            {
                $node->set_deprel('AuxY');
            }
            else
            {
                $self->identify_coap_members($node);
            }
        }
    }
}

1;

=over

=item Treex::Block::HamleDT::TA::Harmonize

Converts TamilTB.v0.1 (Tamil Dependency Treebank) from CoNLL to the style of
HamleDT (Prague).

=back

=cut

# Copyright 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
