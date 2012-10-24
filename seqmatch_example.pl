#Thanks to Mike Coyne of Channing Laboratory at Harvard for help writing this perl client.
#!/usr/bin/perl -w
use strict;
use SOAP::Lite; # or "use SOAP::Lite +trace => 'debug'" for debugging information

my (%seqs, $id, $comment, @order);

die "No fasta filename provided!\n" unless ($ARGV[0]);
die "No file named $ARGV[0] found!\n" unless (-e $ARGV[0]);

# read a fasta file into a hash: id as key, bases as value;
open (FASTA, $ARGV[0]) or die "Can't open fasta input file: $!\n";

 while (<FASTA>) {
    if (/^>\S+/) {
        ($id, $comment) = (split /\s+/, $_, 2);
        $id =~ s/^>//;
        chomp ($comment);
        $comment = ' ' unless ($comment);
        $seqs{$id}{comment} = $comment;
        push (@order, $id);
    } else {
        chomp;
        $seqs{$id}{seq} .= $_;
    }
}

# create the parameters to pass to the SOAP service.
my @data;
foreach my $id (@order) {
    my $bases = $seqs{$id}{seq};
    push @data, SOAP::Data->name("query" => \SOAP::Data->value(
        SOAP::Data->name("bases" => $bases)->type(''),
        SOAP::Data->name("id" => $id)->type('')));
}
push @data, SOAP::Data->name("strainType" => 'both')->type('');      # type, nontype, or both
push @data, SOAP::Data->name("sourceType" => 'both')->type('');      # environ, isolates, or both
push @data, SOAP::Data->name("sizeType" => 'ge1200')->type('');      # ge1200, lt1200, or both
push @data, SOAP::Data->name("qualityType" => 'good')->type('');     # good, low, or both
push @data, SOAP::Data->name("taxonomyType" => 'rdpHome')->type(''); # rdpHome or ncbiHome
push @data, SOAP::Data->name("numberOfResults" => '20')->type('');   # integer = matches to return per query

# create the soap object.
my $soap = SOAP::Lite->uri('http://rdp.cme.msu.edu/services/seqmatch')
    ->proxy('http://rdp.cme.msu.edu/services/seqmatch');

# call the soap web service method.
my $result = $soap->call(
    SOAP::Data->name('n1:seqmatchWithOptions')
        ->attr({'xmlns:n1' => 'http://rdp.cme.msu.edu/services/seqmatch'}) => @data)
    ->paramsin;

print "#RDP Seqmatch Results\n";
print "#RDP Release: " . $result->{'rdpRelease'} . "\n";
print "#Date Run: " . $result->{'dateRun'} . "\n";
print "\n";
print "#Query:\tqueryID\tqueryWordCount\n";
print "#Query description:\tqueryDefinition\n";
print "#Match:\tsab\toligos\tsid\tdefinition\tlineageString\n";
print "\n";

# SOAP::Lite will return an array ref if there is more then one result, otherwise just the object itself.
if (ref($result->{'query'}) eq 'ARRAY') {
    foreach my $query (@{$result->{'query'}}) {
        print "Query:\t" . $query->{'queryId'} . "\t" . $query->{'queryWordCount'} . "\n";
        print "Query description: $seqs{$id}{comment}\n" if ($seqs{$id}{comment} =~ /\w+/);
        if (ref($query->{'match'}) eq 'ARRAY') {
            foreach my $match (@{$query->{'match'}}) {
                print "Match:\t" . $$match{'sab'} . "\t" . $$match{'oligos'}
                    . "\t" . $$match{'sid'} . "\t" . $$match{'definition'}
                    . "\t" . $$match{'lineageStr'} . "\n";
            }
        } else {
            print "Match:\t" . $query->{'match'}{'sab'} . "\t" . $query->{'match'}{'oligos'}
                . "\t" . $query->{'match'}{'sid'} . "\t" . $query->{'match'}{'definition'}
                . "\t" . $query->{'match'}{'lineageStr'} . "\n";
        }
        print "\n";
    }
} else {
    print "Query:\t" . $result->{'query'}{'queryId'} . "\t" . $result->{'query'}{'queryWordCount'} . "\n";
    print "Query description: $seqs{$id}{comment}\n" if ($seqs{$id}{comment} =~ /\w+/);
    if (ref($result->{'query'}{'match'}) eq 'ARRAY') {
        foreach my $match (@{$result->{'query'}{'match'}}) {
            print "Match:\t" . $$match{'sab'} . "\t" . $$match{'oligos'}
                . "\t" . $$match{'sid'} . "\t" . $$match{'definition'}
                . "\t" . $$match{'lineageStr'} . "\n";
        }
    } else {
        print "Match:\t" . $result->{'query'}{'match'}{'sab'} . "\t" . $result->{'query'}{'match'}{'oligos'}
            . "\t" . $result->{'query'}{'match'}{'sid'} . "\t" . $result->{'query'}{'match'}{'definition'}
            . "\t" . $result->{'query'}{'match'}{'lineageStr'} . "\n";
    }
}
