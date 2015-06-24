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

# don't need any

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

my $ForwardReads = $ARGV[0];
my $ReverseReads = $ARGV[1];
my $ResultDirectory = $ARGV[2];
if (not defined $ARGV[2] ) {
  $ResultDirectory = cwd();
}


#-----------------------------------------------------------------------------
#--------- Run Ray assmbly K=31                                       --------
#-----------------------------------------------------------------------------

my $system_string = "Ray -k31 -p ".$ResultDirectory."/".$ForwardReads." ".$ResultDirectory."/".$ReverseReads." -o ".$ResultDirectory."/ray_31";
system ($system_string);
#printf("\n\n\n".$system_string."\n\n\n");

# to run this with multiple cores use mpiexec; does not work yet on mgmic; implement later
# mpiexec -n 6 Ray -k31 -p output_forward_paired.fastq output_reverse_paired.fastq -o ray_31/

$system_string = "cp ".$ResultDirectory."/ray_31/Contigs.fasta ".$ResultDirectory."/Contigs.fasta";
system ($system_string);

 
#-----------------------------------------------------------------------------
#--------- Predict ORFs and generate FAA and FNA files                --------
#-----------------------------------------------------------------------------

system("mkdir ".$ResultDirectory."/temp");

$system_string = "prodigal -d ".$ResultDirectory."/temp/temp.orfs.fna -a ".$ResultDirectory."/temp/temp.orfs.faa -i ".$ResultDirectory."/Contigs.fasta -m -o ".$ResultDirectory."/temp/temp.txt -p meta -q";

system ($system_string);

$system_string = "cut -f1 -d \" \" ".$ResultDirectory."/temp/temp.orfs.fna > ".$ResultDirectory."/prodigal.orfs.fna";
system ($system_string);


$system_string = "cut -f1 -d \" \" ".$ResultDirectory."/temp/temp.orfs.faa > ".$ResultDirectory."/prodigal.orfs.faa";
system ($system_string);

#-----------------------------------------------------------------------------
#--------- Cleanup                                                    --------
#-----------------------------------------------------------------------------

system ("rm -rf ".$ResultDirectory."/ray_31");
system ("rm -rf ".$ResultDirectory."/temp");
system ("rm -rf ".$ResultDirectory."/RayOutput");

