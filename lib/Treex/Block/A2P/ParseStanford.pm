package Treex::Block::A2P::ParseStanford;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

has '+language' => ( required => 1 );

has _parser => ( is => 'rw', required => 1, default => 'en' );
has use_tags => ( isa => 'Bool', is => 'rw', default => 0, );
has memory =>  ( isa => 'Str', is => 'rw', default => '2G', );
# default => '2G',
use Treex::Tool::PhraseParser::Stanford;

sub BUILD {
    my ($self) = @_;
    $self->_set_parser( Treex::Tool::PhraseParser::Stanford->new( { language => $self->language, use_tags => $self->use_tags, memory => $self->memory } ) );
    return;
}

sub process_document {
    my ( $self, $document ) = @_;
    my @zones = map { $_->get_zone( $self->language, $self->selector ) } $document->get_bundles;
    $self->_parser->parse_zones( \@zones );
}

1;

=pod

=over

=item Treex::Block::A2P::ParseStanford

Expects tokenized nodes (a-tree),
creates phrase-structure trees using Stanford constituency parser.
(not in ::EN:: in hope that there will be models for more languages)

=back

=cut

# Copyright 2011 Zdenek Zabokrtsky
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.

