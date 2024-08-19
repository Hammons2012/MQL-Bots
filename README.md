# Trading Bots Repository

This repository contains a collection of trading bots written in MQL4 and MQL5 for the MetaTrader 4 and MetaTrader 5 platforms. These bots are designed to automate trading strategies and can be customized to fit various trading needs.

## Important Notice

**This bot is no longer being developed since most US-based Forex brokers no longer support MT4/5.**

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This repository includes various trading bots designed to automate trading strategies on the MetaTrader platforms. The bots are written in MQL4 for MetaTrader 4 and MQL5 for MetaTrader 5. These bots can help traders execute strategies more efficiently and consistently.

## Features

- **Automated Trading**: Execute trades based on predefined strategies.
- **Customizable Parameters**: Adjust trading parameters to fit your strategy.
- **Backtesting**: Test your strategies on historical data.
- **Real-time Monitoring**: Monitor trades in real-time.
- **Error Handling**: Robust error handling to ensure smooth operation.

## Installation

To use these trading bots, follow these steps:

### **Clone the Repository**:
bash
git clone https://github.com/yourusername/trading-bots.git
Copy the Files:

For MQL4 bots, copy the .mq4 files to the Experts folder in your MetaTrader 4 MQL4 directory.
For MQL5 bots, copy the .mq5 files to the Experts folder in your MetaTrader 5 MQL5 directory.
Compile the Bots:

### Open MetaTrader 4 or MetaTrader 5.
Go to the Navigator window, right-click on the Experts folder, and select Refresh.
Double-click on the bot you want to compile, and it will open in the MetaEditor.
Click on the Compile button to compile the bot.

### Usage
Attach the Bot to a Chart:

Open a chart in MetaTrader 4 or MetaTrader 5.
Go to the Navigator window, find the bot in the Experts folder, and drag it onto the chart.
Configure the Bot:

A configuration window will appear. Adjust the parameters as needed and click OK.
Monitor the Bot:

The bot will start executing trades based on the configured parameters.
You can monitor the bot's activity in the Experts tab of the Terminal window.
Configuration
Each bot comes with a set of configurable parameters. These parameters can be adjusted to fit your trading strategy. The parameters include:

Lot Size: The size of the trades.
Take Profit: The profit target for each trade.
Stop Loss: The stop loss level for each trade.
Timeframe: The timeframe on which the bot operates.
Indicators: Various indicators used by the bot.

### Configuration

Each bot comes with a set of configurable parameters. These parameters can be adjusted to fit your trading strategy. The parameters include:

## Time-based Configurations
'''
input int InpTimeFrameStart = 9;                                           // Start time for trade execution (in hours)
input int InpTimeFrameEnd = 17;                                            // End time for trade execution (in hours)

input bool InpTradeOnMonday = true;                                        // Allow trades on Monday
input bool InpTradeOnTuesday = true;                                        // Allow trades on Tuesday
input bool InpTradeOnWednesday = true;                                     // Allow trades on Wednesday
input bool InpTradeOnThursday = true;                                      // Allow trades on Thursday
input bool InpTradeOnFriday = true;                                        // Allow trades on Friday
Trade-based Configurations

input int InpTDICrossoverFiftyMiddleMagicNumber = 11111;     				   // Magic number for trades opened by TDI crossover and middle above 50 strategy
input int InpTDICrossoverAboveBelowMiddleMagicNumber = 22222;              // Magic Number for trades opened by TDI crossover and price and signal above/below middle
input int InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber = 33333;       // Magic Number for trades opened by TDI Crossover, middle above 50, price and signal above middle, and HA
input int InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber = 44444;   // Magic Number for trades opened by TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP
input int InpReversalMagicNumber = 55555;                                  // Magic Number for reversal trades

input ENUM_TIMEFRAMES InpTrendTimeframe = 0;                               // The timeframe used to note trend.

input double InpRiskPercentage = 1.0;                                      // User-defined risk percentage
input double InpRewardPercentage = 2.0;                                    // User defined reward percentage
input double InpStopLoss = 20.0;                                           // User-defined  stop loss value
input bool InpEnableTrailingStop = false;                                  // Enable trailing stop loss
input bool InpAllowBothTypePositions = false;                              // Allow both position types to be openned at the same time
'''

## Indicator Configurations
'''
extern string PriceTypes = "0=close, 1=open, 2=high, 3=low, 4=median, 5=typical, 6=weighted";
extern string MATypes = "0=simple, 1=exponential, 2=smoothed, 3=linear-weighted";
input int InpRSIBaselinePeriod = 10;                                       // Baseline period
input int InpRSIBaselinePrice = 5;                                         // What data to use for pulling the data to calculate the baseline
input int InpVolatilityBand = 34;                                          // BBand period
input int InpRSIPriceLine = 2;                                             // RSI MA period used for price action
input int InpRSIPriceType = 1;                                             // Type of MA to use for price action
input int InpTradeSignalLine = 7;                                          // RSI MA period for signal
input int InpTradeSignalType = 0;                                          // Type of MA to use for signal
'''

## Strategy-based Configurations
'''
input bool InpTDICrossoverFiftyMiddleStrategy = false;      				   // Open trades based on TDI crossover and middle abce 50 indicators
input bool InpTDICrossoverAboveBelowMiddleStrategy = false;             	// Open trades based on TDI crossover and price and signal above/below middle indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAStrategy = false;         // Open trades based on TDI Crossover, middle above 50, price and signal above middle, and HA indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy = false;     // Open trades based on TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP indicators
input bool InpAllowReveralTrades = false;                                  // Allow for reversal trades and auto closing of open trades
input bool InpAllowCloseLogic = false;                                     // Enabling this allows the expert advisor to close trades based on the indicators/market condition changes
Info-based Configurations

input bool InpShowExpertConfigInfo = true;                                 // Show expert advisor configuration information
input bool InpShowExpertTradeInfo = true;                                  // Show expert advisor trade info (stop loss, take profit, etc.)
input color InpInfoColor = clrWhite;                                       // Color used for color for info to chart
'''

### License

This project is licensed under the MIT License. See the LICENSE file for more details.
