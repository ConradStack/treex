package Treex::Block::Write::AmrAligned;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Write::Amr';


override 'process_ttree' => sub {
    my ( $self, $ttree ) = @_;

    my ($src_ttree) = $ttree->src_tnode(); # the source t-ttree
    my ($atree) = $src_ttree->get_zone()->get_atree; # and its associated a-tree
   
    # print the sentence
    print  { $self->_file_handle } "# ::snt " . $ttree->get_zone()->sentence . "\n";
    print  { $self->_file_handle } "# ::tok "; # tokenized
    print  { $self->_file_handle } join(' ', map{$_->form} $atree->get_descendants({ordered=>1})) . "\n";

    # determine top AMR node 
    # (only child of the tech. root / tech. root in case of more root children)
    my @ttop_children = $ttree->get_children();
    my $tamr_top = @ttop_children > 1 ? $ttree : $ttop_children[0];

    # determine the alignment to surface and print it
    my %spans2nodes;
    $self->_add_aligned_spans(\%spans2nodes, $tamr_top, 0); # tech. root won't get alignment
    
    print { $self->_file_handle } "# ::alignments " . join(' ', map { $_ . '|' . $spans2nodes{$_} } keys %spans2nodes );
    print { $self->_file_handle } " ::annotator FakeAnnotator ::date 2013-09-26T04:27:51.715 ::editor AlignerTool v.03\n";

    $self->_print_ttree($tamr_top);    
};

# collecting alignments AMR <-> surface (adding it all to a hash where keys = surface word spans,
# values = AMR nodes)
sub _add_aligned_spans {
    
    my ($self, $tgt_hash, $tnode, $node_id) = @_;
    # process this node
    my $src_tnode = $tnode->src_tnode();
    my $lex_anode = $src_tnode ? $src_tnode->get_lex_anode() : undef;
   
    # just nodes that have a source t-node and a lexical a-node 
    if ($src_tnode and $lex_anode){
        # add this amr node under the a-node's ord into the hash
        my $ali_key = $lex_anode->ord . '-' . ($lex_anode->ord + 1);
        my $cur_alignment = ($tgt_hash->{$ali_key} // '');
        $cur_alignment .= '+' if ($cur_alignment);
        $cur_alignment .= $node_id;
        $tgt_hash->{$ali_key} = $cur_alignment;
    }

    # recurse to children
    my $child_no = 0;
    foreach my $tchild ($tnode->get_children({ordered=>1})){
        $self->_add_aligned_spans($tgt_hash, $tchild, $node_id . '.' . $child_no);
        $child_no++;
    }
    return;
}


1;

__END__

=head1 NAME

Treex::Block::Write::AmrAligned

=head1 DESCRIPTION

Document writer for amr-like format, with alignments

=head1 ATTRIBUTES

=over

=item language

Language of tree


=item selector

Selector of tree


=back


=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.