package Treex::Core::Phrase;

use utf8;
use namespace::autoclean;

use Moose;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
use Treex::Core::Log;
use Treex::Core::Node;



has 'parent' =>
(
    is       => 'rw',
    isa      => 'Maybe[Treex::Core::Phrase]',
    writer   => '_set_parent',
    reader   => 'parent',
    default  => undef
);

has 'is_member' =>
(
    is            => 'rw',
    isa           => 'Bool',
    documentation => 'Is this phrase a member of a coordination (i.e. conjunct) or apposition?',
);



#------------------------------------------------------------------------------
# Sets a new parent for this phrase. Unlike the bare setter _set_parent(),
# this public method also takes care of the reverse links from the parent to
# the children. The method returns the old parent, if any.
#------------------------------------------------------------------------------
sub set_parent
{
    log_fatal('Incorrect number of arguments') if(scalar(@_) != 2);
    my $self = shift;
    my $new_parent = shift; # Treex::Core::Phrase::NTerm or undef
    if(defined($new_parent) && $new_parent->depends_on($self))
    {
        log_fatal('Cannot set parent phrase because it would create a cycle');
    }
    my $old_parent = $self->parent();
    # Say the old parent good bye.
    if(defined($old_parent))
    {
        $old_parent->_remove_child($self);
    }
    # Set the new parent before we call its _add_child() method so that it can verify it has been called from here.
    $self->_set_parent($new_parent);
    # Say the new parent hello.
    if(defined($new_parent))
    {
        $new_parent->_add_child($self);
    }
    return $old_parent;
}



#------------------------------------------------------------------------------
# Tests whether this phrase depends on another phrase via the parent links.
# This method is used to prevent cycles when setting a new parent.
#------------------------------------------------------------------------------
sub depends_on
{
    log_fatal('Incorrect number of arguments') if(scalar(@_) != 2);
    my $self = shift;
    my $on_phrase = shift; # Treex::Core::Phrase
    my $parent = $self->parent();
    return defined($parent) ? $parent->depends_on($on_phrase) : 0;
}



#------------------------------------------------------------------------------
# Tells whether this phrase is terminal. We could probably use the Moose's
# methods to query the class name but this will be more convenient.
#------------------------------------------------------------------------------
sub is_terminal
{
    my $self = shift;
    log_fatal("The is_terminal() method is not implemented");
}



#------------------------------------------------------------------------------
# Returns the head node of the phrase. For terminal phrases this should just
# return their node attribute. For nonterminal phrases this should return the
# node of their head child. This is an abstract method that must be defined in
# every derived class.
#------------------------------------------------------------------------------
sub node
{
    my $self = shift;
    log_fatal("The node() method is not implemented");
}



#------------------------------------------------------------------------------
# Returns the type of the dependency relation of the phrase to the governing
# phrase. This is an abstract method that must be defined in every derived
# class. When the phrase structure is built around a dependency tree, the
# relations will be probably taken from (or based on) the deprels of the
# underlying nodes. When the phrase tree is transformed to the desired style,
# the relations may be modified; at the end, they can be projected to the
# dependency tree again. A general nonterminal phrase typically has the same
# deprel as its head child. Terminal phrases store deprels as attributes.
#------------------------------------------------------------------------------
sub deprel
{
    my $self = shift;
    log_fatal("The deprel() method is not implemented");
}



#------------------------------------------------------------------------------
# Returns the node's ord attribute. This means that nodes that do not implement
# the Ordered role cannot be wrapped in phrases. We sometimes need to order
# child phrases according to the word order of their head nodes.
#------------------------------------------------------------------------------
sub ord
{
    my $self = shift;
    return $self->node()->ord();
}



#------------------------------------------------------------------------------
# Projects dependencies between the head and the dependents back to the
# underlying dependency structure. This is an abstract method that must be
# implemented in the derived classes.
#------------------------------------------------------------------------------
sub project_dependencies
{
    my $self = shift;
    log_fatal("The project_dependencies() method is not implemented");
}



__PACKAGE__->meta->make_immutable();

1;



=for Pod::Coverage BUILD

=encoding utf-8

=head1 NAME

Treex::Core::Phrase

=head1 DESCRIPTION

A C<Phrase> is a concept defined on top of dependency trees and subtrees
(where a subtree contains a node and all its descendants, not just any arbitrary subset of nodes).
Similarly to the Chomsky's hierarchy of formal grammars, there are two main types of phrases:
I<terminal> and I<nonterminal>.
Furthermore, there may be subtypes of the nonterminal type with special behavior.

A B<terminal phrase> contains just one C<Node> (which typically corresponds to a surface token).

A B<nonterminal phrase> does not directly contain any C<Node> but it contains
one or more (usually at least two) sub-phrases.
The hierarchy of phrases and their sub-phrases is also a tree structure.
In the typical case there is a relation between the tree of phrases and the underlying dependency
tree, but the rules governing this relation are not fixed.

