package Treex::Block::T2T::CS2EN::RemovePerspronGender;

use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $t_node ) = @_;

    # only personal pronouns whose source node is also a personal pronoun
    return if ( $t_node->t_lemma ne '#PersPron' );
    my $t_src = $t_node->src_tnode();
    return if ( !$t_src or $t_src->t_lemma ne '#PersPron' );

    # look at the source side: skip anything where we don't know the antecedent (or it is not a common noun)
    my @coref = $t_src->get_coref_chain( { ordered => 1 } );

    if ( !@coref ) {

        # even without antecedent: generated subjects -- remove gender if 'anim' was just guessed
        # TODO: this is good for QTLeap, but bad for news !!
        if ( ( $t_src->formeme // '' ) eq 'drop' and ( $t_src->wild->{'aux_gram/gender'} // '' ) eq 'anim/inan/fem/neut' ) {
            $t_node->set_gram_gender('nr');
        }
        return;
    }

    my $t_antec = first { $_->gram_sempos =~ /^n.denot/ } reverse @coref;
    return if ( !$t_antec );

    # skip anything that might refer to persons
    return if ( $t_antec->is_name_of_person );

    my $a_antec = $t_antec->get_lex_anode() or return;
    my $n_antec = $a_antec->n_node;

    return if ( $n_antec and $n_antec->ne_type =~ /^[pP]/ );

    # remove the gender
    $t_node->set_gram_gender('nr');
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2T::CS2EN::RemovePerspronGender

=head1 DESCRIPTION

Removing Czech genders of C<#PersPron>s that do not refer to persons. They
will default to neuter gender "it" in English.

This rule aims mainly for precision -- the antecedent must be set, and it must
a noun, not a personal named entity (and C<is_name_of_person> must be false).

TODO: For QTLeap, it is good to also remove guessed gender of generated subjects,
but this is bad for the news domain. 

=head1 AUTHORS 

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

