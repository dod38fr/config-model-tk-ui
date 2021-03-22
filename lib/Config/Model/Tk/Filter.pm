package Config::Model::Tk::Filter;

use 5.10.1;
use strict;
use warnings;
use Carp;
use Log::Log4perl 1.11;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/apply_filter/;

my $logger = Log::Log4perl::get_logger('Tk::Filter');

sub _get_filter_action {
    my ($elt, $elt_filter, $filtered_state, $unfiltered_state) = @_;

    my $action = 'show';
    if (length($elt_filter) > 2) {
        if ($elt =~ /$elt_filter/) {
            $action = $filtered_state ;
        }
        else {
            $action = $unfiltered_state;
        }
    }
    return $action;
}

# scan a tree and return a hash where each found path is the key and the
# value is either hide, show or an empty string.
sub apply_filter {
    my (%args) = @_;

    # fd_path: force display path. The show action must be set in the
    # call back so that the 'show' action can be propagated from the
    # shown leaf up to the root of the tree.

    my $elt_filter = $args{elt_filter_value} // carp "missing elt_filter_value" ;
    my $show_only_custom = $args{show_only_custom} // carp "missing show_only_custom" ;
    my $hide_empty_values = $args{hide_empty_values} // carp "missing hide_empty_values" ;
    my $instance = $args{instance} // carp "missing instance" ;
    my $fd_path = $args{fd_path} // carp "missing fd_path" ;

    # 'show' trumps 'hide' which trumps ''
    my %combine_hash = (
        show => { show => 'show', hide => 'show', '' => 'show'},
        hide => { show => 'show', hide => 'hide', '' => 'hide'},
        ''   => { show => 'show', hide => 'hide', '' => ''    },
    );

    my $leaf_cb = sub {
        my ($scanner, $data_ref, $node,$element_name,$index, $leaf_object) = @_ ;
        my $loc = $leaf_object->location;
        my $action = '';
        if ( $show_only_custom ) {
            $action = $leaf_object->has_data ? 'show' : 'hide';
        }
        if ( $hide_empty_values ) {
            my $v = $leaf_object->fetch(qw/ check no/);
            $action = (defined $v and length($v)) ? 'show' : 'hide';
        }
        $action = 'show' if $loc eq $fd_path;
        $data_ref->{return} = $data_ref->{actions}{$loc} = $action ;
    };

    my $check_list_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,undef, $obj) = @_;
        my $loc = $obj->location;
        my $action = '';
        if ( $hide_empty_values ) {
             $action = 'hide' unless $obj->fetch(mode => 'user');
        }
        $action = 'show' if $loc eq $fd_path;
        $data_ref->{return} = $data_ref->{actions}{$loc} = $action ;
    };

    my $hash_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
        my $obj = $node->fetch_element($element_name);
        my $loc = $obj->location;

        # resume exploration
        my $hash_action = $hide_empty_values ? 'hide' : '';
        foreach my $key (@keys) {
            my $inner_ref = { actions => $data_ref->{actions} };
            $scanner->scan_hash($inner_ref, $node, $element_name, $key);
            $hash_action = $combine_hash{$hash_action}{$inner_ref->{return}};
        }
        $hash_action = 'show' if $loc eq $fd_path;
        $data_ref->{return} = $data_ref->{actions}{$loc} = $hash_action;
    };

    my $node_cb = sub {
        my ($scanner, $data_ref,$node, @element_list) = @_ ;
        my $node_loc = $node->location;

        my $node_action = $hide_empty_values ? 'hide' : '';
        foreach my $elt ( @element_list ) {
            my $filter_action = '';
            if (length($elt_filter) > 2) {
                if ($elt =~ /$elt_filter/) {
                    $filter_action = 'show' ;
                }
                else {
                    $filter_action = 'hide';
                }
            }
            my $obj = $node->fetch_element($elt);
            my $loc = $obj->location;
            # make sure that the hash ref stays attached to $data_ref
            $data_ref->{actions} //= {};
            my $inner_ref = { actions => $data_ref->{actions} };
            $scanner->scan_element($inner_ref, $node,$elt);
            my $action = $combine_hash{$filter_action}{$inner_ref->{return}};
            $data_ref->{actions}{$loc} = $action;
            $node_action = $combine_hash{$node_action}{$action};
        }

        $node_action = 'show' if $node_loc eq $fd_path;

        $data_ref->{return} = $data_ref->{actions}{$node_loc} = $node_action;
    };

    my $scan = Config::Model::ObjTreeScanner-> new (
        leaf_cb => $leaf_cb,
        hash_element_cb => $hash_cb,
        list_element_cb => $hash_cb,
        node_content_cb => $node_cb,
    ) ;

    my %force_display_path = ();
    $scan->scan_node(\%force_display_path, $instance->config_root) ;

    return $force_display_path{actions};
}

1;

