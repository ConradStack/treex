package Treex::Block::T2T::CS2CS::Deepfix;
use Moose;
use Treex::Core::Common;
use utf8;
use Carp;
extends 'Treex::Core::Block';

has '+language'          => ( required => 1 );
has 'src_alignment_type' => ( is       => 'rw', isa => 'Str', default => 'src' );
has 'log_to_console'     => ( is       => 'rw', isa => 'Bool', default => 0 );
has 'dont_try_switch_number' => ( is => 'rw', isa => 'Bool', default => '0' );
# has 'source_language'     => ( is       => 'rw', isa => 'Str', required => 0 );
# has 'source_selector'     => ( is       => 'rw', isa => 'Str', default => '' );
# has 'orig_alignment_type' => ( is       => 'rw', isa => 'Str', default => 'orig' );
#
has 'magic' => ( is => 'ro', isa => 'Str', default => '' );

use Treex::Tool::Lexicon::CS;
use Treex::Tool::Depfix::CS::FormemeSplitter;
use Treex::Tool::Depfix::CS::FormGenerator;
use Treex::Tool::Depfix::CS::TagHandler;

my $formGenerator;

sub process_start {
    my $self = shift;

    $formGenerator = Treex::Tool::Depfix::CS::FormGenerator->new();

    return;
}

my $tnode_being_processed;

sub process_tnode {
    my ( $self, $node ) = @_;

    if (!defined $node->wild->{'deepfix_info'}) {
        log_fatal "deepfix_info must be precomputed for Deepfix to operate!!";
    }

    # remember the node being processed
    $tnode_being_processed = $node;

    # try to fix the node
    $self->fix($node);

    return;
}

# change the nde if necessary
sub fix {
    my ( $self, $node ) = @_;

    croak "Deepfix::fix is an abstract method!\n";
}

# NODE CHANGE METHODS

# returns log message
sub change_anode_attribute {
    my ( $self, $attribute, $value, $anode, $do_not_regenerate ) = @_;

    if (!defined $anode) {
        log_warn("Cannot change undefined lex node!");
        return;
    }

    my $msg = 'CHANGE ATTR on ' . $self->anode_sgn($anode) . ': ' . $attribute . ' ';

    # change attribute
    if ( $attribute =~ /^tag:(.+)$/ ) {
        my $cat = $1;
        my $tag = $anode->tag;
        $msg .= get_tag_cat( $tag, $cat ) . '->' . $value;
        my $new_tag = set_tag_cat( $tag, $cat, $value );
        $anode->set_tag($new_tag);
    }
    else {
        $msg .= $anode->get_attr($attribute) . '->' . $value;
        $anode->set_attr( $attribute, $value );
    }

    # regenerate node
    if ( !$do_not_regenerate ) {
        $self->regenerate_node($anode);
    }

    $msg .= ' ';
    return $msg;
}

# changes multiple attributes,
# regenerate only at the last attribute (if not forbidden)
# returns log message
sub change_anode_attributes {
    my ( $self, $attributes_info, $anode, $do_not_regenerate ) = @_;

    if (!defined $anode) {
        log_warn("Cannot change undefined lex node!");
        return;
    }

    my $msg = '';

    my @attributes = keys %$attributes_info;
    for ( my $i = 0; $i < @attributes; $i++ ) {
        my $attribute = $attributes[$i];
        my $value     = $attributes_info->{$attribute};
        my $dnr       = ( $i + 1 == @attributes ) ? $do_not_regenerate : 1;
        $msg .= $self->change_anode_attribute( $attribute, $value, $anode, $dnr );
    }

    return $msg;
}

# remove only the given node, moving its children under its parent
# returns log message
sub remove_anode {
    my ( $self, $anode ) = @_;

    if (!defined $anode) {
        log_warn("Cannot remove undefined lex node!");
        return;
    }

    my $msg = 'REMOVE ' . $self->anode_sgn($anode) . ' ';

    my $parent   = $anode->get_parent();
    my @children = $anode->get_children();
    foreach my $child (@children) {
        $child->set_parent($parent);
    }
    $anode->remove();

    return $msg;
}

