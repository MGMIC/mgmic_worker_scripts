#!/usr/bin/env perl
use strict;
use warnings;
#--INCLUDE PACKAGES-----------------------------------------------------------
use IO::String;
use Cwd;
#use substr;
#-----------------------------------------------------------------------------
#   SUBROUTINES
#-----------------------------------------------------------------------------

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
# input files 
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $MapFile = $ARGV[1];
my $ResultDirectory = $ARGV[2];
if (not defined $ARGV[2] ) {
  $ResultDirectory = cwd();
}

my $runtime_flags = $ARGV[3];

#-----------------------------------------------------------------------------
# DEFAULT RUNTIME PARAMETERS
#-----------------------------------------------------------------------------

my $min_library_size = 500;  #usually default of 500
my $referaction_depth =1;

#-----------------------------------------------------------------------------
# RUNTIME FLAG MANAGEMENT
#
#  -remove_mitochonrial_16S 1
#
#-----------------------------------------------------------------------------

my $remove_mitochonrial_16S =0;

my @rf1 = @{(parse_flags($runtime_flags))[0]};
my @rf2 = @{(parse_flags($runtime_flags))[1]};

for (my $rf_count = 0; $rf_count <=scalar(@rf1); $rf_count++)
    {
    if ($rf1[$rf_count] eq "remove_mitochonrial_16S")  { $remove_mitochonrial_16S = $rf2[$rf_count]; }           
    }


#-----------------------------------------------------------------------------
### Set Display
###-----------------------------------------------------------------------------
system ("Xvfb :1 -screen 0 1024x768x16 &> xvfb.log  &");
chdir($ResultDirectory);

#-----------------------------------------------------------------------------
# Install usearch8 and usearch61
#-----------------------------------------------------------------------------

system ("wget http://mgmic.oscer.ou.edu/sequence_data/tutorials/install_usearch.sh");
system ("sh install_usearch.sh");
chdir($ResultDirectory);

# -------------------------------------------------------------
# Extract your reads and barcodes
# -------------------------------------------------------------

my $system_string = ("extract_barcodes.py -f ".$ResultDirectory."/joinedQ30_for_qiime.fastq -m ".$ResultDirectory."/".$MapFile." -l 12 -o processed_seqs");

system ($system_string);

#for fasta
#demultiplex_fasta.py -m GoM_Sept_Mapping.txt -f GOM_R1.fas.q30.FR.fasta --barcode_type 12 -o processed_seqs -B

# -------------------------------------------------------------
# Split libraries
# -------------------------------------------------------------

$system_string = ("split_libraries_fastq.py -i ".$ResultDirectory."/processed_seqs/reads.fastq -b ".$ResultDirectory."/processed_seqs/barcodes.fastq -m  ".$ResultDirectory."/".$MapFile." -o ".$ResultDirectory."/processed_seqs/Split_Output/ --barcode_type 12");

system ($system_string);


#for fasta
#split_libraries.py -m GoM_Sept_Mapping.txt -f processed_seqs/demultiplexed_seqs.fna -o processed_seqs/Split_Output


# -------------------------------------------------------------
# Pick your OTUs
# -------------------------------------------------------------

$system_string = ("pick_de_novo_otus.py -i ".$ResultDirectory."/processed_seqs/Split_Output/seqs.fna -o ".$ResultDirectory."/OTUs_silva -p /opt/local/scripts/bin/qiime_parameters_silva111.par");

system ($system_string);


# -------------------------------------------------------------
# find mitochonridal 16S
# -------------------------------------------------------------

