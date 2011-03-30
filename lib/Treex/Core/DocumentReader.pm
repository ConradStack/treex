package Treex::Core::DocumentReader;
use Moose::Role;

# attrs for distributed processing
# TODO: check jobs >= jobindex > 0
has jobs => (
    is            => 'rw',
    isa           => 'Int',
    documentation => 'number of jobs for parallel processing',
);

has jobindex => (
    is            => 'rw',
    isa           => 'Int',
    documentation => 'ordinal number of the current job in parallel processing',
);

# TODO: this should not be needed in future
has outdir => (
    is  => 'rw',
    isa => 'Str',
);

has doc_number => (
    isa           => 'Int',
    is            => 'ro',
    writer        => '_set_doc_number',
    default       => 0,
    init_arg      => undef,
    documentation => 'Number of documents loaded so far, i.e.'
        . ' the ordinal number of the current (most recently loaded) document.',
);

# Is the document that was most recently returned by $self->next_document()
# supossed to be processed by this job?
# Job indices and document numbers are 1-based, so e.g. for
# jobs = 5, jobindex = 3 we want to load documents with numbers 3,8,13,18,...
# jobs = 5, jobindex = 5 we want to load documents with numbers 5,10,15,20,...
# i.e. those documents where (doc_number-1) % jobs == (jobindex-1).
sub is_current_document_for_this_job {
    my ($self) = @_;
    return 1 if !$self->jobindex;
    return ( $self->doc_number - 1 ) % $self->jobs == ( $self->jobindex - 1 );
}

# Returns a next document which should be processed by this job.
# If jobindex is set, returns "modulo number of jobs".
sub next_document_for_this_job {
    my ($self) = @_;
    my $doc = $self->next_document();
    while ( $doc && !$self->is_current_document_for_this_job ) {
        $doc = $self->next_document();
    }

    # TODO this is not very elegant
    # and it is also wrong, because if next_document issues some warnings,
    # these are printed into a wrong file.
    # However, I don't know how to get the correct doc_number before executing next_document.
    # Regarding  perlcritic ProtectPrivateSubs:
    # I consider _redirect_output as internal for Treex::Core modules.
    if ( $doc && $self->jobindex ) {
        Treex::Core::Run::_redirect_output( $self->outdir, $self->doc_number, $self->jobindex ); ## no critic (ProtectPrivateSubs)
    }

    return $doc;
}

requires 'next_document';

# total number of documents that will be produced
# If the number is unknown, undef is returned.
requires 'number_of_documents';

sub number_of_documents_per_this_job {
    my ($self) = @_;
    my $total = $self->number_of_documents() or return;
    return $total if !$self->jobs;
    my $rest = $total % $self->jobs;
    my $div  = ( $total - $rest ) / $self->jobs;
    return $div + ( $rest >= $self->jobindex ? 1 : 0 );
}

sub restart {
    my ($self) = @_;
    $self->_set_doc_number(0);
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Core::DocumentReader - interface for all document readers

=head1 DESCRIPTION

Document readers are a Treex concept how to load documents to be processed by Treex.
The documents can be stored in files (in various formats) or read from STDIN
or retrieved from a socket etc.

=head1 SEE

L<Treex::Block::Read::Sentences>
L<Treex::Block::Read::Text>
L<Treex::Block::Read::Treex>


=head1 AUTHOR

Martin Popel <popel@ufal.mff.suni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by UFAL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

