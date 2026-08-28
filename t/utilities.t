# test utilities

use ExtUtils::testlib;
use Test::More ;
use Tk;
use Config::Model::Tk::HashEditor;

use strict;
use warnings;

# force import symbols
*escape_keys = *Config::Model::Tk::HashEditor::escape_keys;
*restore_keys = *Config::Model::Tk::HashEditor::restore_keys;

subtest "Hash editor escape keys" => sub {
    is(escape_keys("foo"),"foo", "no change");
    is(escape_keys("\n"),'\n', 'LF => \n');
    is(escape_keys("\\n"),'\\\n', '\n => \\\n');
};

subtest "Hash editor restore keys" => sub {
    is(restore_keys("foo"),"foo", "no change");
    is(restore_keys('\n'  ),"\n" , '\n => LF');
    is(restore_keys('\\\n'),"\\n", '\\\n => \n');

};

subtest "Hash editor escape and restore keys round trip" => sub {
    foreach my $t ("foo", '\n', "\n","\\n\n\\n\n",'\\\\n','\\n[\\-\\*]', '^\\s*\\n' ) {
        my $label = $t =~ s/\n/LF/gr;
        is(restore_keys(escape_keys($t)),$t, "round trip $label");
    }
};

done_testing;
