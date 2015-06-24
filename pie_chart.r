args <- commandArgs(trailingOnly = TRUE)

file_name = args[1]
output_file = args[2]
tax_level = args[3]

system (paste ("perl /opt/local/scripts/prep_qiime_Ltable.pl ", file_name," temp.txt ", tax_level))
data_file <- read.table("temp.txt",sep="\t", header=TRUE)
system ("rm temp.txt")

png(filename=output_file,width=8,height=5,units="in",res=100)
par(pin=c(8,5))
par(oma=c(0,0,0,0))
# Simple Pie Chart
slices <- as.matrix(data_file[2]) 

lbls <- as.matrix(data_file[1])
pct <- round(slices/sum(slices)*100)
lbls <- paste(pct) # add percents to labels
lbls <- paste(lbls,"%",sep="") # ad % to labels 


#pie(slices, labels = data_file[1], main="Microbial Community Composition")
pie(slices, labels = lbls, col=rainbow(length(lbls)))
legend("topright",c(as.matrix(data_file[1])), cex=0.8,fill=rainbow(length(lbls)))


dev.off()
