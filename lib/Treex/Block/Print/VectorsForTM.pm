package Treex::Block::Print::VectorsForTM;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';
use Treex::Tool::TranslationModel::Features::EN;
binmode STDOUT, ':utf8';

has target_features => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => 'Print also features from the target language parent node',
);

has czeng_domain => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => 'Print also CzEng domain (eu, fiction, subtitles, paraweb, techdoc, news, navajo)',
);

sub process_tnode {
    my ( $self, $cs_tnode ) = @_;
    my ($en_tnodes_rf, $ali_types_rf) = $cs_tnode->get_aligned_nodes();
    for my $i (0 .. $#{$en_tnodes_rf}) {
        my $types = $ali_types_rf->[$i];
        if ($types =~ /int|tali/){
            $self->print_tnode_features($cs_tnode, $en_tnodes_rf->[$i], $types);
        }
    }
    return;
}

sub print_tnode_features {
    my ( $self, $cs_tnode, $en_tnode, $ali_types ) = @_;
    my $cs_anode = $cs_tnode->get_lex_anode or return;

    #return if $en_tnode->functor =~ /CONJ|DISJ|ADVS|APPS/;
    my $en_tlemma = $en_tnode->t_lemma // '';
    my $cs_tlemma = $cs_tnode->t_lemma // '';
    return if $en_tlemma !~ /\p{IsL}/ || $cs_tlemma !~ /\p{IsL}/;

    my $features_rf =
        Treex::Tool::TranslationModel::Features::EN::features_from_src_tnode( $en_tnode, { encode => 1 } ) or return;
    my ($cs_mlayer_pos) = ( $cs_anode->tag =~ /^(.)/ );

    my @add_features = ();

    # target-language features
    if ( $self->target_features ) {
        my ($cs_parent) = $cs_tnode->get_eparents( { or_topological => 1 } );
        my ($en_parent) = $en_tnode->get_eparents( { or_topological => 1 } );
        my ($en_parent2) = $cs_parent->get_aligned_nodes_of_type('int');
        my $edge_aligned = ( $cs_parent->is_root() && $en_parent->is_root() )
            || ( $en_parent2 && $en_parent2 == $en_parent );

        if ( $edge_aligned && $cs_parent->is_root() ) {
            @add_features = qw(TRG_parent_lemma=_ROOT TRG_parent_formeme=_ROOT);
        }
        elsif ($edge_aligned) {
            push @add_features, 'TRG_parent_lemma=' . $cs_parent->t_lemma;
            push @add_features, 'TRG_parent_formeme=' . $cs_parent->formeme;
        }
    }

    # alignment features
    my @gdfa_nodes = $cs_tnode->get_aligned_nodes_of_type('gdfa');
    if (@gdfa_nodes == 1){
        push @add_features, 'ali_int-gdfa=1';
    }
    foreach my $type (split /\./, $ali_types){
        if ($type =~ /int|tali/){
            push @add_features, "ali_$type=1";
        }
    }

    # domain feature
    if ( $self->czeng_domain ) {
        if ( my $domain = $cs_tnode->get_bundle()->attr('czeng/domain') ) {
            push @add_features, "domain=$domain";
        }
    }

    print join "\t", (
        lc($en_tlemma),
        $cs_tlemma . "#" . $cs_mlayer_pos,
        $en_tnode->formeme,
        $cs_tnode->formeme,
        join ' ', @add_features, map {"$_=$features_rf->{$_}"} keys %{$features_rf}
    );
    print "\n";
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::Print::VectorsForTM - print features for training translation models

=head1 DESCRIPTION

For each node, one line is printed
TODO

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
