package Treex::Block::Read::YAML;

use Moose;
use Treex::Core::Common;
use YAML::Any;
use Data::Dumper;
use File::Slurp;

extends 'Treex::Block::Read::BaseReader';

sub next_document_text {

    my ($self) = @_;
    my $filename = $self->next_filename or return;
    my $text;

    if ( $filename eq '-' ) {
        $text = read_file( \*STDIN );
    }
    else {
        # TODO support other encodings ?
        $text = read_file( $filename, binmode => 'encoding(utf8)', err_mode => 'log_fatal' );
    }
    return $text;
}

sub next_document {
    my ($self) = @_;

    my $text = $self->next_document_text();
    return if !defined $text;

    utf8::encode($text); # encoding hack (so that the file is human-readable)
    my $yaml_bundles = Load($text);

    my $document = $self->new_document();
    foreach my $yaml_bundle ( @{$yaml_bundles} ) {
        
        my $bundle = $document->create_bundle();
        
        foreach my $yaml_zone ( @{$yaml_bundle} ) {
        
            my $zone = $bundle->create_zone( $yaml_zone->{language}, $yaml_zone->{selector} );
        
            $zone->set_sentence( $yaml_zone->{sentence} ) if ( defined( $yaml_zone->{sentence} ) );
        
            foreach my $layer (qw(a t n p)) {
                if ( defined( $yaml_zone->{ $layer . 'tree' } ) ) {
                    my $root = $zone->create_tree($layer);
                    $self->deserialize_tree( $root, $layer, $yaml_zone->{ $layer . 'tree' } );
                }
            }
        }
    }
    return $document;
}

# Deserialize a node and, recursively, its children
sub deserialize_tree {
    my ( $self, $node, $layer, $yaml_data ) = @_;

    foreach my $attr ( keys %{$yaml_data} ) {
        if ( $attr eq 'children' ) {
            foreach my $yaml_child ( @{ $yaml_data->{children} } ) {
                my ($child) = $node->create_child();
                $self->deserialize_tree( $child, $layer, $yaml_child );
            }
            next;
        }
        # this will actually work even for IDs and Treex::PML arrays, which makes it simpler
        $node->set_attr( $attr, $yaml_data->{$attr} );
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::Read::YAML

=head1 DESCRIPTION

Read a YAML file containing Treex structures (as arrays and hashes), such as a YAML file 
written by L<Treex::Block::Write::YAML>. 

The YAML file must contain an array of bundles, each being an array of zones. A zone is a hash,
containing the following values: C<language>, C<selector>, C<sentence> and C<Xtree>, where C<X> 
can be C<a>, C<t>, C<n> or C<p>. The tree entries then contain the entire tree structure with 
usual attributes for nodes on the individual layers; the topological children of a node are
contained in the attribute C<children> (which is an array of nodes).
   
=back

=head1 AUTHOR

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
