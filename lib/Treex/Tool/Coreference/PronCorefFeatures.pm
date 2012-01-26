package Treex::Tool::Coreference::PronCorefFeatures;

use Moose;
use Treex::Core::Common;

with 'Treex::Tool::Coreference::CorefFeatures';

my $b_true = '1';
my $b_false = '-1';

my %actants = map { $_ => 1 } qw/ACT PAT ADDR APP/;

sub _build_feature_names {
    my ($self) = @_;
    return log_fatal "method _build_feature_names must be overriden in " . ref($self);
}

sub _binary_features {
    my ($self, $set_features, $anaph, $cand, $candord) = @_;

    my $coref_features = {};

###########################
    #   Distance:
    #   4x num: sentence distance, clause distance, file deepord distance, candidate's order
    $coref_features->{c_sent_dist} =
        $anaph->get_bundle->get_position - $cand->get_bundle->get_position;
    $coref_features->{c_clause_dist} = _categorize(
        $anaph->wild->{aca_clausenum} - $cand->wild->{aca_clausenum}, 
        [-2, -1, 0, 1, 2, 3, 7]
    );
    $coref_features->{c_file_deepord_dist} = _categorize(
        $anaph->wild->{doc_ord} - $cand->wild->{doc_ord},
        [1, 2, 3, 6, 15, 25, 40, 50]
    );
    $coref_features->{c_cand_ord} = _categorize(
        $candord,
        [1, 2, 3, 5, 8, 11, 17, 22]
    );
    #$coref_features->{c_cand_ord} = $candord;

    #   24: 8 x tag($inode, $jnode), joined
    
    $coref_features->{c_join_apos}  
        = $self->_join_feats($set_features->{c_cand_apos}, $set_features->{c_anaph_apos});
    $coref_features->{c_join_anum}  
        = $self->_join_feats($set_features->{c_cand_anum}, $set_features->{c_anaph_anum});

###########################
    #   Functional:
    #   3:  functor($inode, $jnode);
    $coref_features->{b_fun_agree} 
        = $self->_agree_feats($set_features->{c_cand_fun}, $set_features->{c_anaph_fun});
    $coref_features->{c_join_fun}  
        = $self->_join_feats($set_features->{c_cand_fun}, $set_features->{c_anaph_fun});
    
    #   3: afun($inode, $jnode);
    $coref_features->{b_afun_agree} 
        = $self->_agree_feats($set_features->{c_cand_afun}, $set_features->{c_anaph_afun});
    $coref_features->{c_join_afun}  
        = $self->_join_feats($set_features->{c_cand_afun}, $set_features->{c_anaph_afun});
    
    #   3: aktant($inode, $jnode);
    $coref_features->{b_akt_agree} 
        = $self->_agree_feats($set_features->{b_cand_akt}, $set_features->{b_anaph_akt});
    
    #   3:  subject($inode, $jnode);
    $coref_features->{b_subj_agree} 
        = $self->_agree_feats($set_features->{b_cand_subj}, $set_features->{b_anaph_subj});
    
    #   Context:
    $coref_features->{b_app_in_coord} = _is_app_in_coord( $cand, $anaph );
    
    #   4: get candidate and anaphor eparent functor and sempos
    #   2: agreement in eparent functor and sempos
	#my ($anaph_epar_lemma, $cand_epar_lemma) = map {my $epar = ($_->get_eparents)[0]; $epar->t_lemma} ($anaph, $cand);
    $coref_features->{b_epar_fun_agree}
        = $self->_agree_feats($set_features->{c_cand_epar_fun}, $set_features->{c_anaph_epar_fun});
    $coref_features->{c_join_epar_fun}          
        = $self->_join_feats($set_features->{c_cand_epar_fun}, $set_features->{c_anaph_epar_fun});
    $coref_features->{b_epar_sempos_agree}      
        = $self->_agree_feats($set_features->{c_cand_epar_sempos}, $set_features->{c_anaph_epar_sempos});
    $coref_features->{c_join_epar_sempos}       
        = $self->_join_feats($set_features->{c_cand_epar_sempos}, $set_features->{c_anaph_epar_sempos});
    $coref_features->{b_epar_lemma_agree}       
        #= $self->_agree_feats($cand_epar_lemma, $anaph_epar_lemma);
        = $self->_agree_feats($set_features->{c_cand_epar_lemma}, $set_features->{c_anaph_epar_lemma});
    $coref_features->{c_join_epar_lemma}        
        #= $self->_join_feats($cand_epar_lemma, $anaph_epar_lemma);
        = $self->_join_feats($set_features->{c_cand_epar_lemma}, $set_features->{c_anaph_epar_lemma});
    $coref_features->{c_join_clemma_aeparlemma} 
        #= $self->_join_feats($cand->t_lemma, $anaph_epar_lemma);
        = $self->_join_feats($cand->t_lemma, $set_features->{c_anaph_epar_lemma});
    
    #   3:  tfa($inode, $jnode);
    $coref_features->{b_tfa_agree} 
        = $self->_agree_feats($set_features->{c_cand_tfa}, $set_features->{c_anaph_tfa});
    $coref_features->{c_join_tfa}  
        = $self->_join_feats($set_features->{c_cand_tfa}, $set_features->{c_anaph_tfa});
    
    #   1: are_siblings($inode, $jnode)
    $coref_features->{b_sibl} = _are_siblings( $cand, $anaph );

    return $coref_features;
}

