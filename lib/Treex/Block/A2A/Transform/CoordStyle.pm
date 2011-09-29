package Treex::Block::A2A::Transform::CoordStyle;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::A2A::Transform::BaseTransformer';

# Shortcuts
has style => (
    is            => 'ro',
    isa           => 'Str',
    documentation => 'output coord style - shorcut for other options (e.g. fPhRsHcHpB)',
);

has from_style => (
    is            => 'ro',
    isa           => 'Str',
    documentation => 'input coord style - shorcut for other options (e.g. fPhRsHcHpB)',
);

# Output style
has family => (
    is            => 'ro',
    isa           => enum( [qw(Moscow Prague Stanford)] ),
    writer        => '_set_family',
    documentation => 'output coord style family (Prague, Moscow, and Stanford)',
);

has head => (
    is            => 'ro',
    isa           => enum( [qw(left right mixed)] ),
    writer        => '_set_head',
    documentation => 'which node should be the head of the coordination structure',
);

has shared => (
    is            => 'ro',
    isa           => enum( [qw(head nearest)] ),
    writer        => '_set_shared',
    documentation => 'which node should be the head of the shared modifiers',
);

has conjunction => (
    is            => 'ro',
    isa           => enum( [qw(previous following between head)] ),
    writer        => '_set_conjunction',
    documentation => 'conjunction parents (previous, following, between, head)',
);

has punctuation => (
    is            => 'ro',
    isa           => enum( [qw(previous following between)] ),
    writer        => '_set_punctuation',
    documentation => 'punctuation parents (previous, following, between)',
);

# Input style
has from_family => (
    is            => 'ro',
    isa           => enum( [qw(Moscow Prague Stanford autodetect)] ),
    default       => 'autodetect',
    writer        => '_set_from_family',
    documentation => 'input coord style family',
);

has from_head => (
    is            => 'ro',
    isa           => enum( [qw(left right nearest autodetect)] ),
    default       => 'autodetect',
    writer        => '_set_from_head',
    documentation => 'input style head',
);

has from_shared => (
    is            => 'ro',
    isa           => enum( [qw(head nearest autodetect)] ),
    default       => 'autodetect',
    writer        => '_set_from_shared',
    documentation => 'input style shared modifiers parents',
);

has from_conjunction => (
    is            => 'ro',
    isa           => enum( [qw(previous following between head autodetect)] ),
    default       => 'autodetect',
    writer        => '_set_from_conjunction',
    documentation => 'input style conjunction parents',
);

has from_punctuation => (
    is            => 'ro',
    isa           => enum( [qw(previous following between autodetect)] ),
    default       => 'autodetect',
    writer        => '_set_from_punctuation',
    documentation => 'input style punctuation parents',
);

sub BUILD {
    my ( $self, $args ) = @_;

    # TODO: rewrite (code duplication, $self->{attr} etc.)
    my @pars = qw(family head shared conjunction punctuation);
    if ( $self->style ) {
        my $style_regex = 'f[MPS]h[LRM]s[HN]c[PFBH]p[PFB]';
        log_fatal "Parameter 'style' cannot be combined with other parameters"
            if any { $args->{$_} } @pars;
        log_fatal "Prameter 'style' must be in form $style_regex"
            if $self->style !~ /^$style_regex$/;
        $self->_fill_style_from_shortcut( 0, $self->style );
    }
    else {
        for my $par (@pars) {
            log_fatal "Parameter $par (or style) is required" if !$self->{$par};
        }
    }

    if ( $self->from_style ) {
        my $from_style_regex = 'f[MPSA]h[LRMA]s[HNA]c[PFBHA]p[PFBA]';
        log_fatal "Parameter 'from_style' cannot be combined with other parameters"
            if any { $args->{ 'from_' . $_ } } @pars;
        log_fatal "Prameter 'from_style' must be in form $from_style_regex"
            if $self->style !~ /^$from_style_regex$/;
        $self->_fill_style_from_shortcut( 1, $self->from_style );
    }

    log_fatal "Prague family must have parameter conjunction=head"
        if $self->family eq 'Prague' && $self->conjunction ne 'head';
    log_fatal "conjunction=head parameter is applicable only for Prague family"
        if $self->family ne 'Prague' && $self->conjunction eq 'head';
    return;
}

my %FAMILY_NAME = (
    M => 'Moscow',
    P => 'Prague',
    S => 'Stanford',
);

my %HEAD_NAME = (
    L => 'left',
    R => 'right',
    M => 'mixed',
);

my %SHARED_NAME = (
    H => 'head',
    N => 'nearest',
);

my %CONJUNCTION_NAME = (
    P => 'previous',
    F => 'following',
    B => 'between',
    H => 'head',
);

my %PUNCTUATION_NAME = (
    P => 'previous',
    F => 'following',
    B => 'between',
);

