## app.R ##
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)

jumia=read.csv("C:/Users/User/Documents/Mulei/Udemy Learning/R/Projects/Jumia-Web-Scraping-RStudio/data/jumia_data.csv")
ui <- dashboardPage(
  
  # Dash Board title
  dashboardHeader(title = "Jumia WebScraping"),
  
  # Slider panel configuration
  dashboardSidebar(
    sidebarMenu(
      menuItem("Jumia Website", tabName = "dashboard", icon = icon("dashboard")),
      #menuItem(textInput("text", "Url Input")),
      menuItem("Data", icon = icon("th"), tabName = "data"),
      menuItem("Charts", icon = icon("line-chart"), tabName = "charts")
    )
  ),# end of sidebar
  
  # Body
  dashboardBody(
    # Boxes need to be put in a row (or column)
    tabItems(
      # website tab
      tabItem(tabName = "dashboard",  h2("Jumia Website"),
              fluidRow(
                    box(title = "Embedded Website",
                        width = 12,
                        height = "30px",
                        solidHeader = TRUE,
                        collapsible = TRUE,
                        uiOutput("tab")
                        ) )
            ), #end of 1-st tab item
      
      # data tab
      tabItem(tabName = "data", h2("Scraped Data Table"),
              fluidRow(
                # Display text
                box( title = "Table Information",
                     verbatimTextOutput("table_info"),
                    width=12),
                
                #price slider
                box(title = "Table Filters",
                    sliderInput("price_slider", "Price Range", 
                                min=0, max=max(jumia$Price),step=100, value=c(0,40000)),
                    selectInput("category", "Select Categories", 
                                choices = c("All",unique(jumia$Category))),
                    sliderInput("dsc_slider", "Discount Range", 
                                min=0, max=max(jumia$Discount),step=10, value=c(0,max(jumia$Discount))),
                    width=4,
                    ),
                # table box
                box(title = "Table Output",
                          status = "primary",
                          solidHeader = TRUE,
                          collapsible = TRUE,
                          tableOutput("table1"),
                          background = "light-blue",
                          width = 8 )
              )
          ),

              
      )
    ) # end of tab items
  ) # end of body
) # end of ui

server <- function(input, output) {
  
  
  url <- a("Jumia Homepage", href="https://www.jumia.co.ke/")
  output$tab <- renderUI({
    tags$a(href="https://www.jumia.co.ke/", "Open Jumia Website")
  })

  table <- reactiveVal(NULL)
  
  # updating the reactiveVal whenever the table output changes
  observe({
    if (input$category == "All") {
      table(jumia %>%
                   filter(Price >= input$price_slider[1] & Price <= input$price_slider[2]) %>% 
                   filter(Discount >= input$dsc_slider[1] & Discount <= input$dsc_slider[2]))
    } else {
      table(jumia %>%
                   filter(Price >= input$price_slider[1] & Price <= input$price_slider[2]) %>%
                   filter(Discount >= input$dsc_slider[1] & Discount <= input$dsc_slider[2]) %>% 
                   filter(Category == input$category) )
    }
  })
  
  output$table1 <- renderTable({
    req(table())
    table()
  })
  
  output$table_info = renderText({
      if (input$category == "All") {
        paste("Table Information:
              Number of items:", nrow(table()), "
              Category:",input$category,"
              Price Range: ",input$price_slider[1]," - ",input$price_slider[2],"
              Discount Range: ",input$dsc_slider[1]," - ",input$dsc_slider[2] )
      } else {
        paste("Table Information:
              Number of items:", nrow(table()), "
              Category:",input$category,"
              Price Range: ",input$price_slider[1]," - ",input$price_slider[2],"
              Discount Range: ",input$dsc_slider[1]," - ",input$dsc_slider[2] )
      }
    })
  
  
} # end of server

shinyApp(ui, server)