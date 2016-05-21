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

 perl -MFile::Which::Patch::Hide=-prog,'foo;bar' ...

=cut
