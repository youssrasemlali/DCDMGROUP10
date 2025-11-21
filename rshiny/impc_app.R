
install.packages("DBI")
install.packages("RMariaDB")
install.packages("shiny")
install.packages("poltly")
install.packages("tibble")
install.packages("dplyr")
install.packages("shinydashbaord")


# Load libraries
library(DBI)
library(RMariaDB)
library(shiny)
library(dplyr)
library(plotly)
library(tidyr)
library(tibble)
library(shinydashboard)

options(shiny.maxRequestSize = 100*1024^2)

# DATABASE CONNECTION
DCDMSQL <- dbConnect(
  MariaDB(),
  user = "root",
  password = "Monte*cristO13",
  host = "127.0.0.1",
  port = 3306,
  dbname = "IMPC_phenotype_db"
)

# Check connection
print(paste("Connection valid:", dbIsValid(DCDMSQL)))
print("Tables in database:")
print(dbListTables(DCDMSQL))

# LOAD DATA 
IMPC_data <- dbGetQuery(DCDMSQL, 
                        "SELECT 
    pa.analysis_id,
    g.gene_symbol,
    g.gene_accession_id,
    p.parameter_name,
    p.parameterId,
    pa.mouse_strain,
    pa.life_stage,
    pa.pvalue
  FROM phenotype_analyses pa
  INNER JOIN Genes g ON pa.gene_id = g.gene_id
  INNER JOIN Parameters p ON pa.parameter_id = p.parameter_id")

# Disconnect from database
dbDisconnect(DCDMSQL)

# Print confirmation
print(paste("Successfully loaded", nrow(IMPC_data), "rows from database"))

# Mutate the logpvalue for valid results
IMPC_data <- IMPC_data %>%
  mutate(logpvalue = -log10(pvalue), 
         logpvalue = ifelse(
           is.infinite(logpvalue) | 
             is.na(logpvalue), 
           0, 
           logpvalue))

# Produce a numerical matrix for our dataset (pca)
IMPC_matrix <- IMPC_data %>%
  select(gene_symbol, parameter_name, logpvalue) %>%
  pivot_wider(
    names_from = parameter_name,
    values_from = logpvalue,
    values_fn = mean,
    values_fill = 0
  ) %>%
  column_to_rownames("gene_symbol")

# START OF UI
ui <- dashboardPage(skin = "purple",
                    dashboardHeader(title = "IMPC Data Group 10"),
                    
                    dashboardSidebar(
                      sidebarMenu(
                        menuItem("Phenotypic Scores", tabName = "phenoKOgene", icon = icon("atom")),
                        menuItem("Mice Scores", tabName = "micescores", icon = icon("dna")),
                        menuItem("Gene Clusters", tabName = "geneclusters", icon = icon("th"))
                      )
                    ),
                    
                    dashboardBody( 
                      tabItems(
                        tabItem(tabName = "phenoKOgene",
                                h2("Phenotypic Scores for KO Gene"),
                                p("Select a knockout mouse gene and visualise the statistical
scores of all phenotypes tested with the scatter graph. Significant and non-significant -log10 P-values are shown. The red dotted line signifies the significance threshold."),
                                br(),
                                fluidRow(
                                  column(6, selectInput("gene",
                                                        "Select Gene Symbol:",
                                                        choices = sort(unique(IMPC_data$gene_symbol)))),
                                  column(6, h4(textOutput("sigtable1title")),
                                         tableOutput("sigtable"))),
                                br(),
                                plotlyOutput("p1_gene", height = "750px")
                        ),
                        
                        tabItem(tabName = "micescores",
                                h2("All Mice Scores for a Phenotype"),
                                p("Select a phenotype and visualise the
statistical scores of all knockout mice with the scatter graph. Significant and non-significant -log10 P-values are shown. The red dotted line signifies the significance threshold."),
                                br(),
                                fluidRow(
                                  column(6, selectInput("phenotype",
                                                        "Select the Specific Phenotype:",
                                                        choices = sort(unique(IMPC_data$parameter_name)))),
                                  column(6, h4(textOutput("sigtable2title")),
                                         tableOutput("sigtable2"))),
                                br(),
                                plotlyOutput("p2_mouse", height = "750px")
                        ),
                        
                        tabItem(tabName = "geneclusters",
                                h2("Visualising Gene Clusters Based on Similar Phenotype Scores"),
                                p("Select principal components and visualise gene clusters based on their phenotype scores. 
                This PCA plot shows how genes are grouped together with different colours that represent k-means clusters.
                The loading table lists the top ten phenotypes that contribute towards a PC"),
                                br(),
                                fluidRow(
                                  column(4, selectInput("pc_xaxis", "PC X-axis: ", choices = paste0("PC", 1:10), selected = "PC1")),
                                  column(4, selectInput("pc_yaxis", "PC Y-axis: ", choices = paste0("PC", 1:10), selected = "PC2")),
                                  column(4, sliderInput("kclusters", "Number of Clusters: ", min = 2, max = 10, value = 3))
                                ),
                                br(),
                                fluidRow(
                                  column(3, h4(textOutput("loadingtabletitle")),
                                         tableOutput("loadingtable")),
                                  column(9,
                                         plotlyOutput("p3_cluster", height = "750px")))
                        )
                      )
                    )
)

# START OF SERVER
server <- function(input, output) { 
  # 1- Phenotypic Scores for KO Gene
  genedf <- reactive({
    df1 <- IMPC_data %>% filter(gene_symbol == input$gene)
  })
  
  output$p1_gene <- renderPlotly({
    df1 <- genedf()
    
    df1$significant <- factor(df1$pvalue < 0.05,
                              levels = c(FALSE, TRUE),
                              labels = c("Not Significant", "Significant"))
    
    plot_ly(data = df1, 
            x = ~parameter_name,
            y = ~logpvalue,
            type = "scatter",
            mode = "markers",
            marker = list(size = 10),
            color = ~significant,
            hovertemplate = paste(
              "<b>Phenotype:</b> %{x}<br>",
              "<b>P-value:</b> %{text}<br><extra></extra>"
            ),
            text = ~sprintf("%.10f", pvalue)
    ) %>%
      layout(
        title = paste("Phenotypic Scores for:", input$gene),
        yaxis = list(title = "-log10(P-value)"),
        xaxis = list(title = "Phenotype"),
        shapes = list(
          type = "line",
          y0 = -log10(0.05),
          y1 = -log10(0.05),
          x0 = 0,
          x1 = 1,
          yref = "y",
          xref = "paper",
          line = list(color = "red", dash = "dash")
        )
      )
  })
  
  output$sigtable <- renderTable({
    df1 <- genedf()
    df1 %>%
      filter(pvalue < 0.05) %>%
      select(parameter_name, pvalue) %>%
      arrange(pvalue) %>%
      mutate(pvalue = sprintf("%.10f", pvalue))
  })
  
  output$sigtable1title <- renderText({
    paste0("Significant Phenotypes (P-values (10dp) < 0.05) for ", input$gene)
  })
  
  
  # 2 All Mice Scores for a Phenotype
  phenodf <- reactive({
    df2 <- IMPC_data %>% filter(parameter_name == input$phenotype)
  })
  
  output$p2_mouse <- renderPlotly({
    df2 <- phenodf()
    
    df2$significant <- factor(df2$pvalue < 0.05,
                              levels = c(FALSE, TRUE),
                              labels = c("Not Significant", "Significant"))
    
    plot_ly(data = df2, 
            x = ~gene_symbol,
            y = ~logpvalue,
            type = "scatter",
            mode = "markers",
            marker = list(size = 10),
            color = ~significant,
            text = ~paste0(
              "Gene: ", gene_symbol, "<br>",
              "P-value: ", sprintf("%.10f", pvalue)),
            hoverinfo = "text"
    ) %>%
      layout(
        title = paste("All P-Value Scores for the Phenotype:", input$phenotype),
        yaxis = list(title = "-log10(P-value)"),
        xaxis = list(title = "KO Gene"),
        shapes = list(
          list(type = "line",
               y0 = -log10(0.05),
               y1 = -log10(0.05),
               x0 = 0, 
               x1 = 1,
               yref = "y", 
               xref = "paper",
               line = list(color = "red", dash = "dash"))
        )
      )
  })
  
  output$sigtable2 <- renderTable({
    df2 <- phenodf()
    df2 %>%
      filter(pvalue < 0.05) %>%
      select(gene_symbol, pvalue) %>%
      arrange(pvalue) %>%
      mutate(pvalue = sprintf("%.10f", pvalue))
  })
  
  output$sigtable2title <- renderText({
    paste0("Significant KO Genes for ", input$phenotype)
  })
  
  
  # 3 Gene Clusters
  pcadata <- reactive({
    scaled_matrix <- scale(IMPC_matrix, center = TRUE, scale = apply(IMPC_matrix, 2, mad))
    pca <- prcomp(scaled_matrix, center = TRUE, scale. = FALSE)
    pca_scores <- as.data.frame(pca$x[, 1:10])
    
    set.seed(123)
    pca_scores$Cluster <- factor(kmeans(pca_scores[, 1:10], centers = input$kclusters)$cluster)
    
    list(pca = pca, pca_scores = pca_scores)
  })
  
  output$p3_cluster <- renderPlotly({
    df3 <- pcadata()$pca_scores
    pc_x <- input$pc_xaxis
    pc_y <- input$pc_yaxis
    
    var_pc <- summary(pcadata()$pca)$importance["Proportion of Variance", ]
    vx <- paste0(sprintf("%.2f", var_pc[as.numeric(sub("PC", "", pc_x))] * 100), "%")
    vy <- paste0(sprintf("%.2f", var_pc[as.numeric(sub("PC", "", pc_y))] * 100), "%")
    
    plot_ly(df3,
            x = ~get(pc_x),
            y = ~get(pc_y),
            type = "scatter",
            mode = "markers",
            color = ~Cluster,
            marker = list(size = 10),
            text = ~paste0("Gene: ", rownames(df3),
                           "<br>Cluster: ", Cluster,
                           "<br>", pc_x, ": ", sprintf("%.3f", get(pc_x)),
                           "<br>", pc_y, ": ", sprintf("%.3f", get(pc_y))),
            hoverinfo = "text") %>%
      layout(title = paste("PCA of Genes:", pc_x, "vs", pc_y),
             xaxis = list(title = paste0(pc_x, " (", vx, ")")),
             yaxis = list(title = paste0(pc_y, " (", vy, ")")))
  })
  
  output$loadingtable <- renderTable({
    res <- pcadata()
    pc_index <- as.numeric(sub("PC", "", input$pc_xaxis))
    data.frame(Phenotype = rownames(res$pca$rotation),
               Loading = res$pca$rotation[, pc_index]) %>%
      mutate(AbsLoading = abs(Loading)) %>%
      arrange(desc(AbsLoading)) %>%
      head(10) %>%
      select(Phenotype, Loading)
  })
  
  output$loadingtabletitle <- renderText({ 
    paste0("Top Phenotypes that influence ", input$pc_xaxis) 
  })
}

# LAUNCH SHINY APPLICATION 
shinyApp(ui = ui, server = server)


