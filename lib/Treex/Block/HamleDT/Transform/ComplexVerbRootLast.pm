package Treex::Block::HamleDT::Transform::ComplexVerbRootLast;
use Moose;
extends 'Treex::Block::HamleDT::Transform::BaseTransformer';
use Treex::Tool::ATreeTransformer::ComplexVerb;

sub BUILD {
    my ($self) = @_;
    $self->set_transformer(
        Treex::Tool::ATreeTransformer::ComplexVerb->new(
            {
                subscription => $self->subscription,
                new_root     => 'last',
            }
            )
        )
}

1;

