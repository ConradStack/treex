package Treex::Tool::Coreference::NodeFilter::RelPron;

use Moose;
use Treex::Core::Common;
use Treex::Tool::Lexicon::CS;

with 'Treex::Tool::Coreference::NodeFilter';

sub is_candidate {
    my ($self, $t_node) = @_;
    return is_relat($t_node);
}

sub is_relat {
    my ($tnode) = @_;
    if ($tnode->language eq 'cs') {
        return _is_relat_cs($tnode);
    }
    if ($tnode->language eq 'en') {
        return _is_relat_en($tnode);
    }
}

sub _is_relat_cs {
    my ($tnode) = @_;

    my $is_via_indeftype = _is_relat_via_indeftype($tnode);
    return ($is_via_indeftype ? 1 : 0);
    #if (defined $is_via_indeftype) {
    #    return $is_via_indeftype;
    #}

    #my $has_relat_tag = _is_relat_cs_via_tag($tnode);
    #my $is_relat_lemma = _is_relat_cs_via_lemma($tnode); 
    
    #return $has_relat_tag || $is_relat_lemma;
    
    #return $is_relat_lemma;
}

sub _is_relat_en {
    my ($tnode) = @_;
    #my $is_via_indeftype = _is_relat_via_indeftype($tnode);
    #return $is_via_indeftype ? 1 : 0;

    my $anode = $tnode->get_lex_anode();
    return 0 if (!defined $anode);
    return 1 if ($anode->tag =~ /^W/);
    return 1 if ($anode->tag eq "IN" && $anode->lemma eq "that" && !$anode->get_children());
    return 0;
}

# so far the best
# not annotated on the Czech side of PCEDT
# => must be copied there from "cs_src"
sub _is_relat_via_indeftype {
    my ($tnode) = @_;
    my $indeftype = $tnode->gram_indeftype;
    return undef if (!defined $indeftype);
    return ($indeftype eq "relat") ? 1 : 0;
}

# "kde" and "kdy" are missing since their tags are Dd------
sub _is_relat_cs_via_tag {
    my ($tnode) = @_;
    my $anode = $tnode->get_lex_anode;
    return 0 if !$anode;
    
    # 1 = Relative possessive pronoun jehož, jejíž, ... (lit. whose in subordinate relative clause) 
    # 4 = Relative/interrogative pronoun with adjectival declension of both types (soft and hard) (jaký, který, čí, ..., lit. what, which, whose, ...) 
    # 9 = Relative pronoun jenž, již, ... after a preposition (n-: něhož, niž, ..., lit. who)
    # E = Relative pronoun což (corresponding to English which in subordinate clauses referring to a part of the preceding text) 
    # J = Relative pronoun jenž, již, ... not after a preposition (lit. who, whom) 
    # K = Relative/interrogative pronoun kdo (lit. who), incl. forms with affixes -ž and -s (affixes are distinguished by the category VAR (for -ž) and PERSON (for -s))
    # ? = Numeral kolik (lit. how many/how much)
    return $anode->tag =~ /^.[149EJK\?]/;
}

# there is a problem with "již"
my %relat_lemmas = map {$_ => 1}
    qw/co což jak jaký jenž již kam kde kdo kdy kolik který odkud/;

sub _is_relat_cs_via_lemma {
    my ($tnode) = @_;
    my $anode = $tnode->get_lex_anode;
    return 0 if !$anode;
    return $relat_lemmas{Treex::Tool::Lexicon::CS::truncate_lemma($anode->lemma, 0)}; 
}

# TODO doc

1;
