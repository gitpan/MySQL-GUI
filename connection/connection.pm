package MySQL::GUI::connection;

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

return 1;

sub new {
    Gtk->init;
    Gtk->set_locale;

    my $this = shift;
    my $dbo  = shift;

    croak "bad database object!" if not $dbo;  my $h = $dbo->ready("show tables");
    croak "bad database object!" if not $h;       $h->execute;

    my $row = $h->fetchrow_hashref;
    my @key = keys %$row;

    $this = bless {
        'dbo'     => $dbo,

        'window'  => new Gtk::Window( "toplevel" ),
        'vbox'    => new Gtk::VBox( 0, 0 ),
        'hbox'    => new Gtk::HBox( 0, 0 ),
        'hber'    => new Gtk::HBox( 0, 0 ),
        'combo'   => new Gtk::Combo,
        'clist'   =>     Gtk::CList->new_with_titles(@key),
        'scroll'  => new Gtk::ScrolledWindow(undef, undef),
        'submit'  => new Gtk::Button( "submit" ),
        'error'   => new Gtk::Label( "" ),

        'callback' => 0,
    }, $this;

    my @val = values %$row;

    $this->{clist}->append( @val );
    $this->{clist}->append( @val ) while(@val = $h->fetchrow_array);

    $this->{scroll}->set_policy( "automatic", "always" );
    $this->{scroll}->add( $this->{clist} );

    $this->{hbox}->pack_start( $this->{combo},  (1, 1, 2) );
    $this->{hbox}->pack_start( $this->{submit}, (0, 0, 2) );

    $this->{vbox}->pack_start( $this->{scroll}, (1, 1, 2) );
    $this->{vbox}->pack_start( $this->{error},  (0, 0, 2) );
    $this->{vbox}->pack_start( $this->{hbox},   (0, 0, 2) );

    $this->{clist}->show;
    $this->{vbox}->show;
    $this->{scroll}->show;

    $this->{error}->show;
    $this->{submit}->show;
    $this->{combo}->show;
    $this->{hbox}->show;

    @{ $this->{combo}->{list} } = &read_history_file;
    @{ $this->{combo}->{list} } = () if not ref($this->{combo}->{list}) eq "ARRAY";

    $this->{combo}->set_popdown_strings( @{ $this->{combo}->{list} } );

    $this->{window}->border_width( 7 );
    $this->{window}->add( $this->{vbox} );
    $this->{window}->set_usize( 750, 300 );

    #$this->{window}->signal_connect( "delete_event", \&close_app_window,    $this);
    $this->{submit}->signal_connect( "clicked",      \&submit_button_press, $this);

    return $this;
}

sub freeze { my $this = shift; $this->{clist}->freeze; }
sub thaw   { my $this = shift; $this->{clist}->thaw;   }

sub ready {
    my $this = shift;

    return $this->{dbo}->ready(@_);
}

sub set_field_names {
    my $this = shift;

    $this->{scroll}->remove( $this->{clist} );  # do we have to do this?
    undef $this->{clist};  # this should work but doesn't... it's Gtk bug.

    $this->{clist} = Gtk::CList->new_with_titles(@_),
    $this->{clist}->show;

    $this->{scroll}->add( $this->{clist} );
}

