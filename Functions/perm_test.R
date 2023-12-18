library(tidyverse)

perm_test = function(data, perm_num = 9999)
{
  x = data |> filter(intrapn == 'Same subject') |> select(coral)
  y = data |> filter(intrapn == 'Different subjects')|> select(coral)
  
  res = list()
  x=x[!is.na(x)]
  y=y[!is.na(y)]
  
  xy_rank = rank(c(x,y))
  x = xy_rank[1:length(x)]
  y = xy_rank[ (length(x)+1):length(xy_rank) ]
  diff = abs(mean(x)-mean(y))
  
  count=0
  for ( i in 1:perm_num  )
  {
    perm_xy = sample( c( x,y) )
    perm_x = perm_xy[1:length(x)]
    perm_y = perm_xy[ (length(x)+1):length(perm_xy) ]
    perm_diff = abs(mean(perm_x)-mean(perm_y))
    if ( perm_diff >= diff)
      count = count+1
  }
  
  res$p.value = (count+1)/(perm_num+1)
  return(res)
}