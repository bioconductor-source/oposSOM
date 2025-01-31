pipeline.groupSpecificGenesets <- function(env)
{
  sd.thres <- sd( env$samples.GSZ.scores )
  
  for (gr in seq_along(unique(env$group.labels)))
  {
    gs.p.values <- apply(env$samples.GSZ.scores, 1, function(x)
    {
      wilcox.test(x[which(env$group.labels!=unique(env$group.labels)[gr])],
                  x[which(env$group.labels==unique(env$group.labels)[gr])],
                  alternative="less")$p.value
    })

    gs.p.values <- sort(gs.p.values)
    top.gs <- gs.p.values[1:20]

    pdf(paste("Summary Sheets - Groups/Geneset Analysis/Specific GS ",
              make.names(unique(env$group.labels)[gr]),".pdf", sep=""), 21/2.54, 29.7/2.54, useDingbats=FALSE)

    layout(matrix(c(1:8),4, byrow=TRUE), widths=c(3,1))

    for (i in 1:20)
    {
      ylim <- c(-15, 20)
      par(mar=c(3,5,2,1))

      barplot(env$samples.GSZ.scores[names(top.gs)[i],], beside=TRUE, las=2,
              cex.names=1.2, col=env$group.colors, cex.main=1, ylim=ylim,
              border=if (ncol(env$indata) < 80) "black" else NA,
              names.arg=rep("",ncol(env$indata)), cex.axis=1.4)

        abline(h=0,lty=2)
        abline(h=sd.thres*c(-1,1), lty=2, col="gray")
        title(main=names(top.gs)[i], cex.main=1.2, line=1)
        mtext("GSZ", side=2, cex=1.2, line=3)


      n.map <- matrix(0,env$preferences$dim.1stLvlSom,env$preferences$dim.1stLvlSom)
      gs.genes <- unique( env$gene.info$ensembl.mapping[which(env$gene.info$ensembl.mapping$ensembl_gene_id %in% env$gs.def.list[[names(top.gs)[i]]]$Genes),1] )
      gs.nodes <- env$som.result$feature.BMU[gs.genes]
      n.map[as.numeric(names(table(gs.nodes)))] <- table(gs.nodes)
      n.map[which(n.map==0)] <- NA
      n.map <- matrix(n.map, env$preferences$dim.1stLvlSom)

      par(mar=c(5,1,3,1))

      lim <- c(1,env$preferences$dim.1stLvlSom) + env$preferences$dim.1stLvlSom*0.01*c(-1,1)

      plot(which(!is.na(n.map), arr.ind=TRUE), xlim=lim, ylim=lim, pch=16,
            axes=FALSE, xlab="",ylab="", xaxs="i", yaxs="i",
            cex=0.5 + na.omit(as.vector(n.map)) / max(n.map,na.rm=TRUE) * 2.8,
            col=env$color.palette.heatmaps(1000)[(na.omit(as.vector(n.map)) - min(n.map,na.rm=TRUE)) /
                              max(1, (max(n.map,na.rm=TRUE) - min(n.map,na.rm=TRUE))) *
                              999 + 1])

      title(sub=paste("# features =", length(gs.genes),
                      ", max =", max(n.map,na.rm=TRUE)),line=0.5, cex.sub=1.4)

      box()
    }

    dev.off()

    fdr.res <- fdrtool(gs.p.values,statistic="pvalue",plot=FALSE,verbose=FALSE)
    out <- cbind(names(gs.p.values), paste(gs.p.values,"     ."), paste(fdr.res$lfdr,"     ."))
    colnames(out) = c("gene set","p-value","fdr")

    env$csv.function(out, paste("Summary Sheets - Groups/Geneset Analysis/Specific GS ",
                          make.names(unique(env$group.labels)[gr]),".csv", sep=""), row.names=FALSE)
  }
  
  ### detect GS that switch in group specific fashion

  gs.F <- apply(env$samples.GSZ.scores, 1, function(x)
  { 
    summary(aov(x~env$group.labels))[[1]]$'F value'[1]
  }) 
  top.gs <- names(sort(gs.F,decreasing=TRUE)[1:20])
  
  pdf("Summary Sheets - Groups/Geneset Analysis/0verall specific GS.pdf", 21/2.54, 29.7/2.54, useDingbats=FALSE)
  
  layout(matrix(c(1:8),4, byrow=TRUE), widths=c(3,1))
  
  for (i in 1:20)
  {
    ylim <- c(-15, 20)
    par(mar=c(3,5,2,1))
    
    barplot.x = barplot(env$samples.GSZ.scores[top.gs[i],], beside=TRUE, las=2,
            cex.names=1.2, col=env$group.colors, cex.main=1, ylim=ylim,
            border=if (ncol(env$indata) < 80) "black" else NA,
            names.arg=rep("",ncol(env$indata)), cex.axis=1.4)
    
      abline(h=0,lty=2)
      abline(h=sd.thres*c(-1,1), lty=2, col="gray")
      title(main=top.gs[i], cex.main=1.2, line=1)
      mtext("GSZ", side=2, cex=1.2, line=3)
    
      label.string <- tapply( env$samples.GSZ.scores[top.gs[i],], env$group.labels, mean )[unique(env$group.labels)]
      label.string <- as.character(  sign(label.string) * as.numeric( abs(label.string) > sd.thres )  )
      label.string <- sub("-1", "-", label.string, fixed=TRUE)
      label.string <- sub("1", "+", label.string)
      label.string <- sub("0", ".", label.string)
      label.x <- tapply(barplot.x, env$group.labels, mean)[unique(env$group.labels)]
      text(label.x, ylim[2]*0.92, label.string, col=env$groupwise.group.colors,cex=2.5)
    
    n.map <- matrix(0,env$preferences$dim.1stLvlSom,env$preferences$dim.1stLvlSom)
    gs.genes <- unique( env$gene.info$ensembl.mapping[which(env$gene.info$ensembl.mapping$ensembl_gene_id %in% env$gs.def.list[[top.gs[i]]]$Genes),1] )
    gs.nodes <- env$som.result$feature.BMU[gs.genes]
    n.map[as.numeric(names(table(gs.nodes)))] <- table(gs.nodes)
    n.map[which(n.map==0)] <- NA
    n.map <- matrix(n.map, env$preferences$dim.1stLvlSom)
    
    par(mar=c(5,1,3,1))
    
    lim <- c(1,env$preferences$dim.1stLvlSom) + env$preferences$dim.1stLvlSom*0.01*c(-1,1)
    
    plot(which(!is.na(n.map), arr.ind=TRUE), xlim=lim, ylim=lim, pch=16,
         axes=FALSE, xlab="",ylab="", xaxs="i", yaxs="i",
         cex=0.5 + na.omit(as.vector(n.map)) / max(n.map,na.rm=TRUE) * 2.8,
         col=env$color.palette.heatmaps(1000)[(na.omit(as.vector(n.map)) - min(n.map,na.rm=TRUE)) /
                             max(1, (max(n.map,na.rm=TRUE) - min(n.map,na.rm=TRUE))) *
                             999 + 1])
    
    title(sub=paste("# features =", length(gs.genes),
                    ", max =", max(n.map,na.rm=TRUE)),line=0.5, cex.sub=1.4)
    
    box()
  }
  
  dev.off()
  
}