sub set_field_widths {
    my $this = shift;

    $this->{clist}->set_column_width( $_, $_[$_] ) for(0..$#_);
}

sub populate_table_row {
    my $this = shift;

    $this->{clist}->append( @_ );
}

sub set_callback {
    my $this = shift;

    $this->{callback}      = shift;
    @{ $this->{callback_args} } = @_;
}

sub read_history_file {
    my @ret;

    open IN, "$ENV{HOME}/.mysqlgui_history" or return @ret;
    while(<IN>) {
        chomp;
        push @ret, $_;
    }
    close IN;

    return @ret;
}

sub write_history_file {
    my $this = shift;

    open OUT, ">$ENV{HOME}/.mysqlgui_history" or return;
    foreach( $this->get_queries ) {
        print OUT "$_\n";
    }
    close OUT;
}

sub exit {
    my $this = shift;
    my $eval = shift;

    Gtk->exit( $eval );
}

sub close_app_window {
    my $this = "";
       $this = pop while defined($this) and $this !~ /connection/;

    $this->write_history_file;

    $this->exit( 0 );
}

sub submit_button_press {
    my $this = "";
       $this = pop while $this !~ /connection/;

    my $dbqt = $this->{combo}->entry->get_text;

    croak "nobody every set a callback before the connect button was pressed" if ref($this->{callback}) ne "CODE";

    my @args = ();

    push @args, @{ $this->{callback_args} } if defined($this->{callback_args});
    push @args, $dbqt;

    &{ $this->{callback} }(@args);
}

sub get_queries {
    my $this = shift; 

    return @{ $this->{combo}->{list} };
}

sub clear_query {
    my $this = shift;

    $this->{combo}->entry->set_text( "" );
}

sub store_query {
    my $this       = shift;
    my $no_prevent = shift;
    my $prevent    =     0;

    my $dbqt = $this->{combo}->entry->get_text;

    unless($no_prevent) {
        my @list = @{ $this->{combo}->{list} };
        if(@list) {
            for(0..$#list) {
                if($dbqt eq $list[$_]) {
                    @{ $this->{combo}->{list} } = (@list[0..($_-1)], @list[($_+1)..$#list]);
                    last;
                }
            }
        }
    }

    unshift @{ $this->{combo}->{list} }, $dbqt;

    $this->{combo}->set_popdown_strings( @{ $this->{combo}->{list} } );
}

sub print {
    my $this   = shift;
    my $msg    = shift;
    my $pause  = shift;

    $msg =~ s/[\r\n]+/ /g;

    if (defined($pause) and $pause > 0) {
        $SIG{ALRM} = sub {
            $this->{error}->set_text( "" );
        };
     
        alarm $pause;
    }

    $this->{error}->set_text( $msg );
}

sub show {
    my $this = shift;

    $this->{window}->show;

    Gtk->main;
}

__END__

=head1 NAME

MySQL::GUI::connection
  a window for interacting with the database.

=head1 SYNOPSIS

  use strict;
  use MySQL::GUI::connector;
  use MySQL::GUI::connection;

  my $connector = new MySQL::GUI::connector;
  my $c;

  $connector->set_callback( \&connected_callback );

  show $connector;

  sub connected_callback {
      my $dbo = shift;

      if($dbo) {
          $connector->print("I got connected!", 2);
          $c = new MySQL::GUI::connection($dbo);
      }
  }

  sub submit_callback {
      my $dbqt = shift; # passed in by the callback
      # short for database query text

      if($dbqt =~ /^(select|show|desc)/i) {
          my $q  = $c->ready($dbqt); $q->execute or return;
          my $hr = $q->fetchrow_hashref;

          return if not $hr;

          $c->set_field_names( keys %$hr );
          $c->freeze;  # puts the CList on hold 
                       # so it doesn't blink during the updates.

          my @row; 
          my $max_rows = 50;
          {
              foreach(@row) {
                  $_ = defined($_) ? $_ : "NULL";
                  s/^\s*//;
                  s/\s*$//;
              }
              $c->populate_table_row( values %$hr );
              $max_rows--;

              last if not $max_rows;
              redo if $hr = $q->fetchrow_hashref;
          }
          $c->thaw;  
          $c->set_field_widths( (map 10*length($_), (keys %$hr)) );

          $c->store_query;
          $c->clear_query;

          my $paren="";
          if(not $max_rows) {
              $paren = " (truncated to $ROW_LIM rows)";
          }

          $c->print("found " . $q->rows . " rows$paren... " . (time - $t) , 10);
      } else {
          $c->print("unsupported query type", 4);
      }
  }

=head1 AUTHOR

  Jettero Heller <jettero@voltar.org>

=head1 SEE ALSO

perl(1), MySQL::GUI(3), MySQL::GUI::connector(3), MySQL::GUI::connector::dbase(3), MySQL::GUI::connection(3).

=cut
