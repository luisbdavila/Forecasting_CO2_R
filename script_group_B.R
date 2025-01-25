# Importing the needed libraries
library(fpp3)
library(urca)
library(pagedown)

# Importing the data from the csv file
C02_concentrations_dataset <- read.csv('data_group_B.csv')

# Treating the data:
#  - Select only Parts Per Million
#  - Transform the date into the date format
#  - Select data from March 1958, to December 2023
#  - Transform to a tsibble object
C02_concentrations_dataset %>% 
  filter(Unit == "Parts Per Million") %>% 
  mutate(Date = yearmonth(paste0(substr(Date, 1, 4), "-", substr(Date, 6, 7)))) %>% 
  select(c('Date', 'Value')) %>% as_tsibble(index = Date) %>% 
  filter(year(Date) < "2024") -> CO2_tsibble_data

# Plotting the series
CO2_tsibble_data %>% autoplot() + labs(x = 'Date', y='Parts Per Million', title = 'Evolution of CO2 Concentrations')
# Constant Variance, linearly increasing trend and clear seasonality

# Seeing the evolution by season, to confirm the existence of seasonality
gg_season(CO2_tsibble_data) + labs(x = 'Month', y='Parts Per Million', title = 'Evolution of C02 Concentrations by Month')
# Every year the peak is reached around May (April, May and June have the highest values throughout the year),
# The lowest values are achieved in September and October.
# In general we can see an increase from January to May, then a decrease until September and it starts to rise again going to December

# Looking at the seasonal evolution by comparing the yearly evolution for each month as well the overall mean
gg_subseries(CO2_tsibble_data)
# This confirms what was seen in the other plots
# Increased trend over the years, peaks in May and downs in September and October


# Finding the value of the box-cox transformation to stabilize the variance
CO2_tsibble_data %>% features(Value, guerrero) #0.873
# Applying the box-cox transformation
CO2_tsibble_data %>% autoplot(box_cox(Value,0.873)) # it's identical to the original
# Applying the log transformation
CO2_tsibble_data %>% autoplot(log(Value)) # it's also identical to the original
# So, no transformation will be applied

# Correlogram and plot of our series
Correlogram_CO2 <- CO2_tsibble_data %>% gg_tsdisplay(Value, plot_type = "partial") +
                        labs(title = 'CO2 Concentrations')
Correlogram_CO2
# We can see that it is not a stationary time series because the ACF doesn't decay and the mean isn't constant

# Augmented Dickey-Fuller to test stationarity
summary(ur.df(CO2_tsibble_data$Value, type='trend',lags=48))
summary(ur.df(CO2_tsibble_data$Value, type='trend',lags=47))
summary(ur.df(CO2_tsibble_data$Value, type='trend',lags=46))
# p-value for lag46 is = 0.007662 which is less than 0.1, thus we can proceed to test. The observed test-statistic is: -0.1601 and at a 5%
# significance level the critical value is -3.41, we don't reject ho, 
# so we will apply a seasonal difference because the original time series is not stationary

# Seasonal difference
CO2_tsibble_data <- CO2_tsibble_data %>% mutate(diff_season_value = difference(Value, 12))
CO2_tsibble_data

# Correlogram and plot of seasonally differentiated time series
CO2_tsibble_data %>% gg_tsdisplay(diff_season_value, plot_type = "partial") +
                      labs(title = 'CO2 Concentrations with 1 Sesonal Difference')
# We can see that it is not a stationary time series because the ACF doesn't decay and the mean isn't constant

# Augmented Dickey-Fuller to test stationarity
summary(ur.df(na.omit(CO2_tsibble_data$diff_season_value), type='trend',lags=48))
# p-value for lag48 is = 0.000133, which is less than 0.1, thus we can proceed to test. The observed test-statistic is: -3.1787 and at a 5%
# significance level the critical value is -3.41, we don't reject ho,
# so we will apply 1 normal difference because the seasonal difference of the time series is still not stationary 

# Normal difference on top of the seasonal difference
CO2_tsibble_data <- CO2_tsibble_data %>% mutate(diff_diff_season_value = difference(diff_season_value, 1))
CO2_tsibble_data

