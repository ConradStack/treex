package Treex::Block::HamleDT::SK::FixUD;
use utf8;
use Moose;
use List::MoreUtils qw(any);
use Treex::Core::Common;
extends 'Treex::Block::HamleDT::Base'; # provides get_node_spanstring()



sub process_atree
{
    my $self = shift;
    my $root = shift;
    my @nodes = $root->get_descendants({'ordered' => 1});
    foreach my $node (@nodes)
    {
        $self->fix_morphology($node);
    }
    # Do not call syntactic fixes from the previous loop. First make sure that
    # all nodes have correct morphology, then do syntax (so that you can rely
    # on the morphology you see at the parent node).
    foreach my $node (@nodes)
    {
        $self->fix_constructions($node);
        $self->fix_annotation_errors($node);
        $self->identify_acl_relcl($node);
    }
    # It is possible that we changed the form of a multi-word token.
    # Therefore we must re-generate the sentence text.
    #$root->get_zone()->set_sentence($root->collect_sentence_text());
}



#------------------------------------------------------------------------------
# Fixes known issues in part-of-speech and features.
#------------------------------------------------------------------------------
sub fix_morphology
{
    my $self = shift;
    my $node = shift;
    my $lform = lc($node->form());
    my $lemma = $node->lemma();
    my $iset = $node->iset();
    my $deprel = $node->deprel();
    # Abbreviations have X instead of the UPOS tag of the unabbreviated word.
    # Try to fix at least some occurrences.
    if($node->is_abbreviation() && $iset->pos() eq '')
    {
        # If all letters are uppercase, assume it is an acronym of a named entity.
        if(uc($node->form()) eq $node->form())
        {
            $node->set_tag('PROPN');
            $iset->add('pos' => 'noun', 'nountype' => 'prop');
            if($deprel =~ m/^advmod(:|$)/)
            {
                $deprel = 'obl';
                $node->set_deprel($deprel);
            }
        }
        elsif($lform =~ m/^(cca|napr|resp)$/)
        {
            $iset->add('pos' => 'adv');
        }
    }
    # "si" is the 2nd person singular present form of "byť" ("to be"), or the dative form of the reflexive clitic.
    elsif($lform eq 'si' && $deprel =~ m/^(aux|cop)(:|$)/)
    {
        $lemma = 'byť';
        $node->set_lemma($lemma);
        $node->set_tag('AUX');
        $iset->set_hash({'pos' => 'verb', 'verbtype' => 'aux', 'aspect' => 'imp', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'number' => 'sing', 'person' => '2', 'polarity' => 'pos'});
    }
    # "ste" is the 2nd person plural present form of "byť" ("to be"), or a form of the numeral "sto" ("hundred").
    elsif($lform eq 'ste' && $deprel =~ m/^(aux|cop)(:|$)/)
    {
        $lemma = 'byť';
        $node->set_lemma($lemma);
        $node->set_tag('AUX');
        $iset->set_hash({'pos' => 'verb', 'verbtype' => 'aux', 'aspect' => 'imp', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'number' => 'plur', 'person' => '2', 'polarity' => 'pos'});
    }
    # Typo: "so" instead of "som".
    elsif($lform eq 'so' && $deprel =~ m/^aux(:|$)/ && $node->parent()->is_participle())
    {
        $lemma = 'byť';
        $node->set_lemma($lemma);
        $node->set_tag('AUX');
        $iset->set_hash({'pos' => 'verb', 'verbtype' => 'aux', 'aspect' => 'imp', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'number' => 'sing', 'person' => '1', 'polarity' => 'pos', 'typo' => 'yes'});
    }
    # "ako" can be adverb ("how") or subordinating conjunction ("as, like").
    # If it is tagged SCONJ but attached as advmod, the UPOS should be changed
    # to ADV.
    elsif($lform =~ m/^(ako|čo|čím|tým)$/ && $node->is_conjunction() && $deprel =~ m/^advmod(:|$)/)
    {
        $node->set_tag('ADV');
        $iset->set_hash({'pos' => 'adv', 'prontype' => $lform eq 'tým' ? 'dem' : 'int|rel'});
    }
    # "že" is attached as advmod in "Že ste už o mne počuli?" but we will re-attach it as mark.
    elsif($lform =~ m/^(že|keby)$/ && $deprel =~ m/^advmod(:|$)/)
    {
        $deprel = 'mark';
        $node->set_deprel($deprel);
    }
    # "akoby" ("as if") is SCONJ/mark in sentences like
    # "O'Brien sa zastavil, akoby Winston vyslovil tú myšlienku nahlas."
    # But in sentences like
    # "Zaburácal silný výbuch, ktorý akoby zodvihol chodník."
    # the national tagset classifies it as a particle. In UD it should rather
    # be an adverb.
    elsif($lform eq 'akoby')
    {
        if($iset->is_particle())
        {
            $iset->set_hash({'pos' => 'adv', 'mood' => 'cnd'});
            if($deprel =~ m/^mark(:|$)/)
            {
                $deprel = 'advmod';
                $node->set_deprel($deprel);
            }
        }
        else # SCONJ
        {
            $deprel = 'mark';
            $node->set_deprel($deprel);
        }
    }
    # "čo" is not a pronoun but a subordinator in sentences like
    # "Po tom, čo boli počty zredukované..."
    elsif($lform =~ m/^(čo)$/ && $deprel =~ m/^mark(:|$)/)
    {
        $node->set_tag('SCONJ');
        $iset->set_hash({'pos' => 'conj', 'conjtype' => 'sub'});
    }
    # "I" can be the conjunction "i", capitalized, or it can be the Roman numeral 1.
    # If it appears at the beginning of the sentence and is attached as advmod:emph or cc,
    # we will assume that it is a conjunction (there is at least one case where it
    # is wrongly tagged NUM).
    elsif($lform eq 'i' && $node->ord() == 1 && $deprel =~ m/^(advmod|cc)(:|$)/)
    {
        $iset->set_hash({'pos' => 'conj', 'conjtype' => 'coor'});
    }
    # If "to znamená" is abbreviated and tokenized as "tzn .", PDT tags it as
    # a verb but analyzes it syntactically as a conjunction. We will re-tag it
    # as a conjunction.
    elsif($lform eq 'tzn' && $iset->is_verb())
    {
        $iset->set_hash({'pos' => 'conj', 'conjtype' => 'coor', 'abbr' => 'yes'});
    }
    # The word "plus" can be a noun or a mathematical conjunction. If it is
    # attached as 'cc', it should be conjunction.
    elsif($lform eq 'plus' && $deprel =~ m/^cc(:|$)/)
    {
        $iset->set_hash({'pos' => 'conj', 'conjtype' => 'oper'});
    }
    # These are symbols, not punctuation.
    elsif($lform =~ m/^[<>]$/)
    {
        $iset->set_hash({'pos' => 'sym', 'conjtype' => 'oper'});
    }
    # Make sure that the UPOS tag still matches Interset features.
    $node->set_tag($node->iset()->get_upos());
}



