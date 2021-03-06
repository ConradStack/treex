package Treex::Block::A2T::SetValencyFrameRefVW;

use Moose;
use Treex::Core::Common;
use Treex::Tool::Vallex::ValencyFrame;
use Treex::Block::Print::VWForValencyFrames;
use Treex::Tool::ML::VowpalWabbit::CsoaaLdfClassifier;

extends 'Treex::Core::Block';

has '+language' => ( required => 1 );

has 'valency_dict_name' => ( is => 'ro', isa => 'Str', required => 1 );

has 'valency_dict_prefix' => ( is => 'ro', isa => 'Str', default => '' );

has 'sempos_filter' => ( is => 'ro', isa => 'Str', default => '' );

has 'model_file' => ( is => 'ro', isa => 'Str', required => 1 );

has 'features_file' => ( is => 'ro', isa => 'Str', required => 1 );

has 'vallex_mapping_file' => ( is => 'ro', isa => 'Str', default => '' );

has 'vallex_mapping_by_lemma' => ( is => 'ro', isa => 'Bool', default => 0 );

has 'restrict_frames_file' => ( is => 'ro', isa => 'Str', default => '' );

has '_valframe_feats' => ( is => 'rw' );

has '_classif' => ( is => 'rw' );

sub process_start {

    my ($self) = @_;

    my $classif = Treex::Tool::ML::VowpalWabbit::CsoaaLdfClassifier->new( { model_path => $self->model_file } );
    $self->_set_classif($classif);

    my $valframe_feats = Treex::Block::Print::VWForValencyFrames->new(
        {
            language                => $self->language,
            features_file           => $self->features_file,
            valency_dict_name       => $self->valency_dict_name,
            valency_dict_prefix     => $self->valency_dict_prefix,
            vallex_mapping_file     => $self->vallex_mapping_file,
            vallex_mapping_by_lemma => $self->vallex_mapping_by_lemma,
            restrict_frames_file    => $self->restrict_frames_file,
        }
    );
    $self->_set_valframe_feats($valframe_feats);

    return;
}

sub process_ttree {

    my ( $self, $troot ) = @_;

    # apply sempos filter
    my $sempos_filter = $self->sempos_filter;
    my @tnodes        = grep {
        my $sempos = $_->gram_sempos // '';
        $sempos =~ /$sempos_filter/
    } $troot->get_descendants( { ordered => 1 } );

    return if ( !@tnodes );    # no nodes passed the filter in this sentence

    for ( my $i = 0; $i < @tnodes; ++$i ) {

        $tnodes[$i]->set_val_frame_rf();    # force-undef the valency frame beforhand to enable predicting 1st frame

        my ( $feat_str, $frame_id ) = $self->_valframe_feats->get_feats_and_class( $tnodes[$i] );
        $frame_id = $frame_id // '';

        $tnodes[$i]->wild->{val_frame_set} = 'VALLEX-1st';
        if ($feat_str) {
            my $predicted = $self->_classif->classify($feat_str);
            if ($predicted) {
                $frame_id = $predicted;
                $tnodes[$i]->wild->{val_frame_set} = 'ML';
            }
        }

        if ( $frame_id ne '' ) {
            $frame_id =~ s/.*#//; # remove any possible previous prefix
            $frame_id = $self->valency_dict_prefix . $frame_id; # add our set-up prefix
        }
        $tnodes[$i]->set_val_frame_rf($frame_id);
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::A2T::SetValencyFrameRefVW

=head1 DESCRIPTION

Set valency frame reference (val_frame.rf) to an id from a valency dictionary, using
the VowpalWabbit classifier with the given model, plus the dictionary as a fallback. 

=head1 PARAMETERS

=over

=item valency_dict_name

Name of the valency dictionary, such as C<vallex.xml> (will be located in 
C<share/data/resources/vallex>).

=item valency_dict_prefix

The valency dictionary prefix to be used (e.g., C<cs-v#>). This is a kind of hack,
the value should correspond to the reference to the dictionary in the Treex file
(but the reference is never checked, which may lead to problems in TrEd).

=item sempos_filter

Use this parameter if you want to set valency frames eg. for verbs only
(sempos_filter='^v'). The filter is a regexp on the gram/sempos attribute of t-nodes.
The default is empty, ie. all nodes will be allowed to the classification.

=item model_file

Path to the VowpalWabbit model file (in share or plain relative/absolute path).

=item features_file

Path to features configuration file (in YAML format).

=item vallex_mapping_file

Path to Vallex mapping file for billingual experiments.

=item vallex_mapping_by_lemma

Split the 'present in Vallex mapping' feature by lemmas (default and better: 0)?

=item restrict_frames_file

Allows to the list of frames that may be predicted to the ones given in this file.

=back

=head1 AUTHOR

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014-2015 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
