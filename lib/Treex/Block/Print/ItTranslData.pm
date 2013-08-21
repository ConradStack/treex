package Treex::Block::Print::ItTranslData;

use Moose;
use Moose::Util::TypeConstraints;
use Treex::Core::Common;

use Treex::Tool::TranslationModel::Features::It;

extends 'Treex::Core::Block';

has 'data_type' => ( isa => enum([qw/pcedt czeng/]), is => 'ro', required => 1, default => 'pcedt' );

has '_feat_extractor' => (
    is => 'ro',
    isa => 'Treex::Tool::TranslationModel::Features::It',
    builder => '_build_feat_extractor',
);

sub _build_feat_extractor {
    my ($self) = @_;
    return Treex::Tool::TranslationModel::Features::It->new({
        adj_compl_path => '/home/mnovak/projects/mt_coref/model/adj.compl',
        verb_func_path => '/home/mnovak/projects/mt_coref/model/czeng0.verb.func',
    });
}

sub _get_aligned_nodes_pcedt {
    my ($self, $tnode) = @_;

    my ($t_csrefs, $t_has_enref) = $self->_csrefs_from_ensrc($tnode);
    
    return ($t_csrefs, undef) if (!defined $t_has_enref);
    return ([], undef) if ($t_has_enref);
        
    my $anode = $tnode->get_lex_anode;
    my ($a_csrefs, $a_has_enref) = $self->_csrefs_from_ensrc($anode);
    
    log_warn "NO_A_MONOALIGN: this should not happen (" . $tnode->get_address . ")\n" if (defined $a_has_enref && ($a_has_enref == 0));

    return (undef, $a_csrefs);

}

sub _csrefs_from_ensrc {
    my ($self, $ensrc) = @_;
    
    my @enrefs = grep {$_->is_aligned_to($ensrc, 'monolingual')} $ensrc->get_referencing_nodes('alignment');
    return ([], 0) if ( @enrefs == 0 );
    
    my ($aligns, $type) = $enrefs[0]->get_aligned_nodes;
    return ([], 1) if (!$aligns || !$type);
        
    my @csrefs = map {$aligns->[$_]} grep {$type->[$_] ne 'monolingual'} (0 .. @$aligns-1);
    return (\@csrefs);
}

sub _get_aligned_nodes_czeng {
    my ($self, $tnode) = @_;

    my @cs_src = grep {!$_->is_aligned_to($tnode, 'monolingual')} $tnode->get_referencing_nodes('alignment');
    return @cs_src;
}

sub get_class_pcedt {
    my ($self, $tnode) = @_;

    my $class;

    my ($aligned_t, $aligned_a) = $self->_get_aligned_nodes_pcedt($tnode);
    if ($aligned_t) {
        $class = "<" . (join ":", map {$_->t_lemma} @$aligned_t) . ">";
    } elsif ($aligned_a) {
        $class = "<alemmas=<" . (join ":", map {$_->lemma} @$aligned_a) . ">>";
    }
    return $class;
}

sub get_class_czeng {
    my ($self, $tnode) = @_;
    my @aligned = $self->_get_aligned_nodes_czeng($tnode);
    my $class = "<" . (join ":", map {$_->t_lemma} @aligned) . ">";
    return $class;
}

sub get_class {
    my ($self, $tnode) = @_;
    
    if ($self->data_type eq 'pcedt') {
        return $self->get_class_pcedt($tnode);
    } else {
        return $self->get_class_czeng($tnode);
    }
    #print STDERR "CLASS: $class; " . $tnode->get_address . "\n";
    #return $class;
}

# for a given "it" in src, returns the t-lemma of a node from cs_ref,
# which has the same functor and both are governed by mutually aligned nodes (verbs)
# can be used only on analysed PCEDT
sub _get_gold_counterpart_tlemma {
    my ($self, $ensrc_it) = @_;
    
    my $a_ensrc_it = $ensrc_it->get_lex_anode;
    my ($a_enref_it) = grep {$_->is_aligned_to($a_ensrc_it, 'monolingual')} $a_ensrc_it->get_referencing_nodes('alignment');
    return "__NO_A_ENREF__" if !$a_enref_it;
    my ($enref_it) = $a_enref_it->get_referencing_nodes('a/lex.rf');
    return "__NO_T_ENREF__" if !$enref_it;

    my ($enref_par) = grep {$_->formeme && ($_->formeme =~ /^v/)} $enref_it->get_eparents;
    return "__NO_V_ENREF_PAR__" if !$enref_par;
    my ($aligns, $type) = $enref_par->get_aligned_nodes;
    return "__NO_CSREF_PAR__" if (!$aligns || !$type);
        
    my ($csref_par) = grep {$_->formeme =~ /^v/} map {$aligns->[$_]} grep {$type->[$_] ne 'monolingual'} (0 .. @$aligns-1);
    return $self->_gold_counterpart_tlemma_via_alayer($a_enref_it, $enref_it) if !$csref_par;

    my ($csref_it) = grep {$_->functor eq $enref_it->functor} $csref_par->get_echildren;
    return "__NO_CSREF__" if !$csref_it;
    return $csref_it->t_lemma;
}

sub _gold_counterpart_tlemma_via_alayer {
    my ($self, $a_enref_it, $enref_it) = @_;

    my ($a_enref_par) = grep {defined $_->tag && ($_->tag =~ /^V/)} $a_enref_it->get_eparents;
    return "__A:NO_A_V_ENREF_PAR__" if !$a_enref_par;

    my ($aligns, $type) = $a_enref_par->get_aligned_nodes;
    return "__A:NO_A_CSREF_PAR1__" if (!$aligns || !$type);
    my ($a_csref_par) = map {$aligns->[$_]} grep {$type->[$_] ne 'monolingual'} (0 .. @$aligns-1);
    return "__A:NO_A_CSREF_PAR2__" if !$a_csref_par;
    my ($csref_par) = $a_csref_par->get_referencing_nodes('a/lex.rf');
    return "__A:NO_CSREF_PAR__" if !$csref_par;

    my ($csref_it) = grep {$_->functor eq $enref_it->functor} $csref_par->get_echildren({or_topological => 1});
    return "__A:NO_CSREF__" if !$csref_it;
    return "A:".$csref_it->t_lemma;
}

sub process_tnode {
    my ($self, $tnode) = @_;
    
    return if ($tnode->t_lemma ne "#PersPron");

    # TRANSLATION OF "IT" - can be possibly left out => translation of "#PersPron"
    my $anode = $tnode->get_lex_anode;
    return if (!$anode || ($anode->lemma ne "it"));

    my $class = $self->get_class($tnode);
    my @features = $self->_feat_extractor->get_features($tnode);
    push @features, "gcp=" . $self->_get_gold_counterpart_tlemma($tnode);

    print $class . "\t" . (join " ", @features) . "\n";
}

1;

# TODO POD
