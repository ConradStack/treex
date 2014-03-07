package Treex::Tool::Parser::Service;

use Moose;
use namespace::autoclean;
extends 'Treex::Core::Service';
with 'Treex::Tool::Parser::Role';

has '+module' => ( default => 'parser' );

sub parse_sentence {
    return shift->run(@_);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Treex::Tool::Parser::Service - Perl extension for blah blah blah

=head1 SYNOPSIS

   use Treex::Tool::Parser::Service;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for Treex::Tool::Parser::Service,

Blah blah blah.

=head1 AUTHOR

Michal Sedlak E<lt>sedlak@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Michal Sedlak

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut