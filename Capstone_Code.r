#Importing packages
install.packages("rio")
library(rio)
install.packages("tidyverse")
library(tidyverse)
install.packages("ggplot2") 
library("ggplot2")
install.packages("scales")
library(scales)
library(dplyr)
#importing in the dataset
col_data<-rio::import("C:\\Users\\joelt\\Downloads\\Jtorres Google Data Analytics Capstone\\cleaned_col.csv")
#Makes a bar graph that plots the amount of families in deficit by state split by the number of children
remaining_income_state <- ggplot(data = col_data) + #initializes plot
    geom_bar(mapping = aes(x = state, y = round(median_family_income - total_cost)<0, fill = round(median_family_income - total_cost) <0), stat = "identity") +
    coord_flip() + #flips the plot for viewability
    scale_fill_manual(values = c("FALSE" = "#92bcde", "TRUE" = "#ba7070")) + #fills bar chart depneding on if theyre negative or positive values
    facet_wrap(~Number_children) +#splits graph by number of children
    labs(fill="Deficit Status", x = "Families in Deficit", y = "State", title = "Families in Deficit by State", subtitle = "Split by number of children")
#Makes a bar graph plotting the remaining income by each number of children split by how many parents are present
remaining_income_children<- ggplot(data=col_data) +
    geom_bar(mapping = aes(x = Number_children, y = round((median_family_income - total_cost)/10000), fill = round(median_family_income - total_cost) < 0), stat = "identity") +
    scale_y_continuous(labels = comma) +
    scale_fill_manual(values = c("FALSE" = "#92bcde", "TRUE" = "#ba7070")) +
    facet_wrap(~Number_adults)+
    labs(fill="Deficit Status", x = "Number of Children", y = "Remaining Income", title = "Remaining Income by Number of Children", subtitle = "Split by number of parents")
#plots a scatterplot to view relationship between children and family income vs remaining income
remaining_income_income<-ggplot(data=col_data)+
    geom_point(mapping=aes(x=median_family_income,y=round((median_family_income-total_cost)/10),color=Number_children))+
    facet_wrap(~Number_adults) +
    scale_y_continuous(labels = comma) +
    scale_color_gradient(low = "#73b67e", high = "#004e1d") +
    labs(color="Number of Children", x = "Median Family Income", y = "Remaining Income", title = "Remaining Income by Median Income", subtitle = "Split by number of parents and color coded by number of children")

#linear regression model to calculate how number of children impact remaining income
lm_<-lm(round(median_family_income-total_cost)/10 ~ Number_children, data = col_data)
child_coef<-round(coef(lm_)["Number_children"])#extracts the coeffecient
#plots the linear regression model as a line
income_children<-ggplot(data=col_data) +
    geom_point(mapping = aes(x = Number_children, y = round(median_family_income - total_cost)/10), alpha = 0.4, color = "#285e37") +
    geom_smooth(method="lm", mapping=aes(y = round(median_family_income-total_cost)/10, x = Number_children)) +
    facet_wrap(col_data$Number_adults) +
    scale_y_continuous(labels = comma) +
    labs(x = "Number of Children", y = "Remaining Income ($)", title = "Remaining Income by Number of Children", subtitle = "Split by number of Parents", caption = paste0("Remaining income decreases by ~$", abs(child_coef), " per additional child (linear regression estimate)"))
#adding edits to the data for further analysis (done after initial analysis)
#Adds remaining income and deficit status
col_data <- col_data %>%
    mutate(
        remaining_income = median_family_income - total_cost,
        deficit_status = remaining_income < 0
    )
#defines a function to extract the child coefficient from linear regression
get_child_coef <- function(df) {
    model <- lm(remaining_income ~ Number_children, data = df)
    coef <- coef(model)["Number_children"]
    return(ifelse(is.na(coef), NA, round(coef)))
}
#add child_coef per county
county_coefs <- col_data %>%
    group_by(state, county) %>%
    summarise(child_coef = get_child_coef(cur_data_all()), .groups = "drop")

#merge back with main data
col_data <- col_data %>%
    left_join(county_coefs, by = c("state", "county"))

#saves to csv
write.csv(col_data, "C:/Users/joelt/Downloads/Jtorres Google Data Analytics Capstone/col_data_updated.csv", row.names = FALSE)
#returns the graphs/values for viewing
return(remaining_income_state)
return(remaining_income_children)
return(remaining_income_income)
return(income_children)
return(lm_)
