package Treex::Block::Write::LayerAttributes::CzechCoarseTag;
use Moose;
use Treex::Core::Common;

with 'Treex::Block::Write::LayerAttributes::AttributeModifier';

has '+return_values_names' => ( builder => '_build_retval_names', lazy_build => 1 );

has 'very_coarse' => ( isa => 'Bool', is => 'ro', default => 0 );

has 'use_case' => ( isa => 'Bool', is => 'ro', default => 1 );

has 'split' => ( isa => 'Bool', is => 'ro', default => 0 );

has 'no_tense' => ( isa => 'Bool', is => 'ro', default => 0 );

has 'no_voc' => ( isa => 'Bool', is => 'ro', default => 0 );

# Get the use_case and split parameters out of the given parameters to new
sub BUILDARGS {

    my ( $class, @params ) = @_;

    return $params[0] if ( @params == 1 && ref $params[0] eq 'HASH' );

    @params = @{ $params[0] } if ( @params == 1 && ref $params[0] eq 'ARRAY' );

    if ( @params > 5 ) {
        log_fatal('CzechCoarseTag:There must be up to 4 binary parameters to new().');
    }

    my $ret = {};

    $ret->{no_voc}      = $params[4] if ( @params >= 5 );
    $ret->{no_tense}    = $params[3] if ( @params >= 4 );
    $ret->{split}       = $params[2] if ( @params >= 3 );
    $ret->{use_case}    = $params[1] if ( @params >= 2 );
    $ret->{very_coarse} = $params[0] if ( @params >= 1 );

    return $ret;
}

# Czech POS tag simplified to POS&CASE (or POS&SUBPOS if no case, or instructed not to use cases)
sub modify_single {

    my ( $self, $tag ) = @_;

    return ( $self->split ? ( undef, undef ) : undef ) if ( !defined($tag) );
    return ( $self->split ? ( '',    '' )    : '' )    if ( length($tag) < 5 );

    return substr( $tag, 0, 1 ) if ( $self->very_coarse );

    my $ctag;

    # no case or set not to use it -> Pos + Subpos
    if ( substr( $tag, 4, 1 ) eq '-' || !$self->use_case ) {
        $ctag = substr( $tag, 0, 2 );
    }

    # has case -> Pos + Case
    else {
        $ctag = substr( $tag, 0, 1 ) . substr( $tag, 4, 1 );
    }

    $ctag = 'VB' if ( $self->no_tense && $ctag =~ m/^V/ );
    $ctag = 'RR' if ( $self->no_voc   && $ctag =~ m/^R/ );

    return $self->split ? split //, $ctag : $ctag;
}

# Build the return values names based on the split parameter
sub _build_retval_names {
    my ($self) = @_;
    return $self->split ? [ '_MainPOS', '_SubPOS' ] : [''];
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::Write::LayerAttributes::CzechCoarseTag

=head1 SYNOPSIS

    my $modif = Treex::Block::Write::LayerAttributes::CzechCoarseTag->new(); 
    my $tag = 'NNIS1-----A----';   
    print $modif->modify_all( $tag ); # prints 'N1'
    $tag = 'VpYS---XR-AA---';
    print $modif->modify_all( $tag ); # prints 'Vp'

=head1 DESCRIPTION

A text modifier for blocks using L<Treex::Block::Write::LayerAttributes> which takes the Czech positional morphological tag
and makes a "coarse tag" out of it, which consists either of the coarse part-of-speech and case, if the given part-of-speech
can be declined, or of the coarse and detailed part-of-speech.

=head1 PARAMETERS

The constructor can take either individual boolean values, or a reference to an array containing them, or a hash reference 
with the appropriate keys. 

=over 

=item C<use_case>

If set to 0, the case values are not used, even if the given part-of-speech has them. Default is 1. This parameter can
also be passed to the constructor as a single boolean value (or the first of the two). 

=item C<split>

If set to 1, the two positions of the coarse POS tag are returned as two separate values. 0 is the default. This can also
be passed to the constructor as the second of two boolean values.

=back 

=head1 AUTHORS

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
