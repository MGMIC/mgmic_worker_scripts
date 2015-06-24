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

# none needed

#-----------------------------------------------------------------------------
# input files 
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $MapFile = $ARGV[1];
my $ResultDirectory = $ARGV[2];
if (not defined $ARGV[2] ) {
  $ResultDirectory = cwd();
}



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

#pick_de_novo_otus.py -i processed_seqs/Split_Output/seqs.fna -o OTUs_silva -p qiime_parameters_silva111.par

# -------------------------------------------------------------
# remove chimeras
# -------------------------------------------------------------

$system_string = ("identify_chimeric_seqs.py -m usearch61 -i ".$ResultDirectory."/OTUs_silva/rep_set/seqs_rep_set.fasta -r /data/DATABASES/16S/Silva_111_post/rep_set/90_Silva_111_rep_set.fasta -o ".$ResultDirectory."/chimeric_seqs/");

system ($system_string);


$system_string = ("filter_otus_from_otu_table.py -i ".$ResultDirectory."/OTUs_silva/otu_table.biom -o ".$ResultDirectory."/OTUs_silva/otu_table.nochimeras.biom -e ".$ResultDirectory."/chimeric_seqs/chimeras.txt"); 

system ($system_string);

#identify_chimeric_seqs.py -m usearch61 -i OTUs_Silva/rep_set/seqs_rep_set.fasta -r /data/DATABASES/16S/Silva_111_post/rep_set/90_Silva_111_rep_set.fasta -o chimeric_seqs/
#filter_otus_from_otu_table.py -i OTUs_silva/otu_table.biom -o OTUs_silva/otu_table.nochimeras.biom -e chimeric_seqs/chimeras.txt 

# -------------------------------------------------------------
# Run QIIME core diversity analysis
# -------------------------------------------------------------

$system_string = ("biom summarize-table -i ".$ResultDirectory."/OTUs_silva/otu_table.nochimeras.biom");

my @biom_summary = `$system_string`;
my $referaction_depth =1;


foreach my $g (@biom_summary)
        {
        my @gg = split (" ", $g);
        if (@gg) {if ($gg[0] eq "Min:"){$referaction_depth = $gg[1]}}
        }

$referaction_depth = int ($referaction_depth);
#printf ("\n\nRarefaction depth = ".$referaction_depth."\n\n\n");

$system_string = ("core_diversity_analyses.py -o ".$ResultDirectory."/diversity/ -i  ".$ResultDirectory."/OTUs_silva/otu_table.biom -m ".$ResultDirectory."/GoM_Sept_Mapping.txt -t ".$ResultDirectory."/OTUs_silva/rep_set.tre -e ".$referaction_depth. " -a");

system ($system_string);
