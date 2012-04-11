package Treex::Block::Test::A::AuxVNotOnTop;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Test::BaseTester';

#Testing if there is not an auxiliary verb directly under the root

sub process_atree {
    my ( $self, $a_root ) = @_;

    foreach my $anode ($a_root->get_children()) {
        if ($anode->afun eq "AuxV") {
            $self->complain($a_root);
            return;
        }
    }
}

#(C) 2012 Karel Bílek, Jindřich Libovický

1;
