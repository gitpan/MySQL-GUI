package MySQL::GUI::connector::dbase;

require 5.005_62;
use strict;
use warnings;
use Carp qw/croak/;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw( );

use DBI;

return 1;

sub new { 
    my $this = shift;
    my $hr   = shift;

    $this = bless {
        trace => 0,
        user  => 0,
        pass  => 0,
        db    => 0,
        host  => 0,
        dbh   => 0,
        port  => 3306,
    }, $this;

    read_my_cnf $this;

    foreach my $k (keys %$hr) {
        $this->{$k} = $hr->{$k};
    }

    return $this;
}

sub get_defaults {
    my $this = shift;

    return (
        $this->{user},
        $this->{pass},
        $this->{db},
        $this->{host},
    );
}

sub trace { 
    my $this       = shift;
    $this->{trace} = shift;

    $this->{dbh}->trace( $this->{trace} ) if defined($this->{dbh});
}

sub disconnect {
    my $this = shift;
    die "not connected" if not $this->{dbh};

    $this->{dbh}->disconnect;
}

sub set_db   { my $this = shift; $this->{db}   = shift; }
sub set_host { my $this = shift; $this->{host} = shift; } 
sub set_port { my $this = shift; $this->{port} = shift; } 
sub set_user { my $this = shift; $this->{user} = shift; } 
sub set_pass { my $this = shift; $this->{pass} = shift; } 

sub handle {
    my $this = shift;

    if(not $this->{dbh}) {
        $this->{dbh} = DBI->connect("DBI:mysql:". 
           "database=$this->{db};host=$this->{host};port=$this->{port}",
            $this->{user}, $this->{pass} 
        );
        $this->{dbh}->trace( $this->{trace} ) if $this->{dbh};
    }

    return $this->{dbh};
}

sub ready {
    my $this = shift;
    my $dbh  = $this->handle;

    return ($this->{dbh} ? $this->{dbh}->prepare(@_) : undef);
}

sub read_my_cnf {
    my $this = shift;

    open PASS, "$ENV{HOME}/.my.cnf" or die "$!";

    while(<PASS>) {
        $this->{pass} = $1 if /password\s*=\s*(\S+)/;
        $this->{host} = $1 if /host\s*=\s*(\S+)/;
        $this->{user} = $1 if /user\s*=\s*(\S+)/;
        $this->{db}   = $1 if /database\s*=\s*(\S+)/;

        last if( $this->{user} and $this->{pass} and $this->{host} and $this->{db} );
    }

    close PASS;
}

__END__

=head1 NAME

MySQL::GUI::connector::dbase - Perl extension 
  to make the db stuff a little less painless.

=head1 SYNOPSIS

  use strict;
  use MySQL::GUI::connector::dbase;

  # to do db transactions
  my $dbo = new MySQL::GUI::connector::dbase;
  my $dbh = $dbo->handle;
  my $sth = $dbh->prepare("select * from something");
  my $STH = $dbo->ready("select * from something"); # shortcut. ;)

  # the dbase.pm uses the .my.cnf to be able to connect pretty like that...
  # you can override it.  After the $dbo is connected this will
  # not do anything!  Note that there is no connect function.

  $dbo->disconnect;

  $dbo->set_db(   "cool_db"   );
  $dbo->set_host( "localhost" );
  $dbo->set_user( "jettero"   );
  $dbo->set_pass( "S3crET"    );

  my $sth =
      $dbo->ready("select * from cool_table");  # this connects automajikcally;
                                            # so does the $dbo->handle function.

  $dbo->trace( 1 ); # will do what you expect before/after connect,
                    # and will persist even after a $dbo->disconnect.


  # to read a .my.cnf
  my $temp = new MySQL::GUI::connector::dbase;
  my ($u, $p, $d, $h) = $temp->get_defaults;
  undef $temp;

=head1 AUTHOR

  Jettero Heller <jettero@voltar.org>

=head1 SEE ALSO

perl(1), MySQL::GUI(3), MySQL::GUI::connector(3), MySQL::GUI::connector::dbase(3), MySQL::GUI::connection(3).

=cut
