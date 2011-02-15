package Treex::Block::T2T::EN2CS::TrLFCompounds;
use Moose;
use Treex::Moose;
extends 'Treex::Core::Block';

use Lexicon::Czech;
use EnglishMorpho::Lemmatizer;
use Tagger::TnT;

my $tagger = Tagger::TnT->new;

use TranslationModel::Static::Model;
use TranslationModel::Derivative::EN2CS::Deverbal_adjectives;
use TranslationModel::Derivative::EN2CS::Deadjectival_adverbs;
use TranslationModel::Derivative::EN2CS::Nouns_to_adjectives;
use ProbUtils::Normalize;

my $MODEL_STATIC = 'data/models/translation/en2cs/tlemma_czeng09.static.pls.gz';
my ( $static_model, $deverbadj_model, $deadjadv_model, $noun2adj_model );

sub get_required_share_files { return $MODEL_STATIC; }

sub BUILD {
    $static_model = TranslationModel::Static::Model->new();
    $static_model->load("$ENV{TMT_ROOT}/share/$MODEL_STATIC");
    $deverbadj_model = TranslationModel::Derivative::EN2CS::Deverbal_adjectives->new(  { base_model => $static_model } );
    $deadjadv_model  = TranslationModel::Derivative::EN2CS::Deadjectival_adverbs->new( { base_model => $static_model } );
    $noun2adj_model  = TranslationModel::Derivative::EN2CS::Nouns_to_adjectives->new(  { base_model => $static_model } );
}

sub process_bundle {
    my ( $self, $bundle ) = @_;
    my $t_root = $bundle->get_tree('TCzechT');

    # For all nodes with untranslated (i.e. "cloned" from source tnode) lemmas...
    foreach my $t_node ( grep { $_->t_lemma_origin eq 'clone' } $t_root->get_descendants() ) {
        my $en_tlemma = $t_node->t_lemma;

        # If the lemma looks like a compound, try to translate it as two or more t-nodes.
        if ( $en_tlemma =~ /[a-z]\-[a-z]/ and $en_tlemma !~ /[A-Z]/ ) {
            translate_compound($t_node);
        }
    }

    return;
}

sub translate_compound {
    my ($t_node) = @_;

    my @forms = split( /\-/, $t_node->t_lemma );
    my @tags = @{ $tagger->analyze( \@forms ) };

    SUBWORD:
    while (@forms) {
        my $form = shift @forms;
        my $tag  = shift @tags;

        # prepositions and determiners (that are not at the end of the compound) are not translated
        next SUBWORD if $tag =~ /^(IN|TO|DT)$/ && @forms;

        my ($lemma) = EnglishMorpho::Lemmatizer::lemmatize( $form, $tag );

        my @translations = (
            $static_model->get_translations( lc($lemma) ),
            $deverbadj_model->get_translations( lc($lemma) ),
            $deadjadv_model->get_translations( lc($lemma) ),
            $noun2adj_model->get_translations( lc($lemma) ),
        );

        # rules
        if ( $lemma eq 'ex' ) {
            @translations = ( { label => 'bývalý#A', 'prob' => 0.5, 'origin' => 'rule-Translate_LF_compounds' } );
        }
        elsif ( $lemma eq 'credit' ) {
            @translations = ( { label => 'kreditní#A', 'prob' => 0.5, 'origin' => 'rule-Translate_LF_compounds' } );
        }

        my @t_lemma_variants;
        foreach my $tr (@translations) {
            if ( $tr->{label} =~ /(.+)#(.)/ ) {
                push @t_lemma_variants, {
                    't_lemma'          => $1,
                    'pos'              => $2,
                    'origin'           => $tr->{source},
                    'logprob'          => ProbUtils::Normalize::prob2binlog( $tr->{prob} ),
                    'backward_logprob' => -1,
                };
            }
        }

        if ( !@t_lemma_variants ) {
            @t_lemma_variants = (
                {   't_lemma'          => $form,
                    'pos'              => 'X',
                    'origin'           => 'clone-Tranalste_LF_compounds',
                    'logprob'          => '-1',
                    'backward_logprob' => -1,
                }
            );
        }

        if ( !@t_lemma_variants ) {
            Report::warn('Something is rotten in the state of Translate_LF_compounds');
            next SUBWORD;
        }

        # If translating non-last sub-word of the compound,
        # create new child node.
        if (@forms) {
            my $new_formeme = $tag =~ /^D/ ? 'adv:' : 'adj:attr';
            my $new_node = $t_node->create_child(
                {   attributes => {
                        't_lemma'                            => $t_lemma_variants[0]->{t_lemma},
                        't_lemma_origin'                     => 'dict-first-Translate_LF_compounds',
                        'nodetype'                           => 'complex',
                        'functor'                            => '???',
                        'gram/sempos'                        => 'adj.denot',
                        'formeme'                            => $new_formeme,
                        'formeme_origin'                     => 'rule-Translate_LF_compounds',
                        'translation_model/t_lemma_variants' => [@t_lemma_variants],
                        }
                }
            );
            $new_node->shift_before_node( $t_node, { without_children => 1 } );
            my $en_t_node = $t_node->src_tnode;
            $new_node->set_src_tnode($en_t_node);
        }

        # If translating the last sub-word of the compound,
        # save the translation into the original t_node.:
        else {
            $t_node->set_t_lemma( $t_lemma_variants[0]->{t_lemma} );
            $t_node->set_t_lemma_origin('dict-first-Translate_LF_compounds');
            $t_node->set_attr( 'translation_model/t_lemma_variants', [@t_lemma_variants] );
        }
    }
    return;
}

1;

=over

=encoding utf8

=item Treex::Block::T2T::EN2CS::TrLFCompounds

Tries to translated compounds like I<ex-commander> to two or more t-nodes.
This block should go after other blocks that add t-lemma translation variants
(e.g. B<SEnglishT_to_TCzechT::Translate_L_add_variants>), so it tries to translate
only the nodes which were not translated so far.
=back

=cut

# Copyright 2010 David Marecek, Martin Popel
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