# Correlogram and plot of diff seasonal time series
Correlogram_CO2_2diff <- CO2_tsibble_data %>% gg_tsdisplay(diff_diff_season_value, plot_type = "partial", lag_max=72) +
                         labs(title = 'CO2 Concentrations with 1 Sesonal and 1 Normal Difference')
Correlogram_CO2_2diff
# Looks like a stationary time series

# Augmented Dickey-Fuller to test stationarity
summary(ur.df(na.omit(CO2_tsibble_data$diff_diff_season_value), type='none',lags=48))
summary(ur.df(na.omit(CO2_tsibble_data$diff_diff_season_value), type='none',lags=47))
# p-value for lag47 is = 2.31e-05 which is less than 0.1, thus we can proceed to test. The observed test-statistic is: -7.3139 and at a 5%
# significance level the critical value is -1.95, we reject ho, the time series is now stationary.
# Now we once again look at the plot and correlogram to suggest candidate models. The models we selected are
# a SARIMA(0,1,1)(0,1,1) and a SARIMA(0,1,1)(0,1,2)

# Splitting our data into train and test sets
# We will use our train set which includes data up to 2018 to train our models 
# and then we will compare the predictions to the real values from the test set
CO2_train<-CO2_tsibble_data%>%
  filter(year(Date) <= 2018)

CO2_test<-CO2_tsibble_data%>%
  filter(year(Date) > 2018)

# Fit models on the training data
CO2_fit_model<-CO2_train%>%
  model(
    SARIMA011011 = ARIMA(Value ~pdq(0,1,1)+PDQ(0,1,1)),
    SARIMA011012 = ARIMA(Value ~pdq(0,1,1)+PDQ(0,1,2))
  )


# Information criteria of the models
glance(CO2_fit_model)%>% 
  arrange(AICc)%>%
  select(.model:BIC)
# SARIMA011011 has lower values in the various IC

# Forecasting the test data
forecast_test_CO2<-CO2_fit_model%>% 
                  forecast(CO2_test)

# Plot results of the predictions using the train set and real values from the test set
Forecast_test_CO2_models <- forecast_test_CO2%>%
                            autoplot(bind_rows(filter(CO2_train, year(Date) > 2015),CO2_test),
                            level=NULL)+
                            labs(y='Parts Per Million',
                            title = 'Models Forcasting CO2 in Parts Per Million')+
                            guides(colour=guide_legend(title ="Model"))

Forecast_test_CO2_models
# Both models are producing identical forecasts

# Comparing the accuracy of the forecasts
accuracy(forecast_test_CO2, CO2_tsibble_data)
# Both models are still producing identical forecasts

# Our final model is a SARIMA011011 because the IC are lower, and accuracy is similar for both

# Looking at the residuals of our model
Resid_SARIMA <- CO2_fit_model %>% select(SARIMA011011) %>%  gg_tsresiduals() + labs(title = 'Residuals of SARIMA011011')
Resid_SARIMA
# Residuals are like white noise (mean 0, constant variance and normally distributed)

# ljung_box test to see if the residuals are autocorrelated 
# (We want a high p-value, as this means h0 is not rejected and the residuals are not autocorrelated)
augment(CO2_fit_model)%>% 
  filter(.model=='SARIMA011011')%>%
  features(.innov, ljung_box)
# p-value = 0.531, so we don't reject ho, so the residuals are not autocorrelated.

# Now that we know our final model is adequate for predictions, we are going to forecast the next 5 years of CO2 concentration

next_5_years <- CO2_tsibble_data%>%
                model(SARIMA011011 = ARIMA(Value ~pdq(0,1,1)+PDQ(0,1,1))) %>% 
                forecast(h ="5 years")
  
forecast_next_5_years <- next_5_years %>% autoplot(filter(CO2_tsibble_data, year(Date) > 2015))+
                          labs(y='Parts Per Million',
                          title = 'Forecasts CO2 Concentrations in the Next 5 Years')
forecast_next_5_years

# According to our forecasts, the concentrations of CO2 will keep increasing in the next 5 years
# leading to heightened effects of climate change.

#pagedown::chrome_print("script_group_B.html")
