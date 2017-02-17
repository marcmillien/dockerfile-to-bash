#!/usr/bin/env perl
use warnings;
use strict;

my @dockerfile;
my $position = -1;
my $instructions = {
  COPY => \&COPY,
  ENV => \&ENV,
  FROM => \&FROM,
  RUN => \&RUN,
  MAINTAINER => \&MAINTAINER,
};

sub RUN($) {
  my ($cmd) = @_;
  open(RUN, "|".$cmd) || die "RUN failed: $!\n";
}

sub ENV($) {
  my ($cmd) = @_;
  my @env = split(/ /, $cmd);
  $ENV{$env[0]} = $env[1];
}

sub FROM($) {
  my ($base) = @_;
  print "This should be based on: ".$base."\n";
}

sub MAINTAINER($) {
  my ($author) = @_;
  print "This is maintained by: ".$author."\n";
}

sub COPY($) {
  my ($src, $dest) = @_;
}

sub line_analyzer($) {
  my ($line) = @_;
  return if $line =~ /^\s*#/;

  $line =~ s/^\s*//g;
  my @table_string = split(/ /, $line);
  my $cmd = $table_string[0];

  return if not defined($cmd);
  if (defined($instructions->{$cmd})) {
    my $args = join(' ', @table_string[1 .. scalar(@table_string) - 1]);
    $position++;
    my $configuration = {
      'command' => $cmd,
      'arguments' => $args,
    };
    $dockerfile[$position] = $configuration;
  } else {
    $dockerfile[$position]->{'arguments'} .= join(' ', @table_string);
  }
}

sub execute {
  foreach my $docker_instruction (@dockerfile) {
    my $cmd = $docker_instruction->{'command'};
    my $args = $docker_instruction->{'arguments'};
    chomp($args);
    &{$instructions->{$cmd}}($args);
  }
}


open(FH, '<', 'Dockerfile') || die $!;
while(my $line = readline(FH)) {
  &line_analyzer($line);
}
close(FH);
execute();
