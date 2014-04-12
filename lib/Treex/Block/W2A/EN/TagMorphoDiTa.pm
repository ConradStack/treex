package Treex::Block::W2A::EN::TagMorphoDiTa;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::W2A::TagMorphoDiTa';

has '+model' => ( default => 'data/models/morphodita/en/english-morphium-wsj-140407-no_negation.tagger' );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Treex::Block::W2A::EN::TagMorphoDiTa

=head1 DESCRIPTION

This is just a small modification of L<Treex::Block::W2A::TagMorphoDiTa> which adds the path to the
default model for English.

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
