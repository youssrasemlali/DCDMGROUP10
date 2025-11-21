#MAIN DASHBOARD


########SQL CONNECT######
#reads a mysqltable into rshiny app
#DCDM_SQL<- dbConnect(RMySQL::MySQL(), 
                     #username = "my_username", 
                     #password = "my_password", 
                     #host     = "host_address", 
                     #port     = 3306,
                     #dbname   = 'IMPC_phenotype_db')

#load data
#df <- dbGetQuery(DCDM_SQL, 'table_name') #reads as a data.frame




######shinydashboard#######

#library 
library(shiny)
library(dplyr)
library(plotly)
library(tidyr)
library(tibble)
library(shinydashboard) #for our dashboard

#set rshiny size
options(shiny.maxRequestSize = 100*1024^2)

#DATA IMPORTATION & NEEDED MUTATION (check if needed with SQL#

#load data 
IMPC_data <- read.csv("C:/Users/sarah/OneDrive/Desktop/KCL/DCDM/GROUP WORK 10/Group10/Group10/IMPC_cleaned_data.csv", 
                      stringsAsFactors = FALSE)

#mutate the logpvalue for valid results
#negative log transformation of pvalue for better visualisation of smaller p-values (stat sig)  
#replaces infinite or missing values with 0 as pca graph would error
IMPC_data <- IMPC_data %>%
  mutate(logpvalue = -log10(pvalue), 
         logpvalue = ifelse(
           is.infinite(logpvalue) | #| = or
             is.na(logpvalue), 
           0, 
           logpvalue))

#produce a numerical matrix for our dataset (pca)
#reshape wide matrix so parameter_name will be the columns with the pvalues
IMPC_matrix <- IMPC_data %>%
  select(gene_symbol, parameter_name, logpvalue) %>% #selecting what is in our matrix
  pivot_wider(
        names_from = parameter_name, #our columns
        values_from = logpvalue, #our values
        values_fn = mean, #makes sure each gene has one value per phenotype for when a gene has more than one value for the same phenotype
        values_fill = 0 #fill in with 0 when gene doesnt have an effect on a phenotype 
        ) %>%
  column_to_rownames("gene_symbol") #to represent genes 



