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
library(shinydashboard) #for our dashboard


#set rshiny size
options(shiny.maxRequestSize = 100*1024^2)

#load data 
IMPC_data <- read.csv("C:/Users/sarah/OneDrive/Desktop/KCL/DCDM/GROUP WORK 10/Group10/Group10/IMPC_cleaned_data.csv", 
                      stringsAsFactors = FALSE)

#negative log transformation of pvalue for better visualisation of smaller p-values (stat sig)  
IMPC_data$logpvalue <- -log10(IMPC_data$pvalue)

#start of our UI - visuals and layouts
#shinydashboard
ui <- dashboardPage(
  dashboardHeader(title = "IMPC Data Group 10"),
  
  #created a sidebar that you can click on the different graphs 
  dashboardSidebar(
    sidebarMenu(
      menuItem("Phenotypic Scores for KO Gene", tabName = "phenoKOgene", icon =icon("dashboard")),
      menuItem("All Mice Scores for a Phenotype", tabName = "micescores", icon =icon("dashboard")),
      menuItem("Gene Clusters", tabName = "3 Gene Clusters", icon =icon("dashboard"))
    )
  ),
  
  #organise inside content
  dashboardBody(
    tabItems(
        #tab for Phenotypic Scores for KO Gene
      tabItem(tabName = "phenoKOgene", #to link to the menuItem
              h2("Phenotypic Scores for KO Gene"), #header
              #dropdown for ko gene selection
              selectInput("gene",
                          "Select Gene Symbol:",
                          choices = sort(unique(IMPC_data$gene_symbol))),
              #our significant table 
                tableOutput("sigtable"),
              #our first plot 
                plotlyOutput("p1_gene", height ="750px")
        ),
      
      tabItem(tabName = "micescores", #to link to the menuItem
              h2("All Mice Scores for a Phenotype"), #header
              #dropdown for ko gene selection
              selectInput("phenotype",
                          "Select the Specfic Phenotype:",
                          choices = sort(unique(IMPC_data$parameter_name))),
              #our significant table 
              tableOutput("sigtable2"),
              #our second plot 
              plotlyOutput("p2_mouse", height ="750px"))
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
  },
  caption = "Significant Phenotypes (P-values (10dp) < 0.05)",
  caption.placement = "top",
  align = 'lr')#left to right: parameter_name then pvalue order in columns
  
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
      select(gene_symbol,parameter_name, pvalue) %>% #our table headers
      arrange(pvalue) %>% #sort based on most signficant at the top 
      mutate(pvalue = sprintf("%.10f", pvalue)) #format pvalue to 10dp
  },
  caption = "Significant KO Genes(P-values (10dp) < 0.05)",
  caption.placement = "top",
  align = 'l')#left to right
  
  
  
  
  
  }
#end of server

#launch Shiny application 
shinyApp(ui = ui, server = server)

               xref = "paper",# makes the line span across whole x axis/plot
               line = list(color = "red", dash = "dash"))
      )
  })
  
  # create our significance table
  output$sigtable <- renderTable({
    df <- genedf() #retrieves the selected KO gene
    df %>%
      filter(pvalue < 0.05) %>% #only keeps significant values
      select(parameter_name, pvalue) %>% #our table headers
      arrange(pvalue) %>% #sort based on most signficant at the top 
      mutate(pvalue = sprintf("%.10f", pvalue)) #format pvalue to 10dp
  },
  caption = "Significant Phenotypes (P-values (10dp) < 0.05)",
  caption.placement = "top",
  align = 'lr')#left to right: parameter_name then pvalue order in columns
  
  }
#end of server

#launch Shiny application 
shinyApp(ui = ui, server = server)

