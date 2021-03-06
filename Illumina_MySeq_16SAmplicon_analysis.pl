#!/usr/bin/env perl
use strict;
use warnings;
#--INCLUDE PACKAGES-----------------------------------------------------------
use IO::String;
use Cwd;
#use substr;
#-----------------------------------------------------------------------------
#----SUBROUTINES--------------------------------------------------------------
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
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $ReverseReads = $ARGV[1];
my $ResultDirectory = $ARGV[2];
if (not defined $ARGV[2] ) {
  $ResultDirectory = cwd();
}

system ("mkdir ".$ResultDirectory."/temp/");

#-----------------------------------------------------------------------------
#-join reads------------------------------------------------------------------
#-----------------------------------------------------------------------------

my $join_filename = $ResultDirectory."/temp/".substr($ForwardReads,0,10);
my $confstring = "fastq-join ".$ForwardReads." ".$ReverseReads." -o ".$join_filename;
printf "\n\n".$confstring."\n\n";
system ($confstring);

#-----------------------------------------------------------------------------
#-trim to Q30-----------------------------------------------------------------
#-----------------------------------------------------------------------------

my $join_filename_q30 = $ResultDirectory."/temp/".substr($ForwardReads,0,10).".q30.fastq";
$confstring = "read_fastq -e base_33 -i ".$join_filename."join | trim_seq -m 30 | write_fastq -o ".$join_filename_q30." -x\n";
printf $confstring."\n\n";
system ($confstring);

#-----------------------------------------------------------------------------
#-converto fasta-----------------------------------------------------------------
#-----------------------------------------------------------------------------
my $join_filename_q30_fasta =$join_filename_q30; 
chop ($join_filename_q30_fasta);
$join_filename_q30_fasta = $join_filename_q30_fasta."a";
$confstring = "read_fastq -e base_33 -i ".$join_filename_q30." | write_fasta -o ".$join_filename_q30_fasta." -x";
printf $confstring."\n\n";
system ($confstring);

#-----------------------------------------------------------------------------
#-find out which barcodes are prsent -----------------------------------------
#-----------------------------------------------------------------------------

$confstring = "perl /opt/local/scripts/create_mapping_de_novo.pl ".$join_filename_q30_fasta;
printf $confstring."\n\n";
system ($confstring);

my @bacrodes = get_file_data ($ResultDirectory."/temp/"."detected.barcodes"); chomp (@bacrodes);

#-----------------------------------------------------------------------------
#-trim to barcodes on forward side -------------------------------------------
#-----------------------------------------------------------------------------

my @ftemp;
my @rtemp;
my @ttemp;
my $seqs_trimmed = 0;
my $barcode_not_found =0;
my $seqs_barcode_f_direction =0;
my @alltags;

open my $FILEA, "< $join_filename_q30_fasta";

while (<$FILEA>)
{
my $lineA = $_; 
$_ = <$FILEA>;
my $lineB = $_;

my $found_barcode =0;
my $posl=-1; 

#printf "\n\n".$lineB."\n";
foreach my $tag (@bacrodes)
        {
#         chomp($tag);
         if ($found_barcode == 0)
           {
              if (index ($lineB, $tag) != -1)
              {
              $found_barcode =1;
              push(@alltags,$tag);
              $posl = index ($lineB, $tag);
              if ($posl > 0) 
                 {
                  $lineB = substr($lineB,$posl);
                  $seqs_trimmed =$seqs_trimmed +1;
                 }
              }
           } else {last;}
        }

if ($found_barcode > 0)
   {
#   $lineA =~ s/-/:/g;$lineA =~ s/ /:/g;
   push (@ftemp, $lineA);
   push (@ftemp, $lineB);
   $found_barcode =0;
   $seqs_barcode_f_direction=$seqs_barcode_f_direction+1;
   }
   else
   {
   $barcode_not_found = $barcode_not_found +1;
   $found_barcode =0;
#  $lineA =~ s/-/:/g;$lineA =~ s/ /:/g;
   push (@ttemp, $lineA);
   push (@ttemp, $lineB);
   }
}
close $FILEA; 

printf "Number of seqeunces trimmed in forward direction:".$seqs_trimmed."\n\n";
printf "Number of sequences without barcode in forward direction:".$barcode_not_found."\n\n";
printf "Number of sequences found with barcode in forward direction:".$seqs_barcode_f_direction."\n\n";
chomp (@ftemp); chomp (@ttemp);

