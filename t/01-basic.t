#!perl

use strict;
use warnings;

use FindBin;
use Test::More;
use File::Spec;
use CSS::Minifier::XS 'minify';

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

my $served = get('/test');

ok $served, q{served data isn't blank};
my $path = File::Spec->catfile($FindBin::Bin, qw{lib TestApp root css foo.css});
open my $file, '<', $path;

my $str = q{};
while (<$file>) {
   $str .= $_;
}

is minify($str), $served, 'server actually minifed the css';

done_testing;