#------------------------------------------------------------------------------
# Figures out whether an adnominal clause is a relative clause, and changes the
# relation accordingly.
#------------------------------------------------------------------------------
sub identify_acl_relcl
{
    my $self = shift;
    my $node = shift;
    return unless($node->deprel() =~ m/^acl(:|$)/);
    # Look for a relative pronoun or a subordinating conjunction. The first
    # such word from the left is the one that matters. However, it is not
    # necessarily the first word in the subtree: there can be punctuation and
    # preposition. The relative pronoun can be even the root of the clause,
    # i.e., the current node, if the clause is copular.
    # Specifying (first|last|preceding|following)_only implies ordered.
    my @subordinators = grep {$_->is_subordinator() || $_->is_relative()} ($node->get_descendants({'preceding_only' => 1, 'add_self' => 1}));
    return unless(scalar(@subordinators) > 0);
    my $subordinator = $subordinators[0];
    # If there is a subordinating conjunction, the clause is not relative even
    # if there is later also a relative pronoun.
    return if($subordinator->is_subordinator() || $subordinator->deprel() =~ m/^mark(:|$)/);
    # Many words can be both relative and interrogative and the two functions are
    # not disambiguated in morphological features, i.e., they get PronType=Int,Rel
    # regardless of context. We only want to label a clause as relative if there
    # is coreference between the relative word and the nominal modified by the clause.
    # For example, 1. is a relative clause and 2. is not:
    # 1. otázka, ktorá sa stále vracia (question that recurs all the time)
    # 2. otázka, ktorá strana vyhrá voľby (question which party wins the elections)
    # Certain interrogative-relative words seem to never participate in a proper
    # relative clause.
    return if($subordinator->lemma() =~ m/^(ako|koľko)$/);
    # The interrogative-relative adverb "prečo" ("why") could be said to corefer with a few
    # selected nouns but not with others. Note that the parent can be also a
    # pronoun (typically the demonstrative/correlative "to"), which is also OK.
    my $parent = $node->parent();
    return if($subordinator->lemma() eq 'proč' && $parent->lemma() !~ m/^(dôvod|príčina|ten|to)$/);
    # An incomplete list of nouns that can occur with an adnominal clause which
    # resembles but is not a relative clause. Of course, all of them can also be
    # modified by a genuine relative clause.
    my $badnouns = 'argument|definícia|dôkaz|dotaz|kombinácia|kritérium|možnosť|myšlenka|nariadenie|nápis|názor|otázka|pochopenie|pochyba|pomyšlenie|právda|problém|projekt|prieskum|predstava|prehľad|príklad|rada|skúmanie|spôsob|údaj|úslovie|uvedenie|východisko|vysvetlenie';
    # The interrogative-relative pronouns "kto" ("who") and "čo" ("what") usually
    # occur with one of the "bad nouns". We will keep only the remaining cases
    # where they occur with a different noun or pronoun. This is an approximation
    # that will not always give correct results.
    return if($subordinator->lemma() =~ m/^(kto|čo)$/ && $parent->lemma() =~ m/^($badnouns)$/);
    # The relative words are expected only with certain grammatical relations.
    # The acceptable relations vary depending on the depth of the relative word.
    # In depth 0, the relation is acl, which is not acceptable anywhere deeper.
    my $depth = 0;
    for(my $i = $subordinator; $i != $node; $i = $i->parent())
    {
        $depth++;
    }
    return if($depth > 0 && $subordinator->lemma() =~ m/^(kto|čo|ktorý|aký)$/ && $subordinator->deprel() !~ m/^(nsubj|obj|iobj|obl)(:|$)/);
    return if($subordinator->lemma() =~ m/^(kam|kde|kedy|kudy|odkiaľ|prečo)$/ && $subordinator->deprel() !~ m/^advmod(:|$)/);
    ###!!! We do not rule out the "bad nouns" for the most widely used relative
    ###!!! word "ktorý" ("which"). However, this word can actually occur in
    ###!!! fake relative (interrogative) clauses. We may want to check the bad
    ###!!! nouns and agreement in gender and number; if the relative word agrees
    ###!!! with the bad noun, the clause is recognized as relative, otherwise
    ###!!! it is not.
    $node->set_deprel('acl:relcl');
}