WriteArrayToFile($ResultDirectory."/temp/"."ftemp.fasta",@ftemp);
WriteArrayToFile($ResultDirectory."/temp/"."ttemp.fasta",@ttemp);

#-----------------------------------------------------------------------------
#-lets try the reverse side -------------------------------------------
#-----------------------------------------------------------------------------

my $seqs_barcode_r_direction =0;
$barcode_not_found =0;

my $join_filename_q30_fasta_r = $join_filename_q30.".r.fasta";
#$confstring = "fastx_reverse_complement -i ".$join_filename_q30_fasta." -o ".$join_filename_q30_fasta_r;
$confstring = "fastx_reverse_complement -i ".$ResultDirectory."/temp/ttemp.fasta -o ".$join_filename_q30_fasta_r;
printf $confstring."\n\n";
system ($confstring);

open $FILEA, "< $join_filename_q30_fasta_r";

while (<$FILEA>)
{
my $lineA = $_; 
$_ = <$FILEA>;
my $lineB = $_;

my $found_barcode =0;
my $posl; 

foreach my $tag (@bacrodes)
        {
#         chomp($tag);
         if ($found_barcode == 0)
           {
              if (index ($lineB, $tag) != -1)
              {
              $found_barcode =1;
              push(@alltags,$tag);
              $posl = index ($lineB, $tag);
              if ($posl > 0) 
                 {
                  $lineB = substr($lineB,$posl);
                  $seqs_trimmed =$seqs_trimmed +1;
                 }
              }
           } else {last;}
        }

if ($found_barcode > 0)
   {
   push (@rtemp, $lineA);
   push (@rtemp, $lineB);
   $found_barcode =0;
   $seqs_barcode_r_direction=$seqs_barcode_r_direction+1;
   }
   else
   {
   $barcode_not_found = $barcode_not_found +1;
   $found_barcode =0;
   }
}
close $FILEA; 

printf "Number of seqeunces trimmed in reverse direction:".$seqs_trimmed."\n\n";
printf "Number of sequences without barcode in reverse direction:".$barcode_not_found."\n\n";
printf "Number of sequences found with barcode in reverse direction:".$seqs_barcode_r_direction."\n\n";
chomp (@rtemp);
WriteArrayToFile($ResultDirectory."/temp/"."rtemp.fasta",@rtemp);

#-----------------------------------------------------------------------------
#-create final output file -------------------------------------------
#-----------------------------------------------------------------------------

system ("cat ".$ResultDirectory."/temp/ftemp.fasta ".$ResultDirectory."/temp/rtemp.fasta > ".$ResultDirectory."/".substr($ForwardReads,0,10).".q30.FR.fasta");

#-----------------------------------------------------------------------------
#-cleanup -------------------------------------------
#-----------------------------------------------------------------------------

#system ("rm -rf temp/");






# -------------------------------------------------------------
# Extract your reads and barcodes
# -------------------------------------------------------------


#extract_barcodes.py -f GoM_16S_Sept.fastq -m GoM_Sept_Mapping.txt --attempt_read_reorientation -l 12 -o processed_seqs


# -------------------------------------------------------------
# Split libraries
# -------------------------------------------------------------

#split_libraries_fastq.py -i processed_seqs/reads.fastq -b processed_seqs/barcodes.fastq -m  GoM_Sept_Mapping.txt -o processed_seqs/Split_Output/ --barcode_type 12

# -------------------------------------------------------------
# Pick your OTUs
# -------------------------------------------------------------

#wget http://mgmic.oscer.ou.edu/sequence_data/tutorials/qiime_jamie/qiime_parameters_silva111.par
#pick_de_novo_otus.py -i processed_seqs/Split_Output/seqs.fna -o OTUs_silva -p qiime_parameters_silva111.par

# -------------------------------------------------------------
# remove chimeras
# -------------------------------------------------------------







# -------------------------------------------------------------
# Run QIIME core diversity analysis
# -------------------------------------------------------------


#core_diversity_analyses.py -o cdout_silva/ -i  OTUs_silva/otu_table.biom -m GoM_Sept_Mapping.txt -t OTUs_silva/rep_set.tre -e 20














