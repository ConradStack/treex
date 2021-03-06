package Treex::Tool::Lexicon::EN::PersonalRoles;
use utf8;
use strict;
use warnings;

my %IS_PERSONAL_ROLE;
while (<DATA>) {
    for (split) {
        $IS_PERSONAL_ROLE{$_} = 1;
    }
}
close DATA;

sub is_personal_role {
    return $IS_PERSONAL_ROLE{ $_[0] }
}

1;

=encoding utf8

=head1 NAME

Treex::Tool::Lexicon::EN::PersonalRoles

=head1 SYNOPSIS

 use Treex::Tool::Lexicon::EN::PersonalRoles;
 print Treex::Tool::Lexicon::EN::PersonalRoles::is_personal_role('actor');
 # prints 1

=head1 DESCRIPTION

A list of personal roles which such as I<author, cardinal, citizen,...>.

=head1 AUTHOR

Zdeněk Žabokrtský <zabokrtsky@ufal.mff.cuni.cz>

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2012 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__DATA__

abbot accountant actor administrator admirer adviser advisor advocate agency
agent agreement aide alderman amateur ambassador amendment analyst apprentice
archbishop architect artist assistant associate astronomer attorney auditor
aunt auntie author baba baby baker band bank banker bankers baron barrister
bass bassist being benefactor billionaire biologist biology bishop blacksmith
board book boss boxer boy boyfriend brigadier broadcaster broker brother
brother-in-law buddy builder bursar business businessman butcher cabinetmaker
cameraman campaigner candidate capt captain cardinal cardiologist celebrity
cellist ceo chair chairman chairperson challenger champion chancellor change
chap character chef chemist chief child churchwarden citizen classic cleaning
clerk climber coach co-author co-founder col collaborator colleague collector
colonel columnist comedian comic commandant commander commentator commissionaire
commissioner commons companion company competition composer comrade conductor
congressman conservationist constable consultant contender contractor controller
convict cook coordinator co-ordinator cop correspondent council councillor
counsel counsellor couple cousin couturier criminal critic crooner curator
custodian cyclist dad dancer daughter deal dealer dear decision defender
delegate deputy designer detective diplomat director director-general disciple
doctor dr driver drummer duke duo economist editor educationalist electrician
emissary emperor employee engineer entrepreneur envoy executive exhibition
exile expert family fan farmer father father-in-law fighter figure finalist
fisherman footballer foreman forerunner founder freedom friend gardener gen
general genius gentleman geologist girl goalie goalkeeper governor governors
graduate grandfather grandmaster grandson granny group guard guardsman guest
guide guitarist gunman gunner guy gynaecologist hall head headmaster
headmistress heir hero historian holder husband idol illustrator inspector
instructor inventor investor joiner journalist judge judges justice keeper
keyboardist kid king kinsman knights lad lady lamb landlord landowner landscape
laureate lawyer leader lecturer librarian lieutenant liquidator listener
locksmith lodger lord lover lt magician magistrate maid major maker mama man
manager manufacturer marksman marshal marshall martyr master mate mathematician
mayor mechanic medic member members merchant millionaire mind minister ministers
miss mister mistress mother mp mps mr mrs ms mum murder musician nanny
naturalist navigator negotiator neighbour neighbor nephew newcomer news newsman
niece novelist nurse office officer official operator opponent organiser owner
owners pa painter pair pal papa partner partners passenger pastor pensioner
people person personality philosopher photographer physician physicist pianist
pilot pioneer playboy player playwright poet police policeman policy politician
pope porter practitioner preacher predecessor premier premiere presentation
presenter president press priest prince princess principal prisoner pro producer
prof professor proprietor prosecutor psychiatrist psychologist publican
publicist publisher queen radical raider railwayman rebellion rector ref referee
replacement reporter representative republican researcher retailer retiree
returnee rider riders rival runner runner-up sailor salesman scholar schoolmate
scientist scout screenwriter sculptor seaman secretaries secretary
secretary-general sen senator sergeant servant sgt shepherd sheriff shipowner
singer sir sister skipper smith sociologist soldier solicitor soloist son song
speaker specialist spokesman spokesperson spokeswoman squire staff star stars
stockbroker stonemason store strategy striker student stylist successor
superintendent superstar supervisor supplier supporter surgeon surveyor teacher
team teammate technician technology tenant theologian theorist thief title
tracks trainee trainer traveller treasurer trooper troops trumpeter trustee
tsar tutor umpire uncle understudy unionist veteran vice-chairman vice-president
victim victor violinist virgin vocalist vp waiter warden weatherman widow wife
winner witness woman worker writer young youngster zoologist 
