package Treex::Block::Test::A::SubjectBelowVerb;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Test::BaseTester';

sub process_anode {
    my ($self, $anode) = @_;
    if (($anode->afun||'') eq 'Sb') {
        foreach my $parent ($anode->get_eparents) {
            if (defined $parent->get_attr('iset/pos')
                    and $parent->get_attr('iset/pos') ne 'verb' ) {
                $self->complain($anode);
            }
        }
    }
}

1;

=over

=item Treex::Block::Test::A::SubjectBelowVerb

Subjects (afun=Sb) are expected only below verbs.

=back

=cut

# Copyright 2011 Zdenek Zabokrtsky
# This file is distributed under the GNU GPL v2 or later. See $TMT_ROOT/README.

