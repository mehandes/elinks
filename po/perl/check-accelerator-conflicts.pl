#! /usr/bin/perl
# The copyright notice and license are in the POD at the bottom.

use strict;
use warnings;
use Locale::PO qw();
use Getopt::Long qw(GetOptions :config bundling gnu_compat);
use autouse 'Pod::Usage' => qw(pod2usage);

my $VERSION = "1.1";

sub show_version
{
    print "check-accelerator-conflicts.pl $VERSION\n";
    pod2usage({-verbose => 99, -sections => "COPYRIGHT AND LICENSE",
	       -exitval => 0});
}

my $Accelerator_tag;

sub check_po_file ($)
{
    my($po_file_name) = @_;
    my %contexts;
    my $warnings = 0;
    my $pos = Locale::PO->load_file_asarray($po_file_name)
	or warn "$po_file_name: $!\n", return 2;
    foreach my $po (@$pos) {
	next if $po->fuzzy();
	my $msgstr = $po->msgstr()
	    or next;
	my($accelerator) = ($msgstr =~ /\Q$Accelerator_tag\E(.)/s)
	    or next;
	$accelerator = uc($accelerator);
	my $automatic = $po->automatic()
	    or next;
	my($contexts) = ($automatic =~ /^accelerator_context\(([^\)]*)\)/)
	    or next;
	foreach my $context (split(/\s*,\s*/, $contexts)) {
	    my $prev = $contexts{$context}{$accelerator};
	    if (defined($prev)) {
		warn "$po_file_name: Accelerator conflict for \"$accelerator\" in \"$context\":\n";
		warn "$po_file_name:  1st msgid " . $prev->msgid() . "\n";
		warn "$po_file_name:  1st msgstr " . $prev->msgstr() . "\n";
		warn "$po_file_name:  2nd msgid " . $po->msgid() . "\n";
		warn "$po_file_name:  2nd msgstr " . $po->msgstr() . "\n";
		$warnings++;
	    } else {
		$contexts{$context}{$accelerator} = $po;
	    }
	}
    }
    return $warnings ? 1 : 0;
}

GetOptions("accelerator-tag=s" => sub {
	       my($option, $value) = @_;
	       die "Cannot use multiple --accelerator-tag options\n"
		   if defined($Accelerator_tag);
	       die "--accelerator-tag requires a single-character argument\n"
		   if length($value) != 1;
	       $Accelerator_tag = $value;
	   },
	   "help" => sub { pod2usage({-verbose => 1, -exitval => 0}) },
	   "version" => \&show_version)
    or exit 2;
$Accelerator_tag = "~" unless defined $Accelerator_tag;
print(STDERR "$0: missing file operand\n"), exit 2 unless @ARGV;

my $max_error = 0;
foreach my $po_file_name (@ARGV) {
    my $error = check_po_file($po_file_name);
    $max_error = $error if $error > $max_error;
}
exit $max_error;

__END__

=head1 NAME

check-accelerator-conflicts.pl - Scan a PO file for conflicting
accelerator keys.

=head1 SYNOPSIS

B<check-accelerator-conflicts.pl> [I<option> ...] F<I<language>.po> [...]

=head1 DESCRIPTION

B<check-accelerator-conflicts.pl> is part of a framework that detects
conflicting accelerator keys in Gettext PO files.  A conflict is when
two items in the same menu or two buttons in the same dialog box use
the same accelerator key.

The PO file format does not normally include any information on which
strings will be used in the same menu or dialog box.
B<check-accelerator-conflicts.pl> can only be used on PO files to which
this information has been added with B<gather-accelerator-contexts.pl>
or merged with B<msgmerge>.

B<check-accelerator-conflicts.pl> reads the F<I<language>.po> file
named on the command line and reports any conflicts to standard error.

B<check-accelerator-conflicts.pl> does not access the source files to
which F<I<language>.po> refers.  Thus, it does not matter if the line
numbers in "#:" lines are out of date.

=head1 OPTIONS

=over

=item B<--accelerator-tag=>I<character>

Specify the character that marks accelerators in C<msgstr> strings.
Whenever this character occurs in a C<msgstr>,
B<check-accelerator-conflicts.pl> treats the next character as an
accelerator and checks that it is unique in each of the contexts in
which the C<msgstr> is used.

Omitting the B<--accelerator-tag> option implies
B<--accelerator-tag="~">.  The option must be given to each program
separately because there is no standard way to save this information
in the PO file.

=back

=head1 ARGUMENTS

=over

=item F<I<language>.po> [...]

The PO files to be scanned for conflicts.  These files must include the
"accelerator_context" comments added by B<gather-accelerator-contexts.pl>.
If the special comments are missing, no conflicts will be found.

=back

=head1 EXIT CODE

0 if no conflicts were found.

1 if some conflicts were found.

2 if the command line is invalid or a file cannot be read.

=head1 BUGS

B<check-accelerator-conflicts.pl> reports the same conflict multiple
times if it occurs in multiple contexts.

Jonas Fonseca suggested the script could propose accelerators that are
still available.  This has not been implemented.

=head2 Waiting for Locale::PO fixes

The warning messages should include line numbers, so that users of
Emacs could conveniently edit the conflicting part of the PO file.
This is not feasible with the current version of Locale::PO.

When B<check-accelerator-conflicts.pl> includes C<msgstr> strings in
warnings, it should transcode them from the charset of the PO file to
the one specified by the user's locale.

=head1 AUTHOR

Kalle Olavi Niemitalo <kon@iki.fi>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2006 Kalle Olavi Niemitalo.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  In addition:

=over

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE COPYRIGHT HOLDER(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=back

=head1 SEE ALSO

L<gather-accelerator-contexts.pl>, C<xgettext(1)>, C<msgmerge(1)>