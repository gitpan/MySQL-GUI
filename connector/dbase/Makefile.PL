# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'MySQL::GUI::connector::dbase',
    'VERSION_FROM'  => '../../GUI.pm',
    'PREREQ_PM'     => {DBI => 0, DBD::mysql => 0},
);
