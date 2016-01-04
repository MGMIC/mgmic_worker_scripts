#!/usr/bin/env perl
use strict;
use warnings;
#--INCLUDE PACKAGES-----------------------------------------------------------
use IO::String;
use File::Basename;
use File::Copy;
use Cwd;
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
# inputs and parameters
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $ReverseReads = $ARGV[1];
#my $database_path = $ARGV[2];
#my $database_path = "/data/DATABASES/16S/SSURef_108_97_candidate_db.udb";
my $database_path = "/data/DATABASES/16S/90_Silva_111_rep_set.udb";
my $ResultDirectory = $ARGV[3];
if (not defined $ARGV[3] ) {
  $ResultDirectory = cwd();
}
my $on_off_switch = $ARGV[4];
if (not defined $ARGV[4] ) {
    $on_off_switch = "on";
#    $on_off_switch = "off";
}
my $runtime_flags = $ARGV[5];

#-----------------------------------------------------------------------------
# DEFAULT RUNTIME PARAMETERS
# we assume that data are MiSeq PE250 as default parameters
#-----------------------------------------------------------------------------

my $min_col = 100;  #default 150
my $id = 0.7;

#-----------------------------------------------------------------------------
# RUNTIME FLAG MANAGEMENT
#-----------------------------------------------------------------------------

#my @rf1 = @{(parse_flags($runtime_flags))[0]};
#my @rf2 = @{(parse_flags($runtime_flags))[1]};

#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------

if ($on_off_switch eq "on")
{


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
#system($confstring);

$confstring = "sh /opt/local/scripts/bin/install_usearch.sh";  
system($confstring);

#-----------------------------------------------------------------------------
# run usearch search
#-----------------------------------------------------------------------------

mkdir($ResultDirectory."/temp");

#-----------------------------------------------------------------------------
#------create fasta files-----------------------------------------------------
#-----------------------------------------------------------------------------

#system ("read_fastq -i ".$ForwardReads." -e base_33 | write_fasta -o ".$ResultDirectory."/temp/fr.fasta -x");
#system ("read_fastq -i ".$ReverseReads." -e base_33 | write_fasta -o ".$ResultDirectory."/temp/rr.fasta -x");

$ForwardReads =~ s/.fastq/.fasta/g;
$ReverseReads =~ s/.fastq/.fasta/g;

system ("cp ".$ForwardReads." ".$ResultDirectory."/temp/fr.fasta");
system ("cp ".$ReverseReads." ".$ResultDirectory."/temp/rr.fasta");

#-----------------------------------------------------------------------------
#------run usearch commands----------------------------------------------------
#-----------------------------------------------------------------------------

$confstring = "usearch8 -usearch_global ".$ResultDirectory."/temp/fr.fasta -db ".$database_path." -id ".$id." -qsegout ".$ResultDirectory."/temp/f_hits.fasta -strand both -mincols ".$min_col." -maxhits 1 -blast6out ".$ResultDirectory."/temp/f_hits.txt";
printf($confstring."\n\n");
system ($confstring);

$confstring = "usearch8 -usearch_global ".$ResultDirectory."/temp/rr.fasta -db ".$database_path." -id ".$id." -qsegout ".$ResultDirectory."/temp/r_hits.fasta -strand both -mincols ".$min_col." -maxhits 1 -blast6out ".$ResultDirectory."/temp/r_hits.txt";
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


#-----------------------------------------------------------------------------
# extract whole reads, not just matching portions
# I'm not sure I need this part. It seems like the matching does just fine.
#-----------------------------------------------------------------------------

#my $system_string;
#$system_string = "cut -d \\t ".$ResultDirectory."/temp/f_hits.txt -f2 | awk '{print \$1}' \> ".$ResultDirectory."/temp/f_h.txt";
#system ($system_string);

#$system_string = "cut -d \\t ".$ResultDirectory."/temp/r_hits.txt -f2 | awk '{print \$1}' \> ".$ResultDirectory."/temp/r_h.txt";
#system ($system_string);

#$ReverseReads =~ s/.fastq/.fasta/g;
#$ForwardReads =~ s/.fastq/.fasta/g;

#$system_string = "grep -A 1 -f ".$ResultDirectory."/temp/f_h.txt ".$ForwardReads." > ".$ResultDirectory."/temp/f_h.fas";
#system ($system_string);
#$system_string = "grep -A 1 -f ".$ResultDirectory."/temp/r_h.txt ".$ReverseReads." > ".$ResultDirectory."/temp/r_h.fas";
#system ($system_string);

#$system_string = "sed '/--/d' ".$ResultDirectory."/temp/f_h.fas > ".$ResultDirectory."/temp/f_h.fasta";
#system ($system_string);
#$system_string = "sed '/--/d' ".$ResultDirectory."/temp/r_h.fas > ".$ResultDirectory."/temp/r_h.fasta";
#system ($system_string);

#$system_string = "cat ".$ResultDirectory."/temp/f_h.fasta ".$ResultDirectory."/temp/r_h.fasta > ".$ResultDirectory."/16S_fr_whole_reads.fasta";
#system ($system_string);

#$system_string = "rm ".$ResultDirectory."/*.fas";
#$system_string = "rm ".$ResultDirectory."/*.txt";


#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------
} 
#end of on switch braket

if ($on_off_switch eq "off")
{}

















