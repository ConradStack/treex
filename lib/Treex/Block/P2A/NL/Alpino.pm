package Treex::Block::P2A::NL::Alpino;
use Moose;
use Treex::Core::Common;
use utf8;

use tagset::nl::cgn;
#use Treex::Block::HamleDT::NL::Harmonize;

extends 'Treex::Core::Block';

#has '_harmonizer' => ( isa => 'Treex::Block::HamleDT::NL::Harmonize', 
        #'is' => 'ro', 
        #lazy_build => 1, 
        #builder => '_build_harmonizer',
        #reader => '_harmonizer',
    #);

#sub _build_harmonizer {
    #my ($self) = @_;
    #return Treex::Block::HamleDT::NL::Harmonize->new();
#}

has '_processed_nodes' => ( isa => 'HashRef', 'is' => 'rw' );
has '_nodes_to_remove' => ( isa => 'HashRef', 'is' => 'rw' );

my %HEAD_SCORE = ('hd' => 6, 'cmp' => 5, 'crd' => 4, 'dlink' => 3, 'rhd' => 2, 'whd' => 1);

my %DEPREL_CONV = (
    'su' => 'Sb',
    'sup' => 'Sb',
    'obj1' => 'Obj',
    'pobj1' => 'Obj',
    'se' => 'Obj', # reflexive
    'obj2' => 'Obj',
    'me' => 'Obj', # adverbial complement
    'ld' => 'Obj', # ditto
    'predc' => 'Pnom', # predicative complement
    'vc' => 'Obj', # verbal complement (?)
    'obcomp' => 'Obj', # comparative complement of an adjective
    'pc' => 'Obj', # prepositional object
    'svb' => 'AuxV', # separable verbal prefix
    'svp' => 'Obj', # compound predicate
    'predm' => 'Adv',
    'mwp' => 'AuxP',
    'cmp' => 'AuxC',
    'crd' => 'Coord',
    'app' => 'Apos',
    'se' => 'AuxT',
);

sub convert_deprel {
    my ($self, $node) = @_;

    my $deprel = $node->conll_deprel // '';
    my $afun = $DEPREL_CONV{$deprel};
    if (!$afun) {
        if ($deprel eq 'mod'){
            $afun = 'Atr' if ($node->is_adjective);
            $afun = 'Neg' if ($node->lemma eq 'niet');
            $afun = 'Adv' if (!$afun);
        }
        elsif($deprel eq 'hd'){
            $afun = 'Atr' if ($node->match_iset('synpos' => 'attr'));
            $afun = 'Pred' if ($node->is_verb and $node->parent->is_root);
            $afun = 'AuxP' if ($node->is_preposition);
            $afun = 'Obj' if (!$afun);  # TODO fix subject selection
        }
        elsif($deprel eq 'det'){
            $afun = $node->match_iset('subpos' => 'art') ? 'AuxA' : 'Atr';        
        }
        elsif($deprel eq '--'){
            $afun = 'AuxK' if ($node->lemma =~ /[\.!?]/);
            $afun = 'AuxX' if ($node->lemma eq ',');
            $afun = 'AuxG' if (!$afun);
        }
        else {
            $afun = 'NR'; # keep unselected
        }
    }
    $node->set_afun($afun);
}

sub convert_pos {
    my ($self, $node, $postag) = @_;
    
    # convert to Interset (TODO would need CoNLL encoding capability to set CoNLL POS+feat)
    my $iset = tagset::nl::cgn::decode($postag);
    $node->set_iset($iset);
}

sub _leftmost_terminal_ord {
    my ($p_node) = @_;
    return min( map { $_->wild->{pord} } grep { $_->form and $_->wild->{pord} } $p_node->get_descendants() );
}