#------------------------------------------------------------------------------
# Fixes dependency relation labels and/or topology of the tree.
#------------------------------------------------------------------------------
sub fix_constructions
{
    my $self = shift;
    my $node = shift;
    my $parent = $node->parent();
    my $deprel = $node->deprel();
    # There are a few right-to-left appositions that resulted from transforming
    # copula-like constructions with punctuation (":") instead of the copula.
    # Each of them would probably deserve a different analysis but at present
    # we do not care too much and make them 'parataxis' (they occur in nonverbal
    # sentences or segments).
    if($deprel =~ m/^appos(:|$)/ && $node->ord() < $parent->ord())
    {
        $deprel = 'parataxis';
        $node->set_deprel($deprel);
    }
    # The abbreviation "tzv" ("takzvaný" = "so called") is an adjective.
    # However, it is sometimes confused with "tzn" (see below) and attached as
    # 'cc'.
    elsif(lc($node->form()) eq 'tzv' && $node->is_adjective() && $parent->ord() > $node->ord())
    {
        $deprel = 'amod';
        $node->set_deprel($deprel);
    }
    # Reflexive "sa" should not be attached as 'mark' or 'aux'.
    elsif($node->form() =~ m/^(sa)$/i && $node->is_pronoun() && $deprel =~ m/^(mark|aux)(:|$)/)
    {
        $deprel = 'expl:pv';
        $node->set_deprel($deprel);
    }
    # An adverb should not depend on a copula but on the nominal part of the
    # predicate. Example: "Také vakovlk je, respektive před vyhubením byl, ..."
    elsif($node->is_adverb() && $node->deprel() =~ m/^advmod(:|$)/ &&
          $parent->deprel() =~ m/^cop(:|$)/)
    {
        $parent = $parent->parent();
        $node->set_parent($parent);
    }
    # Slovak "a to" ("viz.") is a multi-word conjunction. In the original
    # treebank, multiple attachment options occur:
    # 1. "a" is attached to "to" as 'cc'.
    # 2. both words are attached as siblings (relations 'cc').
    elsif(lc($node->form()) eq 'a' && $deprel =~ m/^cc(:|$)/ &&
          $parent->form() =~ m/^(to|sice)$/i && $parent->deprel() =~ m/^(cc|advmod|discourse)(:|$)/ && $parent->ord() > $node->ord())
    {
        my $grandparent = $parent->parent();
        $node->set_parent($grandparent);
        $deprel = 'cc';
        $node->set_deprel($deprel);
        $parent->set_parent($node);
        $parent->set_deprel('fixed');
        # These occurrences of "to" should be lemmatized as "to" and tagged 'PART'.
        # However, sometimes they are lemmatized as "ten" and tagged 'DET'.
        $parent->set_lemma('to');
        $parent->set_tag('PART');
        $parent->iset()->set_hash({'pos' => 'part'});
        $parent = $grandparent;
    }
    elsif(lc($node->form()) =~ m/^(a)$/ && $deprel =~ m/^cc(:|$)/ &&
          defined($node->get_right_neighbor()) &&
          lc($node->get_right_neighbor()->form()) =~ m/^(to)$/ && $node->get_right_neighbor()->deprel() =~ m/^(cc|advmod|discourse)(:|$)/)
    {
        my $to = $node->get_right_neighbor();
        $to->set_parent($node);
        $to->set_deprel('fixed');
        # These occurrences of "to" should be lemmatized as "to" and tagged 'PART'.
        # However, sometimes they are lemmatized as "ten" and tagged 'DET'.
        $to->set_lemma('to');
        $to->set_tag('PART');
        $to->iset()->set_hash({'pos' => 'part'});
    }
    # The expression "více než" ("more than") functions as an adverb.
    elsif(lc($node->form()) eq 'než' && $parent->ord() == $node->ord()-1 &&
          lc($parent->form()) eq 'více')
    {
        $deprel = 'fixed';
        $node->set_deprel($deprel);
        $parent->set_deprel('advmod');
    }
    # "rozuměj" (imperative of "understand") is a verb but attached as 'cc'.
    # We will not keep the parallelism to "to jest" here. We will make it a parataxis.
    # Similar: "míněno" (ADJ, passive participle of "mínit")
    elsif($node->form() =~ m/^(rozuměj|dejme|míněno|počínaje|řekněme|říkajíc|srov(nej)?|víte|event)$/i && $deprel =~ m/^(cc|advmod|mark)(:|$)/)
    {
        $deprel = 'parataxis';
        $node->set_deprel($deprel);
    }
    # Interjections showing the attitude to the speaker towards the event should
    # be attached as 'discourse', not as 'advmod'.
    elsif($node->is_interjection() && $deprel =~ m/^advmod(:|$)/)
    {
        $deprel = 'discourse';
        $node->set_deprel($deprel);
    }
    # Sometimes a sequence of punctuation symbols (e.g., "***"), tokenized as
    # one token per symbol, is analyzed as a constituent headed by one of the
    # symbols. In UD, this should not happen unless the dependent symbols are
    # brackets or quotation marks and the head symbol is enclosed by them.
    elsif($node->is_punctuation() && $parent->is_punctuation())
    {
        unless($node->form() =~ m/^[\{\[\("']$/ && $parent->ord() == $node->ord()+1 ||
               $node->form() =~ m/^['"\)\]\}]$/ && $parent->ord() == $node->ord()-1)
        {
            # Find the first ancestor that is not punctuation.
            my $ancestor = $parent;
            # We should never get to the root because we should first find an
            # ancestor whose deprel is 'root'. But let's not rely on the data
            # too much.
            while(!$ancestor->is_root() && $ancestor->deprel() =~ m/^punct(:|$)/)
            {
                $ancestor = $ancestor->parent();
            }
            if(defined($ancestor) && !$ancestor->is_root() && $ancestor->deprel() !~ m/^punct(:|$)/)
            {
                $node->set_parent($ancestor);
                $node->set_deprel('punct');
            }
        }
    }
    # The colon between two numbers is probably a division symbol, not punctuation.
    elsif($node->form() =~ m/^[+\-:]$/ && !$parent->is_root() && $parent->form() =~ m/^\d+(\.\d+)?$/ &&
          $node->ord() > $parent->ord() &&
          scalar($node->children()) > 0 &&
          (any {$_->form() =~ m/^\d+(\.\d+)?$/} ($node->children())))
    {
        # The node is currently probably tagged as punctuation but it should be a symbol.
        $node->set_tag('SYM');
        $node->iset()->set_hash({'pos' => 'sym', 'conjtype' => 'oper'});
        # The punct relation should no longer be used.
        # We could treat the operator as a predicate and make it a head, with
        # its arguments attached as dependents. However, it is not clear what
        # their relation should be in linguistic terms. Therefore we simply resort
        # to a flat structure.
        $node->set_deprel('flat');
        foreach my $child ($node->children())
        {
            if($child->ord() > $parent->ord())
            {
                $child->set_parent($parent);
                $child->set_deprel($child->is_punctuation() ? 'punct' : 'flat');
            }
        }
    }
    # A star followed by a year is not punctuation. It is a symbol meaning "born in".
    # Especially if enclosed in parentheses.
    elsif($node->form() eq '*' &&
          (defined($node->get_right_neighbor()) && $node->get_right_neighbor()->ord() == $node->ord()+1 && $node->get_right_neighbor()->form() =~ m/^[12]?\d\d\d$/ ||
           scalar($node->children())==1 && ($node->children())[0]->ord() == $node->ord()+1 && ($node->children())[0]->form() =~ m/^[12]?\d\d\d$/ ||
           !$parent->is_root() && $parent->ord() == $node->ord()+1 && $parent->form() =~ m/^[12]?\d\d\d$/))
    {
        $node->set_tag('SYM');
        $node->iset()->set_hash({'pos' => 'sym'});
        $deprel = 'parataxis' unless($deprel =~ m/^root(:|$)/);
        $node->set_deprel($deprel);
        my $year = $node->get_right_neighbor();
        if(defined($year) && $year->form() =~ m/^[12]?\d\d\d$/)
        {
            $year->set_parent($node);
        }
        elsif(!$parent->is_root() && $parent->form() =~ m/^[12]?\d\d\d$/)
        {
            $year = $parent;
            $parent = $year->parent();
            $node->set_parent($parent);
            if($year->deprel() =~ m/^root(:|$)/)
            {
                $deprel = $year->deprel();
                $node->set_deprel($deprel);
            }
            $year->set_parent($node);
            $year->set_deprel('obl');
            # There may be parentheses attached to the year. Reattach them to me.
            foreach my $child ($year->children())
            {
                $child->set_parent($node);
            }
        }
        my @children = grep {$_->form() =~ m/^[12]?\d\d\d$/} ($node->children());
        if(scalar(@children)>0)
        {
            $year = $children[0];
            $year->set_deprel('obl');
        }
        # If there are parentheses, make sure they are attached to the star as well.
        my $l = $node->get_left_neighbor();
        my $r = $node->get_right_neighbor();
        if(defined($l) && defined($r) && $l->form() eq '(' && $r->form() eq ')')
        {
            $l->set_parent($node);
            $r->set_parent($node);
        }
    }
    # "..." is sometimes attached as the last conjunct in coordination.
    # (It is three tokens, each period separate.)
    # Comma is sometimes attached as a conjunct. It is a result of ExD_Co in
    # the original treebank.
    elsif($node->is_punctuation() && $deprel =~ m/^conj(:|$)/ &&
          $node->is_leaf())
    {
        $deprel = 'punct';
        $node->set_deprel($deprel);
    }
    # Hyphen is sometimes used as a predicate similar to a copula, but not with
    # Pnom. Rather its children are subject and object. Sometimes there is
    # ellipsis and one of the children comes out as 'dep'.
    # "celková škoda - 1000 korun"
    # "týden pro dospělého - 1400 korun, pro dítě do deseti let - 700 korun"
    # We do not know what to do if there fewer than 2 children. However, there
    # can be more if the entire expression is enclosed in parentheses.
    elsif($node->form() =~ m/^[-:]$/ && scalar($node->children()) >= 2)
    {
        my @children = $node->get_children({'ordered' => 1});
        my @punctchildren = grep {$_->deprel() =~ m/^punct(:|$)/} (@children);
        my @argchildren = grep {$_->deprel() !~ m/^punct(:|$)/} (@children);
        if(scalar(@argchildren) == 0)
        {
            # There are 2 or more children and all are punctuation.
            # Silently exit this branch. This will be solved elsewhere.
        }
        elsif(scalar(@argchildren) == 2)
        {
            # Assume that the hyphen is acting like a copula. If we are lucky,
            # one of the children is labeled as a subject. The other will be
            # object or oblique and that is the one we will treat as predicate.
            # If we are unlucky (e.g. because of ellipsis), no child is labeled
            # as subject. Then we take the first one.
            my $s = $argchildren[0];
            my $p = $argchildren[1];
            if($p->deprel() =~ m/subj/ && $s->deprel() !~ m/subj/)
            {
                $s = $argchildren[1];
                $p = $argchildren[0];
            }
            $p->set_parent($parent);
            $deprel = 'parataxis' if($deprel =~ m/^punct(:|$)/);
            $p->set_deprel($deprel);
            $s->set_parent($p);
            foreach my $punct (@punctchildren)
            {
                $punct->set_parent($p);
            }
            $parent = $p;
            $deprel = 'punct';
            $node->set_parent($parent);
            $node->set_deprel($deprel);
        }
        else # more than two non-punctuation children
        {
            # Examples (head words of children in parentheses):
            # 'Náměstek ministra podnikatelům - daňové nedoplatky dosahují miliard' (Náměstek podnikatelům dosahují)
            # 'Týden pro dospělého - 1400 korun , pro dítě do deseti let - 700 korun .' (Týden korun -)
            # 'V " supertermínech " jako je Silvestr - 20 německých marek za osobu , jinak 12 marek , případně v přepočtu na koruny .' (supertermínech marek osobu jinak)
            # 'Dnes v listě Neobyčejně obyčejné příběhy - portrét režiséra Karla Kachyni' (Dnes listě portrét)
            # 'Brankáři s nulou : Hlinka ( Vítkovice ) a Novotný ( Jihlava ) - oba ve 2 . kole .' (Brankáři oba kole)
            # '25 . 2 . 1994 - hebronský masakr ( židovský osadník Baruch Goldstein postřílel při modlitbě tři desítky Arabů ) ;' (2 masakr postřílel)
            ###!!! It is not clear what we should do. For the moment, we just pick the first child as the head.
            my $p = shift(@argchildren);
            $p->set_parent($parent);
            $deprel = 'parataxis' if($deprel =~ m/^punct(:|$)/);
            $p->set_deprel($deprel);
            foreach my $arg (@argchildren)
            {
                $arg->set_parent($p);
            }
            foreach my $punct (@punctchildren)
            {
                $punct->set_parent($p);
            }
            $parent = $p;
            $deprel = 'punct';
            $node->set_parent($parent);
            $node->set_deprel($deprel);
        }
    }
    # If we changed tag of a symbol from PUNCT to SYM above, we must also change
    # its dependency relation.
    elsif($node->is_symbol() && $deprel =~ m/^punct(:|$)/ &&
          $node->ord() > $parent->ord())
    {
        $deprel = 'flat';
        $node->set_deprel($deprel);
    }
    $self->fix_auxiliary_verb($node);
    # Functional nodes normally do not have modifiers of their own, with a few
    # exceptions, such as coordination. Most modifiers should be attached
    # directly to the content word.
    if($node->deprel() =~ m/^(aux|cop)(:|$)/)
    {
        my @children = grep {$_->deprel() =~ m/^(nsubj|csubj|obj|iobj|expl|ccomp|xcomp|obl|advmod|advcl|vocative|dislocated|dep)(:|$)/} ($node->children());
        my $parent = $node->parent();
        foreach my $child (@children)
        {
            $child->set_parent($parent);
        }
    }
    elsif($node->deprel() =~ m/^(case|mark|cc|punct)(:|$)/)
    {
        my @children = grep {$_->deprel() !~ m/^(conj|fixed|goeswith|punct)(:|$)/} ($node->children());
        my $parent = $node->parent();
        foreach my $child (@children)
        {
            $child->set_parent($parent);
        }
    }
}



#------------------------------------------------------------------------------
# Fix auxiliary verb that should not be auxiliary.
#------------------------------------------------------------------------------
sub fix_auxiliary_verb
{
    my $self = shift;
    my $node = shift;
    if($node->deprel() =~ m/^cop(:|$)/ && $node->lemma() !~ m/^(byť|bývať|mať|stať)$/)
    {
        log_warn("Spona má lemma '".$node->lemma()."' a značku '".$node->tag()."'.");
    }
    if($node->tag() eq 'AUX')
    {
        if($node->deprel() =~ m/^cop(:|$)/ &&
           $node->lemma() =~ m/^(mať|stať)$/)
        {
            my $pnom = $node->parent();
            my $parent = $pnom->parent();
            my $deprel = $pnom->deprel();
            # The nominal predicate may have been attached as a non-clause;
            # however, now we have definitely a clause.
            $deprel =~ s/^nsubj/csubj/;
            $deprel =~ s/^i?obj/ccomp/;
            $deprel =~ s/^(advmod|obl)/advcl/;
            $deprel =~ s/^(nmod|amod|appos)/acl/;
            $node->set_parent($parent);
            $node->set_deprel($deprel);
            $pnom->set_parent($node);
            $pnom->set_deprel('xcomp');
            # Subject, adjuncts and other auxiliaries go up (also 'expl:pv' in "stát se").
            # We also have to raise conjunctions and punctuation, otherwise we risk nonprojectivities.
            # Noun modifiers remain with the nominal predicate.
            my @children = $pnom->children();
            foreach my $child (@children)
            {
                if($child->deprel() =~ m/^(([nc]subj|obj|advmod|discourse|vocative|expl|aux|mark|cc|punct)(:|$)|obl$)/ ||
                   $child->deprel() =~ m/^obl:([a-z]+)$/ && $1 ne 'arg')
                {
                    $child->set_parent($node);
                }
            }
            # We also need to change the part-of-speech tag from AUX to VERB.
            $node->iset()->clear('verbtype');
            $node->set_tag('VERB');
        }
    }
    elsif($node->deprel() =~ m/^cop(:|$)/ && $node->lemma() =~ m/^(mať)$/)
    {
        log_warn("Deprel is 'cop' and lemma is 'mať' but tag is ".$node->tag());
    }

}



#------------------------------------------------------------------------------
# Fixes various annotation errors in individual sentences. It is preferred to
# fix them when harmonizing the Prague style but in some cases the conversion
# would be still difficult, so we do it here.
#------------------------------------------------------------------------------
sub fix_annotation_errors
{
    my $self = shift;
    my $node = shift;
    my $spanstring = $self->get_node_spanstring($node);
    # "prosím vás" ("I ask you"): "vás" should be "obj", not "cc".
    if(lc($node->form()) eq 'vás' && !$node->is_root() && lc($node->parent()->form()) eq 'prosím')
    {
        $node->set_deprel('obj');
    }
    # "široko - ďaleko": the hyphen should not be treated as "ADJ" and "cc".
    elsif($node->form() eq '‐' && $node->is_adjective() && $node->deprel() =~ m/^cc(:|$)/)
    {
        $node->set_tag('PUNCT');
        $node->iset()->set_hash({'pos' => 'punc'});
        $node->set_deprel('punct');
    }
    # "+ a –"
    elsif($node->form() eq '–' && $node->deprel() =~ m/^conj(:|$)/)
    {
        $node->set_tag('SYM');
        $node->iset()->set_hash({'pos' => 'sym'});
    }
}



1;

=over

=item Treex::Block::HamleDT::SK::FixUD

Slovak-specific post-processing after the treebank has been converted from the
Prague style to Universal Dependencies. It can also be used to check for and
fix errors in treebanks that were annotated directly in UD.

=back

=head1 AUTHORS

Daniel Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2019 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
