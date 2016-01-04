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

sub parse_flags
{
  my ($flags) = @_;

  my @elements = split("-", $flags);
  my @r1; my @r2;
  foreach my $a (@elements)
      {
      $a=~ s/\s+$//;
      if ($a ne '')
         {
          my @tr = split (/ /, $a);
          if ($tr[0] && $tr[1]) { push (@r1, $tr[0]); push (@r2, $tr[1]);}
         }
      }
return (\@r1, \@r2);
} # end of parse_flags subroutine;

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
  $ResultDirectory = cwd();}
my $runtime_flags = $ARGV[4];

#-----------------------------------------------------------------------------
# DEFAULT RUNTIME PARAMETERS
# we assume that data are MiSeq PE250 as default parameters
#-----------------------------------------------------------------------------

my $min_col = 50;  
my $hitID   = 0.7;

my @db_split_name = split (/\./, $DBname);
if ($db_split_name[1] eq "faa")
{
$min_col = 25;  
$hitID   = 0.5;
}


#-----------------------------------------------------------------------------
# RUNTIME FLAG MANGAGEMENT
#-----------------------------------------------------------------------------

#my @rf1 = @{(parse_flags($runtime_flags))[0]};
#my @rf2 = @{(parse_flags($runtime_flags))[1]};


#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------



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

my $system_string =  "usearch8 -usearch_global ".$ForwardReads." -db ".$DatabaseName." -id ".$hitID." -strand both -mincols ".$min_col." -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Fhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Fhits.tab";

#$system_string = "usearch8 -usearch_global ".$ResultDirectory."/".$FRname.".fasta -db ".$DatabaseName." -id 0.7 -strand both -mincols 50 -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Fhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Fhits.tab";

printf("\n\n\n".$system_string."\n\n\n");
system ($system_string);


$system_string  = "usearch8 -usearch_global ".$ReverseReads." -db ".$DatabaseName." -id ".$hitID." -strand both -mincols ".$min_col." -maxhits 1 -qsegout ".$ResultDirectory."/".$DBname.".Rhits.fasta -blast6out ".$ResultDirectory."/".$DBname.".Rhits.tab";

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
# Make bar graph, histogram, and stats file
#-----------------------------------------------------------------------------

#system ("wget http://mgmic.oscer.ou.edu/sequence_data/tutorials/bargraph_redgreen_scale.r");

#$system_string = "fgrep -o \"+\" ".$ForwardReads." | wc -l";
$system_string = "fgrep -o \"\>\" ".$ForwardReads." | wc -l";
my $number_of_seqs = `$system_string`;

$system_string = "fgrep -o \"\>\" ".$ResultDirectory."/".$DBname.".FRhits.fasta | wc -l";
my $number_of_hits = `$system_string`;


# RPKM = (reads / exon length) * (1,000,000 / mapped reads)
# For example, suppose a transcript has 50 reads that map to it, with an exon transcript length of 7000 bp ( = 7.0 kbp), and there are 5,000,000 reads in that sample. The RPKM value is: 
# 500/(7.000) × (1,000,000/5,000,000) = 14.28 RPKM reads 

#my $a = ($number_of_hits / ($number_of_seqs*2))*100000;
#$system_string ="Rscript /opt/local/scripts/bargraph_redgreen_scale.r ".$a." ".$ResultDirectory."/".$DBname.".bargraph.png";
#if ($a == 0) {$a=0.01;}

my $RPKM =0.01;

if ($number_of_hits >0 )
   {
    $RPKM = ($number_of_hits/1000) * (1000000 / ($number_of_seqs*2)) * 50;
   }

$system_string ="Rscript /opt/local/scripts/bargraph_redgreen_scale.r ".$RPKM." ".$ResultDirectory."/".$DBname.".bargraph.png";
system ($system_string);

$system_string ="Rscript /opt/local/scripts/hist.r ".$ResultDirectory."/".$DBname.".FRhits.tab ".$ResultDirectory."/".$DBname.".hist.png";
system ($system_string);

my @stats;

push (@stats, "Number of read pairs analyzed: ".$number_of_seqs);
push (@stats, "Number of hits observed: ".$number_of_hits);


WriteArrayToFile($ResultDirectory."/".$DBname.".stats.txt", @stats);


#-----------------------------------------------------------------------------
# extract whole reads, not just matching portions
#-----------------------------------------------------------------------------

# cut -d \t bac_rpoB.udb.Fhits.tab -f2 | awk '{print $1}' > f_h.txt
# cut -d \t bac_rpoB.udb.Rhits.tab -f2 | awk '{print $1}' > r_h.txt
# grep -A 1 -f functional_gene/bac_rpoB/f_h.txt F.QCed.fasta > functional_gene/bac_rpoB/f_h.fas
# grep -A 1 -f functional_gene/bac_rpoB/r_h.txt R.QCed.fasta > functional_gene/bac_rpoB/r_h.fas
# sed '/--/d' functional_gene/bac_rpoB/f_h.fas > functional_gene/bac_rpoB/f_h.fasta
# sed '/--/d' functional_gene/bac_rpoB/r_h.fas > functional_gene/bac_rpoB/r_h.fasta
# cat functional_gene/bac_rpoB/f_h.fasta functional_gene/bac_rpoB/r_h.fasta >functional_gene/bac_rpoB/fr_whole_reads.fasta
# rm functional_gene/bac_rpoB/*.txt
# rm functional_gene/bac_rpoB/*.fas


$system_string = "cut -d \\t ".$ResultDirectory."/".$DBname.".Fhits.tab -f2 | awk '{print \$1}' \> ".$ResultDirectory."/f_h.txt";
system ($system_string);

$system_string = "cut -d \\t ".$ResultDirectory."/".$DBname.".Rhits.tab -f2 | awk '{print \$1}' \> ".$ResultDirectory."/r_h.txt";
system ($system_string);

$ReverseReads =~ s/.fastq/.fasta/g;
$ForwardReads =~ s/.fastq/.fasta/g;

$system_string = "grep -A 1 -f ".$ResultDirectory."/f_h.txt ".$ForwardReads." > ".$ResultDirectory."/f_h.fas";
system ($system_string);
$system_string = "grep -A 1 -f ".$ResultDirectory."/r_h.txt ".$ReverseReads." > ".$ResultDirectory."/r_h.fas";
system ($system_string);

$system_string = "sed '/--/d' ".$ResultDirectory."/f_h.fas > ".$ResultDirectory."/f_h.fasta";
system ($system_string);
$system_string = "sed '/--/d' ".$ResultDirectory."/r_h.fas > ".$ResultDirectory."/r_h.fasta";
system ($system_string);

$system_string = "cat ".$ResultDirectory."/f_h.fasta ".$ResultDirectory."/r_h.fasta > ".$ResultDirectory."/fr_whole_reads.fasta";
system ($system_string);

$system_string = "rm ".$ResultDirectory."/*.fas";
$system_string = "rm ".$ResultDirectory."/*.txt";


