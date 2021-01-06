package Config::Model::Tk::CmeDialog;

use strict;
use warnings;
use Carp;
use Log::Log4perl;
use base qw(Tk::DialogBox);

Construct Tk::Widget 'CmeDialog';

sub Populate {
    my($cw, $args) = @_;

    my $msg_arg = delete $args->{-text};
    my $msg = ref $msg_arg eq 'ARRAY' ? join( "\n", @$msg_arg )
        : $msg_arg;

    $cw->SUPER::Populate($args);

    my $tw = $cw->add('Scrolled', 'ROText')->pack;
    $tw->insert('end', $msg );
}

1;
