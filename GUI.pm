package MySQL::GUI;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw( );
our $VERSION     = "0.32";

use Date::Lima qw/beek_date/;

use MySQL::GUI::connector;
use MySQL::GUI::connection;

my $ROW_LIM = 50000;

return 1;

sub new {
    my $class= shift;
    my $this = bless {}, $class;

    $this->{connector} = new MySQL::GUI::connector;
    $this->{connector}->set_callback( \&set_connection, $this );

    return $this;
}

sub go {
    my $this = shift;

    $this->{connector}->show;
}

sub default_behaviour { 
    my $this = shift;
    my $c    = shift;
    my $dbqt = shift;
    my $h;

    return if not defined($dbqt) or not length($dbqt);

    $this->catch_warnings($c);

    if($dbqt =~ /^(select|show|desc)/i) {
        my $q     = $c->ready($dbqt); $q->execute or return;
        my @names = $this->get_names_from_statement_handle( $q );

        return if not $names[0];

        my @cws;
        foreach (@names) {
            $_ = defined($_) ? $_ : "NULL";
            s/^\s*//;
            s/\s*$//;
            push @cws, length($_);
        }

        $c->set_field_names( @names );
        $c->freeze;
        $c->print("wait...", 2);

        my $t = time;

        my @row; 
        my $max_rows = $ROW_LIM;
        while(@row = $q->fetchrow_array) {
            foreach(@row) {
                $_ = defined($_) ? $_ : "NULL";
                s/^\s*//;
                s/\s*$//;
            }
            $c->populate_table_row( @row );
            $cws[$_] = ($cws[$_] > length($row[$_]) ? $cws[$_] : length($row[$_])) for(0..$#cws);
            $max_rows--;

            last if not $max_rows;
        }
        $c->thaw;
        $c->set_field_widths(map 10*$_, @cws);

        $c->store_query;
        $c->clear_query;

        my $paren="";
        if(not $max_rows) {
            $paren = " (truncated to $ROW_LIM rows)";
        }

        $c->print("found " . $q->rows . " rows$paren... " . beek_date(time - $t), 10);
    } else {
        $c->print("unsupported query type", 4);
    }
}


sub set_connection {
    my $this = shift;
    my $dbo  = shift;

    return if not $dbo;

    #$dbo->trace(1);

    my $con = new MySQL::GUI::connection($dbo);

    $con->set_callback( \&default_behaviour, $this, $con );
    $con->show;

    push @{ $this->{connections} }, $con;
}

sub catch_warnings {
    my $this = shift;
    my $con  = shift;

    $SIG{__WARN__} = sub { 
        my $arg = shift;

        if( $arg =~ m/execute failed:/) {
            $arg =~ s/DBD::.+failed:\s*//;
            $arg =~ s/\s+at \S+ line \d+//;

            $con->print($arg);
        } else {
            print STDERR "$arg\n";
        }
    };
}

sub get_names_from_statement_handle {
    my $this = shift;
    my $sth  = shift;
    my $arf  = $sth->FETCH('NAME');

    return (ref($arf) eq "ARRAY" ? @$arf : undef );
}

sub exit {
    my $this = shift;
    my $eval = shift;

    foreach ( @{ $this->{connections} } ) {
        $_->exit($eval);
    }

    $this->{connector}->exit( $eval) if defined($this->{connector} );
}

__END__

=head1 NAME

MySQL::GUI
    makes windows for connecting to and interacting with databases.

=head1 SYNOPSIS

  use MySQL::GUI;

  my $gui = new MySQL::GUI;

  $gui->go;

=head1 AUTHOR

Jettero Heller jettero@cpan.org

http://www.voltar.org

=head1 SEE ALSO

perl(1), MySQL::GUI(3), MySQL::GUI::connector(3), MySQL::GUI::connector::dbase(3), MySQL::GUI::connection(3).

=cut