# returns log message
sub add_parent {
    my ( $self, $parent_info, $anode ) = @_;

    if (!defined $anode) {
        log_warn("Cannot add parent to undefined lex node!");
        return;
    }
    
    my $old_parent = $anode->get_parent();
    my $new_parent = $old_parent->create_child($parent_info);
    $new_parent->set_parent($old_parent);
    $new_parent->shift_before_subtree(
        $anode, { without_children => 1 }
    );

    my $msg = 'ADD PARENT to ' . $self->anode_sgn($anode) . ': ' . $self->anode_sgn($new_parent) . ' ';
    return $msg;
}

# SUPPORT METHODS

sub regenerate_node {
    my ( $self, $anode, $dont_try_switch_number ) = @_;

    if (!defined $dont_try_switch_number) {
        $dont_try_switch_number = $self->dont_try_switch_number;
    }
    # now works only for lexnodes that have been processed by fill_info_lexnode
    my $ennode = $anode->wild->{'deepfix_info'}->{'ennode'};
    $formGenerator->regenerate_node( $anode, $dont_try_switch_number, $ennode);

    return;
}

sub anode_sgn {
    my ($self, $anode) = @_;

    # now works only for lexnodes that have been processed by fill_info_lexnode
    my $sgn = ($anode->wild->{'deepfix_info'}->{'id'} // $anode->id)
        . '(' . $anode->form . ')';

    return $sgn;
}

sub tnode_sgn {
    my ($self, $tnode) = @_;

    my $sgn = ($tnode->wild->{'deepfix_info'}->{'id'} // $tnode->id)
        . '(' . $tnode->t_lemma . ')';

    return $sgn;
}

sub get_tag_cat {
    return Treex::Tool::Depfix::CS::TagHandler::get_tag_cat(@_);
}

sub set_tag_cat {
    return Treex::Tool::Depfix::CS::TagHandler::set_tag_cat(@_);
}

sub get_node_tag_cat {
    my ($self, $node, $cat) = @_;

    return Treex::Tool::Depfix::CS::TagHandler::get_node_tag_cat($node, $cat);
}

sub set_node_tag_cat {
    my ($self, $node, $cat, $value) = @_;

    return Treex::Tool::Depfix::CS::TagHandler::set_node_tag_cat($node, $cat, $value);
}

sub logfix {
    my ( $self, $msg, $log_to_treex ) = @_;

    if (!$msg) {
        return;
    }

    # log to treex file
    if ($log_to_treex) {

        my $fixzone = $tnode_being_processed->get_bundle()
            ->get_or_create_zone( $self->language, 'deepfix' );
        my $sentence = $fixzone->sentence;
        if ($sentence) {
            $sentence .= " [$msg]";
        }
        else {
            $sentence = "[$msg]";
        }
        $fixzone->set_sentence($sentence);
    }

    # log to console
    if ( $self->log_to_console ) {
        log_info($msg);
    }

    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Treex::Block::T2T::CS2CS::Deepfix -
The base Deepfix block,
providing methods for other Deepfix blocks extended from it.

=head1 DESCRIPTION

An attempt to replace infrequent formemes by some more frequent ones.

Each node's formeme is checked against certain conditions --
currently, we attempt to fix only formemes of syntactical nouns
that are not morphological pronouns and that have no or one preposition.
Each such formeme is scored against the C<model> -- currently this is
a +1 smoothed MLE on CzEng data; the node's formeme is conditioned by
the t-lemma of the node and the t-lemma of its effective parent.
If the score of the current formeme is below C<lower_threshold>
and the score of the best scoring alternative formeme
is above C<upper_threshold>, the change is performed.

=head1 PARAMETERS

=over

=item C<src_alignment_type>

Type of alignment between the cs_Tfix t-tree and the en t-tree.
Default is C<src>.
The alignemt must lead from cs_Tfix to en.

=item C<log_to_console>

Set to C<1> to log details about the changes performed, using C<log_info()>.
Default is C<0>.

=back

=head1 AUTHORS

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 by Institute of Formal and Applied Linguistics, Charles
University in Prague

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