if ($remove_mitochonrial_16S == 1)
   {
   system ("mkdir ".$ResultDirectory."/metaxa_output");
   $system_string = ("metaxa -i ".$ResultDirectory."/OTUs_silva/rep_set/seqs_rep_set.fasta -o ".$ResultDirectory."/metaxa_output/metaxa_output");
   system ($system_string);
   $system_string = ("grep -e \">\" ".$ResultDirectory."/metaxa_output/metaxa_output.mitochondria.fasta | sed 's/>//g' | sed 's/ /\t/g' | cut -f 1 > ".$ResultDirectory."/metaxa_output/metaxa_output.mitochondria.ids");
  system ($system_string);
   }  

# -------------------------------------------------------------
# find chimeras
# -------------------------------------------------------------

$system_string = ("identify_chimeric_seqs.py -m usearch61 -i ".$ResultDirectory."/OTUs_silva/rep_set/seqs_rep_set.fasta -r /data/DATABASES/16S/Silva_111_post/rep_set/90_Silva_111_rep_set.fasta -o ".$ResultDirectory."/chimeric_seqs/");
system ($system_string);


# -------------------------------------------------------------
# remove mitochondrial sequences and chimeras
#  -remove_mitochonrial_16S 1
# -------------------------------------------------------------
if ($remove_mitochonrial_16S == 1)
   {
   $system_string = ("cat ".$ResultDirectory."/metaxa_output/metaxa_output.mitochondria.ids >> ".$ResultDirectory."/chimeric_seqs/chimeras.txt");
   system ($system_string);
   }

$system_string = ("filter_otus_from_otu_table.py -i ".$ResultDirectory."/OTUs_silva/otu_table.biom -o ".$ResultDirectory."/OTUs_silva/otu_table.nochimeras.biom -e ".$ResultDirectory."/chimeric_seqs/chimeras.txt"); 

system ($system_string);

# -------------------------------------------------------------
# remove small libraries and determine rarefaction depth
# -------------------------------------------------------------


$system_string = "filter_samples_from_otu_table.py -i ".$ResultDirectory."/OTUs_silva/otu_table.nochimeras.biom -o ".$ResultDirectory."/OTUs_silva/otu_table_no_low_coverage_samples.biom -n ".$min_library_size;

#." -m ".$ResultDirectory."/".$MapFile." --output_mapping_fp ".$ResultDirectory."/".$MapFile.".no_low_coverage.map";

printf "\n".$system_string."\n";
system($system_string);


# -------------------------------------------------------------
# Run QIIME core diversity analysis
# -------------------------------------------------------------

#$system_string = ("biom summarize-table -i ".$ResultDirectory."/OTUs_silva/otu_table.nochimeras.biom");
$system_string = ("biom summarize-table -i ".$ResultDirectory."/OTUs_silva/otu_table_no_low_coverage_samples.biom");


my @biom_summary = `$system_string`;

foreach my $g (@biom_summary)
        {
        my @gg = split (" ", $g);
        if (@gg) {if ($gg[0] eq "Min:"){$referaction_depth = $gg[1]}}
        }

$referaction_depth = int ($referaction_depth);
if ($referaction_depth > 1000)
   {
   $referaction_depth = 1000;
   }
if ($referaction_depth <1)
   {
   $referaction_depth = 1;
   }

printf "\nThe determined rarefaction depth is : ".$referaction_depth."\n";


#$system_string = ("core_diversity_analyses.py -o ".$ResultDirectory."/diversity/ -i  ".$ResultDirectory."/OTUs_silva/otu_table.biom -m ".$MapFile." -t ".$ResultDirectory."/OTUs_silva/rep_set.tre -e ".$referaction_depth. " -a");
$system_string = ("core_diversity_analyses.py -o ".$ResultDirectory."/diversity/ -i  ".$ResultDirectory."/OTUs_silva/otu_table_no_low_coverage_samples.biom -m ".$MapFile." -t ".$ResultDirectory."/OTUs_silva/rep_set.tre -e ".$referaction_depth. " -a");

system ($system_string);

#-----------------------------------------------------------------
#--------- Cleanup                                               
#-----------------------------------------------------------------

system ("rm -rf ".$ResultDirectory."/temp");




