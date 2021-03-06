package Treex::Block::Discourse::EVALD::Base;
use Moose::Role;
use Treex::Core::Common;
use Data::Printer;

use Treex::Tool::Discourse::EVALD::Features;

has 'target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => 'target classification set, three possible values: L1 for native speakers, L2 for second language learners, L2b for the L2b dataset',
);
has 'kenlm_model' => ( is => 'ro', isa => 'Str' );
has 'densities_model' => ( is => 'ro', isa => 'Str' );
has 'ns_filter' => ( is => 'ro', isa => 'Str' );
has '_feat_extractor' => ( is => 'ro', isa => 'Treex::Tool::Discourse::EVALD::Features', builder => '_build_feat_extractor', lazy => 1 );

sub BUILD {
    my ($self) = @_;
    $self->_feat_extractor;
}

sub _build_feat_extractor {
    my ($self) = @_;
    my $args = {
        target => $self->target,
        language => $self->language,
        selector => $self->selector,
        ns_filter => $self->ns_filter
    };
    $args->{kenlm_model} = $self->kenlm_model if (defined $self->kenlm_model);
    $args->{densities_model} = $self->densities_model if (defined $self->densities_model);
    return Treex::Tool::Discourse::EVALD::Features->new($args);
}

1;

__END__

=head1 NAME

Treex::Block::Discourse::EVALD::Base

=head1 DESCRIPTION

Base class for EVALD resolver.

=head1 AUTHOR

Michal Novak <mnovak@ufal.mff.cuni.cz>
Jiří Mírovský <mirovsky@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-17 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
