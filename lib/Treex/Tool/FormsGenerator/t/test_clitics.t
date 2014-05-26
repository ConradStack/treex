#!/usr/bin/env perl

BEGIN {
    if ( ! $ENV{AUTHOR_TESTING}) {
        require Test::More;
        Test::More::plan( skip_all => 'these tests requires AUTHOR_TESTING' );
    }
}

use Treex::Tool::FormsGenerator::TA;
use Test::More;
use utf8;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $generator = Treex::Tool::FormsGenerator::TA->new();

while (<DATA>) {
	chomp;
	s/(^\s+|\s+$)//;
	next if /^#/;
	next if /^$/;	
	my $l = $_;
	if ($l =~ /\t/) {
		# c[0] input wordform
		my @c = split(/\t/, $l);
		if ($#c == 5) {
			# clitics output
			my @co = $generator->generate_cliticized_forms($c[0]);
			ok(($co[0] eq $c[1]) && ($co[1] eq $c[2]) && ($co[2] eq $c[3]) && ($co[3] eq $c[4]) && ($co[4] eq $c[5]), $c[0] . ":" . join(",", @co));
		}		
	}	 
}

done_testing();

__DATA__
கிறவனை	கிறவனையும்	கிறவனையா	கிறவனையே	கிறவனையோ	கிறவனையாவது
தவரை	தவரையும்	தவரையா	தவரையே	தவரையோ	தவரையாவது
ாததை	ாததையும்	ாததையா	ாததையே	ாததையோ	ாததையாவது
தவனுக்கு	தவனுக்கும்	தவனுக்கா	தவனுக்கே	தவனுக்கோ	தவனுக்காவது
பவைக்கு	பவைக்கும்	பவைக்கா	பவைக்கே	பவைக்கோ	பவைக்காவது
ாததற்கு	ாததற்கும்	ாததற்கா	ாததற்கே	ாததற்கோ	ாததற்காவது
தவருக்காக	தவருக்காகவும்	தவருக்காகவா	தவருக்காகவே	தவருக்காகவோ	தவருக்காகவாவது
கிறவனால்	கிறவனாலும்	கிறவனாலா	கிறவனாலே	கிறவனாலோ	கிறவனாலாவது
ாததால்	ாததாலும்	ாததாலா	ாததாலே	ாததாலோ	ாததாலாவது
கிறவனுடன்	கிறவனுடனும்	கிறவனுடனா	கிறவனுடனே	கிறவனுடனோ	கிறவனுடனாவது
கிறவனோடு	கிறவனோடும்	கிறவனோடா	கிறவனோடே	கிறவனோடோ	கிறவனோடாவது
ாதவரோடு	ாதவரோடும்	ாதவரோடா	ாதவரோடே	ாதவரோடோ	ாதவரோடாவது
ாததுடன்	ாததுடனும்	ாததுடனா	ாததுடனே	ாததுடனோ	ாததுடனாவது
தவனில்	தவனிலும்	தவனிலா	தவனிலே	தவனிலோ	தவனிலாவது
தவளில்	தவளிலும்	தவளிலா	தவளிலே	தவளிலோ	தவளிலாவது
ாததில்	ாததிலும்	ாததிலா	ாததிலே	ாததிலோ	ாததிலாவது
ாததிடம்	ாததிடமும்	ாததிடமா	ாததிடமே	ாததிடமோ	ாததிடமாவது
தவளிலிருந்து	தவளிலிருந்தும்	தவளிலிருந்தா	தவளிலிருந்தே	தவளிலிருந்தோ	தவளிலிருந்தாவது
ாததிலிருந்து	ாததிலிருந்தும்	ாததிலிருந்தா	ாததிலிருந்தே	ாததிலிருந்தோ	ாததிலிருந்தாவது
தவளிடமிருந்து	தவளிடமிருந்தும்	தவளிடமிருந்தா	தவளிடமிருந்தே	தவளிடமிருந்தோ	தவளிடமிருந்தாவது
__END__