sub _fill_style_from_shortcut {
    my ( $self, $from, $shortcut ) = @_;
    my $style_regex = 'f([MPSA])h([LRMA])s([HNA])c([PFBHA])p([PFBA])';
    my ( $f, $h, $s, $c, $p ) = ( $shortcut =~ /^$style_regex$/ );
    if ( !$from ) {
        $self->_set_family( $FAMILY_NAME{$f} );
        $self->_set_head( $HEAD_NAME{$h} );
        $self->_set_shared( $SHARED_NAME{$s} );
        $self->_set_conjunction( $CONJUNCTION_NAME{$c} );
        $self->_set_punctuation( $PUNCTUATION_NAME{$p} );
    }
    else {
        $self->_set_from_family( $FAMILY_NAME{$f}           || 'autodetect' );
        $self->_set_from_head( $HEAD_NAME{$h}               || 'autodetect' );
        $self->_set_from_shared( $SHARED_NAME{$s}           || 'autodetect' );
        $self->_set_from_conjunction( $CONJUNCTION_NAME{$c} || 'autodetect' );
        $self->_set_from_punctuation( $PUNCTUATION_NAME{$p} || 'autodetect' );
    }
    return;
}

sub process_atree {
    my ( $self, $atree ) = @_;

    #return if $atree->get_bundle->get_position > 5;
    $self->process_subtree($atree);
}

sub _empty_res {
    return ( members => [], shared => [], commas => [], ands => [] );
}

sub _merge_res {
    my ( $self, @results ) = @_;
    my $merged_res = { $self->_empty_res };
    foreach my $res ( grep {$_} @results ) {
        foreach my $type ( keys %{$merged_res} ) {
            push @{ $merged_res->{$type} }, @{ $res->{$type} };
        }
    }
    return $merged_res;
}

# returns $res
sub process_subtree {
    my ( $self, $node ) = @_;
    my @children = $node->get_children();

    # Leaves are simple (end of recursion).
    if ( !@children ) {
        my $type = $self->type_of_node($node) or return 0;
        return { $self->_empty_res, $type => [$node], head => $node };
    }

    # Recursively process children subtrees.
    my @child_res = grep {$_} map { $self->process_subtree($_) } @children;

    # If $node is not part of CS, we are finished.
    # (@child_res should be empty, but even if not, we can't do anything about that.)
    my $my_type = $self->type_of_node($node);
    return 0 if !$my_type;

    # So $node is a CS participant (it has non-empty $my_type).
    my $parent      = $node->get_parent();
    my $parent_type = $self->type_of_node($parent);
    my $merged_res  = $self->_merge_res(@child_res);
    my @child_types = map { $self->type_of_node( $_->{head} ) } @child_res;
    $merged_res->{head} = $node;
    push @{ $merged_res->{$my_type} }, $node;

    # TODO merged_res may represent more CSs in case of nested CSs and Moscow or Stanford
    #my $from_f      = $self->from_family;

    # If $node is the top node of a CS, let's transform the CS now and we are finished
    if ( !$parent_type ) {
        my $new_head = $self->transform_coord( $node, $merged_res );
        return 0;
    }

    # TODO in case of nested CSs, we might still need to transform the CS and return some $res
    #if ( $from_f eq 'Prague' && $my_type eq 'ands' ) {
    #}

    return $merged_res;
}

# Find the nearest previous/following member.
# "Previous/following" is set by $direction, but if no such is found, the other direction is tried.
sub _nearest {
    my ( $self, $direction, $node, @members ) = @_;
    if ( $direction eq 'previous' ) {
        my $prev_mem = first { $_->precedes($node) } reverse @members;
        return $prev_mem if $prev_mem;
        return first { $node->precedes($_) } @members;
    }
    else {    # 'following'
        my $foll_mem = first { $node->precedes($_) } @members;
        return $foll_mem if $foll_mem;
        return first { $_->precedes($node) } reverse @members;
    }
}

# Note that (in nested CSs) a node can be both member and a conjunction (ands) or shared,
# but for this purpose we treat it as a member.
sub type_of_node {
    my ( $self, $node ) = @_;
    return 0 if $node->is_root();

    # We ignore appositions, we want only coordination members
    return 'members' if $node->is_member;
    return 'shared'  if $node->is_shared_modifier;
    return 'ands'    if $node->wild->{is_coord_conjunction};
    return 'commas'  if $self->is_comma($node);
    return 0;
}

sub _dump_res {
    my ( $self, $res ) = @_;
    my $head = $res->{head};
    warn "COORD_DUMP head=" . $head->form . "(id=" . $head->id . ")\n";
    foreach my $type (qw(members ands shared commas)) {
        warn $type . ":" . join( '|', map { $_->form } @{ $res->{$type} } ) . "\n";
    }
    return;
}

