package Treex::Block::T2T::ProjectTreeThroughAlignment;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

has '+language'   => ( required => 1 );
has 'to_language' => ( is       => 'rw', isa => 'Str', required => 1 );
has 'to_selector' => ( is       => 'rw', isa => 'Str', required => 1 );

sub process_bundle {
    my ( $self, $bundle ) = @_;
    
    my $source_root = $bundle->get_zone($self->language, $self->selector)->get_ttree;
    my $target_root = $bundle->get_zone($self->to_language, $self->to_selector)->get_ttree;

    foreach my $node ($target_root->get_descendants) {
        $node->set_parent($target_root);
    }
    foreach my $node ($target_root->get_descendants) {
        my $prev_node = $node->get_prev_node();
        $node->set_parent($prev_node) if $prev_node;
    }

    my %linked_to;
    my @counterparts;

    # sort counterparts for each node from 'int' through 'gdfa' to 'right'
    foreach my $node ($source_root->get_descendants({ordered => 1})) {
        my ($nodes, $types) = $node->get_aligned_nodes();
        foreach my $i ((0 .. $#$nodes)) {
            if ($$types[$i] =~ /int/ && !defined $linked_to{$$nodes[$i]}) {
                push @{$counterparts[$node->ord]}, $$nodes[$i];
                $linked_to{$$nodes[$i]} = $node;
            }
        }
    }
    foreach my $node ($source_root->get_descendants({ordered => 1})) {
        my ($nodes, $types) = $node->get_aligned_nodes();
        foreach my $i ((0 .. $#$nodes)) {
            if ($$types[$i] =~ /gdfa/ && $$types[$i] =~ /right/ && $$types[$i] !~ /int/ && !defined $linked_to{$$nodes[$i]}) {
                push @{$counterparts[$node->ord]}, $$nodes[$i];
                $linked_to{$$nodes[$i]} = $node;
            }
        }
    }
    foreach my $node ($source_root->get_descendants({ordered => 1})) {
        my ($nodes, $types) = $node->get_aligned_nodes();
        foreach my $i ((0 .. $#$nodes)) {
            if ($$types[$i] =~ /right/ && $$types[$i] !~ /gdfa/ && !defined $linked_to{$$nodes[$i]}) {
                push @{$counterparts[$node->ord]}, $$nodes[$i];
                $linked_to{$$nodes[$i]} = $node;
            }
        }
    }

    project_subtree($bundle, $source_root, $target_root, \@counterparts);
}

sub project_subtree {
    my ($bundle, $source_root, $target_root, $counterparts) = @_;
    foreach my $source_node ($source_root->get_children({ordered => 1})) {
        my @other_target_nodes = @{$$counterparts[$source_node->ord]} if $$counterparts[$source_node->ord];
        my $main_target_node = shift @other_target_nodes if @other_target_nodes;

        if ($main_target_node) {
            $main_target_node->set_parent($target_root);
            foreach my $target_node (@other_target_nodes) {
                next if $target_node eq $main_target_node;
                $target_node->set_parent($main_target_node);
            }
            project_subtree($bundle, $source_node, $main_target_node, $counterparts);
        }
        else {
            project_subtree($bundle, $source_node, $target_root, $counterparts);
        }
    }
}

1;


__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::ProjectTreeThroughAlignment

=head1 DESCRIPTION

Project a tectogrammatical tree from one zone to an other using alignment links.
Target trees must exist before and the alignment links must lead from the source to target
and must be typed as from GIZA++ ('int', 'int.gdfa', 'left.gdfa' etc.)

=head1 AUTHOR

David Mareček <marecek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
