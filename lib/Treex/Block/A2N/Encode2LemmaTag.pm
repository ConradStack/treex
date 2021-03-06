package Treex::Block::A2N::Encode2LemmaTag;
use Moose;
use Treex::Core::Common;
use Treex::Tool::Lexicon::CS;

extends 'Treex::Core::Block';

sub process_zone {
    my ( $self, $zone ) = @_;

    return if !$zone->has_ntree();
    my $n_root = $zone->get_ntree();
   
    # To prevent deleting one node twice, in case of nested named entities.
    my %solved = ();
    
    foreach my $outer_n_node ($n_root->get_children()){
        my ($first_a_node, @other_a_nodes) = $outer_n_node->get_anodes();
        
        # TODO warn
        next if !$first_a_node;
        next if $solved{$first_a_node->id};
        $solved{$first_a_node->id} = 1;
        #my $name = $outer_n_node->normalized_name();
        #$name =~ s/ /_/g;
        #$first_a_node->set_lemma($name);
        
        my $merged_lemma = join '_', map {Treex::Tool::Lexicon::CS::truncate_lemma($_->lemma,1)} ($first_a_node, @other_a_nodes);
        $first_a_node->set_lemma($merged_lemma);
        my $merged_form = join '_', map {$_->form} ($first_a_node, @other_a_nodes);
        $first_a_node->set_form($merged_form);
        $first_a_node->set_tag($outer_n_node->ne_type);
        
        # Delete @other_a_nodes
        foreach my $a_node (@other_a_nodes){
            next if ref $a_node eq 'Treex::Core::Node::Deleted'; # TODO: why is this needed?
            next if $solved{$a_node->id};
            $solved{$a_node->id} = 1;
            foreach my $a_child ($a_node->get_children()){
                $a_child->set_parent($a_node->get_parent());
            }
            $a_node->remove();
        }
        
    }
    
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::A2N::Encode2LemmaTag - substitute a-nodes lemma, form and tag based on NE annotation

=head1 DESCRIPTION

This is a special-purpose block for Pavel Pecina.
For each named entity, all the corresponding a-nodes are merged into one a-node.
Its lemma is set to the concatenation of the original lemmas joined with underscores,
its form is set to the concatenation of the original forms joined with underscores,
and its PoS tag is set to the entity type.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
