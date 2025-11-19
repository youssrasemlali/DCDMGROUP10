#MAIN DASHBOARD


#library 
library(shiny)
library(dplyr)
library(shinydashboard) #for our dashboard


#set rshiny size
options(shiny.maxRequestSize = 100*1024^2)

#load data 
IMPC_data <- read.csv("C:/Users/sarah/OneDrive/Desktop/KCL/DCDM/GROUP WORK 10/Group10/Group10/IMPC_cleaned_data.csv", 
                      stringsAsFactors = FALSE)

#negative log transformation of pvalue for better visualisation  
IMPC_data$logpvalue <- -log10(IMPC_data$pvalue)

#start of our UI - visuals and layout 
ui <- dashboardPage(
  dashboardHeader(title = "IMPC Data Group 10"),
  
  #created a sidebar that you can click on the different graphs 
  dashboardSidebar(
    sidebarMenu(
      menuItem("Phenotypic Scores for KO Gene", tabName = "phenoKOgene", icon =icon("dashboard")),
      menuItem("All Mice Scores for a Phenotype", tabName = "2 Scores of All Mice for a Selected Phenotype", icon =icon("dashboard")),
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
    df <- IMPC_data %>% filter(gene_symbol == input$gene)
  })
  
  #generating an interactive scatter plot 
  output$p1_gene <- renderPlotly({
    df <- genedf() #gets the dataframe from the input
    
    #defines the significant pvalues
    df$significant <- factor(df$pvalue < 0.05,
                             levels = c(FALSE,TRUE),
                             labels = c("Not Significant","Significant"))
    
    #plotting the graph 
    plot_ly(data = df, 
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