sub _unary_features {
    my ($self, $node, $type) = @_;

    my $coref_features = {};

    return if (($type ne 'cand') && ($type ne 'anaph'));

    #   1: anaphor's ID
    $coref_features->{$type.'_id'} = $node->id;

    if ($type eq 'anaph') {
        $coref_features->{c_anaph_sentord} = _categorize(
            $node->get_root->wild->{czeng_sentord},
            [0, 1, 2, 3]
        );
    }

###########################
    #   Functional:
    #   3:  functor($inode, $jnode);
    $coref_features->{'c_'.$type.'_fun'}  = $node->functor;
    
    #   3: afun($inode, $jnode);
    $coref_features->{'c_'.$type.'_afun'}  = _get_afun($node);
    
    #   3: aktant($inode, $jnode);
    $coref_features->{'b_'.$type.'_akt'}  = $actants{ $node->functor  } ? $b_true : $b_false;
    
    #   3:  subject($inode, $jnode);
    $coref_features->{'b_'.$type.'_subj'}  = _is_subject($node);
    
    #   Context:
    if ($type eq 'cand') {
        $coref_features->{b_cand_coord} = ( $node->is_member ) ? $b_true : $b_false;
    }
    
    #   4: get candidate and anaphor eparent functor and sempos
    #   2: agreement in eparent functor and sempos
    ( $coref_features->{'c_'.$type.'_epar_fun'},  $coref_features->{'c_'.$type.'_epar_sempos'} )  = _get_eparent_features($node);
	my $eparent = ($node->get_eparents)[0];
	$coref_features->{'c_'.$type.'_epar_lemma'} = $eparent->t_lemma;
    
    #   3:  tfa($inode, $jnode);
    $coref_features->{'c_'.$type.'_tfa'}  = $node->tfa;
    
    return $coref_features;
}

# returns if $inode and $jnode have the same eparent
sub _are_siblings {
	my ($inode, $jnode) = @_;
	my $ipar = ($inode->get_eparents)[0];
	my $jpar = ($jnode->get_eparents)[0];
	return ($ipar == $jpar) ? $b_true : $b_false;
}

# returns the first eparent's functor, sempos and lemma
sub _get_eparent_features {
	my ($node) = @_;
	my $epar_fun;
	my $epar_sempos;
	my $epar_lemma;
	my $epar = ($node->get_eparents)[0];
	if ($epar) {
		$epar_fun = $epar->functor;
		$epar_sempos = $epar->gram_sempos;
		$epar_lemma = $epar->t_lemma;
	}
	return ($epar_fun, $epar_sempos, $epar_lemma);
}

# returns whether an anaphor is APP and is in the same clause with a
# candidate and they have a common (grand)parent CONJ|DISJ
sub _is_app_in_coord {
	my ($cand, $anaph) = @_;
	if ($anaph->functor eq 'APP' && 
        ($anaph->wild->{aca_clausenum} eq $cand->wild->{aca_clausenum})) {
		
        my $par = $anaph->parent;
		while ($par && ($par != $cand) && !$par->is_root && 
            (!$par->gram_tense || $par->gram_tense !~ /^(sim|ant|post)/) && 
            (!$par->functor || $par->functor !~ /^(PRED|DENOM)$/)) {

            if ($par->functor =~ /^(CONJ|DISJ)$/) {
				return (grep {$_ eq $cand} $par->descendants) ? $b_true : $b_false;
			}
			$par = $par->parent;
		}
	}
	return $b_false;
}

# returns $b_true if the parameter is subject; otherwise $b_false
sub _is_subject {
	my ($node) = @_;
	my $par = ($node->get_eparents)[0];
    return $b_false if (!defined $par || $par->is_root);
	
    if ($par->gram_tense && ($par->gram_tense =~ /^(sim|ant|post)/) || 
        ($par->functor eq 'DENOM')) {
		
        my @cands = $par->get_echildren;
 		my @sb_ids;
		foreach my $child (@cands) {
			if (defined $child->gram_sempos && ($child->gram_sempos =~ /^n/)) {
                my $achild = $child->get_lex_anode;
                if (defined $achild && ($achild->afun eq 'Sb')) {
					push @sb_ids, $child->id;
				}
			}
		}

        if ((@sb_ids == 0) && ($node->functor eq 'ACT')) {
			return $b_true;
        }
        my %subj_hash = map {$_ => 1} @sb_ids; 
		if (defined $subj_hash{$node->id}) { 
			return $b_true;
		}	
	}
	return $b_false;
}


# returns the function of an analytical node $node
sub _get_afun {
	my ($node) = @_;
	my $anode = $node->get_lex_anode;
    if ($anode) {
		return $anode->afun;
	}
    return;
}


1;
