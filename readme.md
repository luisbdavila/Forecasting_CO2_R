# Forecasting CO₂ Concentrations Using SARIMA Models

## Project Overview
This project focuses on predicting future CO₂ concentrations using SARIMA (Seasonal AutoRegressive Integrated Moving Average) models. Rising CO₂ levels are a major concern due to their impact on climate change, which causes natural disasters and long-term environmental damage. This analysis provides insights into future trends, aiding in climate-related decision-making.

## Objectives
The primary objectives of this project were:
1. Analyze historical CO₂ concentration data to understand trends and seasonality.
2. Build and validate SARIMA models to forecast future CO₂ levels.
3. Assess whether the increase in CO₂ concentrations shows any signs of slowing down.

## Problem Statement
Rising atmospheric CO₂ concentrations contribute significantly to climate change. Accurate forecasts of future levels can help policymakers and scientists mitigate climate impacts. This project uses SARIMA models to predict CO₂ concentrations, addressing the challenge of identifying trends and seasonality in historical data.

## Methodology
### Dataset
The dataset contains monthly CO₂ concentrations (in PPM) and percentage changes from March 1958 to December 2023. It was sourced from the International Monetary Fund's Climate Data portal.

### Analysis Steps
1. **Stationarity Testing**:
   - ADF tests confirmed the presence of trends and seasonality.
   - Applied seasonal differencing and first-order differencing to achieve stationarity.

2. **Model Specification**:
   - Identified candidate models SARIMA(0,1,1)(0,1,1) and SARIMA(0,1,1)(0,1,2) using ACF and PACF plots.
   - Evaluated models using Information Criteria (AIC, AICc, and BIC) and predictive accuracy.

3. **Model Validation**:
   - Split data into training (pre-2018) and testing sets (post-2018).
   - Chose SARIMA(0,1,1)(0,1,1) as the final model based on better information criteria and simpler parameterization.
   - Validated residuals using the Ljung-Box test to confirm white noise behavior.

4. **Forecasting**:
   - Predicted CO₂ concentrations for the next five years to assess future trends.

### Results
- **Model Accuracy**:
  - Metrics: RMSE = 0.641, MAE = 0.562, MAPE = 0.135, MASE = 0.360.
  - Residuals followed a normal distribution with no autocorrelation.
- **Forecast**:
  - CO₂ concentrations are predicted to continue rising, with no signs of slowing down.

## Conclusion
The SARIMA(0,1,1)(0,1,1) model effectively forecasts future CO₂ levels, highlighting an ongoing upward trend. This finding underscores the urgent need for global action to mitigate climate change. Policymakers and environmental scientists can use these forecasts to plan strategies and address climate-related challenges.

## Deliverables
1. **Poster**: Summarizing methodology, results, and implications.
2. **R Code**: For data processing, modeling, and forecasting.
3. **Dataset**: Monthly CO₂ concentration data.
