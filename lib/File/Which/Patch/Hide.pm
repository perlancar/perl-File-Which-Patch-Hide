package File::Which::Patch::Hide;

# DATE
# VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our %config;

my $w_which = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my @prog = split /\s*[;,]\s*/, $config{-prog};

    my $wa = wantarray;
    my @res;
    if ($wa) {
        @res = $orig->(@_);
    } else {
        my $res = $orig->(@_);
        push @res, $res if defined $res;
    }

    my @filtered_res;
    for my $path (@res) {
        my ($vol, $dir, $file) = File::Spec->splitpath($path);
        next if grep { $file eq $_ } @prog;
        push @filtered_res, $path;
    }

    if ($wa) {
        return @filtered_res;
    } else {
        if (@filtered_res) {
            return $filtered_res[0];
        } else {
            return undef;
        }
    }
};

sub patch_data {
    return {
        v => 3,
        config => {
            -prog => {
                summary => 'A string containing semicolon-separated list '.
                    'of program names to hide',
                schema => 'str*',
            },
        },
        patches => [
            {
                action => 'wrap',
                sub_name => 'which',
                code => $w_which,
            },
        ],
    };
}

1;
# ABSTRACT: Hide some programs from File::Which

=head1 SYNOPSIS

 % PERL5OPT=-MFile::Which::Patch::Hide=-prog,'foo;bar' app.pl

C<app.pl> will think that C<foo> and C<bar> are not in C<PATH> even though they
actually are.


=head1 DESCRIPTION

This module can be used to simulate the absence of certain programs. This module
works by patching (wrapping) L<File::Which>'s C<which()> routine to remove the
result if the programs that want to be hidden are listed in the result. So only
programs that use C<which()> will be fooled.

An example of how I use this module: L<Nodejs::Util> has a routine
C<get_nodejs_path()> which uses C<File::Which::which()> to check for the
existence of node.js binary. The C<get_nodejs_path()> routine is used in some of
my test scripts to optionally run tests when node.js is available. So to
simulate a condition where node.js is not available:

 % PERL5OPT=-MFile::Which::Patch::Hide=-prog,'node;nodejs' prove ...


=head1 append:SEE ALSO

To simulate tha absence of some perl modules, you can try: L<lib::filter>,
L<lib::disallow>.

=cut
