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
sub get_file_data
{
  my ($file_name) = @_;
  my @file_content;
  open (PROTEINFILE, $file_name);
  @file_content = <PROTEINFILE>;
  close PROTEINFILE;
  return @file_content;
} # end of subroutine get_file_data;


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
# inputs and parameters
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $ReverseReads = $ARGV[1];
my $database_path = $ARGV[2];
my $ResultDirectory = $ARGV[3];
if (not defined $ARGV[3] ) {
  $ResultDirectory = cwd();
}
my $id = 0.7;

#-----------------------------------------------------------------------------
#--INSTALL SILVA 111 AND USEARCH
#--NOTE: Installing silva is not necessary on mgmic; i've already done this
#-- if we add extra nodes, we will need to develop a deploy database script
#-----------------------------------------------------------------------------

my $confstring = "sh deploy_silva111.sh";
printf($confstring."\n\n");
#system($confstring);

# generate udb database from silva111
#$confstring = "usearch -makeudb_usearch SSURef_111_candidate_db.fasta -output SSURef_111_candidate_db.udb";
#printf($confstring);
#system($confstring);

$confstring = "sh /opt/local/scripts/bin/install_usearch.sh";  
printf($confstring."\n\n");
system($confstring);

#-----------------------------------------------------------------------------
# run usearch search
#-----------------------------------------------------------------------------

mkdir($ResultDirectory."/temp");

#-----------------------------------------------------------------------------
#------create fasta files-----------------------------------------------------
#-----------------------------------------------------------------------------

system ("read_fastq -i ".$ForwardReads." | write_fasta -o ".$ResultDirectory."/temp/fr.fasta -x");
system ("read_fastq -i ".$ReverseReads." | write_fasta -o ".$ResultDirectory."/temp/rr.fasta -x");

#-----------------------------------------------------------------------------
#------run usearch commands----------------------------------------------------
#-----------------------------------------------------------------------------

$confstring = "usearch8 -usearch_global ".$ResultDirectory."/temp/fr.fasta -db ".$database_path." -id ".$id." -qsegout ".$ResultDirectory."/temp/f_hits.fasta -strand both -maxhits 1 -blast6out ".$ResultDirectory."/temp/f_hits.txt";
printf($confstring."\n\n");
system ($confstring);

$confstring = "usearch8 -usearch_global ".$ResultDirectory."/temp/rr.fasta -db ".$database_path." -id ".$id." -qsegout ".$ResultDirectory."/temp/r_hits.fasta -strand both -maxhits 1 -blast6out ".$ResultDirectory."/temp/r_hits.txt";
printf($confstring."\n\n");
system ($confstring);


#-----------------------------------------------------------------------------
# -------Reformat the resulting fasta files to avoid seqID duplication errors
#-----------------------------------------------------------------------------

$confstring ="sed -i 's/>/>f_/g' ".$ResultDirectory."/temp/f_hits.fasta";
printf($confstring."\n\n");
system ($confstring);

$confstring ="sed -i 's/>/>r_/g' ".$ResultDirectory."/temp/r_hits.fasta";
printf($confstring."\n\n");
system ($confstring);


#-----------------------------------------------------------------------------
# ----Catentating the forward and reverse ssu query segments into a single file
#-----------------------------------------------------------------------------

$confstring ="cat ".$ResultDirectory."/temp/f_hits.fasta ".$ResultDirectory."/temp/r_hits.fasta > ".$ResultDirectory."/temp/ssu_hits.fasta";

printf($confstring."\n\n");
system ($confstring);

#-----------------------------------------------------------------------------
#Removing any extraneous line returns that USEARCH may have added within sequences using Biopieces
#-----------------------------------------------------------------------------

$confstring ="read_fasta -i ".$ResultDirectory."/temp/ssu_hits.fasta | write_fasta -o ".$ResultDirectory."/ssu_hits_corrected.fasta -x";
printf($confstring."\n\n");
system ($confstring);




















