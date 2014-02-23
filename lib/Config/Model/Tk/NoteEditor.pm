package Config::Model::Tk::NoteEditor ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl ;

use base qw/Tk::Frame/;
use vars qw/$icon_path/ ;
use subs qw/menu_struct/ ;
use Tk::Dialog ;
use Tk::Photo ;
use Tk::Balloon ;
use Tk; # Needed to import Ev function

Construct Tk::Widget 'ConfigModelNoteEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x    / ;
my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

# This widget is to be integrated directly in a ConfigModel editor widget

sub Populate { 
    my ($cw, $args) = @_;
    my $obj = delete $args->{-object} 
      || croak "NoteEditor: no -object option, got ",
	join(',', keys %$args);

    my $label = 'Edit Note' ;
    my $status = $label;
    my $note_w ;

    my $save_cb = sub { $obj->annotation($note_w-> Contents ) ; $status = $label ;} ;
    my $del_cb  = sub {
        # FIXME: remove hack once C::M 2.049 is out
        $obj->can('clear_annotation') ? $obj->clear_annotation : $obj->{annotation} = '';
        $note_w -> Contents('');
        $status = $label ;
    } ;
    my $updated_cb =  sub {
        my $k = Ev('k') ;
	$status = $label.'*' ;
    };

    my $ed_frame = $cw->Frame->pack();
    my $ctrl_frame = $ed_frame->Frame->pack(-side => 'left') ;
    $ctrl_frame->Label(  -textvariable => \$status )->pack( ) ;
    $ctrl_frame->Button( -text => 'save note', -command => $save_cb )->pack(-fill => 'x') ;
    $ctrl_frame->Button( -text => 'del note',  -command => $del_cb  )->pack(-fill => 'x') ;

    $note_w = $ed_frame->Scrolled (
        'Text',
        -height => 5 ,
        -scrollbars => 'ow',
    ) ->pack(@fbe1, -anchor => 's', -side => 'bottom');

    my $balloon = $ed_frame->Balloon(-state => 'balloon') ;
    $balloon->attach($note_w, -msg => 'You may enter a comment here');


    # read annotation and set up a callback to save user's entry at
    # every return
    $note_w -> Contents($obj->annotation);
    $note_w -> bind ('<KeyPress>', $updated_cb);
    $note_w->bind('<Button-2>', $updated_cb) ;
}

1;
