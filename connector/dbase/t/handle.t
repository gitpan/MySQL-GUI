use Test;

plan tests => 3;

use MySQL::GUI::connector::dbase; ok 1;

$d =  new MySQL::GUI::connector::dbase;

if($d) {
    ok 1;

    $h = $d->ready("select * from something");

    ok ($h ? 1:0);
}
