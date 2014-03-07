package Treex::Service::Manager;

use Moose;
use Moose::Util::TypeConstraints;
use Treex::Core::Loader qw/load_module search_module/;
use Treex::Core::Log;
use Digest::MD5 qw(md5_hex);
use Cache::LRU;
use namespace::autoclean;

role_type 'Service', { role => 'Treex::Service::Role' };

has cache_size => (
    is  => 'ro',
    isa => 'Int',
    default => 20
);

has instances => (
    is => 'ro',
    isa => 'Cache::LRU',
    lazy => 1,
    default => sub { Cache::LRU->new(size => $_[0]->cache_size); },
    handles => {
        set_service => 'set',
        get_service => 'get',
        service_remove => 'remove'
    }
);

has modules => (
    traits  => ['Hash'],
    is => 'ro',
    isa => 'HashRef[Str]',
    lazy_build => 1,
    handles => {
        set_module => 'set',
        get_module => 'get',
        module_exists => 'exists',
    }
);

sub _build_modules {
    my $ns = 'Treex::Service::Module';
    return {
        map { (my $key = $_) =~ s/^\Q$ns\E:://; $key =~ s/::/-/; lc($key) => $_ }
          @{search_module($ns)}
      };
}

sub init_service {
    my ($self, $module, $init_args) = @_;

    use Data::Dumper;
    print STDERR Dumper($init_args);
    log_fatal "Unknown service module: '$module'" unless $self->module_exists($module);

    my $fingerprint = $self->compute_fingerprint($module, $init_args);
    my $service = $self->get_service($fingerprint);
    unless ($service) {
        my $module = $self->get_module($module);
        load_module($module);

        $service = $module->new(manager => $self,
                                fingerprint => $fingerprint,
                                name => $module);

        $service->initialize($init_args);
        $self->set_service($fingerprint, $service);
    }

    return $service;
}

sub compute_fingerprint {
    my ($self, $module, $args_ref) = @_;
    return $module.md5_hex(map {"$_=$args_ref->{$_}"} sort keys %{$args_ref});
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Treex::Service::Manager - Manage service instances called modules

=head1 SYNOPSIS

   use Treex::Service::Manager;

   my $sm = Treex::Service::Manager->new();
   $sm->get_service('addprefix', { prefix => 'aaa' });

=head1 AUTHOR

Michal Sedlak E<lt>sedlak@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Michal Sedlak

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
