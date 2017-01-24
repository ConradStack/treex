package Treex::Block::W2W::EstimateNoSpaceAfter;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

###!!! Directed quotation marks are language-dependent. We are currently treating
###!!! them as in English, regardless the language of the document.
my $lbr = '\(\[\{‘';
my $rbr = '\}\]\)’';



sub process_zone
{
    my $self = shift;
    my $zone = shift;
    my $root = $zone->get_atree();
    my @nodes = $root->get_descendants({'ordered' => 1});
    my $nq = 0;
    for(my $i = 0; $i<$#nodes; $i++)
    {
        my $form = $nodes[$i]->form();
        $form = '' if(!defined($form));
        my $next_form = $nodes[$i+1]->form();
        $next_form = '' if(!defined($next_form));
        # The ASCII hyphen (spojovník) should be used only to join two parts of
        # a compound word and thus there are no spaces around it. Note however
        # that it is often used wrongly instead of N- and M-dash.
        ###!!! Loganathan's Tamil data contain hyphens as separate tokens only in cases where they were separated by spaces in the original data.
        ###!!! The compounds with hyphen are kept as one token (i.e. left part + hyphen + right part). Thus we currently omit the hyphen from both
        ###!!! regular expressions.
        if($form      =~ m/^[¡¿$lbr]$/ ||
           $next_form =~ m/^[\.,;:!\?$rbr]$/)
        {
            $nodes[$i]->set_no_space_after(1);
        }
        # Odd undirected quotes are considered opening, even are closing.
        # It will not work if a quote is missing or if the quoted text spans multiple sentences.
        if($form eq '"')
        {
            $nq++;
            # If the number of quotes is even, the no_space_after flag has been set at the previous token.
            # If the number of quotes is odd, we must set the flag now.
            if($nq % 2 == 1)
            {
                $nodes[$i]->set_no_space_after(1);
            }
        }
        # If the current number of quotes is odd, the next quote will be even.
        if($next_form eq '"' && $nq % 2 == 1)
        {
            $nodes[$i]->set_no_space_after(1);
        }
    }
    # We have to set the sentence text anew.
    my $text = $self->collect_sentence_text(@nodes);
    $zone->set_sentence($text);
}



#------------------------------------------------------------------------------
# Returns the sentence text, observing the current setting of no_space_after
# and of the fused multi-word tokens (still stored as wild attributes).
#------------------------------------------------------------------------------
sub collect_sentence_text
{
    my $self = shift;
    my @nodes = @_;
    my $text = '';
    for(my $i = 0; $i<=$#nodes; $i++)
    {
        my $node = $nodes[$i];
        my $wild = $node->wild();
        my $fused = $wild->{fused};
        if(defined($fused) && $fused eq 'start')
        {
            my $first_fused_node_ord = $node->ord();
            my $last_fused_node_ord = $wild->{fused_end};
            my $last_fused_node_no_space_after = 0;
            # We used to save the ord of the last element with every fused element but now it is no longer guaranteed.
            # Let's find out.
            if(!defined($last_fused_node_ord))
            {
                for(my $j = $i+1; $j<=$#nodes; $j++)
                {
                    $last_fused_node_ord = $nodes[$j]->ord();
                    $last_fused_node_no_space_after = $nodes[$j]->no_space_after();
                    last if(defined($nodes[$j]->wild()->{fused}) && $nodes[$j]->wild()->{fused} eq 'end');
                }
            }
            else
            {
                my $last_fused_node = $nodes[$last_fused_node_ord-1];
                log_fatal('Node ord mismatch') if($last_fused_node->ord() != $last_fused_node_ord);
                $last_fused_node_no_space_after = $last_fused_node->no_space_after();
            }
            if(defined($first_fused_node_ord) && defined($last_fused_node_ord))
            {
                $i += $last_fused_node_ord - $first_fused_node_ord;
            }
            else
            {
                log_warn("Cannot determine the span of a fused token");
            }
            $text .= $wild->{fused_form};
            $text .= ' ' unless($last_fused_node_no_space_after);
        }
        else
        {
            $text .= $node->form();
            $text .= ' ' unless($node->no_space_after());
        }
    }
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}



1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::W2W::EstimateNoSpaceAfter

=head1 DESCRIPTION

The C<no_space_after> attribute of nodes encodes whether the current token was
separated by a whitespace from the next token in the original sentence before
tokenization.

If this information is not available in the corpus, we can estimate it
according to usual typographical rules. It mostly affects punctuation symbols
attached to the previous or to the following token. Note however that it is not
completely language-independent (for example, quotation marks are attached to
the quoted contents in English but not in French). It is also not possible (or
at least not easy) to recover all contexts. If tokenization split decimal
numbers on the decimal point, we could make an error if we treat the decimal
point as a normal period.

This block only adds the C<no_space_after> flags but it never removes them.
It assumes that these flags have not been present in the text.

Undirected quotation marks are treated in a primitive way.
The odd-numbered quotes are considered opening, the even-numbered closing.
It will not work properly if a quote is missing or if the quoted text spans
multiple sentences.

Directed typographical quotes are language-dependent (e.g. the English opening
quote is used as closing quote in Czech). Language-specific rules are currently
ignored.

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by Institute of Formal and Applied Linguistics,
Charles University in Prague

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
