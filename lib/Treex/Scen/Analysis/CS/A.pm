package Treex::Scen::Analysis::CS::A;
use Moose;
use Treex::Core::Common;
with 'Treex::Core::RememberArgs';

sub get_scenario_string {
    my ($self) = @_;
    return 'Scen::Analysis::CS tokenizer=none tagger=none ner=none tecto=none ' . $self->args_str;
}

1;

=head1 NAME 

Treex::Scen::Analysis::CS::A - Czech analysis from "m-layer" to a-layer

=head1 SYNOPSIS

 treex -Lcs Read::Sentences from=my.txt Scen::Analysis::CS::M Scen::Analysis::CS::A Write::Treex to=my.treex.gz

=head1 DESCRIPTION

Performs a-layer parsing.

Expects tagged and lemmatized data,
i.e. L<Scen::Analysis::CS::M> is a prerequisite.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by Institute of Formal and Applied Linguistics,
Charles University in Prague

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

