package Type::Tiny::Union;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Union::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Union::VERSION   = '0.007_05';
}

use Scalar::Util qw< blessed >;
use Types::TypeTiny ();

sub _croak ($;@) { require Type::Exception; goto \&Type::Exception::croak }

use overload q[@{}] => 'type_constraints';

use base "Type::Tiny";

sub new {
	my $proto = shift;
	my %opts = @_;
	_croak "Union type constraints cannot have a parent constraint" if exists $opts{parent};
	_croak "Need to supply list of type constraints" unless exists $opts{type_constraints};
	$opts{type_constraints} = [
		map { $_->isa(__PACKAGE__) ? @$_ : $_ }
		map Types::TypeTiny::to_TypeTiny($_),
		@{ ref $opts{type_constraints} eq "ARRAY" ? $opts{type_constraints} : [$opts{type_constraints}] }
	];
	my $self = $proto->SUPER::new(%opts);
	$self->coercion if grep $_->has_coercion, @$self;
	return $self;
}

sub type_constraints { $_[0]{type_constraints} }
sub constraint       { $_[0]{constraint} ||= $_[0]->_build_constraint }

sub _build_display_name
{
	my $self = shift;
	join q[|], @$self;
}

sub _build_coercion
{
	require Type::Coercion::Union;
	my $self = shift;
	return "Type::Coercion::Union"->new(type_constraint => $self);
}

sub _build_constraint
{
	my @tcs = @{+shift};
	return sub
	{
		my $val = $_;
		$_->check($val) && return !!1 for @tcs;
		return;
	}
}

sub can_be_inlined
{
	my $self = shift;
	not grep !$_->can_be_inlined, @$self;
}

sub inline_check
{
	my $self = shift;
	sprintf '(%s)', join " or ", map $_->inline_check($_[0]), @$self;
}

sub _instantiate_moose_type
{
	my $self = shift;
	my %opts = @_;
	delete $opts{parent};
	delete $opts{constraint};
	delete $opts{inlined};
	
	my @tc = map $_->moose_type, @{$self->type_constraints};
	
	require Moose::Meta::TypeConstraint::Union;
	return "Moose::Meta::TypeConstraint::Union"->new(%opts, type_constraints => \@tc);
}

sub has_parent
{
	defined(shift->parent);
}

sub parent
{
	$_[0]{parent} ||= $_[0]->_build_parent;
}

sub _build_parent
{
	my $self = shift;
	my ($first, @rest) = @$self;
	
	for my $parent ($first, $first->parents)
	{
		return $parent unless grep !$_->is_a_type_of($parent), @rest;
	}
	
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Union - union type constraints

=head1 DESCRIPTION

Union type constraints.

This package inherits from L<Type::Tiny>; see that for most documentation.
Major differences are listed below:

=head2 Attributes

=over

=item C<type_constraints>

Arrayref of type constraints.

When passed to the constructor, if any of the type constraints in the union
is itself a union type constraint, this is "exploded" into the new union.

=item C<constraint>

Unlike Type::Tiny, you should generally I<not> pass a constraint to the
constructor. Instead rely on the default.

=item C<inlined>

Unlike Type::Tiny, you should generally I<not> pass an inlining coderef to
the constructor. Instead rely on the default.

=item C<coercion>

Will typically be a L<Type::Coercion::Union>.

=back

=head2 Overloading

=over

=item *

Arrayrefification calls C<type_constraints>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

