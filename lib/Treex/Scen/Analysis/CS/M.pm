package Treex::Scen::Analysis::CS::M;
use Moose;
use Treex::Core::Common;
with 'Treex::Core::RememberArgs';

has tagger => (
     is => 'ro',
     isa => enum( [qw(MorphoDiTa Featurama Morce)] ),
     default => 'MorphoDiTa',
);

has gazetteer => (
     is => 'ro',
     isa => 'Str',
     default => '0',
);

# TODO gazetteers should work without any dependance on target language
has trg_lang => (
    is => 'ro',
    isa => 'Str',
);

sub get_scenario_string {
    my ($self) = @_;
    return 'Scen::Analysis::CS tokenizer=none ner=none parser=none tecto=none ' . $self->args_str;
}

1;

=head1 NAME 

Treex::Scen::Analysis::CS::M - Czech analysis to "m-layer".

=head1 SYNOPSIS

 treex -Lcs Read::Sentences from=my.txt Scen::Analysis::CS::M Write::Treex to=my.treex.gz

=head1 DESCRIPTION

Performs "m-layer" processing, i.e. tokenization, tagging and lemmatization.
(Note: technically, the m-layer analysis is stored on a-layer.)

Expects text split into sentences,
so it is usually preceded by L<Read::Sentences>
and possibly also L<W2A::ResegmentSentences>.

=head1 PARAMETERS

=over

=item tagger

Which PoS tagger to use: 
C<tagger=MorphoDiTa> (default),
or C<tagger=Featurama>,
or C<tagger=Morce>

=item gazetteer

Use W2A::GazeteerMatch A2T::ProjectGazeteerInfo?
C<gazetteer=0> (default),
or C<gazetteer=all>,
and other options -- see L<W2A::GazeteerMatch>

=item trg_lang

Gazetteers are defined for language pairs. Both source and target languages must be specified.

=back

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by Institute of Formal and Applied Linguistics,
Charles University in Prague

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

