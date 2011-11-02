package Treex::Block::A2A::Transform::CoordStyle2;
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

has prefer_conjunction => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => 'In Prague family, if possible prefer conjunction as head instead of commas',
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
            if $self->from_style !~ /^$from_style_regex$/;
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

my %entered;

sub process_atree {
    my ( $self, $atree ) = @_;

    #return if $atree->get_bundle->get_position != 34; #DEBUG
    my $from_f = $self->from_family;
    if ( $from_f eq 'Prague' ) {
        $self->detect_prague($atree);
    }
    elsif ( $from_f eq 'Moscow' ) {
        $self->detect_moscow($atree);
    }
    elsif ( $from_f eq 'Stanford' ) {
        $self->detect_stanford($atree);
    }
    else {
        log_fatal "$from_f not implemented";

        #TODO
    }

    # clean temporary variables, so we save some memory
    %entered = ();
    return;
}

sub detect_prague {
    my ( $self, $node ) = @_;
    my @children = $node->get_children( { ordered => 1 } );

    # If $node is not a head of coordination,
    # just skip it and recursively process its children.
    if ( ( $node->afun || '' ) ne 'Coord' ) {
        foreach my $child (@children) {
            $self->detect_prague($child);
        }
        return $node;
    }

    # So $node is a head of coordination.
    # Detect all coordination participants.
    my @members = grep { $_->is_member } @children;
    my ( @shared, @commas );
    if ( $self->from_shared eq 'nearest' ) {
        @shared = grep { $_->is_shared_modifier } map { $_->get_children } @members;
    }
    else {
        @shared = grep { $_->is_shared_modifier } @children;
    }
    my @todo = grep { !$_->is_member && !$_->is_shared_modifier } @children;
    my @ands = grep { $_->wild->{is_coord_conjunction} } @todo;
    @todo = grep { !$_->wild->{is_coord_conjunction} } @todo;
    if ( $self->from_punctuation =~ /previous|following/ ) {
        @commas = grep { $self->is_comma($_) } map { $_->get_children } @members;
    }
    else {
        @commas = grep { $self->is_comma($_) } @todo;
        @todo   = grep { !$self->is_comma($_) } @todo;
    }

    # Recursion
    @members = map { $self->detect_prague($_); } @members;
    @shared  = map { $self->detect_prague($_); } @shared;

    #TODO? @commas, @ands (these should be mostly leaves)

    # Finally add the head (afun=Coord) as either conjunction or comma
    if ( $node->wild->{is_coord_conjunction} ) {
        push @ands, $node;
    }
    else {
        push @commas, $node;
    }

    # Transform the detected coordination
    my $res = { members => \@members, ands => \@ands, shared => \@shared, commas => \@commas, head => $node };
    my $new_head = $self->transform_coord( $node, $res );
    return $new_head;
}

