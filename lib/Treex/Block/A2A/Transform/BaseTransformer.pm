package Treex::Block::A2A::Transform::BaseTransformer;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

has 'transformer' => ( is => 'rw',
                   #    required => 1,
                   );

sub process_atree {
    my ($self,$atree) = @_;
    $self->transformer->apply_on_tree($atree);
}

sub subscribe {
    my ($self, $node) = @_;
    $node->wild->{"trans_".$self->subscription} = 1;
}

# shortened block's name (namespace prefix deleted)
sub subscription {
    my ($self) = @_;
    ref($self) =~ /([^:]+)$/;
    return $1;
}

1;



=over

=item Treex::Block::A2A::Transform::BaseTransformer

Abstract class predecessor for blocks transforming a-trees from one convention
to another. Attribute transformer is supposed to be filled by a block's constructor.
It should contain an object capable of tree transformations invoked by
its method apply_on_tree.

=back

=cut

# Copyright 2011 Zdenek Zabokrtsky
# This file is distributed under the GNU GPL v2 or later. See $TMT_ROOT/README.

