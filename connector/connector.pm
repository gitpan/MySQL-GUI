package MySQL::GUI::connector;

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

use Gtk;
use MySQL::GUI::connector::dbase;

return 1;

sub new { 
    Gtk->init;
    Gtk->set_locale;

    my $this = bless {
        'window'  => new Gtk::Window( "toplevel" ),
        'vbox'    => new Gtk::VBox( 0, 0 ),
        'hbox'    => new Gtk::HBox( 0, 0 ),

        'error'   => new Gtk::Label( "" ),

        'user'    => new Gtk::Entry,
        'pass'    => new Gtk::Entry,
        'host'    => new Gtk::Entry,
        'db'      => new Gtk::Entry,
        'connect' => new Gtk::Button( "connect" ),
        'clear'   => new Gtk::Button( "clear"   ),

        'callback' => 0,
    };

    my $temp = new MySQL::GUI::connector::dbase;

    my ($u, $p, $d, $h) = $temp->get_defaults; 

    $this->{user}->set_text( $u );
    $this->{pass}->set_text( $p );
    $this->{host}->set_text( $h );
    $this->{db}->set_text(   $d );

    undef $temp;

    $this->{vbox}->show;
    $this->{hbox}->show;
    $this->{pass}->set_visibility( 0 );
 
    foreach ( "user", "pass", "host", "db" ) {
        my $hbox  = new Gtk::HBox(0, 0);
        my $label = new Gtk::Label( $_ . ":  " );

        set_usize   $label  38, 07;

        $hbox->pack_start( $label,      (0, 0, 2) );
        $hbox->pack_start( $this->{$_}, (1, 1, 0) );

        show $hbox;
        show $label;

        $this->{$_}->show;

        $this->{vbox}->pack_start( $hbox, (0, 0, 2) );
    } {
        my $hbox  = new Gtk::HBox(0, 0);

        $this->{'error'}->set_usize(38, 07 );

        show $hbox;

        $this->{'error'}->show;
        $this->{'connect'}->show;
        $this->{'clear'}->show;

        $hbox->pack_start( $this->{'error'},   (1, 1, 2) );
        $hbox->pack_start( $this->{'clear'},   (0, 0, 0) );
        $hbox->pack_start( $this->{'connect'}, (0, 0, 0) );

        $this->{vbox}->pack_start( $hbox, (0, 0, 2) );
    }

    $this->{hbox}->pack_start( $this->{vbox},   (1, 1, 2) );

    $this->{window}->border_width(7);
    $this->{window}->add( $this->{hbox} );
    $this->{window}->set_title( "MySQL::GUI" );

    $this->{window}->signal_connect( "delete_event", \&close_app_window,     $this);
    $this->{'connect'}->signal_connect( "clicked",   \&connect_button_press, $this);
    $this->{'clear'}->signal_connect( "clicked",     \&clear_button_press,   $this);

    return $this;
}

sub close_app_window {
    my $this = "";
       $this = pop while $this !~ /connector/;

    $this->exit( 0 );
}

sub clear_button_press {
    my $this = pop;

    $this->{user}->set_text("");
    $this->{pass}->set_text("");
    $this->{host}->set_text("");
    $this->{db}->set_text("");
}

sub connect_button_press {
    my $this = pop;

    my ($user, $pass, $host, $db) = (
        $this->{user}->get_text,
        $this->{pass}->get_text,
        $this->{host}->get_text,
        $this->{db}->get_text,
    );

    croak "nobody every set a callback before the connect button was pressed" if ref($this->{callback}) ne "CODE";

    my $dbo = new MySQL::GUI::connector::dbase;

    $dbo->set_user( $user ) if $user;
    $dbo->set_pass( $pass ) if $pass;
    $dbo->set_host( $host ) if $host;
    $dbo->set_db(   $db   ) if $db;

    my $h = $dbo->handle;

    my @args = ();

    push @args, @{ $this->{callback_args} } if defined($this->{callback_args});

    if($h) {
        &print($this, "Success!" );

        push @args, $dbo;
    } else {
        &print($this, "failed to connect" );
    }

    &{ $this->{callback} }(@args);
}

sub print {
    my $this   = shift;

    $SIG{ALRM} = sub {
        $this->{error}->set_text( "" );
    };
 
    alarm 3;

    $this->{error}->set_text( shift );
}

sub set_callback {
    my $this = shift;

    $this->{callback}           = shift;
    @{ $this->{callback_args} } = @_;
}

sub show {
    my $this = shift;

    $this->{window}->show;

    Gtk->main;
}

sub exit {
    my $this = shift;

    my $eval = int(shift);

    Gtk->exit( $eval );
}

__END__

=head1 NAME

MySQL::GUI::connector
  a window for connecting to databases.

=head1 SYNOPSIS

  use strict;
  use MySQL::GUI::connector;

  my $connector = new MySQL::GUI::connector;

  $connector->set_callback( \&connected_callback );

  show $connector;

  sub connected_callback {
      my $dbo = shift;
      my $tsp = 2; # two second pause

      $connector->print("I got connected!", $tsp) if $dbo;
  }

  $connector->exit;

=head1 AUTHOR

  Jettero Heller <jettero@voltar.org>

=head1 SEE ALSO

perl(1), MySQL::GUI(3), MySQL::GUI::connector(3), MySQL::GUI::connector::dbase(3), MySQL::GUI::connection(3).

=cut
