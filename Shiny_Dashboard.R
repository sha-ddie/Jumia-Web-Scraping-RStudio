## app.R ##
library(DT)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)

jumia=read.csv("./data/jumia_data.csv")

ui <- dashboardPage(
  
  # Dash Board title
  dashboardHeader(title = "Jumia WebScraping"),
  
  # Slider panel configuration
  dashboardSidebar(
    width = 200,
    sidebarMenu(
      menuItem("Jumia Data", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Analysis", icon = icon("line-chart"), tabName = "charts")
    )
  ),# end of sidebar
  
  # Body
  dashboardBody(
    # Boxes need to be put in a row (or column)
    tabItems(
      # website tab
      tabItem(tabName = "dashboard",  h2("Scraped Data-Jumia Website (Today's Data)"),
              fluidRow(
                    box(title = "Embedded Website",
                        width = 12,
                        height = "52px",
                        solidHeader = TRUE,
                        collapsible = TRUE,
                        uiOutput("tab")
                        )),
              fluidRow(
                column( width=5,
                    #price slider
                    box(title = "Table Filters",
                        sliderInput("price_slider", "Price Range", 
                                    min=0, max=max(jumia$Price),step=1000, value=c(0,40000)),
                        selectInput("category", "Select Categories", 
                                    choices = c("All",unique(jumia$Category))),
                        sliderInput("dsc_slider", "Discount Range", 
                                    min=0, max=max(jumia$Discount),step=10, value=c(0,max(jumia$Discount))),
                        width = 12, height = "350px"
                    ),
                    # Display text
                    box( 
                         verbatimTextOutput("table_info"), 
                         width = 12
                         ) 
                    ),
                column(width = 7,
                    # table box
                    box(title = "Table Output",
                        status = "primary",
                        solidHeader = TRUE,
                        collapsible = TRUE,
                        DT::dataTableOutput( "table1"),
                        #tableOutput("table1"),
                        width=12 ))
                  ) # end of fluid row
            ), #end of dashboard tab item
      #charts tab
      tabItem(tabName="charts",h2("Analysis Charts"),
              fluidRow( box(title = "Top 5 Categories with High Discounts",
                            plotOutput("charts_1"),
                            background = "olive",
                            width=12)),
              fluidRow( box(title = "Top 5 Categories with Lowest Prices",
                            plotOutput("charts_2"),
                            background = "olive",
                            width=12)),
              fluidRow( box(title = "Top 10 Products with highets Discounts",
                            plotOutput("charts_3"),
                            background = "olive",
                            width=12)
                        )
        ) #end of charts tab item   
    ) # end of tab items
  ) # end of body
) # end of ui

server <- function(input, output) {
  
  
 
  output$tab <- renderUI({
    url <- a("Jumia Homepage", href="https://www.jumia.co.ke/")
    tags$a(href="https://www.jumia.co.ke/", "Click!! Open Jumia Website")
  })
  

  table <- reactiveVal(NULL)
  
  # updating the reactiveVal whenever the table output changes
  observe({
    if (input$category == "All" ) {
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
  
  output$table1 <- DT::renderDataTable({
    req(table())
    datatable(
      table(),
      options =   list(
        pageLength=5,
        lengthMenu = c(5,10),
        scrollX =TRUE), 
        filter = 'none'
    )
  })
  
  #output$table1 <- renderTable({
   # req(table())
    #table()
#  })
  
  output$table_info = renderText({
      if (input$category == "All") {
        paste("Search Results:
              Number of items:", nrow(table()), "
              Category:",input$category,"
              Price Range: ",input$price_slider[1]," - ",input$price_slider[2],"
              Discount Range: ",input$dsc_slider[1]," - ",input$dsc_slider[2] )
      } else {
        paste("Search Results:
              Number of items:", nrow(table()), "
              Category:",input$category,"
              Price Range: ",input$price_slider[1]," - ",input$price_slider[2],"
              Discount Range: ",input$dsc_slider[1]," - ",input$dsc_slider[2] )
      }
    })
 
  
  # chart 1
  output$charts_1 <- renderPlot({
    plot= jumia %>% 
      group_by(Category) %>% 
      summarize(count=n(),discount= mean(Discount, na.rm = T)) %>% 
      filter(rank(desc(discount))<=5) %>% 
      ggplot(aes(x=forcats::fct_reorder(Category,desc(discount)), 
                 y=discount))+
      geom_col(fill="cadetblue4") + # bar plot layer
      geom_label(aes(label = paste(round(discount,1),"%")),
                 size=4,fontface="bold") #adding discount as text labels
    
    # formating the plot
    plot+
      # adding x and y labels
      labs(title = "Barplot of Categories Vs Discount",
           y="Discount %",
           x="Categories")+
      theme_bw()+
      # rotating the x labels
      theme(axis.text.x = element_text(angle = 90))+
      theme(axis.text = element_text(size = 10,face="bold"))
  })
  
  
  # Chart 2 
  output$charts_2 <- renderPlot({ 
    # creating plot
    plot= jumia %>% 
      group_by(Category) %>% 
      summarize(count=n(),price= mean(Price, na.rm = T)) %>% 
      filter( rank(price)<=5) %>% 
      ggplot(aes(x=forcats::fct_reorder(Category,price), 
                 y=price))+
      geom_col(fill="cadetblue4") + # bar plot layer
      geom_label(aes(label = round(price,1)),size=4,fontface="bold") #adding discount as text labels
    
    # formatting the plot
    plot+
      # adding x and y labels
      labs(title = "Barplot of Categories Vs Price",
           y="Price",
           x="Categories")+
      theme_bw()+
      # rotating the x labels
      theme(axis.text.x = element_text(angle = 90))+
      theme(axis.text = element_text(size = 10,face="bold"))
  }) 
  
  # Chart 3
  output$charts_3 <- renderPlot({
    data = jumia %>% 
      arrange(desc(Discount)) %>% 
      filter(rank(desc(Discount))<=5) %>% 
      mutate(Name=stringr::str_sub(Name,1,16))
    
    # creating the plot
    ggplot(data=data, aes(x= forcats::fct_reorder(Name,Discount),
                          y=Discount, 
                          label=paste("Price:",Price, ", -",Discount,"%")))+
      geom_col(inherit.aes = T,fill="cadetblue4")+
      geom_label(size=4,fontface="bold")+
      labs(title = "Top 10 Products with highets Discounts",
           y="Discount",
           x="Product Name")+
      theme_bw()+
      theme(axis.text.x = element_text(angle=90))+
      theme(axis.text = element_text(size = 10,face="bold"))
  })
  
  
} # end of server

shinyApp(ui, server)