Phrases help us model situations that are difficult to model in the dependency tree alone.
We can encode multiple levels of “tightness” of relations between governors and dependents.
In particular we can distinguish between dependents that modify the whole phrase (shared modifiers)
and those that modify only the head of the phrase (private modifiers).

This is particularly useful for various tree transformations and conversions between annotation
styles (such as in the HamleDT blocks).
The idea is that we will first construct a phrase tree based on the existing dependency tree,
then we will perform transformations on the phrase tree
and finally we will create new dependency relations based on the phrase tree and
on the rules defined by the desired annotation style.
Phrase is a temporary internal structure that will not be saved in the Treex format on the disk.

Every phrase knows its parent (superphrase) and, if it is nonterminal, its children (subphrases).
It also knows which of the children is the I<head> (as long as there are children, there is always
one and only one head child).
The phrase can also return its head node. For terminal phrases, this is the node they enwrap.
For nonterminal phrases, this is defined recursively as the head node of their head child phrase.

Every phrase also has a dependency relation label I<(deprel)>.
These labels are analogous to deprels of nodes in dependency trees.
Most of them are just taken from the underlying dependency tree and they are propagated back when
new dependency structure is shaped after the phrases; however, some labels may have special
meaning even for the C<Phrase> objects. They help recognize special types of nonterminal phrases,
such as coordinations.
If the phrase is the head of its parent phrase, its deprel is identical to the deprel of its parent.
Otherwise, the deprel represents the dependency relation between the phrase and the head of its parent.

=head1 ATTRIBUTES

=over

=item parent

Refers to the parent C<Phrase>, if any.

=item is_member

Is this phrase member of a paratactic structure such as coordination (where
members are known as conjuncts) or apposition? We need this attribute because
of the Prague-style dependency trees. We need it only during the building phase
of the phrase tree.

We could encode this attribute in C<deprel> but it would not be practical
because it acts independently of C<deprel>. Unlike C<deprel>, C<is_member> is
less tied to the underlying nodes; it is really an attribute of the whole
phrase. If we decide to change the C<deprel> of the phrase (which is propagated
to selected core children), we do not necessarily want to change C<is_member>
too. And we do not want to decode C<is_member> from C<deprel>, shuffle and
encode elsewhere again.

When a terminal phrase is created around a C<Node>, it takes its C<is_member>
value from the node. When the phrase receives a parent, the C<is_member> flag
will be typically moved to the parent (and erased at the child). However, this
does not happen automatically and the C<Builder> has to do that when desired.
Similarly, when the type of the phrase is changed (e.g. a new C<Phrase::PP> is
created, the contents of the old C<Phrase::NTerm> is moved to it and the old
phrase is destroyed), the surrounding code should make sure that the
C<is_member> flag is carried over, too. Finally, the value will be used when
a C<Phrase::Coordination> is recognized. At that point the C<is_member> flag
can be erased for all newly identified conjuncts because now they can be
recognized without the flag. However, if the C<Phrase::Coordination> itself (or its
C<Phrase::NTerm> predecessor) is a member of a larger paratactic structure, then it
must keep the flag for its parent to see and use.

=back

=head1 METHODS

=over

=item $phrase->set_parent ($nonterminal_phrase);

Sets a new parent for this phrase. The parent phrase must be a L<nonterminal|Treex::Core::Phrase::NTerm>.
This phrase will become its new I<non-head> child.
The new parent may also be undefined, which means that the current phrase will
be disconnected from the phrase structure (but it will keeep its own children,
if any).
The method returns the old parent.

=item if( $phrase->depends_on ($another_phrase) ) {...}

Tests whether this phrase depends on another phrase via the parent links.
This method is used to prevent cycles when setting a new parent.

=item my $ist = $phrase->is_terminal();

Tells whether this phrase is terminal, that is, it does not have children
(subphrases).

=item my $node = $phrase->node();

Returns the head node of the phrase. For terminal phrases this should just
return their node attribute. For nonterminal phrases this should return the
node of their head child. This is an abstract method that must be defined in
every derived class.

=item my $deprel = $phrase->deprel();

Returns the type of the dependency relation of the phrase to the governing
phrase. This is an abstract method that must be defined in every derived
class. When the phrase structure is built around a dependency tree, the
relations will be probably taken from (or based on) the deprels of the
underlying nodes. When the phrase tree is transformed to the desired style,
the relations may be modified; at the end, they can be projected to the
dependency tree again. A general nonterminal phrase typically has the same
deprel as its head child. Terminal phrases store deprels as attributes.

=item my $ord = $phrase->ord();

Returns the head node's ord attribute. This means that nodes that do not implement
the L<Treex::Core::Node::Ordered|Ordered> role cannot be wrapped in phrases. We sometimes need to order
child phrases according to the word order of their head nodes.

=item $phrase->project_dependencies();

Recursively projects dependencies between the head and the dependents back to the
underlying dependency structure.

=back

=head1 AUTHORS

Daniel Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013, 2015 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
