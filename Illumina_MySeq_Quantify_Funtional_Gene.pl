#!/usr/bin/env perl
use strict;
use warnings;
#--INCLUDE PACKAGES-----------------------------------------------------------$
use IO::String;
use File::Basename;
use File::Copy;
use Cwd;
#-----------------------------------------------------------------------------$
#----SUBROUTINES--------------------------------------------------------------$
#-----------------------------------------------------------------------------$

sub WriteArrayToFile
{
  my ($filename, @in) = @_;
  my $a = join (@in, "\n");
  open (OUTFILE, ">$filename");
  foreach my $a (@in)
{
    print OUTFILE $a;
    print OUTFILE "\n";
  }
close (OUTFILE);
}

#-----------------------------------------------------------------------------
# input parameters
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $FRname = basename($ForwardReads);
my $ReverseReads = $ARGV[1];
my $RRname = basename($ReverseReads);
my $DatabaseName = $ARGV[2];
my $DBname = basename($DatabaseName);
my $ResultDirectory = $ARGV[3];
if (not defined $ARGV[3] ) {
  $ResultDirectory = cwd();
}

#-----------------------------------------------------------------------------
# install usearch8 in docker - uncomment if its not installed
#-----------------------------------------------------------------------------

system ("wget http://mgmic.oscer.ou.edu/sequence_data/tutorials/install_usearch8.sh");
system ("sh install_usearch8.sh");
system ("cd ".$ResultDirectory);

#----------------------------------------------------------------------------
# convert files from fastq to fasta
### I MOVED THIS PART TO THE QC SCRIPT
#-----------------------------------------------------------------------------

#my $system_string = "read_fastq -i ".$ForwardReads." | write_fasta -o ".$ResultDirectory."/".$FRname.".fasta -x";
#system ($system_string);
#$system_string = "read_fastq -i ".$ReverseReads." | write_fasta -o ".$ResultDirectory."/".$RRname.".fasta -x";
#system ($system_string);

#-----------------------------------------------------------------------------
# run usearch
#-----------------------------------------------------------------------------

my $system_string =  "usearch8 -usearch_global ".$ForwardReads." -db ".$DatabaseName." -id 0.7 -strand both -mincols 50 -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Fhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Fhits.tab";

#$system_string = "usearch8 -usearch_global ".$ResultDirectory."/".$FRname.".fasta -db ".$DatabaseName." -id 0.7 -strand both -mincols 50 -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Fhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Fhits.tab";

printf("\n\n\n".$system_string."\n\n\n");
system ($system_string);


$system_string  = "usearch8 -usearch_global ".$ReverseReads." -db ".$DatabaseName." -id 0.7 -strand both -mincols 50 -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Rhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Rhits.tab";

#$system_string = "usearch8 -usearch_global ".$ResultDirectory."/".$RRname.".fasta -db ".$DatabaseName." -id 0.7 -strand both -mincols 50 -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Rhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Rhits.tab";

printf("\n\n\n".$system_string."\n\n\n");
system ($system_string);


#-----------------------------------------------------------------------------
# parse results
#-----------------------------------------------------------------------------

system ("sed -i 's/>/>F_/g' ".$ResultDirectory."/".$DBname.".Fhits.fasta");
system ("sed -i 's/>/>R_/g' ".$ResultDirectory."/".$DBname.".Rhits.fasta");
system ("cat ".$ResultDirectory."/".$DBname.".Fhits.fasta ".$ResultDirectory."/".$DBname.".Rhits.fasta >  ".$ResultDirectory."/".$DBname.".FRhits.fasta");
system ("cat ".$ResultDirectory."/".$DBname.".Fhits.tab ".$ResultDirectory."/".$DBname.".Rhits.tab > ".$ResultDirectory."/".$DBname.".FRhits.tab");


#-----------------------------------------------------------------------------
# Make bar graph
#-----------------------------------------------------------------------------

#system ("wget http://mgmic.oscer.ou.edu/sequence_data/tutorials/bargraph_redgreen_scale.r");

#$system_string = "fgrep -o \"+\" ".$ForwardReads." | wc -l";
$system_string = "fgrep -o \"\>\" ".$ForwardReads." | wc -l";
my $number_of_seqs = `$system_string`;

$system_string = "fgrep -o \"\>\" ".$ResultDirectory."/".$DBname.".FRhits.fasta | wc -l";
my $number_of_hits = `$system_string`;

my $a = ($number_of_hits / ($number_of_seqs*2))*100000;
if ($a == 0) {$a=0.1;}
#1 in 1000 =100% so 100 in 100000  = 100%
$system_string ="Rscript /opt/local/scripts/bargraph_redgreen_scale.r ".$a." ".$ResultDirectory."/".$DBname.".bargraph.png";
system ($system_string);

my @stats;

push (@stats, "Number of read pairs analyzed: ".$number_of_seqs);
push (@stats, "Number of hits observed: ".$number_of_hits);


WriteArrayToFile($ResultDirectory."/".$DBname.".stats.txt", @stats);


#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
