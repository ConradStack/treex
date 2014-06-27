package Treex::Block::T2A::PT::GenerateWordforms;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

use Treex::Tool::Lexicon::Generation::PT;
my $generator = Treex::Tool::Lexicon::Generation::PT->new();

sub process_anode {
    my ( $self, $anode ) = @_;
    $anode->set_form($generator->best_form_of_lemma($anode->lemma, $anode->iset));
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::PT::GenerateWordforms

=head1 DESCRIPTION

just a draft of Portuguese verbal conjugation
(placeholder for the real morphological module by LX-Center)
based on http://en.wikipedia.org/wiki/Portuguese_verb_conjugation


=head1 AUTHORS 

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
