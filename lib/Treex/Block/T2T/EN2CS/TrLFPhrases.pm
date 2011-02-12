package Treex::Block::T2T::EN2CS::TrLFPhrases;
use Moose;
use Treex::Moose;
extends 'Treex::Core::Block';


use ProbUtils::Normalize;


# TODO: it is taking the place of... #make use of
Readonly my $CHILD_PARENT_TO_ONE_NODE => {
    prime_minister => 'premiér#N',
    Dalai_Lama     => 'dalajláma#N',
    use_make       => 'použít#V|využít#V|používat#V|využívat#V',
    place_take     => 'konat_se#V|proběhnout#V|probíhat#V',
    happy_make     => 'potěšit#V|těšit#V',
    this_time      => 'tentokrát#D',
    that_time      => 'tehdy#D',
    first_time     => 'poprvé#D',
    second_time    => 'podruhé#D',
    third_time     => 'potřetí#D',
    last_time      => 'naposledy#D',
};

sub process_bundle {
    my ( $self, $bundle ) = @_;
    my $cs_troot = $bundle->get_tree('TCzechT');
    my @cs_tnodes = $cs_troot->get_descendants( { ordered => 1 } );

    # Hack for "That is," -> "Jinými slovy"
    if ( $bundle->get_attr('english_source_sentence') =~ /^That is,/ ) {
        my ( $that, $is ) = @cs_tnodes;
        if ( $that->t_lemma eq 'that' && $is->t_lemma eq 'be' ) {
            $that->disconnect();
            shift @cs_tnodes;
            $is->set_attr( 'mlayer_pos',     'X' );
            $is->set_t_lemma('Jinými slovy');
            $is->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );
            $is->set_formeme('phrase');
            $is->set_attr( 'formeme_origin', 'rule-Translate_LF_phrases' );
        }
    }

    foreach my $cs_tnode (@cs_tnodes) {
        process_tnode($cs_tnode);
    }
    return;
}

sub process_tnode {
    my ($cs_tnode) = @_;
    my $en_tnode = $cs_tnode->get_source_tnode() or return;
    my ( $lemma, $formeme ) = $en_tnode->get_attrs(qw(t_lemma formeme));
    my $en_parent = $en_tnode->get_parent();
    return if $en_parent->is_root();
    my $cs_parent = $cs_tnode->get_parent();
    my ( $p_lemma, $p_formeme ) = $en_parent->get_attrs(qw(t_lemma formeme));

    # this/last year
    if ( $lemma =~ /^(this|last)$/ && $p_lemma eq 'year' ) {

        # "this year's X" -> "letošní X"
        if ( $p_formeme eq 'n:poss' ) {
            my $l = $lemma eq 'this' ? 'letošní' : 'loňský';
            $cs_parent->set_t_lemma($l);
            $cs_parent->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );
            $cs_parent->set_attr( 'mlayer_pos',     'A' );
            $cs_parent->set_formeme('adj:attr');
            $cs_parent->set_attr( 'formeme_origin', 'rule-Translate_LF_phrases' );
            foreach my $child ( $cs_tnode->get_children() ) {
                $child->set_parent($cs_parent);
            }
            $cs_tnode->disconnect();
            return;
        }

        # "this year" -> "letos"
        if ( $p_formeme =~ /^n:(adv|than.X)$/ ) {
            my $l = $lemma eq 'this' ? 'letos' : 'vloni';
            my $f = $p_formeme =~ /adv/ ? 'adv:' : 'n:než+X';
            $cs_parent->set_attr( 'mlayer_pos',     'D' );
            $cs_parent->set_t_lemma($l);
            $cs_parent->set_formeme($f);
            $cs_parent->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );
            $cs_parent->set_attr( 'formeme_origin', 'rule-Translate_LF_phrases' );
            foreach my $child ( $cs_tnode->get_children() ) {
                $child->set_parent($cs_parent);
            }
            $cs_tnode->disconnect();
            return;
        }

        # "by the end of last year" -> "koncem loňského roku"
        # But don't solve here: "in last years" -> "v posledních letech"
        if ( $en_parent->get_attr('gram/number') eq 'sg' ) {
            my $l = $lemma eq 'this' ? 'letošní' : 'loňský';
            $cs_tnode->set_t_lemma($l);
            $cs_tnode->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );
            $cs_tnode->set_attr( 'mlayer_pos',     'A' );
            return;
        }
        return;
    }

    # "for example" -> "například"
    # Parsing might be wrong, better to look for this as a phrase
    if ( $lemma =~ /^(example|instance)$/ ) {
        my $en_anode = $en_tnode->get_lex_anode() or return;
        my $a_for    = $en_anode->get_prev_node() or return;
        if ( $a_for->lemma eq 'for' ) {
            $cs_tnode->set_attr( 'mlayer_pos',     'D' );
            $cs_tnode->set_t_lemma('například');
            $cs_tnode->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );
            $cs_tnode->set_formeme('x');
            $cs_tnode->set_attr( 'formeme_origin', 'rule-Translate_LF_phrases' );
            return;
        }
    }

    # "be worth" -> "mit cenu"
    if ( $lemma eq 'worth' && $en_parent->t_lemma eq 'be' ) {
        $cs_parent->set_t_lemma('mít');
        $cs_parent->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );
        $cs_parent->set_attr( 'mlayer_pos', 'V' );
        $cs_tnode->set_formeme('n:4');
        $cs_tnode->set_attr( 'formeme_origin', 'rule-Translate_LF_phrases' );

    }


    # Two English t-nodes, child and parent, translates to one Czech t-node
    my $one_node_variants = $CHILD_PARENT_TO_ONE_NODE->{ $lemma . '_' . $p_lemma };
    if ($one_node_variants) {
        my @variants = split /\|/, $one_node_variants;
        my $uniform_logprob = ProbUtils::Normalize::prob2binlog( 1 / @variants );
        $cs_parent->set_attr(
            'translation_model/t_lemma_variants',
            [   map {
                    my ( $cs_lemma, $m_pos ) = split /#/, $_;
                    {   't_lemma' => $cs_lemma,
                        'pos'     => $m_pos,
                        'origin'  => 'Translate_LF_phrases',
                        'logprob' => $uniform_logprob,
                    }
                    } @variants
            ]
        );
        my ( $cs_lemma, $m_pos ) = split /#/, $variants[0];
        $cs_parent->set_attr( 'mlayer_pos',     $m_pos );
        $cs_parent->set_t_lemma($cs_lemma);
        $cs_parent->set_attr( 't_lemma_origin', 'rule-Translate_LF_phrases' );

        if ($m_pos eq "D") {  # for the first time -> * pro poprve
            $cs_parent->set_formeme('adv');
            $cs_parent->set_attr( 'formeme_origin', 'rule-Translate_LF_phrases' );
        }

        foreach my $child ( $cs_tnode->get_children() ) {
            $child->set_parent($cs_parent);
        }
        $cs_tnode->disconnect();
        return;
    }

}

1;

__END__

=over

=item Treex::Block::T2T::EN2CS::TrLFPhrases

Try to apply some hand written rules for phrases translation.
This block serves as an experimental (and temporary, I hope) place,
where we try rules in order to learn them automatically from data with ML in future.

=back

=cut

# Copyright 2009-2010 Martin Popel
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
