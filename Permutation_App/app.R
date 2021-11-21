# Author: Daniele Scanzi
# Date: 14/11/2021
# Github: https://github.com/d-scanzi

# Set up Environment
library(shiny)
library(ggplot2)
library(ggthemr)
library(ggdist)
library(tidyverse)
library(ggdist)
library(gghalves)

options(scipen = 999)

palette <- define_palette(
    swatch = c('#111111', '#E84646', '#233B43', '#C29365', '#168E7F', '#65ADC2', '#109B37', '#DB784D'),
    gradient = c(lower = '#E84646', upper = '#109B37'))
ggthemr(palette, layout = 'scientific')


# Define UI for application that draws a histogram
ui <- fluidPage(
    titlePanel('Comparing two groups means with Permutations'),
    p('The app computes the permutations by randomly sampling without replacement the values from the two distributions. 
    This corresponds to shuffling the values. Then it reassigns the shuffled values to the two groups, accounting for the size of each group. 
    Finally, it computes the difference in means between the groups. This is repeated for the number of reiterations specified.'),
    p('The p-value is defined as the proportion of permuted differences greater than the absolute value of the original (observed) difference or below its opposite.'),
    
    #Permutation Plot
    fluidRow(
        column(2,
               numericInput('nperm', label = '# Permutations',
                            value = 1000, 
                            min = 1, 
                            max = 5000),
               actionButton('sample',
                            label = 'Permute'),
               textOutput('permt'),
               textOutput('ttest')),
        column(10,
               plotOutput('permPlot'))),
    
    # Single groups plots
    fluidRow(
        h4('Groups Distributions'),
        column(6,
               plotOutput('plot1')),
        column(6,
               plotOutput('plot2'))),
    fluidRow(
        column(6,
               wellPanel(sliderInput('sampleSize1',
                                     label = 'Sample Size Group 1',
                                     min   = 1,
                                     max   = 100,
                                     value = 30),
                         numericInput('mu1',
                                      label = 'mean',
                                      value = 10,
                                      min = -Inf,
                                      max = Inf),
                         numericInput('sd1',
                                      label = 'Standard Deviation',
                                      value = 15,
                                      min = -Inf,
                                      max = Inf))),
        column(6,
               wellPanel(
                   sliderInput('sampleSize2',
                               label = 'Sample Size Group 2',
                               min   = 1,
                               max   = 100,
                               value = 30),
                   numericInput('mu2',
                                label = 'mean',
                                value = 8,
                                min = -Inf,
                                max = Inf),
                   numericInput('sd2',
                                label = 'Standard deviation',
                                value = 27,
                                min = -Inf,
                                max = Inf))))
                         
                             
)


# Define server logic required to draw a histogram
server <- function(input, output) {
    
    ## Define parameters for plotting groups distributions
    
    dist1 <- reactive({rnorm(n = input$sampleSize1, mean = input$mu1, sd = input$sd1)})
    dist2 <- reactive({rnorm(n = input$sampleSize2, mean = input$mu2, sd = input$sd2)})
    
    data.all <- reactive({data.frame(values = c(dist1(), dist2()),
                            group = c(rep('group1', input$sampleSize1),
                                      rep('group2', input$sampleSize2)))})

    
    # Plot distributions
    output$plot1 <- renderPlot({
        
        data.plot <- data.all()
        
        ggplot(data = data.plot, aes(x = group, 
                                     y = values,
                                     fill = group)) +
            ggdist::stat_halfeye(adjust = .5,
                                 width = .6, 
                                 justification = -.2,
                                 .width = 0,
                                 point_colour = NA) +
            geom_boxplot(width = .12, 
                         outlier.colour = NA) +
            gghalves::geom_half_point(mapping = aes(colour = group),
                                      side = 'l',
                                      range_scale = .4,
                                      alpha = 0.6,
                                      size = 2) +
            scale_colour_ggthemr_d()
        })
    
    # Plot means
    output$plot2 <- renderPlot({
        
        data.plot <- data.all()
        ggplot(data = data.plot, aes(sample = values, colour = group)) +
            stat_qq() +
            stat_qq_line() +
            facet_grid(~group)
    })
    
    ## Permutations
    
    # Define function that compute permutations
    computePerm <- function(data, np, size1, size2){
        
        result <- vector(mode = 'list', length = size1+size2)
        
        for(n in 1:np){
            
            newperm <- sample(data$values) %>% 
                split(rep(c('group1', 'group2'), c(size1, size2)))
            
            result[[n]]  <- mean(newperm[['group1']]) - mean(newperm[['group2']])
            }
        
        result <- unlist(result, use.names = FALSE)
        return(result)
    }
    
    # Permute when button is pressed
    permutations <- eventReactive(input$sample, computePerm(data.all(), input$nperm, input$sampleSize1, input$sampleSize2))
    

    # Plot Permutations
    output$permPlot <- renderPlot({
        
        #data.perm <- data.all()
        
        # Compute t value of data
        data.diff <- abs(mean(dist1()) - mean(dist2()))
        proportion <- (sum(permutations() >= data.diff) +  sum(permutations() <= -data.diff)) / input$nperm #two-tailed
        
        ## Display results
        toPlot <- data.frame(values = permutations())
        
        ggplot(data = toPlot, aes(x = values)) +
            geom_histogram(binwidth = .2,
                           fill = palette[['swatch']][4],
                           colour = palette[['swatch']][4],
                           alpha = .8) +
            geom_histogram(data = toPlot %>% filter(values >= data.diff | values <= -data.diff),
                           binwidth = .2, 
                           colour = palette[['swatch']][5],
                           fill= palette[['swatch']][5]) +
            annotate(geom = 'text', x = data.diff + 2, y = 6, label = paste('P-value \n', proportion), colour = 'black', size = 5)
        
        
        })
            
    output$permt <- renderText({
        
        # Compute t value of data
        data.diff <- abs(mean(dist1()) - mean(dist2()))
        proportion <- (sum(permutations() >= data.diff) +  sum(permutations() <= -data.diff)) / input$nperm #two-tailed
        paste('Permutation p-value: ', proportion)    
            
    })  
    
    output$ttest <- renderText({
        
        # Compute classic t-value
        t <- t.test(dist1(), dist2())$p.value
        paste('t test p-value: ', round(t, digits = 3))
    })
}

# Run the application 
shinyApp(ui = ui, server = server, options = list(width = '100%', display.mode = 'showcase'))