sub create_subtree {

    my ($self, $p_root, $a_root) = @_;
    
    my @children = sort {($HEAD_SCORE{$b->wild->{rel}} || 0) <=> ($HEAD_SCORE{$a->wild->{rel}} || 0)} grep {!defined $_->form || $_->form !~ /^\*\-/} $p_root->get_children();
    #my @children = sort {($HEAD_SCORE{$b->wild->{rel}} || 0) <=> ($HEAD_SCORE{$a->wild->{rel}} || 0)} $p_root->get_children();
    
    # no coordination head -> insert commas from those attached to sentence root
    if ($p_root->phrase eq 'conj' and not any {$_->form} @children){
        my ($last_child) = sort { _leftmost_terminal_ord($b) <=> _leftmost_terminal_ord($a) } @children;        
        my $needed_ord = _leftmost_terminal_ord($last_child) - 1;
        my ($punct_node) = grep { ($_->wild->{pord} // -1) == $needed_ord } $p_root->get_root()->get_children();

        if ($punct_node){
            $punct_node->wild->{rel} = 'crd';
            unshift @children, $punct_node;
            # an a-node for the same p-node has already been created -> mark it for deletion
            if ($self->_processed_nodes->{$punct_node}){
                $self->_nodes_to_remove->{$punct_node} = $self->_processed_nodes->{$punct_node};
            }
            # remember that we created an a-node for this p-node
            $self->_processed_nodes->{$punct_node} = $a_root;
        }
    }

    my $head = $children[0];
    foreach my $child (@children) {
        my $new_node;
        if ($child == $head) {
            $new_node = $a_root;
        }
        else {
            $new_node = $a_root->create_child();
        }
        if (defined $child->form) { # the node is terminal
            $self->fill_attribs($child, $new_node);
        }
        elsif (defined $child->phrase) { # the node is nonterminal
            $self->create_subtree($child, $new_node);
        }
    }
}

# fill newly created node with attributes from source
sub fill_attribs {
    my ($self, $source, $new_node) = @_;

    $new_node->set_form($source->form);
    $new_node->set_lemma($source->lemma);
    $new_node->set_tag($source->tag);
    $new_node->set_attr('ord', $source->wild->{pord});
    $new_node->set_conll_deprel($source->wild->{rel});
    $self->convert_pos($new_node, $source->wild->{postag});
    foreach my $attr (keys %{$source->wild}) {
        next if $attr =~ /^(pord|rel)$/;
        $new_node->wild->{$attr} = $source->wild->{$attr};
    }
    $self->convert_deprel($new_node);
}


sub process_zone {
    my ($self, $zone) = @_;
    my $p_root = $zone->get_ptree;
    my $a_root = $zone->create_atree();

    $self->_set_processed_nodes({});
    $self->_set_nodes_to_remove({});
    foreach my $child ($p_root->get_children()) {

        # skip nodes already attached to coordination
        next if ($self->_processed_nodes->{$child});

        my $new_node = $a_root->create_child();

        if ($child->phrase) {
            $self->create_subtree($child, $new_node);
        }
        else {
            $self->fill_attribs($child, $new_node);
            # remember that we created an a-node for this p-node (likely punctuation)
            # so it gets deleted if we use the p-node as coordination head
            $self->_processed_nodes->{$child} = $new_node;
        }
    }
    # remove doubly created punctuation nodes (keep coord heads)
    foreach my $node (values %{$self->_nodes_to_remove}){
        $node->remove();
    }
    # post-processing
    $self->rehang_relative_clauses($a_root);
}

sub rehang_relative_clauses {
    my ($self, $a_root) = @_;

    foreach my $anode (grep { $_->conll_deprel eq 'rhd' } $a_root->get_descendants()){
        my ($clause) = $anode->get_children();
        my $parent = $anode->get_parent();
        $clause->set_parent($parent);
        $anode->set_parent($clause);
        $anode->set_afun('Obj');
        $clause->set_afun('Atr');
    }
}

1;

=over

=item Treex::Block::P2A::NL::Alpino

Converts phrase-based Dutch Alpino Treebank to dependency format.

=back

=cut

# Copyright 2014 David Mareček <marecek@ufal.mff.cuni.cz>
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
