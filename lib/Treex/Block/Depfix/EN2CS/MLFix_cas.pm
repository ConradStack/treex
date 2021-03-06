package Treex::Block::Depfix::EN2CS::MLFix_cas;
use Moose;
use Treex::Core::Common;
use utf8;

use Treex::Tool::Depfix::CS::FormGenerator;

extends 'Treex::Block::Depfix::MLFix';

has c_cas_config_file => ( is => 'rw', isa => 'Str', required => 1 );
has c_cas_model_file => ( is => 'rw', isa => 'Str', required => 1 );

has model_type => ( is => 'rw', isa => 'Str', default => 'maxent' );
# allowed values: maxent, nb, dt, odt

use Treex::Tool::Depfix::CS::NodeInfoGetter;
use Treex::Tool::Depfix::EN::NodeInfoGetter;

override '_build_node_info_getter' => sub  {
    return Treex::Tool::Depfix::CS::NodeInfoGetter->new();
};

override '_build_src_node_info_getter' => sub  {
    return Treex::Tool::Depfix::EN::NodeInfoGetter->new();
};

override '_build_form_generator' => sub {
    my ($self) = @_;

    return Treex::Tool::Depfix::CS::FormGenerator->new();
};

override '_load_models' => sub {
    my ($self) = @_;

    my $model_params = {
        config_file => $self->c_cas_config_file,
        model_file  => $self->c_cas_model_file,
    };
    
    if ( $self->model_type eq 'maxent' ) {
        $self->_models->{c_cas} =
            Treex::Tool::Depfix::MaxEntModel->new($model_params);
    } elsif ( $self->model_type eq 'nb' ) {
        $self->_models->{c_cas} =
            Treex::Tool::Depfix::NaiveBayesModel->new($model_params);
    } elsif ( $self->model_type eq 'dt' ) {
        $self->_models->{c_cas} =
            Treex::Tool::Depfix::DecisionTreesModel->new($model_params);
    } elsif ( $self->model_type eq 'odt' ) {
        $self->_models->{c_cas} =
            Treex::Tool::Depfix::OldDecisionTreesModel->new($model_params);
    } elsif ( $self->model_type eq 'baseline' ) {
        $self->_models->{c_cas} =
            Treex::Tool::Depfix::BaselineModel->new({config_file=>$self->c_cas_config_file});
    }
    
    return;
};

override '_predict_new_tags' => sub {
    my ($self, $child, $model_predictions) = @_;

    my $tag = $child->tag;
    my %new_tags = ();
    foreach my $cas (keys %{$model_predictions->{c_cas}} ) {
        substr $tag, 4, 1, $cas;
        $new_tags{$tag} = $model_predictions->{c_cas}->{$cas};
    }

    return \%new_tags;
};

1;

=head1 NAME 

Depfix::EN2CS::MLFix -- fixes errors using a machine learned correction model,
with EN as the source language and CS as the target language

=head1 DESCRIPTION

=head1 PARAMETERS

=over

=back

=head1 AUTHOR

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013 by Institute of Formal and Applied Linguistics,
Charles University in Prague

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

