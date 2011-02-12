package Treex::Block::T2T::EN2CS::TrLFilterAspect;
use Moose;
use Treex::Moose;
extends 'Treex::Core::Block';


use Readonly;
use Report;

use Lexicon::CS::Aspect;


Readonly my %IS_PHASE_VERB => (
    'začít' => 1, 'začínat' => 1, 'přestat' => 1, 'přestávat' => 1,
);

sub process_bundle {
    my ( $self, $bundle ) = @_;
    my $cs_troot = $bundle->get_tree('TCzechT');

    foreach my $cs_tnode ( $cs_troot->get_descendants() ) {

        # We want to check only verbs with more translation variants
        next if ( $cs_tnode->get_attr('gram/sempos') || '' ) ne 'v';
        next if $cs_tnode->get_attr('t_lemma_origin') !~ /^dict-first/;
        filter_variants($cs_tnode);
    }
    return;
}

sub filter_variants {
    my ($node) = @_;
    my $variants_ref = $node->get_attr('translation_model/t_lemma_variants');

    my @filtred = grep { is_aspect_ok( $_->{t_lemma}, $node ) } @{$variants_ref};
    
    # If no or all variants were filtred, don't change anything 
    return if @filtred == 0 || @filtred == @{$variants_ref};
    
    $node->set_attr('translation_model/t_lemma_variants', \@filtred);
    
    my $first_lemma = $filtred[0]->{t_lemma};
    if ($node->t_lemma ne $first_lemma) {
        $node->set_t_lemma($first_lemma);
        $node->set_attr('mlayer_pos', $filtred[0]->{pos});
    }
    
    return;
}

sub is_aspect_ok {
    my ( $cs_lemma, $node ) = @_;
    my $aspect = Lexicon::CS::Aspect::get_verb_aspect($cs_lemma);
    return 1 if $aspect ne 'P';

    # Following combinations are uncompatible with perfective aspect
    # 1. "thay say" -> "říkají", not "řeknou"
    return 0
        if (
        ( $node->get_attr('gram/tense') || '' ) eq 'sim'
        and ( $node->get_attr('gram/deontmod') || '' ) eq 'decl'
        and ( $node->get_attr('gram/verbmod') || '' ) ne 'cdn'
        and ( $node->is_passive   || '' ) ne '1'
        and ( $node->functor      || '' ) ne 'COND'
        );

    # 2. "dokud dělal", not "dokud udělal"
    my $en_node = $node->get_source_tnode();
    return 0 if $en_node && $en_node->formeme eq 'v:as_long_as+fin';

    # 3. "začal dělat", not "začal udělat"
    my $parent = $node->get_parent() or return 1;
    return 1 if $parent->is_root();
    my $parent_lemma = $parent->t_lemma;
    return 0 if $IS_PHASE_VERB{$parent_lemma};

    
    # Otherwise: OK
    return 1;
}

1;

__END__

=over

=item Treex::Block::T2T::EN2CS::TrLFilterAspect

Applies some rules to filter out verb t-lemmas with uncompatible aspect.  
Such translation variants are removed from
the C<translation_model/t_lemma_variants> attribute.

=back

=cut

# Copyright 2009 Martin Popel
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
