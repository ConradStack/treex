package Treex::Tool::Parser::MSTperl::Reader;

use Moose;
use autodie;

has featuresControl => (
    isa      => 'Treex::Tool::Parser::MSTperl::FeaturesControl',
    is       => 'ro',
    required => '1',
);

sub read_tsv {

    # (Str $filename)
    my ( $self, $filename ) = @_;

    my @sentences;
    my @nodes;
    my $id = 1;
    open my $file, '<:encoding(utf8)', $filename;
    print "Reading '$filename'...\n";
    while (<$file>) {
        chomp;
        if (/^$/) {
            my $sentence = Treex::Tool::Parser::MSTperl::Sentence->new(
                id => $id++, nodes => [@nodes],
                featuresControl => $self->featuresControl
            );
            push @sentences, $sentence;
            undef @nodes;

            # only progress and/or debug info
            if ( scalar(@sentences) % 50 == 0 ) {
                print "  " . scalar(@sentences) . " sentences read.\n";
            }

            # END only progress and/or debug info

        } else {
            my @fields = split /\t/;
            my $node   = Treex::Tool::Parser::MSTperl::Node->new(
                fields          => [@fields],
                featuresControl => $self->featuresControl
            );
            push @nodes, $node;
        }
    }
    close $file;
    print "Done.\n";

    return [@sentences];
}

1;

__END__

=pod

=for Pod::Coverage BUILD

=encoding utf-8

=head1 NAME

Treex::Tool::Parser::MSTperl::Reader

=head1 DESCRIPTION

Reads CoNLL-like TSV file
(one line corresponds to one node, its features separated by tabs,
sentence boundary is represented by an empty line)
and converts it to L<Treex::Tool::Parser::MSTperl::Node> and
L<Treex::Tool::Parser::MSTperl::Sentence> instances.

=head1 METHODS

=over 4

=item $reader->read_tsv($filename)

Reads a TSV file C<$filename>, returns a reference to an array of sentences
(instances of L<Treex::Tool::Parser::MSTperl::Sentence>).

The structure of the file (the order of the fields)
is determined by the C<featuresControl> field
(instance of L<Treex::Tool::Parser::MSTperl::FeaturesControl>),
specifically by the C<field_names> setting.

=back

=head1 AUTHORS

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles 
University in Prague

This module is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.
