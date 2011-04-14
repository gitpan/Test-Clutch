package Test::Clutch;

use warnings;
use strict;

=head1 NAME

Test::Clutch - add a clutch to your testing drivechain

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

   use Test::Clutch;

   # suspend test output
   Test::Clutch::disengage;

   # enable test output again
   Test::Clutch::engage;

   # is the clutch engaged?
   Test::Clutch::engaged ? 'yes' : 'no';
   Test::Clutch::disengaged ? 'no' : 'yes';


=head1 DESCRIPTION

There are many cases where you have a procedure that you might sometimes want
to run in a test-like fashion, and other times just run.  Rather than having
two subroutines, one that emits tests and one that doesn't, doesn't it make
more sense to install a clutch?

C<Test::Clutch> installs a clutch in L<Test::Builder>.  Since C<Test::Builder>
is the base class for a great many test modules, and since it's singleton-ish,
you have a single pedal (most of the time) for engaging and disengaging test
output.

=cut

use Class::MOP;
use Class::MOP::Class;
use Test::Builder;

my $meta = Class::MOP::Class->initialize('Test::Builder');


=head1 L<Test::Builder> augmentations

C<Test::Clutch> adds an attribute named C<disengaged> to L<Test::Builder>,
as well as C<disengage> and C<engage> methods.

The C<disengaged> attribute actually cannot be initialised, since the
singleton Test::Builder is not created via the MOP; but it is still handy
to create its accessor via the MOP.  This is also the reason the attribute
is called C<disengaged> rather than C<engaged>, the "default" is necessarily
undefined, test output must remain enabled by default.

   $Test->disengaged(1);  # suspend test output
   $Test->disengaged(0);  # enable test output

   $Test->disengage;  # suspend test output
   $Test->engage;     # enable test output

=cut

$meta->add_attribute('failed_while_disengaged' => (
		accessor => 'failed_while_disengaged'
));
$meta->add_attribute('disengaged' => (accessor => 'disengaged'));
$meta->add_method('disengage', sub { shift->disengaged(1) });
$meta->add_method('engage', sub { shift->disengaged(undef) });


# simple methods that return 1 on success
foreach (qw/plan done_testing/) {
	$meta->add_around_method_modifier($_, sub {
		my $orig = shift;
		my $self = shift;

		return 1 if $self->disengaged;
		return $self->$orig(@_);
	});
}

# simple methods that return 0 on success
foreach (qw/_print_comment/) {
	$meta->add_around_method_modifier($_, sub {
		my $orig = shift;
		my $self = shift;

		return 0 if $self->disengaged;
		return $self->$orig(@_);
	});
}


=head2   ok

The original ok method is only invoked if the clutch in engaged, but the
C<is_passing> attribute is still set according the first argument.

=cut
$meta->add_around_method_modifier('ok', sub {
	my $orig = shift;
	my $self = shift;

	if ($self->disengaged) {
		$self->failed_while_disengaged(1) unless $_[0] || $self->in_todo;
		return $_[0] ? 1 : 0;
	}
	# the MOP modifier adds three stack frames
	local $Test::Builder::Level = $Test::Builder::Level + 3;
	return $self->$orig(@_);
});


=head2   child

The child Builder's clutch must be disengaged if the parent (that is, the
invocant) is disengaged; this wrapper takes care of that.

=cut

$meta->add_around_method_modifier('child', sub {
	my $orig = shift;
	my $self = shift;
	# the MOP modifier adds three stack frames
	local $Test::Builder::Level = $Test::Builder::Level + 3;
	my $child = $self->$orig(@_);
	$child->disengaged($self->disengaged);
	return $child;
});


=head2   is_passing

If the clutch is currently engaged, simply defers to the original method.
If the clutch is disengaged, the test is considered to be passing only if
the original method returns true, and we have also not failed any tests
and any point while the clutch was disengaged.

=cut

$meta->add_around_method_modifier('is_passing', sub {
	my $orig = shift;
	my $self = shift;
	if ($self->disengaged) {
		return $self->$orig(@_) && !$self->failed_while_disengaged;
	}
	else {
		return $self->$orig(@_);
	}
});


=head1 SUBROUTINES

=head2   engaged

Return true if the clutch is currently engaged, otherwise false.

=cut

sub engaged { !Test::Builder->new->disengaged }


=head2   disengaged

Return true if the clutch is currently disengaged, otherwise false.

=cut

sub disengaged { Test::Builder->new->disengaged }


=head2   disengage

Disable test output.

=cut

sub disengage { Test::Builder->new->disengage }


=head2   engage

Enable test output.

=cut

sub engage { Test::Builder->new->engage }


=head1 AUTHOR

Fraser Tweedale, C<< <frasert at jumbolotteries.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-test-clutch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Clutch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Clutch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Clutch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Clutch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Clutch>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Clutch/>

=back


=head1 SEE ALSO

L<Test::Builder> provides the test features that can be enabled/disabled
courtesy of this module.

L<Class::MOP> is the amazing meta-object protocol that makes all of this
possible.


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Benon Technologies Pty Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Clutch
