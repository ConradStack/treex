package Treex::Block::Read::BaseReader;
use Moose;
use Treex::Moose;
use File::Spec;

has selector => ( isa => 'Selector', is => 'ro', default => '' );

has filenames => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    lazy_build    => 1,
    documentation => 'array of filenames to be loaded;'
        . ' automatically initialized from the attribute "from"',
);

has from => (
    isa           => 'Str',
    is            => 'ro',
    documentation => 'space or comma separated list of filenames to be loaded',
);

has file_stem => (
    isa           => 'Str',
    is            => 'ro',
    documentation => 'how to name the loaded documents',
);

has file_number => (
    isa           => 'Int',
    is            => 'ro',
    writer        => '_set_file_number',
    default       => 0,
    init_arg      => undef,
    documentation => 'Number of input files loaded so far.',
);

has is_one_doc_per_file => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has _file_numbers => ( is => 'rw', default => sub { {} } );

# attrs for distributed processing
has jobs => (
    is => 'rw',

    #	     isa => 'Int',
);
has modulo => (
    is => 'rw',

    #	       isa => 'Int',
);

sub _build_filenames {
    my $self = shift;
    log_fatal "Parameter 'from' must be defined!" if !defined $self->from;
    $self->set_filenames( [ split /[ ,]+/, $self->from ] );
}

sub current_filename {
    my ($self) = @_;
    return if $self->file_number == 0 || $self->file_number > @{ $self->filenames };
    return $self->filenames->[ $self->file_number - 1 ];
}

sub next_filename {
    my ($self) = @_;

    # local sequential processing
    if ( not defined $self->modulo ) {
        $self->_set_file_number( $self->file_number + 1 );
        return $self->current_filename();
    }

    # one of jobs in parallelized processing
    else {
        my $filename;
        while (1) {
            $self->_set_file_number( $self->file_number + 1 );
            my $filename = $self->current_filename();
            if ( $self->file_number % $self->jobs == $self->modulo ) {
                return $filename;
            }
        }
    }
}

sub new_document {
    my ( $self, $load_from ) = @_;
    my $path = $self->current_filename();
    log_fatal "next_filename() must be called before new_document()" if !defined $path;
    my ( $volume, $dirs, $file ) = File::Spec->splitpath($path);
    my ( $stem, $extension ) = $file =~ /([^.]+)(\..+)?/;
    my %args = ( file_stem => $stem, loaded_from => $path );
    if ( defined $dirs ) {
        $args{path} = $volume . $dirs;
    }

    if ( $self->file_stem ) {
        $args{file_stem} = $self->file_stem;
    }

    if ( $self->is_one_doc_per_file && !$self->file_stem ) {
        $args{file_number} = '';
    }
    else {
        my $num = $self->_file_numbers->{$stem};
        $self->_file_numbers->{$stem} = ++$num;
        $args{file_number} = sprintf "%03d", $num;
    }

    if ( defined $load_from ) {
        $args{filename} = $load_from;
    }

    return Treex::Core::Document->new( \%args );
}

sub number_of_documents {
    my $self = shift;
    return $self->is_one_doc_per_file ? scalar @{ $self->filenames } : '?';
}

1;
