#!/usr/bin/env perl
use strict;
use warnings;
#--INCLUDE PACKAGES-----------------------------------------------------------
use IO::String;
use File::Basename;
use File::Copy;
use Cwd;
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#----------------------------MAXBIN ANALYSIS TO BIN GENOMES-------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#----SUBROUTINES--------------------------------------------------------------
#-----------------------------------------------------------------------------

#put necessary subruoutines here

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

#input files
#arg[0] = "Contigs.fasta"" from the assembly_ray folder
#arg[1] = "prodigal.orfs.faa" from the assembly_ray folder
#arg[2] = "prodigal.orfs.fna" from the assembly_ray folder
#arg[3] = "F.QCed.fastq"
#arg[4] = "R.QCed.fastq"
#arg[5] = working direcotory

my $assembly = $ARGV[0];
my $predicted_proteins = $ARGV[1];
my $predicted_genes = $ARGV[2];
my $ForwardReads = $ARGV[3];
my $ReverseReads = $ARGV[4];

my $ResultDirectory = $ARGV[5];
if (not defined $ARGV[5] ) {
  $ResultDirectory = cwd();
}

my $on_off_switch = $ARGV[6];
if (not defined $ARGV[6] ) {
    $on_off_switch = "on";
#    $on_off_switch = "off";
}

my $runtime_flags = $ARGV[7];


#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------

if ($on_off_switch eq "on")
{


#-----------------------------------------------------------------------------
#--------- main loop                                                  --------
#-----------------------------------------------------------------------------

my $system_string;

$system_string = "perl /opt/local/software/MaxBin-1.4.2/run_MaxBin.pl -contig ".$ResultDirectory."/assemble_ray/Contigs.fasta -reads ".$ResultDirectory."/F.QCed.fasta "." -reads ".$ResultDirectory."/R.QCed.fasta -out ".$ResultDirectory."/maxbin_output";

system($system_string);



#-----------------------------------------------------------------------------
# on/off switch end
#-----------------------------------------------------------------------------

}

#-----------------------------------------------------------------------------
#--------- Cleanup                                                    --------
#-----------------------------------------------------------------------------


#system ("rm -rf ".$ResultDirectory."/temp");

