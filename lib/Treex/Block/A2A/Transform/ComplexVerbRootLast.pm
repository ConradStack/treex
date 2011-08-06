package Treex::Block::A2A::Transform::ComplexVerbRootLast;
use Moose;
extends 'Treex::Block::A2A::Transform::BaseTransformer';
use Treex::Tool::ATreeTransformer::ComplexVerb;

sub BUILD {
    my ($self) = @_;
    $self->set_transformer(
        Treex::Tool::ATreeTransformer::CoApStyle->new({
            subscription => $self->subscription,
            new_root => 'last',
        })
    )
}

1;

