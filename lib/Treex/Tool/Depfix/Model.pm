package Treex::Tool::Depfix::Model;
use Moose;
use Treex::Core::Common;
use utf8;

use Storable;     # for model

extends 'Treex::Tool::Depfix::Base';

has model_file => ( is => 'rw', isa => 'Str', required => 1 );
has model => ( is => 'rw' );

# for training (goes to training mode if training_file is set)
has training_file => ( is => 'rw', isa => 'Str', default => '' );

sub BUILD {
    my ($self) = @_;

    if ( $self->training_file ne '' ) {
        $self->set_model($self->_initialize_model());
    } else {
        $self->set_model($self->_load_model());
    }

    return;
}

## FOR RUNTIME ##

# override if needed
sub _load_model {
    my ($self) = @_;

    return Storable::retrieve( $self->model_file );
}

sub get_predictions {
    my ($self, $instance_info) = @_;

    my $features = $self->fields2features($instance_info);
    
    log_debug "Features: " . join ' ', map { $_ . '=' . $features->{$_} } keys %$features;

    # TODO if empty, put in baseline prediction
    return $self->_get_predictions($features);
}

sub _get_predictions {
    my ($self, $features) = @_;

    log_fatal "_get_predictions is abstract";    

    return;
}

override 'get_best_prediction' => sub {
    my ($self, $instance_info) = @_;

    my $features = $self->fields2features($instance_info);

    my $prediction = $self->_get_best_prediction($features);
    if ( !defined $prediction ) {
        log_warn "No prediction generated, using the baseline instead.";
        $prediction = $self->get_baseline_prediction($features);
    }
    
    return $prediction;
};

# may be undef
# may be overridden if the model has a better way to do that
sub _get_best_prediction {
    my ($self, $features) = @_;

    my $predictions = $self->_get_predictions($features);
    my $best_prediction = undef;
    my $best_prediction_score = 0;
    foreach my $prediction (keys %$predictions) {
        if ( $predictions->{$prediction} > $best_prediction_score ) {
            $best_prediction = $prediction;
            $best_prediction_score = $predictions->{$prediction};
        }
    }

    return $best_prediction;
}

## FOR TRAINING ##

sub _initialize_model {
    my ($self) = @_;

    log_fatal "_initialize_model is abstract";

    return;
}

sub train_and_store {
    my ($self) = @_;

    log_info 'Seeing the training data...';
    $self->_training_loop();
    
    log_info 'Learning the model...';
    $self->_train_model();
    
    log_info 'Storing the model...';
    $self->_store_model();

    log_info 'Model trained and stored!';

    return;
}

sub _training_loop {
    my ($self) = @_;

    open my $training_file, '<:gzip:utf8', $self->training_file;
    while ( my $line = <$training_file> ) {
        chomp $line;
        my @fields = split /\t/, $line;
        my %instance_info;
        @instance_info{ @{ $self->config->{fields} } } = @fields;
        
        $self->see_instance(\%instance_info);

        if ( $. % 10000 == 0) { log_info "Line $. processed"; }
    }
    close $training_file;

    return;
}

sub see_instance {
    my ($self, $instance_info) = @_;

    my $features = $self->fields2features($instance_info);
    
    my $class = $self->fields2feature($instance_info, $self->config->{predict});

    return $self->_see_instance($features, $class);
}

sub _see_instance {
    my ($self, $features, $class) = @_;

    log_fatal "_see_instance is abstract";    

    return;
}

# override if needed
sub _train_model {
    my ($self) = @_;

    # nothing done by default

    return;
}

# override if needed
sub _store_model {
    my ($self) = @_;

    Storable::store( $self->model, $self->model_file );

    return;
}

sub fields2features {
    my ($self, $fields) = @_;

    my %features = map {
        $_ => $self->fields2feature($fields, $_)
    } @{ $self->config->{features} };
    
    return \%features;
}


1;

=head1 NAME 

Treex::Tool::Depfix::Model -- a base class for a model for Depfix
corrections

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

