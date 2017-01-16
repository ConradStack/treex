package Treex::Block::Coref::CS::RelPron::Base;
use Moose::Role;
use Treex::Core::Common;

use Treex::Tool::Coreference::AnteCandsGetter;
#use Treex::Tool::Coreference::Features::RelPron;
use Treex::Tool::Coreference::Features::Container;
use Treex::Tool::Coreference::Features::Aligned;
use Treex::Tool::Coreference::Features::Coreference;
use Treex::Tool::Coreference::Features::CS::AllMonolingual;
use Treex::Tool::Coreference::Features::EN::AllMonolingual;

with 'Treex::Block::Coref::SupervisedBase' => {
    -excludes => [ '_build_feature_extractor', '_build_ante_cands_selector' ],
};

sub _build_node_types {
    return 'relpron';
}

sub _build_feature_extractor {
    my ($self) = @_;
    my @container = ();
 
    #my $cs_fe = Treex::Tool::Coreference::Features::RelPron->new();
    #return $cs_fe;
    my $cs_fe = Treex::Tool::Coreference::Features::CS::AllMonolingual->new();
    push @container, $cs_fe;

    if ($self->aligned_feats) {
        my $aligned_fe = Treex::Tool::Coreference::Features::Aligned->new({
            feat_extractors => [ 
                Treex::Tool::Coreference::Features::EN::AllMonolingual->new(),
                Treex::Tool::Coreference::Features::Coreference->new(),
            ],
            align_lang => 'en',
            align_selector => 'src',
            align_types => ['supervised', '.*'],
        });
        push @container, $aligned_fe;
    }
    
    my $fe = Treex::Tool::Coreference::Features::Container->new({
        feat_extractors => \@container,
    });
    return $fe;
}

sub _build_ante_cands_selector {
    my ($self) = @_;
    my $acs = Treex::Tool::Coreference::AnteCandsGetter->new({
        cand_types => [ 'noun', 'verb' ],
        prev_sents_num => 0,
        cands_within_czeng_blocks => 1,
        max_size => 100,
    });
    return $acs;
}

1;

#TODO extend documentation

__END__

=head1 NAME

Treex::Block::Coref::CS::PersPron::Base

=head1 DESCRIPTION

This role is a basis for supervised coreference resolution of Czech personal pronouns.
Both the data printer and resolver should apply this role.

=head1 AUTHOR

Michal Novak <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011-2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
