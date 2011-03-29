package Treex::Block::Read::Sentences;
use Moose;
use Treex::Moose;
extends 'Treex::Block::Read::BaseTextReader';

sub next_document {
    my ($self) = @_;
    my $text = $self->next_document_text();
    return if !defined $text;

    my $document = $self->new_document();
    foreach my $sentence ( split /\n/, $text ) {
        my $bundle = $document->create_bundle();
        my $zone = $bundle->create_zone( $self->language, $self->selector );
        $zone->set_sentence($sentence);
    }

    return $document;
}

1;

__END__

=head1 NAME

Treex::Block::Read::Sentences

=head1 DESCRIPTION

Document reader for plain text format, one sentence per line.

=head1 ATTRIBUTES

=over

=item from

space or comma separated list of filenames

=back

=head1 METHODS

=over

=item next_document

Loads a document.

=back

=head1 AUTHOR

Martin Popel

=head1 COPYRIGHT

Copyright 2011 Martin Popel
This file is distributed under the GNU GPL v2 or later. See $TMT_ROOT/README