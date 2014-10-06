package Treex::Block::T2A::NL::AddAuxVerbModalTense;

use utf8;
use Moose;
use Treex::Core::Common;
use Treex::Tool::Lexicon::NL::ErgativeVerbs;

extends 'Treex::Block::T2A::AddAuxVerbModalTense';

override '_build_gram2form' => sub {

    return {
        'ind' => {
            'sim' => {
                ''        => '',
                'decl'    => '',
                'poss'    => 'kunnen',
                'poss_ep' => 'kunnen',
                'vol'     => 'willen',
                'deb'     => 'moeten',
                'deb_ep'  => 'moeten',
                'hrt'     => 'moeten',
                'fac'     => 'kunnen',
                'perm'    => 'mogen',
                'perm_ep' => 'mogen',
            },
            'ant' => {
                ''        => '',
                'decl'    => '',
                'poss'    => 'kunnen',
                'poss_ep' => 'kunnen hebben',
                'vol'     => 'willen',
                'deb'     => 'moeten',
                'deb_ep'  => 'moeten hebben',
                'hrt'     => 'moeten',
                'fac'     => 'kunnen',
                'perm'    => 'mogen',
                'perm_ep' => 'mogen hebben',
            },
            'post' => {
                ''     => 'zullen',
                'decl' => 'zullen',
                'poss' => 'zullen kunnen',
                'vol'  => 'zullen willen',
                'deb'  => 'zullen moeten',
                'hrt'  => 'zullen moeten',
                'fac'  => 'zullen kunnen',
                'perm' => 'zullen mogen',
            },
        },
        'cdn' => {
            'sim' => {
                ''        => 'zullen',
                'decl'    => 'zullen',
                'poss'    => 'zullen kunnen',
                'poss_ep' => 'zullen kunnen',
                'vol'     => 'zullen willen',
                'deb'     => 'zullen moeten',
                'deb_ep'  => 'zullen moeten',
                'hrt'     => 'zullen moeten',
                'fac'     => 'zullen kunnen',
                'perm'    => 'zullen mogen',
                'perm_ep' => 'zullen kunnen',
            },
            'ant' => {
                ''        => 'hebben',
                'decl'    => 'hebben',
                'poss'    => 'hebben kunnen',
                'poss_ep' => 'zullen kunnen hebben',
                'vol'     => 'hebben willen',
                'deb'     => 'hebben moeten',
                'deb_ep'  => 'zullen moeten hebben',
                'hrt'     => 'hebben moeten',
                'fac'     => 'hebben kunnen',
                'perm'    => 'hebben kunnen',
                'perm_ep' => 'zullen kunnen hebben',
            },
            'post' => {
                ''     => 'zullen',
                'decl' => 'zullen',
                'poss' => 'zullen kunnen',
                'vol'  => 'zullen willen',
                'deb'  => 'zullen moeten',
                'hrt'  => 'zullen moeten',
                'fac'  => 'zullen kunnen',
                'perm' => 'zullen mogen',
            },
        },
    };
};



override '_postprocess' => sub {
    my ( $self, $verbforms_str, $anodes ) = @_;
    
    # change the lexical verb form: past participle / infinitive    
    if ( $verbforms_str =~ /hebben$/ ) {
        $anodes->[-1]->iset->add('pos' => 'verb', 'verbform' => 'part', 'tense' => 'past');
    }
    else {
        $anodes->[-1]->iset->add('pos' => 'verb', 'verbform' => 'inf');
    }

    # change the past tense auxiliary: hebben/zijn
    if ( $verbforms_str =~ /hebben$/ and Treex::Tool::Lexicon::NL::ErgativeVerbs::is_ergative_verb($anodes->[-1]->lemma) ){
        $anodes->[-1]->set_lemma('zijn');
    }
    
    # TODO move all auxiliaries except the 1st to the end of the clause ?    
    return;
};

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::NL::AddAuxVerbModalTense

=head1 DESCRIPTION

Add auxiliary expression for combined modality and tense.

=head1 AUTHORS 

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.