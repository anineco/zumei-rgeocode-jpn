#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open ':utf8';
use open ':std';
use Text::CSV_XS;
# use Data::Dumper;

sub dms2deg {
  my $dms = shift;
  if ($dms =~ /^[[:space:]]*$/) {
    return 0;
  }
  my @d = split(/[[:space:]]+/, $dms);
  return $#d == 2 ? sprintf("%.6f", $d[0] + $d[1] / 60 + $d[2] / 3600) : 0;
}

my $csv = Text::CSV_XS->new({ binary => 1 });

open(my $in, '-');
my $mapno = '?';
while (my $row = $csv->getline($in)) {
  my $type = 0 + $row->[0];
  if ($row->[1] !~ /^[[:space:]]*$/) {
    $mapno = $row->[1];
  }
  my $name = $row->[2];
  my @pos = map { dms2deg($_) } @{$row}[3..10];
  my $comment = '';
  if (grep { $_ == 0 } @pos) {
    $comment = '-- ';
  }
  print $comment, q/SET @area='{"type":"Polygon","coordinates":[[/,
    '[', $pos[0], ',', $pos[1], '],',
    '[', $pos[2], ',', $pos[3], '],',
    '[', $pos[6], ',', $pos[7], '],',
    '[', $pos[4], ',', $pos[5], '],',
    '[', $pos[0], ',', $pos[1], q/]]]}';/, "\n";
  print $comment, q/INSERT INTO `zumei` VALUES (/, $type, ',"', $mapno, '","', $name,
    q/",ST_GeomFromGeoJSON(@area,1));/, "\n";
}
close($in);
__END__
