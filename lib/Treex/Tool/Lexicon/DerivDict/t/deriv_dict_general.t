#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;

BEGIN {
    Test::More::plan( skip_all => 'these tests require export AUTHOR_TESTING=1' ) if !$ENV{AUTHOR_TESTING};
}

use_ok 'Treex::Tool::Lexicon::DerivDict::Dictionary';

my $dict = Treex::Tool::Lexicon::DerivDict::Dictionary->new();

my $lexeme1 = $dict->create_lexeme({
    lemma  => "ucho",
    mlemma => "ucho",
    pos => 'N',
});

my $lexeme2 = $dict->create_lexeme({
    lemma  => "ušní",
    mlemma => "ušní",
    pos => 'N',
    source_lexeme => $lexeme1,
    deriv_type => 'adj2noun'
});

my $lexeme3 = $dict->create_lexeme({
    lemma  => "ušový",
    mlemma => "ušový",
    pos => 'N',
});

$dict->add_derivation({
    source_lexeme => $lexeme1,
    target_lexeme => $lexeme3,
    deriv_type => 'adj2noun'
});

my @derived_lexemes = $lexeme1->get_derived_lexemes;
is(scalar($lexeme1->get_derived_lexemes), 2, "derived lexemes correctly linked");

is($lexeme3->source_lexeme, $lexeme1, "source lexeme correctly linked");

$dict->save('testdict.tsv');

done_testing();
