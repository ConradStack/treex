package Treex::Block::T2T::EN2PT::TrGazeteerItems;
use utf8;
use Moose;
use Treex::Core::Common;
use Treex::Core::Resource;

extends 'Treex::Core::Block';

has 'gazeteer_path' => ( is => 'ro', isa => 'Str', default => 'data/models/gazeteer/pt_en/20150910_001.IT.pt_en.pt.gaz.gz' );
# idx removed: libreoffice_16090, libreoffice_16123, libreoffice_73656
has '_gazeteer_hash' => ( is => 'ro', isa => 'HashRef[Str]', builder => '_build_gazeteer_hash', lazy => 1 );

sub _build_gazeteer_hash {
    my ($self) = @_;

    log_info "Loading the Czech gazeteer list...";

    my $path = require_file_from_share($self->gazeteer_path);
    open my $fh, "<:gzip:utf8", $path;

    my $hash = {};

    while (my $line = <$fh>) {
        chomp $line;
        my ($id, @phrase_rest) = split /\t/, $line;
        my $phrase = join " ", @phrase_rest;

        $hash->{$id} = $phrase;
    }
    close $fh;

    #log_info Dumper($searchine);

    return $hash;
}

sub process_start {
    my ($self) = @_;
    $self->_gazeteer_hash;
}

sub process_tnode {
    my ($self, $tnode) = @_;

    my $src_tnode = $tnode->src_tnode;

    my $id_list = $src_tnode->wild->{gazeteer_entity_id};
    my $phrase_list = $src_tnode->wild->{matched_item};
    return if (!defined $id_list);

    my @translated_phrases = ();

    for (my $i = 0; $i < @$id_list; $i++) {
        my $id = $id_list->[$i];
        my $phrase = $phrase_list->[$i]; 
        my $translated_phrase;
        if ($id eq "__PUNCT__") {
            $translated_phrase = $phrase;
        }
        else {
            $translated_phrase = $self->_gazeteer_hash->{$id};
        }
        if (!defined $translated_phrase) {
            # this should not happen
            log_warn "Gazetteer in " . $self->gazeteer_path . " does not contain the following id: " . $id;
        }
        push @translated_phrases, $translated_phrase;
    }
    
    $tnode->wild->{gazeteer_entity_id} = $id_list;
    $tnode->wild->{matched_item} = \@translated_phrases;
    $tnode->set_t_lemma(join " ", @translated_phrases);
    $tnode->set_t_lemma_origin('lookup-TrGazeteerItems');
}

1;

__END__

=encoding utf-8

=head1 NAME

=item Treex::T2T::EN2PT::TrGazeteerItems

=head1 DESCRIPTION

Translation of gazeteer items. Load the gazeteer for the target language and look up the translation by its id.

=head1 AUTHORS

Michal Novák <mnovak@ufal.mff.cuni.cz>


=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
