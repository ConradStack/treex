package Treex::Block::Read::CoNLLX;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Read::BaseTextReader';

sub next_document {
    my ($self) = @_;
    my $text = $self->next_document_text();
    return if !defined $text;

    my $document = $self->new_document();
    foreach my $tree ( split /\n\s*\n/, $text ) {
        my $bundle = $document->create_bundle();
        my $zone = $bundle->create_zone( $self->language, $self->selector );
        my @tokens = split (/\n/, $tree);
        my $aroot = $zone->create_atree();
        my @parents = (0);
        my @nodes = ($aroot);
        my $sentence;
        foreach my $token (@tokens) {
            next if $token =~ /^\s*$/;
            my ($id, $form, $lemma, $cpos, $pos, $feat, $head, $deprel) = split(/\t/, $token);
            my $newnode = $aroot->create_child();
            $newnode->shift_after_subtree($aroot);
            $newnode->set_form($form);
            $newnode->set_lemma($lemma);
            $newnode->set_tag($pos);
            $newnode->set_conll_deprel($deprel);
            $sentence .= "$form ";
            push @nodes, $newnode;
            push @parents, $head;
        }
        foreach my $i (1 .. $#nodes) {
            $nodes[$i]->set_parent($nodes[$parents[$i]]);
        }
        $sentence =~ s/\s+$//;
        $zone->set_sentence( $sentence );
    }

    return $document;
}

1;

__END__

=head1 NAME

Treex::Block::Read::CoNLLX

=head1 DESCRIPTION

Document reader for CoNLL format.
Each token is on separated line in the following format:
ord<tab>form<tab>lemma<tab>pos<tab>ppos<tab>features<tab>head<tab>deprel
Sentences are separated with blank line.
The sentences are stored into L<bundles|Treex::Core::Bundle> in the 
L<document|Treex::Core::Document>.

=head1 ATTRIBUTES

=over

=item from

space or comma separated list of filenames

=back

=head1 METHODS

=over

=item next_document

Loads a document.

=back

=head1 SEE

L<Treex::Block::Read::BaseTextReader>
L<Treex::Core::Document>
L<Treex::Core::Bundle>

=head1 AUTHOR

David Mareček

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
