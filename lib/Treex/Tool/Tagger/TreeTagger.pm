package Treex::Tool::Tagger::TreeTagger;
use Moose;
use Treex::Core::Common;
use Treex::Core::Config;
use Treex::Tool::ProcessUtils;

has model => ( isa => 'Str', is => 'rw', required => 1 );
has [qw( _reader _writer _pid )] => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    #to be changed
    use Treex::Core::Resource;
    Treex::Core::Resource::require_file_from_share(
        'installed_tools/tagger/tree_tagger/bin/tree-tagger',
        ref($self)
    );
    my $bindir = Treex::Core::Config::share_dir() . '/installed_tools/tagger/tree_tagger/bin';
    log_fatal("Missing $bindir\n") if !-d $bindir;

    my $command = "$bindir/tree-tagger -token -lemma -no-unknown " . $self->model . ' 2>/dev/null';

    # start TreeTagger and load the model
    my ( $reader, $writer, $pid ) = Treex::Tool::ProcessUtils::bipipe( $command, ":encoding(utf-8)" );
    $self->_set_reader($reader);
    $self->_set_writer($writer);
    $self->_set_pid($pid);

    # writes to the input three technical tokens as a sentence separator
    print $writer ".\n.\n.\n";

    return;
}

sub analyze {
    my $self = shift;
    my $toks = shift;
    return [] if scalar @$toks == 0;

    my $ttwr = $self->_writer;
    my $ttrd = $self->_reader;

    # tokens to force end of sentence
    my $cnt = 0;

    # input tokens
    foreach my $tok (@$toks) {
        print $ttwr $tok . "\n";
        $cnt++;
    }

    # input sentence separator
    print $ttwr ".\n.\n.\n";

    my @tags   = ();
    my @lemmas = ();

    # skip sentence separator
    for ( my $i = 0; $i < 3; $i++ ) {
        my $got = <$ttrd>;
    }

    # read output
    while ( $cnt > 0 ) {
        my $got = <$ttrd>;
        chomp $got;
        my @items = split( /\t/, $got );
        $cnt--;
        push @tags,   $items[1];
        push @lemmas, $items[2];
    }

    my @output = ( \@tags, \@lemmas );
    return \@output;
}

sub DEMOLISH {
    my ($self) = @_;
    close( $self->_writer );
    close( $self->_reader );
    Treex::Tool::ProcessUtils::safewaitpid( $self->_pid );
    return;
}

1;

__END__


=head1 NAME

Treex::Tool::Tagger::TreeTagger

TreeTagger. Reads list of tokens and returns list of tags
and list of lemmas.

=head1 SYNOPSIS

  my $tagger = Treex::Tool::Tagger::TreeTagger->new();
  my ($tags, $lemmas) = @{ $tagger->analyze(["How","are","you","?"]) };
  print join(" ", @$tags);
  print join(" ", @$lemmas);

=cut

Copyright 2009-2011 David Marecek, Martin Popel
This file is distributed under the GNU GPL v2 or later. See $TMT_ROOT/README
