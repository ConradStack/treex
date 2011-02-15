package Treex::Block::T2T::EN2CS::CutVariants;
use Moose;
use Treex::Moose;
extends 'Treex::Core::Block';

sub BUILD {
    my ( $class, $id, $arg_ref ) = @_;
    my $max_lemmas   = $arg_ref->{MAX_LEMMA_VARIANTS};
    my $max_formemes = $arg_ref->{MAX_FORMEME_VARIANTS};
    my $l_sum        = $arg_ref->{LEMMA_PROB_SUM};
    my $f_sum        = $arg_ref->{FORMEME_PROB_SUM};
    Report::fatal(
        'Applying Cut_variants block without specifying parameters does not make sense. '
            . 'Add at least one of: MAX_LEMMA_VARIANTS, MAX_FORMEME_VARIANTS, LEMMA_PROB_SUM, FORMEME_PROB_SUM.'
        )
        if !defined $max_lemmas && !defined $max_formemes && !defined $l_sum && !defined $f_sum;
    Report::fatal("LEMMA_PROB_SUM=$l_sum is not in <0,1>")   if defined $l_sum && ( $l_sum < 0 or $l_sum > 1 );
    Report::fatal("FORMEME_PROB_SUM=$f_sum is not in <0,1>") if defined $f_sum && ( $f_sum < 0 or $f_sum > 1 );
    return;
}

sub process_bundle {
    my ( $self, $bundle ) = @_;
    my $cs_troot     = $bundle->get_tree('TCzechT');
    my $max_lemmas   = $self->get_parameter('MAX_LEMMA_VARIANTS');
    my $max_formemes = $self->get_parameter('MAX_FORMEME_VARIANTS');
    my $l_sum        = $self->get_parameter('LEMMA_PROB_SUM');
    my $f_sum        = $self->get_parameter('FORMEME_PROB_SUM');

    foreach my $node ( $cs_troot->get_descendants() ) {

        # t_lemma_variants
        my $lemmas = $max_lemmas;
        my $ls_ref = $node->get_attr('translation_model/t_lemma_variants');
        if ( $l_sum && $ls_ref ) {
            my ( $sum, $variants ) = ( 0, 0 );
            while ( $sum < $l_sum && $variants < @{$ls_ref} ) {
                $sum += 2**$ls_ref->[ $variants++ ]{'logprob'};
            }
            if ( !defined $lemmas or $variants < $lemmas ) {
                $lemmas = $variants;
            }
        }
        if ( $lemmas && $ls_ref && @{$ls_ref} > $lemmas ) {
            splice @{$ls_ref}, $lemmas;
        }

        # same for formeme_variants
        my $formemes = $max_formemes;
        my $fs_ref   = $node->get_attr('translation_model/formeme_variants');
        if ( $f_sum && $fs_ref ) {
            my ( $sum, $variants ) = ( 0, 0 );
            while ( $sum < $f_sum && $variants < @{$fs_ref} ) {
                $sum += 2**$fs_ref->[ $variants++ ]{'logprob'};
            }
            if ( !defined $formemes or $variants < $formemes ) {
                $formemes = $variants;
            }
        }
        if ( $formemes && $fs_ref && @{$fs_ref} > $formemes ) {
            splice @{$fs_ref}, $formemes;
        }
    }
    return;
}

1;

__END__

=over

=item Treex::Block::T2T::EN2CS::CutVariants

Utility block that deletes some translation variants of t-lemmas and formemes.
By parameters (MAX_[LEMMA|FORMEME]_VARIANTS and [LEMMA|FORMEME]_PROB_SUM) you can set
the number of variants to be left in the C<translation_model/t_lemma_variants>
and C<translation_model/formeme_variants> attributes.

PARAMETERS:

=over

=item MAX_LEMMA_VARIANTS

Retain at most MAX_LEMMA_VARIANTS translation variants.

=item LEMMA_PROB_SUM

Retain at most N translation variants, where N is the smallest number so that a sum of N first probabilities is higher than LEMMA_PROB_SUM.

=item MAX_FORMEME_VARIANTS

=item FORMEME_PROB_SUM

=back

Conditions are evaluated in conjunction, for example, MAX_LEMMA_VARIANTS=3 and LEMMA_PROB_SUM=0.6
nodeA: prob1=0.5 prob2=0.2 prob3=0.1             ... 2 variants left (sum=0.7)
nodeB: prob1=0.3 prob2=0.1 prob3=0.1 prob4=0.05  ... 3 variants left (sum=0.5)


If the variants were generated by
L<SEnglishT_to_TCzechT::Translate_L_add_variants> or
L<SEnglishT_to_TCzechT::Translate_F_add_variants> block,
you can also use their own C<MAX_VARIANTS> parameter
so superfluous variants are never even saved to the attributes.

=back

=cut

# Copyright 2008 Martin Popel
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