# returns new_head
sub transform_coord {
    my ( $self, $old_head, $res ) = @_;
    return $old_head if !$res;

    #$self->_dump_res($res);
    my $parent  = $old_head->get_parent();
    my @members = sort { $a->ord <=> $b->ord } @{ $res->{members} };
    my @shared  = @{ $res->{shared} };
    my @commas  = @{ $res->{commas} };
    my @ands    = @{ $res->{ands} };

    # Skip if no members
    if ( !@members ) {

        # These cases may be AuxX from appositions or incorrectly detected
        # coordination conjunction, e.g. "A(afun=AuxY) to se podívejme."
        # So I've commented the next line, since most warnings would be false alarms.
        #log_warn "No conjuncts in coordination under " . $parent->get_address;
        return $old_head;
    }
    my $new_head;
    my $parent_left = $parent->precedes( $members[0] );
    my $is_left_top = $self->head eq 'left' ? 1 : $self->head eq 'right' ? 0 : $parent_left;

    # Commas should have afun AuxX, conjunctions Coord.
    # (Except for Prague family, where the head conjunction has always Coord,
    # but that will be solved later.)
    foreach my $sep ( @commas, @ands ) {
        $sep->set_afun( $self->is_comma($sep) ? 'AuxX' : 'Coord' );
    }

    # PRAGUE
    if ( $self->family eq 'Prague' ) {
        my @separators = sort { $a->ord <=> $b->ord } ( @ands, @commas );
        if ( !@separators ) {
            log_warn "No separators in coordination under " . $parent->get_address;
            return $old_head;
        }

        # $new_head will be the leftmost (resp. rightmost) separator (depending on $self->head)
        # The rest of separators will be treated as commas.
        $new_head = $is_left_top ? shift @separators : pop @separators;
        @commas = @separators;

        # Rehang the conjunction and members
        $self->rehang( $new_head, $parent );
        $new_head->set_afun('Coord');
        foreach my $member (@members) {
            $self->rehang( $member, $new_head );
        }

        # In Prague family, punctuation=between means that
        # commas are hanged on the head conjunction.
        if ( $self->punctuation eq 'between' ) {
            foreach my $sep (@separators) {
                $self->rehang( $sep, $new_head );
            }
        }
    }

    # STANFORD & MOSCOW
    else {
        my @andmembers = @members;
        $new_head = $is_left_top ? shift @andmembers : pop @andmembers;
        push @andmembers, @ands   if $self->conjunction eq 'between';
        push @andmembers, @commas if $self->punctuation eq 'between';
        @andmembers = sort { $a->ord <=> $b->ord } @andmembers;
        if ( !$is_left_top ) {
            @andmembers = reverse @andmembers;
        }

        # Rehang the members (and conjunctions and commas if "between")
        $self->rehang( $new_head, $parent );
        my $rehang_to = $new_head;
        foreach my $andmember (@andmembers) {
            $self->rehang( $andmember, $rehang_to );
            if ( $self->family eq 'Moscow' ) {
                $rehang_to = $andmember;
            }
        }
    }

    # COMMAS (except "between" which is already solved)
    if ( $self->punctuation =~ /previous|following/ ) {
        my @andmembers = sort { $a->ord <=> $b->ord } @members, @ands;
        foreach my $comma (@commas) {
            $self->rehang( $comma, $self->_nearest( $self->punctuation, $comma, @andmembers ) );
        }
    }

    # CONJUNCTIONS (except "between" and "head" which are already solved)
    if ( $self->conjunction =~ /previous|following/ ) {
        foreach my $and (@ands) {
            $self->rehang( $and, $self->_nearest( $self->conjunction, $and, @members ) );
        }
    }

    # SHARED MODIFIERS
    foreach my $sm (@shared) {

        # Note that if there is no following member, nearest previous will be chosen.
        if ( $self->shared eq 'nearest' ) {
            $self->rehang( $sm, $self->_nearest( 'following', $sm, @members ) );
        }
        elsif ( $self->shared eq 'head' ) {
            $self->rehang( $sm, $new_head );
        }
    }

    return $new_head;
}

# Is the given node a coordination separator such as comma or semicolon?
sub is_comma {
    my ( $self, $node ) = @_;

    #return $node->afun =~ /Aux[XYG]/;
    return $node->form =~ /^[,;]$/;
}

1;

__END__

    #    if ( $from_f eq 'detect' ) {
    #        if ( $my_type eq 'ands' ) {
    #            if ( $parent_type ne 'members' && !$self->is_conjunction($parent) ) {
    #                $from_f = 'Prague';
    #            }
    #        }
    #        elsif (1) {
    #
    #        }
    #    }


=head1 NAME

Treex::Block::A2A::Transform::CoordStyle - change the style of coordinations

=head1 SYNOPSIS

  # in scenario:
  A2A::Transform::CoordStyle
         family=Moscow
           head=left
         shared=nearest
    conjunction=between
    punctuation=previous

  TODO the same using a shortcut
  A2A::Transform::CoordStyle style=fMhLsNcBpP
  
=head1 DESCRIPTION

TODO

=head1 PREREQUISITIES

  is_member
  is_shared_modifier
  wild->{is_coord_conjunction}

=head1 SEE ALSO

L<Treex::Block::A2A::SetSharedModifier>,
L<Treex::Block::A2A::SetCoordConjunction>


# Copyright 2011 Martin Popel
# This file is distributed under the GNU GPL v2 or later. See $TMT_ROOT/README.