sub detect_stanford {
    my ( $self, $node ) = @_;

    # Don't go twice thru one node
    return $node if $entered{$node};
    $entered{$node} = 1;

    #warn "dive [" . $node->form . "]\n"; #DEBUG

    my @children = $node->get_children( { ordered => 1 } );
    my @members = grep { $_->is_member } @children;

    # If $node is not a head of coordination,
    # just skip it and recursively process its children.
    # In Stanford style, the head of coordination is recognized iff
    #  - there are conjuncts (marked by is_member=1) among its children
    #  - or thera are coordinating conjunctions among its children.
    # For CSs with only one conjunct (the head) only the latter holds.
    # E.g. "And I love her." is in some annotation styles considered as a CS
    # with only one conjunct ("love") and one conjunction ("And").
    if ( !@members && !grep { $_->wild->{is_coord_conjunction} } @children ) {
        foreach my $child (@children) {
            $self->detect_stanford($child);
        }
        return $node;
    }

    # Add the head as a member
    push @members, $node;
    @members = sort { $a->ord <=> $b->ord } @members;

    # So $node is a head of coordination.
    # Detect all coordination participants.
    my ( @shared, @commas, @ands );
    if ( $self->from_shared eq 'nearest' ) {
        @shared = grep { $_->is_shared_modifier } map { $_->get_children } @members;
    }
    else {
        @shared = grep { $_->is_shared_modifier } @children;
    }
    my @todo = grep { !$_->is_member && !$_->is_shared_modifier } @children;

    if ( $self->from_conjunction =~ /previous|following/ ) {
        @ands = grep { $_->wild->{is_coord_conjunction} } map { $_->get_children } @members;
    }
    else {
        @ands = grep { $_->wild->{is_coord_conjunction} } @todo;
        @todo = grep { !$_->wild->{is_coord_conjunction} } @todo;
    }
    @ands = sort { $a->ord <=> $b->ord } @ands;

    my @andmembers = sort { $a->ord <=> $b->ord } ( @ands, @members );
    if ( $self->from_punctuation =~ /previous|following/ ) {
        @commas = grep { $self->is_comma($_) } map { $_->get_children } @andmembers;
    }
    else {
        @commas = grep { $self->is_comma($_) } @todo;
        @todo   = grep { !$self->is_comma($_) } @todo;
    }

    # Try to distinguish nested coordinations from multi-conjunct coordinations.
    # If last conjunction precedes penultimate conjunct, e.g.: C1 and C2 , C3
    # nested interpretation is more probable: (C1 and C2) , (C3).
    #if (@members > 2 && @ands && $ands[-1]->precedes($members[-2])){
    #
    #}

    @members = map { $self->detect_stanford($_); } @members;
    @shared  = map { $self->detect_stanford($_); } @shared;
    @todo    = map { $self->detect_stanford($_); } @todo;      # private modifiers of the head

    #TODO? @commas, @ands (these should be mostly leaves)

    # Transform the detected coordination
    my $res = { members => \@members, ands => \@ands, shared => \@shared, commas => \@commas, head => $node };
    my $new_head = $self->transform_coord( $node, $res );
    return $new_head;
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
    elsif ( $direction eq 'following' ) {
        my $foll_mem = first { $node->precedes($_) } @members;
        return $foll_mem if $foll_mem;
        return first { $_->precedes($node) } reverse @members;
    }
    elsif ( $direction eq 'any' ) {
        my $my_ord = $node->ord;
        my @sorted = sort { abs( $a->ord - $my_ord ) <=> abs( $b->ord - $my_ord ) } @members;
        return $sorted[0];
    }
    else {
        log_fatal "unknown direction '$direction'";
    }
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

    #$self->_dump_res($res); #DEBUG
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

    # Filter incorrectly detected commas: commas should be between members.
    @commas = grep { $members[0]->precedes($_) && $_->precedes( $members[-1] ) } @commas;

    my $new_head;
    my $parent_left = $parent->precedes( $members[0] );
    my $is_left_top = $self->head eq 'left' ? 1 : $self->head eq 'right' ? 0 : $parent_left;

    # Commas should have afun AuxX, conjunctions Coord. They are not is_member.
    # (Except for Prague family, where the head conjunction has always Coord,
    # but that will be solved later.)
    foreach my $sep ( @commas, @ands ) {
        $sep->set_afun( $self->is_comma($sep) ? 'AuxX' : 'Coord' );
        $sep->set_is_member(0);
    }

    # PRAGUE
    if ( $self->family eq 'Prague' ) {

        # Possible heads are @ands (conjunctions), but if missing
        # or if we don't want to distinguish them from @commas (i.e. not $self->prefer_conjunction)
        # then we should include commas as "eligible" for the head.
        if ( !@ands || !$self->prefer_conjunction ) {
            push @ands, @commas;
            @commas = ();
        }
        if ( !@ands ) {
            log_warn "No separators in coordination under " . $parent->get_address;
            return $old_head;
        }
        @ands = sort { $a->ord <=> $b->ord } @ands;

        # Choose one of the possible heads as $new_head,
        # the rest will be treated as commas.
        $new_head = $is_left_top ? shift @ands : pop @ands;
        push @commas, @ands;
        for (@commas) { $_->set_afun('AuxY'); }

        # Rehang the new_head and members
        $self->rehang( $new_head, $parent );
        $new_head->set_afun('Coord');
        foreach my $member (@members) {
            $self->rehang( $member, $new_head );
        }

        # In Prague family, punctuation=between means that
        # commas (and remaining conjunctions) are hanged on the head.
        if ( $self->punctuation eq 'between' ) {
            foreach my $comma (@commas) {
                $self->rehang( $comma, $new_head );
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

    # SET is_member LABELS
    # Generally, is_member=1 iff a given word is a conjunct ("a member of a coordination").
    # However, there are exceptions for each style family:
    # * Prague:   In nested coordinations, also coordination head
    #             (conjunction or comma) can have is_member=1.
    # * Stanford: The coordination head (the first/last conjunct) is NOT marked
    #             as is_member (unless it is also a non-head conjunct of a nested coordination).
    # * Moscow:   Same as Stanford (but may be changed because of problematic
    #             distinguishing of nested coordinations from multi-conjunct coordinations).
    foreach my $member (@members) {
        $member->set_is_member( $member != $new_head );
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
            $self->rehang( $sm, $self->_nearest( 'any', $sm, @members ) );
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
    return $node->form =~ /^[,;]$/;
}

1;

__END__

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

  #TODO the same using a shortcut
  #A2A::Transform::CoordStyle style=fMhLsNcBpP
  
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
