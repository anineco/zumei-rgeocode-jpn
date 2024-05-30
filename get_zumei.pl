#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open ':utf8';
use open ':std';
use URI;
use Web::Scraper;
use LWP::UserAgent;

# FIXED:
# SSL connect attempt failed error:0A000152:SSL routines::unsafe legacy renegotiation disabled

my $ua = LWP::UserAgent->new(
  ssl_opts => {
    verify_hostname => 0,
    SSL_create_ctx_callback => sub {
      my $ctx = shift;
      # 0x00040000 SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION
      Net::SSLeay::CTX_set_options($ctx, 0x40000);
      Net::SSLeay::CTX_set_security_level($ctx, 1);
    },
  }
);

my $items = scraper {
  process 'table tbody', 'items[]' => scraper {
    process 'tr:nth-child(1)', 'tr1' => scraper {
      process 'td:nth-child(1)', 'id' => 'TEXT';
      process 'td:nth-child(2)', 'name' => 'TEXT';
#     process 'td:nth-child(3)', 'td1' => 'TEXT';
      process 'td:nth-child(4)', 'td2' => 'TEXT';
#     process 'td:nth-child(5)', 'td3' => 'TEXT';
      process 'td:nth-child(6)', 'td4' => 'TEXT';
    };
    process 'tr:nth-child(2)', 'tr2' => scraper {
#     process 'td:nth-child(1)', 'td1' => 'TEXT';
      process 'td:nth-child(2)', 'td2' => 'TEXT';
#     process 'td:nth-child(3)', 'td3' => 'TEXT';
      process 'td:nth-child(4)', 'td4' => 'TEXT';
    };
    process 'tr:nth-child(3)', 'tr3' => scraper {
#     process 'td:nth-child(1)', 'td1' => 'TEXT';
      process 'td:nth-child(2)', 'td2' => 'TEXT';
#     process 'td:nth-child(3)', 'td3' => 'TEXT';
      process 'td:nth-child(4)', 'td4' => 'TEXT';
    };
    process 'tr:nth-child(4)', 'tr4' => scraper {
#     process 'td:nth-child(1)', 'td1' => 'TEXT';
      process 'td:nth-child(2)', 'td2' => 'TEXT';
#     process 'td:nth-child(3)', 'td3' => 'TEXT';
      process 'td:nth-child(4)', 'td4' => 'TEXT';
    };
  };
};
$items->user_agent($ua);

sub output_csv {
  my ($out, $url, $type) = @_;
  my $res = $items->scrape(URI->new($url));
  for my $item (@{$res->{items}}) {
    my @data = (
      $item->{tr1}->{id}, $item->{tr1}->{name},
      $item->{tr2}->{td2}, $item->{tr1}->{td2},
      $item->{tr4}->{td2}, $item->{tr3}->{td2},
      $item->{tr2}->{td4}, $item->{tr1}->{td4},
      $item->{tr4}->{td4}, $item->{tr3}->{td4}
    );
    print $out $type, ',"', join('","', @data), '"', "\n";
  }
}

# 1/20万地勢図
my $out;
open($out, '>', 'map200000.csv');
output_csv($out, 'https://www.gsi.go.jp/MAP/NEWOLDBL/200000/200000.html', 1);
close($out);

my $areas = scraper {
  process 'map area', 'areas[]' => { 'href' => '@href' };
};
$areas->user_agent($ua);

my %map50000 = ();
my %map25000 = ();

my $res = $areas->scrape(URI->new('https://www.gsi.go.jp/MAP/NEWOLDBL/25000-50000/index25000-50000.html'));
for my $area (@{$res->{areas}}) {
  next unless ($area->{href} =~ m%^https://www.gsi.go.jp/MAP/NEWOLDBL/25000-50000/% || $area->{href} =~ m%^https://www.gsi.go.jp/gyoumu/gyoumu40005.html%);
  my $r = $areas->scrape(URI->new($area->{href}));
  for my $a (@{$r->{areas}}) {
    my $h = $a->{href};
    $h =~ s/#.*$//;
    if ($h =~ m%^https://www.gsi.go.jp/MAP/NEWOLDBL/25000-50000/50000/% || $h =~ m%^https://www.gsi.go.jp/gyoumu/gyoumu40007.html%) {
      $map50000{$h} = 1;
    }
    if ($h =~ m%^https://www.gsi.go.jp/MAP/NEWOLDBL/25000-50000/25000/% || $h =~ m%^https://www.gsi.go.jp/gyoumu/gyoumu40006.html%) {
      $map25000{$h} = 1;
    }
  }
}

# 1/5万地形図
open($out, '>', 'map50000.csv');
for my $url (keys %map50000) {
  output_csv($out, $url, 2);
}
close($out);

# 1/2.5万地形図
open($out, '>', 'map25000.csv');
for my $url (keys %map25000) {
  output_csv($out, $url, 3);
}
close($out);

__END__
