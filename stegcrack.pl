#!/usr/bin/env perl
# Programa feito por Andre Marques
# Desc: Cracker de esteganografia que utiliza paralelismo para
# acelerar o processo de cracking.

use strict; use warnings;
use Getopt::ArgParse;
#use DateTime;

my $ap = Getopt::ArgParse->new_parser(
    prog => 'Stegcracker',
    description => 'Cracker de esteganografia que utiliza paralelismo para acelerar o processo de cracking.'
);

$ap->add_arg('--wordlist', '-w', help=>'Arquivo com tentativas de senha', required=>1);
$ap->add_arg('--cores', '-c', help=> 'Numero de processos para paralelizar', required=>0, default=>1);
$ap->add_arg('--file', '-f', help=> 'Arquivo a ser aplicado o brute-force', required=>1);

my $args = $ap->parse_args( @ARGV );

my @children_pids;
my @wordlist_descriptors = [];
#my $start_time = DateTime->now();

sub clean_temp
{
    my $r = system("rm .tmp* > /dev/null 2>&1");
    return $r
}

$SIG{INT} = sub {
    foreach ( @children_pids ) {
        kill('KILL', $_);
    }
    clean_temp;
    die "Caught a sigint $!" ;
};

$SIG{TERM} = sub {
    foreach ( @children_pids ) {
        kill('KILL', $_);
    }
    clean_temp;
    die "Caught a sigterm $!" ;
};

sub open_fd
{
    open(my $fp, '>', $_[0]);
    return $fp;
}

sub split_list
{
    # Wordlist must exist.
    if ( ! -f $args->wordlist ) {
        print "[!] Error: Wordlist not found.\n";
        exit 1;
    }

    #Only split if use more than one core.
    if ($args->cores < 2) {
        return 0;
    }

    print "[+] Dividindo wordlist em ", $args->cores . " fragmentos ...\n";
    open(my $fp, '<', $args->wordlist) or die $!;
    my $i = 0;
    while ( $i < $args->cores ) {
        push @wordlist_descriptors, open_fd(".tmp$i");
        $i++;
    }

    $i = 0;
    while ( my $line = <$fp> ) {
        my $chosen_fd = ($i % $args->cores) + 1;
        my $chosen_fp = $wordlist_descriptors[$chosen_fd];
        chomp $line;
        print {$chosen_fp} $line . "\n";
        $i++;
    }
    return 0;
}

sub crack_func
{
    my $file = $_[0];
    my $try = $_[1];
    my $return = system "steghide extract -sf '" . $file . "' -p '" . $try . "' > /dev/null 2>&1";
    return $return;
}

sub crack
{
    if (not defined $_[0]) {
        print "crack: no params passed\n";
        return -1;
    }

    my $wl = $args->wordlist;
    if ( $args->cores > 1 ) {
        $wl = ".tmp" . $_[0];
    }
    print "[+] Usando lista: $wl\n";
    open(my $tmpfd, '<', $wl) or die $!;
    while ( my $line = <$tmpfd> ) {
        chomp $line;
        my $i = crack_func($args->file, $line);
        if ( $i == 0 ) {
            print "Password cracked: ", $line . "\n";
            exit 0;
        }
    }
    close($tmpfd);
    exit 0;
}


sub main
{

    print "[+] Usando ", $args->cores . " processos\n";
    split_list;

    my $x = 0;
    while ( $x < $args->cores ) {
        my $pid = fork();
        die if not defined $pid;
        if (not $pid) {
            crack $x;
        } else {
            push @children_pids, $pid;
        }

        $x++;
    }

    wait();
    #my $end_time = DateTime-now();
    #my $elapsed = $end_time - $start_time;
    #print "Time elapsed: " . $elapsed->in_units("minutes") . "m\n";
    print "[+] Stego crack has been finished.\n";
    clean_temp;
    foreach ( @children_pids ) {
        kill('KILL', $_);
    }
    return 0;
}


main;
