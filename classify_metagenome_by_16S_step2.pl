#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
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

#my $ForwardReads = $ARGV[0];
#my $ReverseReads = $ARGV[1];
#my $database_path = $ARGV[2];
my $ResultDirectory = $ARGV[2];
if (not defined $ARGV[2] ) {
  $ResultDirectory = cwd();
}

my $on_off_switch = $ARGV[3];
if (not defined $ARGV[3] ) {
    $on_off_switch = "on";
#     $on_off_switch = "off";
}

my $runtime_flags = $ARGV[4];

my $min_seq_length = 100; #default 150
my $id = 0.7;

#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------

if ($on_off_switch eq "on")
{

#-----------------------------------------------------------------------------
# Set Display
#-----------------------------------------------------------------------------
system ("Xvfb :1 -screen 0 1024x768x16 &> xvfb.log  &");

#-----------------------------------------------------------------------------
#   add tags 
#-----------------------------------------------------------------------------

#my $confstring ="perl /opt/local/scripts/bin/add_tag.pl 1 ".$ResultDirectory."/ssu_hits_corrected.fasta ./";

my $confstring ="perl /opt/local/scripts/bin/add_tag.pl 1 ssu_hits_corrected.fasta ".$ResultDirectory."/";

printf($confstring."\n\n");
system ($confstring);


#i'm using barcode 1 here. the sequence to this is ACGAGACTGATT

my $barcode ="ACGAGACTGATT";


#-----------------------------------------------------------------------------
# Now run the qiime commands
#-----------------------------------------------------------------------------

#Validate the mapping file

system ("validate_mapping_file.py -m ".$ResultDirectory."/ssu_hits_corrected.map -o ".$ResultDirectory."/temp/mg_mapping");

#-----------------------------------------------------------------------------
#Split libraries
#-----------------------------------------------------------------------------

$confstring = "split_libraries.py -f ".$ResultDirectory."/ssu_hits_corrected".$barcode.".fasta -m ".$ResultDirectory."/ssu_hits_corrected.map -o ".$ResultDirectory."/temp/mg_processed_seqs/ --barcode_type 12 -l ".$min_seq_length;

printf("\n\n\n\n".$confstring."\n\n");
system ($confstring);

#-----------------------------------------------------------------------------
#pick closed referece OTUs
#-----------------------------------------------------------------------------

$confstring = "pick_closed_reference_otus.py -i ".$ResultDirectory."/temp/mg_processed_seqs/seqs.fna -o ".$ResultDirectory."/temp/mg_OTUs -r /data/DATABASES/16S/Silva_111_post/rep_set/97_Silva_111_rep_set.fasta -t /data/DATABASES/16S/Silva_111_post/taxonomy/97_Silva_111_taxa_map_RDP_6_levels.txt -f";

printf("\n\n\n\n".$confstring."\n\n");
system ($confstring);


#-----------------------------------------------------------------------------
#Make charts
#-----------------------------------------------------------------------------

$confstring = "summarize_taxa_through_plots.py -i ".$ResultDirectory."/temp/mg_OTUs/otu_table.biom -o ".$ResultDirectory."/temp/mg_taxplots -m ".$ResultDirectory."/ssu_hits_corrected.map -p /opt/local/scripts/bin/qiime_default.par -f";

printf("\n\n\n\n".$confstring."\n\n");
system ($confstring);

#-----------------------------------------------------------------------------
# make a prettier pie chart with R
#-----------------------------------------------------------------------------


system ("Rscript /opt/local/scripts/bin/pie_chart.r ".$ResultDirectory."/temp/mg_taxplots/otu_table_L2.txt ".$ResultDirectory."/community_pie_chart_L1.png 1");
system ("Rscript /opt/local/scripts/bin/pie_chart.r ".$ResultDirectory."/temp/mg_taxplots/otu_table_L4.txt ".$ResultDirectory."/community_pie_chart_L3.png 3");
system ("Rscript /opt/local/scripts/bin/pie_chart.r ".$ResultDirectory."/temp/mg_taxplots/otu_table_L6.txt ".$ResultDirectory."/community_pie_chart_L5.png 5");


#-----------------------------------------------------------------------------
# Make a KronaGraph
#-----------------------------------------------------------------------------

$confstring = "perl /opt/local/scripts/bin/convert_qiime_tax_to_krona.pl ".$ResultDirectory."/temp/mg_taxplots/otu_table_L6.txt ".$ResultDirectory."/L6_kt.txt";
system ($confstring);

$confstring = "ktImportText ".$ResultDirectory."/L6_kt.txt  -o ".$ResultDirectory."/Krona_outsd.html";
system ($confstring);



#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------
} 
#end of on switch braket

if ($on_off_switch eq "off")
{}






