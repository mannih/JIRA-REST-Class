package JIRA::REST::Class::Factory;
use base qw( Class::Factory::Enhanced );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A factory class for building all the other classes in L<JIRA::REST::Class>.

=head1 DESCRIPTION

This module imports a hash of object type package names from L<JIRA::REST::Class::FactoryTypes>.

=cut

# we import the list of every class this factory knows how to make
#
use JIRA::REST::Class::FactoryTypes qw( %TYPES );
JIRA::REST::Class::Factory->add_factory_type( %TYPES );

use Carp;
use DateTime::Format::Strptime;

=internal_method B<init>

Initialize the factory object.  Just copies all the elements in the hashref that were passed in to the object itself.

=cut

sub init {
    my $self = shift;
    my $args = shift;
    my @keys = keys %$args;
    @{$self}{@keys} = @{$args}{@keys};
    return $self;
}

=internal_method B<get_factory_class>

Inherited method from L<Class::Factory|Class::Factory/Factory_Methods>.

=internal_method B<make_object>

A tweaked version of C<make_object_for_type> from L<Class::Factory::Enhanced|Class::Factory::Enhanced/make_object_for_type> that calls C<init()> with a copy of the factory.

=cut

sub make_object {
    my ( $self, $object_type, @args ) = @_;
    my $class = $self->get_factory_class( $object_type );
    my $obj   = $class->new( @args );
    $obj->init( $self );    # make sure we pass the factory into init()
    return $obj;
}

=internal_method B<make_date>

Make it easy to get L<DateTime> objects from the factory. Parses JIRA date
strings, which are in a format that can be parsed by the
L<DateTime::Format::Strptime> pattern C<%FT%T.%N%z>

=cut

sub make_date {
    my ( $self, $date ) = @_;
    return unless $date;
    my $pattern = '%FT%T.%N%z';
    state $parser = DateTime::Format::Strptime->new( pattern => $pattern );
    return (
        $parser->parse_datetime( $date )
            or
            confess qq{Unable to parse date "$date" using pattern "$pattern"}
    );
}

=internal_method B<factory_error>

Throws errors from the factory with stack traces

=cut

sub factory_error {
    my $class = shift;
    my $err   = shift;

    # start the stacktrace where we called make_object()
    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
    Carp::confess "$err\n", @_;
}

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
