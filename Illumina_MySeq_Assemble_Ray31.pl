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
my $on_off_switch = $ARGV[3];

if (not defined $ARGV[3] ) {
    $on_off_switch = "on";
#    $on_off_switch = "off";
}

my $runtime_flags = $ARGV[4];


my $system_string;

#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------

if ($on_off_switch eq "on")
{

#-----------------------------------------------------------------------------
#--------- Run Ray assmbly K=31                                       --------
#-----------------------------------------------------------------------------

# $system_string = "Ray -k31 -p ".$ForwardReads." ".$ReverseReads." -o ".$ResultDirectory."/ray_31";
# to run this with multiple cores use mpiexec;

$system_string = "mpiexec -n 6 Ray -k31 -meta -minimum-contig-length 500 -p ".$ForwardReads." ".$ReverseReads." -o ".$ResultDirectory."/ray_31";

#my $system_string = "mpiexec -n 6 Ray -meta -k31 -p ".$ForwardReads." ".$ReverseReads." -o ".$ResultDirectory."/ray_31";

system ($system_string);


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


#------------------------------------------------------------------------------
##--------- Statistics run N50.pl                                      --------
##-----------------------------------------------------------------------------
$system_string = "/opt/local/scripts/bin/N50.pl ".$ResultDirectory."/Contigs.fasta > ".$ResultDirectory."/stats.txt";
system ($system_string);

#-----------------------------------------------------------------------------
#--------- Cleanup                                                    --------
#-----------------------------------------------------------------------------

#system ("rm -rf ".$ResultDirectory."/ray_31");
system ("rm -rf ".$ResultDirectory."/temp");
system ("rm -rf ".$ResultDirectory."/RayOutput");


#-----------------------------------------------------------------------------
# on/off switch
#-----------------------------------------------------------------------------
} 
#end of on/off switch braket

if ($on_off_switch eq "off")
{}



#-----------------------------------------------------------------------------
# running MaxBin-1.4.2
#-----------------------------------------------------------------------------

system ("mkdir ".$ResultDirectory."/maxbin");
system  ("cd ".$ResultDirectory);
system ("mv /tmp /tmp2");

$system_string = "perl /opt/local/software/MaxBin-1.4.2/run_MaxBin.pl -contig ".$ResultDirectory."/Contigs.fasta -reads ".$ForwardReads." -reads ".$ReverseReads." -out ".$ResultDirectory."/maxbin/maxbin";
system($system_string);

system ("mv /tmp2 /tmp");