#start of our UI - visuals and layouts
#shinydashboard
ui <- dashboardPage(
  dashboardHeader(title = "IMPC Data Group 10"),
  
  #created a sidebar that you can click on the different graphs 
  dashboardSidebar(
    sidebarMenu(
      menuItem("Phenotypic Scores", tabName = "phenoKOgene", icon =icon("dashboard")),
      menuItem("Mice Scores", tabName = "micescores", icon =icon("dashboard")),
      menuItem("Gene Clusters", tabName = "geneclusters", icon =icon("dashboard"))
    )
  ),
  
  #organise inside content
  dashboardBody(
    tabItems(
        #tab for Phenotypic Scores for KO Gene
      tabItem(tabName = "phenoKOgene", #to link to the menuItem
              h2("Phenotypic Scores for KO Gene"), #header
              p("Select a knockout mouse gene and visualise the statistical
scores of all phenotypes tested with the scatter graph. Significant and non-significant -log10 P-values are shown. The red dotted line signifies the significance threshold. "),
              #dropdown for ko gene selection
              fluidRow(
                column(6,selectInput("gene",
                          "Select Gene Symbol:",
                          choices = sort(unique(IMPC_data$gene_symbol)))),
              #our significant table 
                column(6,h4(textOutput("sigtable1title")),
                       tableOutput("sigtable"))),
              #our first plot 
                plotlyOutput("p1_gene", height ="750px")
        ),
      
      tabItem(tabName = "micescores", #to link to the menuItem
              h2("All Mice Scores for a Phenotype"), #header
              p("Select a phenotype and visualise the
statistical scores of all knockout mice with the scatter graph. Significant and non-significant -log10 P-values are shown. The red dotted line signifies the significance threshold."),
              #dropdown for ko gene selection
              fluidRow(
                column(6, selectInput("phenotype",
                          "Select the Specfic Phenotype:",
                          choices = sort(unique(IMPC_data$parameter_name)))),
              #our significant table 
                column(6,h4(textOutput("sigtable2title")),
              tableOutput("sigtable2"))),
              #our second plot 
              plotlyOutput("p2_mouse", height ="750px")
              ),
      tabItem(tabName = "geneclusters",
              h2("Visualising Gene Clusters Based on Similar Phenotype Scores"),
              p("Select principal components and visualise gene clusters based on their phenotype scores. 
                This PCA plot shows how genes are grouped together with different colours that represent k-means clusters.
                The loading table lists the top ten phenotypes that contribute towards a PC"),
              fluidRow(
                column(4, selectInput("pc_xaxis", "PC X-axis: ", choices = paste0("PC", 1:10), selected = "PC1")),
                column(4, selectInput("pc_yaxis", "PC Y-axis: ", choices = paste0("PC", 1:10), selected = "PC2")),
                column(4, sliderInput("kclusters", "Number of Clusters: ", min = 2, max = 10, value = 3))
              ),
              fluidRow(
                column(3,h4(textOutput("loadingtabletitle")),
              tableOutput("loadingtable")),
              column(9,
              plotlyOutput("p3_cluster", height ="750px")))
      )
    )
  )
)
#end of UI

#start of server
server <- function(input, output) { 
  # 1- Phenotypic Scores for KO Gene
  #reactive - reruns the code based on input (gene KO chosen)
  genedf <- reactive({
    df1 <- IMPC_data %>% filter(gene_symbol == input$gene)
  })
  
  #generating an interactive scatter plot 
  output$p1_gene <- renderPlotly({
    df1 <- genedf() #gets the dataframe from the input
    
    #defines the significant pvalues
    df1$significant <- factor(df1$pvalue < 0.05,
                             levels = c(FALSE,TRUE),
                             labels = c("Not Significant","Significant"))
    
    #plotting the graph 
    plot_ly(data = df1, 
            x = ~parameter_name,
            y = ~logpvalue,
            type = "scatter", #scatter plot
            mode = "markers", #datapoints as markers
            marker = list(size = 10),
            color = ~significant, #2 colours for Not/Signficant
            #hover- what it shows when user hovers over a point
            hovertemplate = paste(
              "<b>Phenotype:</b> %{x}<br>",
              "<b>P-value:</b> %{text}<br><extra></extra>"
            ),
            #text to be inserted into hover
            text = ~sprintf("%.10f", pvalue) #%.10f defines 10dp, sprintf combines text and variable format
    ) %>%
      layout(
        title = paste("Phenotypic Scores for:", input$gene),
        yaxis = list(title = "-log10(P-value)"),
        xaxis = list(title = "Phenotype"),
        #shapes inserts our red dashed line to see the significance threshold
        shapes =
          list(type = "line",
               y0 = -log10(0.05), #start of y coordinate
               y1 = -log10(0.05), #end of y coordinate 
               #our x axis is categorical (phenotypes) so no data values
               x0 = 0, #left edge of x axis
               x1 = 1, #right edge of x axis
               yref = "y", #start the horizontal line at -log10(0.05)
               xref = "paper",# makes the line span across whole x axis/plot
               line = list(color = "red", dash = "dash"))
      )
  })
  
  # create our significance table
  output$sigtable <- renderTable({
    df1 <- genedf() #retrieves the selected KO gene
    df1 %>%
      filter(pvalue < 0.05) %>% #only keeps significant values
      select(parameter_name, pvalue) %>% #our table headers
      arrange(pvalue) %>% #sort based on most signficant at the top 
      mutate(pvalue = sprintf("%.10f", pvalue)) #format pvalue to 10dp
  })
  
  output$sigtable1title <-renderText({paste0("Significant Phenotypes (P-values (10dp) < 0.05) ",input$gene_symbol)})
  
  
  #2 All Mice Scores for a Phenotype
  #reactive - reruns the code based on input (parameterchosen)
  phenodf <- reactive({
    df2 <- IMPC_data %>% filter(parameter_name == input$phenotype)
  })
  
  #generating an interactive scatter plot 
  output$p2_mouse <- renderPlotly({
    df2 <- phenodf() #gets the dataframe from the input
    
    
    df2$significant <- factor(df2$pvalue < 0.05,
                              levels = c(FALSE,TRUE),
                              labels = c("Not Significant","Significant"))
    
    plot_ly(data = df2, 
            x = ~gene_symbol,
            y = ~logpvalue,
            type = "scatter", #scatter plot
            mode = "markers", #datapoints as markers
            marker = list(size = 10),
            color = ~significant, #2 colours for Not/Signficant
            #hover- what it shows when user hovers over a point
            text =~paste0(
              "Gene: ", gene_symbol,"<br>",
              "P-value: ", sprintf("%.10f", pvalue)), #%.10f defines 10dp, sprintf combines text and variable format
            #text to be inserted into hover
            hoverinfo = "text"
    ) %>%
      layout(
        title = paste("All P-Value Scores for the Phenotype:", input$phenotype),
        yaxis = list(title = "-log10(P-value)"),
        xaxis = list(title = "KO Gene"),
        #shapes inserts our red dashed line to see the significance threshold
        shapes = list(
          list(type = "line",
               y0 = -log10(0.05), #axis 
               y1 = -log10(0.05),
               x0 = 0, 
               x1 = 1,
               yref = "y", 
               xref = "paper",
               line = list(color = "red", dash = "dash"))
        )
      )
  })
  # create our significance table
  output$sigtable2 <- renderTable({
    df2 <- phenodf() #retrieves the selected KO gene
    df2 %>%
      filter(pvalue < 0.05) %>% #only keeps significant values
      select(gene_symbol, pvalue) %>% #our table headers
      arrange(pvalue) %>% #sort based on most signficant at the top 
      mutate(pvalue = sprintf("%.10f", pvalue)) #format pvalue to 10dp
  })
  
  output$sigtable2title <-renderText({paste0("Significant KO Genes for ",input$phenotype)})
  
  
  #3 Gene Clusters
  #reactive - reruns the code based on input (number of clusters, PCA, kmeans)
  pcadata <- reactive({
    
    #scale the matrix to reduce biased clusters in the PCA
    #all phenotypes can equally contribute to the PCA
    scaled_matrix <- scale(IMPC_matrix, center = TRUE, scale = apply(IMPC_matrix, 2, mad))#mean absolute deviation 
    #principal componenet anlysis on our scaled matrix
    #making sure each column has mean 0 before PCA 
    pca <- prcomp(scaled_matrix, center = TRUE, scale. = FALSE)#False as we previously scaled with MAD
   
    pca_scores <- as.data.frame(pca$x[,1:10]) #PCA scores for first 10 pcs
    
    #k-means clustering
    #ensures reproducibility, no random cluster start
    #new column in pca_scores and converts into factor for plotting colours
    set.seed(123)
    pca_scores$Cluster <- factor(kmeans(pca_scores[,1:10], centers = input$kclusters)$cluster)
    
    list(pca = pca, pca_scores = pca_scores)
  })
  
  #generating our cluster plot
  output$p3_cluster <- renderPlotly({
    df3 <- pcadata()$pca_scores #retrieves inputs
    pc_x <- input$pc_xaxis
    pc_y <- input$pc_yaxis
    
    
    #how much total variability is in each PC
    # uses the proportion of variance row name inside the pca summary to display on pca axis
    var_pc <- summary(pcadata()$pca)$importance["Proportion of Variance",]
    vx <- paste0(sprintf("%.2f", var_pc[as.numeric(sub("PC","",pc_x))]*100), "%")
    vy <- paste0(sprintf("%.2f", var_pc[as.numeric(sub("PC","",pc_y))]*100), "%")
    
    plot_ly(df3,
            x = ~get(pc_x),
            y = ~get(pc_y),
            type = "scatter",
            mode = "markers",
            color = ~Cluster,
            marker = list(size = 10),
            #hover- what it shows when user hovers over a point
            text = ~paste0("Gene: ", rownames(df),
                           "<br>Cluster: ", Cluster,
                           "<br>", pc_x, ": ", sprintf("%.3f", get(pc_x)),
                           "<br>", pc_y, ": ", sprintf("%.3f", get(pc_y))),
            #text to be inserted into hover
            hoverinfo = "text") %>%
      layout(title = paste("PCA of Genes: ", pc_x, "vs", pc_y),
             xaxis = list(title = paste0(pc_x, " (", vx, ")")),
             yaxis = list(title = paste0(pc_y, " (", vy, ")")))
  })
  
  #create our PCA loading table that tells the top 10 phenotypes contributing to the PC
  
  output$loadingtable <- renderTable({
    res <- pcadata()
    pc_index <- as.numeric(sub("PC","", input$pc_xaxis))
    data.frame(Phenotype = rownames(res$pca$rotation),
               Loading = res$pca$rotation[, pc_index]) %>%
      mutate(AbsLoading = abs(Loading)) %>%
      arrange(desc(AbsLoading)) %>%
      head(10) %>%
      select(Phenotype, Loading)
  })
  
  output$loadingtabletitle <- renderText({ paste0("Top Phenotypes that influence ", input$pc_xaxis) })
  
}
  
  
#end of server

#launch Shiny application 
shinyApp(ui = ui, server = server)




