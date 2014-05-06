package Slic3r::Layer;

use List::Util qw(first);
use Slic3r::Geometry qw(scale chained_path);
use Slic3r::Geometry::Clipper qw(union_ex);

# the following two were previously generated by Moo
sub print {
    my $self = shift;
    return $self->object->print;
}

sub config {
    my $self = shift;
    return $self->object->config;
}

# the purpose of this method is to be overridden for ::Support layers
sub islands {
    my $self = shift;
    return $self->slices;
}

sub region {
    my $self = shift;
    my ($region_id) = @_;
    
    while ($self->region_count <= $region_id) {
        $self->add_region($self->object->print->get_region($self->region_count));
    }
    
    return $self->get_region($region_id);
}

sub regions {
    my ($self) = @_;
    return [ map $self->get_region($_), 0..($self->region_count-1) ];
}

# merge all regions' slices to get islands
sub make_slices {
    my $self = shift;
    
    my $slices = union_ex([ map $_->p, map @{$_->slices}, @{$self->regions} ]);
    
    # sort slices
    $slices = [ @$slices[@{chained_path([ map $_->contour->first_point, @$slices ])}] ];
    
    $self->slices->clear;
    $self->slices->append(@$slices);
}

sub make_perimeters {
    my $self = shift;
    Slic3r::debugf "Making perimeters for layer %d\n", $self->id;
    $_->make_perimeters for @{$self->regions};
}

package Slic3r::Layer::Support;

sub islands {
    my $self = shift;
    return [ @{$self->slices}, @{$self->support_islands} ];
}

1;
