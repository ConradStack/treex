package Treex::Core::Node::Interset;
use Moose::Role;

# with Moose >= 2.00, this must be present also in roles
use MooseX::SemiAffordanceAccessor;
use Treex::Core::Log;
use List::Util qw(first);    # TODO: this wouldn't be needed if there was Treex::Core::Common for roles
use tagset::common;



#------------------------------------------------------------------------------
# Takes the Interset feature structure as a hash reference (as output by an
# Interset decode() function). For all hash keys that are known Interset
# feature names, sets the corresponding iset attribute.
#
# If the first argument is not a hash reference, the list of arguments is
# considered a list of features and values. Usage examples:
#
#    set_iset(\%feature_structure);
#    set_iset('pos', 'noun');
#    set_iset('pos' => 'noun', 'gender' => 'masc', 'number' => 'sing');
#------------------------------------------------------------------------------
sub set_iset
{
    my $self = shift;
    my %f;
    if(ref($_[0]) eq 'HASH')
    {
        %f = %{$_[0]};
    }
    else
    {
        %f = @_;
    }
    my $known = list_iset_values();
    foreach my $feature (list_iset_features())
    {
        if(exists($f{$feature}))
        {
            if($f{$feature} eq '')
            {
                $self->set_attr("iset/$feature", '');
            }
            elsif(ref($f{$feature}) eq 'ARRAY')
            {
                $self->set_attr("iset/$feature", join('|', $self->sort_iset_values($feature, @{$f{$feature}})));
            }
            else
            {
                my @values = split(/\|/, $f{$feature});
                foreach my $value (@values)
                {
                    unless(grep {$_ eq $value} (@{$known->{$feature}}))
                    {
                        warn("Unknown value $value of Interset feature $feature");
                    }
                }
                $self->set_attr("iset/$feature", join('|', $self->sort_iset_values($feature, @values)));
            }
        }
    }
}



#------------------------------------------------------------------------------
# Gets the value of an Interset feature. Makes sure that the result is never
# undefined so the use/strict/warnings creature keeps quiet. It returns undef
# only if we ask for the value of an unknown feature.
#
# If there is a disjunction of values (such as "fem|neut"), this function
# returns just a string with vertical bars as delimiters. The caller can use
# a split() function to get an array, or call get_iset_structure() instead.
#------------------------------------------------------------------------------
sub get_iset
{
    my $self = shift;
    my $feature = shift;
    my $value = $self->get_attr("iset/$feature");
    if($self->is_known_iset($feature))
    {
        if(!defined($value))
        {
            $value = '';
        }
    }
    else
    {
        warn("Querying unknown Interset feature $feature");
    }
    return $value;
}



#------------------------------------------------------------------------------
# Gets the values of all Interset features and returns a hash. Any multivalues
# (such as "fem|neut") will be converted to arrays referenced from the hash
# (same as the result of decode() functions in Interset tagset drivers).
#------------------------------------------------------------------------------
sub get_iset_structure
{
    my $self = shift;
    my %f;
    foreach my $feature (list_iset_features())
    {
        $f{$feature} = $self->get_iset($feature);
        if($f{$feature} =~ m/\|/)
        {
            my @values = split(/\|/, $f{$feature});
            $f{$feature} = \@values;
        }
    }
    return \%f;
}



#------------------------------------------------------------------------------
# Tests multiple Interset features simultaneously. Input is a list of feature-
# value pairs, return value is 1 if the node matches all these values. This
# function is an abbreviation for a series of get_iset() calls in an if
# statement:
#
# if(match_iset($node, 'pos' => 'noun', 'gender' => 'masc')) { ... }
#------------------------------------------------------------------------------
sub match_iset
{
    my $self = shift;
    my @req = @_;
    for(my $i = 0; $i<=$#req; $i += 2)
    {
        my $feature = $req[$i];
        confess("Undefined feature") unless($feature);
        my $value = $self->get_iset($feature);
        my $comp = $req[$i+1] =~ s/^\!// ? 'ne' : $req[$i+1] =~ s/^\~// ? 're' : 'eq';
        if($comp eq 'eq' && $value ne $req[$i+1] ||
           $comp eq 'ne' && $value eq $req[$i+1] ||
           $comp eq 're' && $value !~ m/$req[$i+1]/)
        {
            return 0;
        }
    }
    return 1;
}



#------------------------------------------------------------------------------
# Static method. Returns the list of known Interset features. Currently just
# an access point to a global array provided by the Interset libraries.
# However, if for some reason the Interset libraries cannot be installed
# together with Treex, the list could be simply copied here.
#------------------------------------------------------------------------------
sub list_iset_features
{
    return @tagset::common::known_features;
}



#------------------------------------------------------------------------------
# Static method. Returns the list of known values for a given Interset feature,
# or a reference to a hash of list of values for each feature, if no specific
# feature is asked for.
#------------------------------------------------------------------------------
sub list_iset_values
{
    my $self = shift;
    my $feature = shift;
    my $hash = \%tagset::common::known_values;
    if($feature)
    {
        return $hash->{$feature};
    }
    else
    {
        return $hash;
    }
}



#------------------------------------------------------------------------------
# Static method. Tells whether a string is a name of a known Interset feature.
# If there is a second argument, it checks whether it is a known value of that
# feature.
#------------------------------------------------------------------------------
sub is_known_iset
{
    my $self = shift;
    my $feature = shift;
    unless($feature)
    {
        return 0;
    }
    my $known = $self->list_iset_values();
    unless(exists($known->{$feature}))
    {
        return 0;
    }
    my @values = @{$known->{$feature}};
    foreach my $value (@_)
    {
        unless($value eq '' || grep {$_ eq $value} (@values))
        {
            return 0;
        }
    }
    return 1;
}



#------------------------------------------------------------------------------
# Static method. Sorts values of a feature "intuitively" (according to order
# defined in Interset). For example, for the number feature, singular is
# intuitively before plural, although plural goes first alphabetically. Useful
# for displaying lists of values.
#------------------------------------------------------------------------------
sub sort_iset_values
{
    my $self = shift;
    my $feature = shift;
    my @values = @_;
    ###!!! Ordering values should be precomputed and stored in a global variable!
    ###!!! Can we use a BEGIN block here?
    my $known_values = $self->list_iset_values($feature);
    my %order = ('' => 0);
    for(my $i = 0; $i<=$#{$known_values}; $i++)
    {
        $order{$known_values->[$i]} = $i+1;
    }
    return sort {$order{$a} <=> $order{$b}} (@values);
}



1;

__END__

=encoding utf-8

=head1 NAME

Treex::Core::Node::Interset

=head1 DESCRIPTION

Moose role for nodes that have the Interset feature structure.

=head1 ATTRIBUTES

=over

=item iset/*

Attributes corresponding to Interset features.

=back

=head1 METHODS

=head2 Access to Interset features

=over

=item my $boolean = $node->match_iset($node, 'pos' => 'noun', 'gender' => '!masc', ...);

Do the feature values of this node match the specification?
(Values of other features do not matter.)
A value preceded by exclamation mark is tested on string inequality.
Other values are tested on string equality.

=back


=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
