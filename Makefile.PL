# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'MySQL::GUI',
    'VERSION_FROM' => 'GUI.pm',
    'PREREQ_PM'    => { Gtk => 0, 'Date::Lima' => 0 },
);
