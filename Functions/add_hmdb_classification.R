library(tidyverse)
add_hmdb_classification <- function(data, n_class = 6, classtokeep = "Other"){
  hmdb_class <- './Datasets/Metabolites_hmdb_classification4.csv' |> 
    read_csv()
  hmdb_class$feature <- make.names(hmdb_class$Feature)
  data <- data |> left_join(hmdb_class |> select(feature,Feature, Final_Class)) |> select(-feature)
  
  classcount <- data |> dplyr::count(Final_Class)
  keepclass <- slice_max(classcount, n=n_class, order_by=n)
  more_class <- classcount$Final_Class[grepl(classtokeep, classcount$Final_Class)]
  replace_na(more_class,classcount$Final_Class[1])
  
  data <- data |> 
    mutate(Final_Class2 = ifelse(Final_Class %in% keepclass$Final_Class, Final_Class, "Other")) |> 
    mutate(Final_Class2 = ifelse(Final_Class %in% more_class, Final_Class,Final_Class2))
  
  data$Final_Class3 <- data$Final_Class2 |> str_replace("_", ": ") |> 
    str_replace(": H", ":\nH") |> 
    str_replace(": P", ":\nP") |> 
    str_replace(": C", ":\nC")
  
  return(data)
}
  
hmdb_palette <- function(data) {
  myPalette0 <- "./Datasets/Classes_counts4.csv" |> read_csv()
  
  myPalette0 <- myPalette0 |> 
    rename(Final_Class2 = colnames(myPalette0)[grepl("Final_Class",colnames(myPalette0))])
  myPalette1 <- myPalette0 |> inner_join(data |> select(Final_Class2, Final_Class3) |> unique())
  
  myPalette <- myPalette1$Color
  names(myPalette) <- myPalette1$Final_Class3
  
  return(myPalette)
}
  
  
