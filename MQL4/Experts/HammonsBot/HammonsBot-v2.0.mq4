//+------------------------------------------------------------------+
//|                                                   HammonsBot.mq4 |
//|                                                  Joshua Mashburn |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Joshua Mashburn"
#property link      ""
#property version   "2.00"
#property strict

// Configurable variables for the expert advisor
// Time based configurations
input int InpTimeFrameStart = 9;                                           // Start time for trade execution (in hours)
input int InpTimeFrameEnd = 17;                                            // End time for trade execution (in hours)

input bool InpTradeOnMonday = true;                                        // Allow trades on Monday
input bool InpTradeOnTuesday = true;                                       // Allow trades on Tuesday
input bool InpTradeOnWednesday = true;                                     // Allow trades on Wednesday
input bool InpTradeOnThursday = true;                                      // Allow trades on Thursday
input bool InpTradeOnFriday = true;                                        // Allow trades on Friday

// Trade-based configurations
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

// TDI indicator configurations
extern string PriceTypes = "0=close, 1=open, 2=high, 3=low, 4=median, 5=typical, 6=weighted";
extern string MATypes = "0=simple, 1=exponential, 2=smoothed, 3=linear-weighted";
input int InpRSIBaselinePeriod = 10;                                       // Baseline period
input int InpRSIBaselinePrice = 5;                                         // What data to use for pulling the data to calculate the baseline 
input int InpVolatilityBand = 34;                                          // BBand period
input int InpRSIPriceLine = 2;                                             // RSI MA period used for price action
input int InpRSIPriceType = 1;                                             // Type of MA to use for price action 
input int InpTradeSignalLine = 7;                                          // RSI MA period for signal
input int InpTradeSignalType = 0;                                          // Type of MA to use for signal

// Allow EA to trade on multiple/specific strategies
input bool InpTDICrossoverFiftyMiddleStrategy = false;      				   // Open trades based on TDI crossover and middle abce 50 indicators
input bool InpTDICrossoverAboveBelowMiddleStrategy = false;             	// Open trades based on TDI crossover and price and signal above/below middle indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAStrategy = false;         // Open trades based on TDI Crossover, middle above 50, price and signal above middle, and HA indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy = false;     // Open trades based on TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP indicators
input bool InpAllowReveralTrades = false;                                  // Allow for reversal trades and auto closing of open trades
input bool InpAllowCloseLogic = false;                                     // Enabling this allows the expert advisor to close trades based on the indicators/market condition changes

// Info based configurations
input bool InpShowExpertConfigInfo = true;                                 // Show expert advisor configuration information
input bool InpShowExpertTradeInfo = true;                                  // Show expert advisor trade info (stop loss, take profit, etc.)
input color InpInfoColor = clrWhite;                                       // Color used for color for info to chart

// Global variables
double EntryPrice = 0.0;
double StopLoss = 0.0;
double TakeProfit = 0.0;
datetime LastBarTime = 0;
bool TDIBuySignal = false;
bool TDISellSignal = false;
bool VWAPBuySignal = false;
bool VWAPSellSignal = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  // Check if EA is attached to a chart
  if (Symbol() == "")
  {
    Print("Error: EA is not attached to a chart");
    return (INIT_FAILED);
  }
  
  // Initialization code goes here
  return (INIT_SUCCEEDED); 
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  ObjectsDeleteAll(ChartID());
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  
  // Calculating TDI values
  // Previous bar values
  double TDIRSIBaselinePrevious = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 0, 2);
  double TDIBBandUpperPrevious = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 1, 2);
  double TDIBBandMiddlePrevious = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 2, 2);
  double TDIBBandLowerPrevious = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 3, 2);
  double TDIRSIPricePrevious = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 4, 2);
  double TDIRSISignalPrevious = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 5, 2);
  
  // Current bar values
  double TDIRSIBaselineCurrent = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 0, 1);
  double TDIBBandUpperCurrent = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 1, 1);
  double TDIBBandMiddleCurrent = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 2, 1);
  double TDIBBandLowerCurrent = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 3, 1);
  double TDIRSIPriceCurrent = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 4, 1);
  double TDIRSISignalCurrent = iCustom(Symbol(), 0, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 5, 1);
  
  // TDI Crossovers
  bool TDIBuyCrossover = CrossoverCheck(TDIRSISignalPrevious, TDIRSIPricePrevious, TDIRSIPriceCurrent, TDIRSISignalCurrent);
  bool TDISellCrossover = CrossoverCheck(TDIRSIPricePrevious, TDIRSISignalPrevious, TDIRSISignalCurrent, TDIRSIPriceCurrent);
  
  // Calculating Heiken Ashi values
  // Previous bar values
  double HALowPrevious = iCustom(Symbol(), 0, "Heiken Ashi", 0, 0, 2);
  double HAHighPrevious = iCustom(Symbol(), 0, "Heiken Ashi", 0, 1, 2);
  double HAOpenPrevious = iCustom(Symbol(), 0, "Heiken Ashi", 0, 2, 2);
  double HAClosePrevious = iCustom(Symbol(), 0, "Heiken Ashi", 0, 3, 2);
  
  // Current bar settings
  double HALowCurrent = iCustom(Symbol(), 0, "Heiken Ashi", 0, 0, 1);
  double HAHighCurrent = iCustom(Symbol(), 0, "Heiken Ashi", 0, 1, 1);
  double HAOpenCurrent = iCustom(Symbol(), 0, "Heiken Ashi", 0, 2, 1);
  double HACloseCurrent = iCustom(Symbol(), 0, "Heiken Ashi", 0, 3, 1);
  
  // Caluclating VWAP values
  // Previous bar values
  double VWAPPrevious = iCustom(Symbol(), 0, "VWAP", 0, 0, 0, 2);
  
  // Current bar values
  double VWAPCurrent = iCustom(Symbol(), 0, "VWAP", 0, 0, 0, 1);
  
  // Trend following
  double TrendTDIRSIBaselineCurrent = iCustom(Symbol(), InpTrendTimeframe, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 0, 1);
  double TrendTDIRSIBaselinePrevious = iCustom(Symbol(), InpTrendTimeframe, "TDI", InpRSIBaselinePeriod, InpRSIBaselinePrice, InpVolatilityBand, InpRSIPriceLine,InpRSIPriceType, InpTradeSignalLine, InpTradeSignalType, 0, 0, 2);
  double TrendVWAPCurrent = iCustom(Symbol(), InpTrendTimeframe, "VWAP", 0, 0, 0, 1);
  double TrendVWAPPrevious = iCustom(Symbol(), InpTrendTimeframe, "VWAP", 0, 0, 0, 2);

  if (TrendTDIRSIBaselineCurrent > 50)
  {
    TDIBuySignal = true;
  }
  if (TrendTDIRSIBaselineCurrent < 50)
  {
    TDISellSignal = true;
  }
  if (HAOpenCurrent > TrendVWAPCurrent)
  {
    VWAPBuySignal = true;
  }
  if (HAOpenCurrent < TrendVWAPCurrent)
  {
    VWAPSellSignal = true;
  }

  // Check if there is an open trade, handle trailing stop loss/take profit if enabled, and prevents more trades from being opened
  double Balance = AccountBalance();
  double RiskAmount = Balance * InpRiskPercentage / 100.0;
  
  bool IsTDICrossoverFiftyMiddleTradeOpen = IsTradeOpen(InpTDICrossoverFiftyMiddleMagicNumber, InpAllowBothTypePositions);
  bool IsTDICrossoverAboveBelowMiddleTradeOpen = IsTradeOpen(InpTDICrossoverAboveBelowMiddleMagicNumber, InpAllowBothTypePositions);
  bool IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen = IsTradeOpen(InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber, InpAllowBothTypePositions);
  bool IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen = IsTradeOpen(InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber, InpAllowBothTypePositions);
  
  // Dashboard data
  int DashboardYValue = 30;
  if (InpShowExpertConfigInfo)
  {
    string TextSpaceBreakBeginningConfig = "==================================================================";
    PrintTextChart("ObjectSpaceBreakBeginningConfig", TextSpaceBreakBeginningConfig, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDISignal = "TDI Sell Signal: " + (TDISellSignal ? "true" : "false") + " / TDI Buy Signal: " +(TDIBuySignal ? "true" : "false");
    PrintTextChart("ObjectTDISignal", TextTDISignal, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTrendTimeframe = "Trend Timeframe: " + IntegerToString(InpTrendTimeframe) + " Minutes";
    PrintTextChart("ObjectTrendTimeframe", TextTrendTimeframe, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverFiftyMiddleStrategy = "TDI Middle 50: " + (InpTDICrossoverFiftyMiddleStrategy ? "true" : "false") + " / Magic Number: " + IntegerToString(InpTDICrossoverFiftyMiddleMagicNumber);
    PrintTextChart("ObjectTDICrossoverFiftyMiddleStrategy", TextTDICrossoverFiftyMiddleStrategy, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverAboveBelowStrategy = "TDI Above/Below Middle: " + (InpTDICrossoverAboveBelowMiddleStrategy ? "true" : "false") + " / Magic Number: " + IntegerToString(InpTDICrossoverAboveBelowMiddleMagicNumber);
    PrintTextChart("ObjectTDICrossoverAboveBelowStrategy", TextTDICrossoverAboveBelowStrategy, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverFiftyAboveBelowMiddleHAStrategy = "TDI Above/Below + 50 Middle: " + (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy ? "true" : "false") + " / Magic Number: " + IntegerToString(InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber);
    PrintTextChart("ObjectTDICrossoverFiftyAboveBelowMiddleHAStrategy", TextTDICrossoverFiftyAboveBelowMiddleHAStrategy, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy = "TDI Above/Below + 50 Middle + VWAP: " + (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy ? "true" : "false") + " / Magic Number: " + IntegerToString(InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber);
    PrintTextChart("ObjectTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy", TextTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextAllowReveralTrades = "Reversal Trades: " + (InpAllowReveralTrades ? "true" : "false") + " / Magic Number: " + IntegerToString(InpReversalMagicNumber);
    PrintTextChart("ObjectTextAllowReveralTrades", TextAllowReveralTrades, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextAllowCloseLogic = "Advanced Exit Logic: " + (InpAllowCloseLogic ? "true" : "false");
    PrintTextChart("ObjectTextAllowCloseLogic", TextAllowCloseLogic, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextSpaceBreakEndConfig = "==================================================================";
    PrintTextChart("ObjectSpaceBreakEndConfig", TextSpaceBreakEndConfig, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
  }
  
  if (InpShowExpertTradeInfo)
  {
    if (!InpShowExpertConfigInfo)
    {
      string TextSpaceBreakBeginningTrade = "==================================================================";
      PrintTextChart("ObjectSpaceBreakBeginningTrade", TextSpaceBreakBeginningTrade, InpInfoColor, DashboardYValue);
      DashboardYValue += 15;
    }
    
    string TextRiskPercent = "Risk Percentage: " + DoubleToString(InpRiskPercentage, 2);
    PrintTextChart("ObjectRiskPercent", TextRiskPercent, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTakeProfitPercent = "Take Profit Percentage: " + DoubleToString(InpRewardPercentage, 2);
    PrintTextChart("ObjectTakeProfitPercent", TextTakeProfitPercent, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextStopLossPoints = "Stop Loss in Points: " + DoubleToString(InpStopLoss, 2);
    PrintTextChart("ObjectStopLossPoints", TextStopLossPoints, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextAllowTrailingStop = "Allow Trailing Stop: " + (InpEnableTrailingStop ? "true" : "false");
    PrintTextChart("ObjectEnableTrailingStop", TextAllowTrailingStop, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextAllowBothPositions = "Allow Both Trade Positions: "+ (InpAllowBothTypePositions ? "true" : "false");
    PrintTextChart("ObjectAllowBothPositions", TextAllowBothPositions, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextSpaceBreakEndTrade = "==================================================================";
    PrintTextChart("ObjectSpaceBreakEndTrade", TextSpaceBreakEndTrade, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
  }
  
  // Check if we are allowed to trade on the current day of the week
  int DayOfTheWeek = TimeDayOfWeek(TimeCurrent());
  bool TradeOnCurrentDay = false;
  switch (DayOfTheWeek)
  {
    case 1: TradeOnCurrentDay = InpTradeOnMonday; break;
    case 2: TradeOnCurrentDay = InpTradeOnTuesday; break;
    case 3: TradeOnCurrentDay = InpTradeOnWednesday; break;
    case 4: TradeOnCurrentDay = InpTradeOnThursday; break;
    case 5: TradeOnCurrentDay = InpTradeOnFriday; break;
  }
  if (!TradeOnCurrentDay)
  {
    Comment("Trading not allowed on this day: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
    return;
  }
    
  // Check if we are within the allowed time frame for trade execution
  if (TimeHour(TimeCurrent()) < InpTimeFrameStart || TimeHour(TimeCurrent()) >= InpTimeFrameEnd)
  {
    Comment("Trading not allowed outside of " + IntegerToString(InpTimeFrameStart) + " and " + IntegerToString(InpTimeFrameEnd) + ". Current time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
    return;
  }
  
  //Checking if there is a new bar - this code needs to be the outer nest of the trading logic below
  if (Time[0] > LastBarTime)
  {
    LastBarTime = Time[0];
    
    // Adjust stoploss
    if (InpEnableTrailingStop)
    {
      TrailingStop(InpStopLoss);
    }
    
    
    // Trading logic      
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there is a buy crossover, Middle BB is above 50, there is no open wick, the bar is bullish, TD middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverFiftyMiddleStrategy && !IsTDICrossoverFiftyMiddleTradeOpen && TDIBuySignal && TDIBuyCrossover && TDIBBandMiddleCurrent > 50 && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent && TDIBBandMiddleCurrent < 70 && TDIRSIPriceCurrent < 70 && TDIRSISignalCurrent < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyMiddleMagicNumber);
    }

    // If strategy is allowed, there are no open trades, TDI sell signal is true, there is a sell crossover, Middle BB is below 50, there is no open wick, the bar is bearish, TD middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverFiftyMiddleStrategy && !IsTDICrossoverFiftyMiddleTradeOpen && TDISellSignal && TDISellCrossover && TDIBBandMiddleCurrent < 50 && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent && TDIBBandMiddleCurrent > 30 && TDIRSIPriceCurrent > 30 && TDIRSISignalCurrent > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyMiddleMagicNumber);
    }
    
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there is a buy crossover, TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish, TD middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverAboveBelowMiddleStrategy && !IsTDICrossoverAboveBelowMiddleTradeOpen && TDIBuySignal && TDIBuyCrossover && TDIRSIPriceCurrent > TDIBBandMiddleCurrent && TDIRSISignalCurrent > TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent && TDIBBandMiddleCurrent < 70 && TDIRSIPriceCurrent < 70 && TDIRSISignalCurrent < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverAboveBelowMiddleMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, TDI sell signal is true,there is a sell crossover, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish, TD middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverAboveBelowMiddleStrategy && !IsTDICrossoverAboveBelowMiddleTradeOpen && TDISellSignal && TDISellCrossover && TDIRSIPriceCurrent < TDIBBandMiddleCurrent && TDIRSISignalCurrent < TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent && TDIBBandMiddleCurrent > 30 && TDIRSIPriceCurrent > 30 && TDIRSISignalCurrent > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverAboveBelowMiddleMagicNumber);
    }
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there has been a buy crossover, Middle BB is above 50, , TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish, TD middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen && TDIBuySignal && TDIBuyCrossover && TDIBBandMiddleCurrent > 50 && TDIRSIPriceCurrent > TDIBBandMiddleCurrent && TDIRSISignalCurrent > TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent && TDIBBandMiddleCurrent < 70 && TDIRSIPriceCurrent < 70 && TDIRSISignalCurrent < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, TDI sell signal is true, there has been a sell crossover, Middle BB is below 50, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish, TD middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen && TDISellSignal && TDISellCrossover && TDIBBandMiddleCurrent < 50 && TDIRSIPriceCurrent < TDIBBandMiddleCurrent && TDIRSISignalCurrent < TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent && TDIBBandMiddleCurrent > 30 && TDIRSIPriceCurrent > 30 && TDIRSISignalCurrent > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber);
    }
    
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there has been a buy crossover, Middle BB is above 50, , TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish, HAOpen is above VWAP, TD middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen && TDIBuySignal && TDIBuyCrossover && TDIBBandMiddleCurrent > 50 && TDIRSIPriceCurrent > TDIBBandMiddleCurrent && TDIRSISignalCurrent > TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent && HAOpenCurrent > VWAPCurrent && TDIBBandMiddleCurrent < 70 && TDIRSIPriceCurrent < 70 && TDIRSISignalCurrent < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, TDI sell signal is true, there has been a sell crossover, Middle BB is below 50, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish, HAOpen is below VWAP, TD middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen && TDISellSignal && TDISellCrossover && TDIBBandMiddleCurrent < 50 && TDIRSIPriceCurrent < TDIBBandMiddleCurrent && TDIRSISignalCurrent < TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent && HAOpenCurrent < VWAPCurrent && TDIBBandMiddleCurrent > 30 && TDIRSIPriceCurrent > 30 && TDIRSISignalCurrent > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber);
    }
    
    
    // Reversal strategies logic
    // If reversal trades are allowed, TDI sell signal is true, a buy crossover happens, the TDI middle is below 30, TDI RSI price is below 30, TDI RSI signal is below 30, bar has no wick, and bar is bearish
    if (InpAllowReveralTrades && TDISellSignal && TDIBuyCrossover && TDIBBandMiddleCurrent < 30 && TDIRSIPriceCurrent < 30 && TDIRSISignalCurrent < 30 && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent)
    {
      // Close all trades
      CloseAllTrades(OP_SELL);
      
      // Open a sell trade
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpReversalMagicNumber);
    }
    
    // If reversal trades are allowed, TDI buy signal is true, a sell crossover happens, the TDI middle is above 70, TDI RSI price is above 70, TDI RSI signal is above 70, bar has no wick, and bar is bearish
    if (InpAllowReveralTrades && TDIBuySignal && TDISellCrossover && TDIBBandMiddleCurrent > 70 && TDIRSIPriceCurrent > 70 && TDIRSISignalCurrent > 70 && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent)
    {
      // Close all trades
      CloseAllTrades(OP_BUY);
      
      // Open a sell trade
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpReversalMagicNumber);
    }
    
    // Advanced closing logic
    // If exit logic is allowed and trend TDI line is below 30 or sell crossover happens above 70
    if (InpAllowCloseLogic && ((TrendTDIRSIBaselineCurrent < 30) || (TDISellCrossover && TDIRSIPriceCurrent > 70 && TDIRSISignalCurrent > 70)))
    {
      CloseAllTrades(OP_BUY);
    }
    // If exit logic is allowed and trend TDI is above 70 or buy crossover happens below 30
    if (InpAllowCloseLogic && ((TrendTDIRSIBaselineCurrent > 70) || (TDIBuyCrossover && TDIRSIPriceCurrent < 30 && TDIRSISignalCurrent < 30)))
    {
      CloseAllTrades(OP_SELL);
    }
  
  }
  
  Comment("Waiting for trade conditions to match.");
  return;
}

//+------------------------------------------------------------------+
//| Expert trade functions                                           |
//+------------------------------------------------------------------+
  // Functions for checking if a trade is open per stratgy
  bool IsTradeOpen(int FunctMagicNumber, bool FunctAllowBothTypePositions)
  {
    int TotalOrders = OrdersTotal();
    for (int i = 0; i < TotalOrders; i++)
    {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == FunctMagicNumber && OrderType() == OP_BUY && FunctAllowBothTypePositions)
        {
          return true;
        }
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == FunctMagicNumber && OrderType() == OP_SELL && FunctAllowBothTypePositions)
        {
          return true;
        }
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == FunctMagicNumber)
        {
          return true;
        }
	   }
	 }
  return false;
  }
  
  // Function for opening Buy trades
  void OpenBuyTrade(double FunctEntryPrice, double FunctStopLoss, double FunctTakeProfit, double FunctRiskAmount, double FunctInpStopLoss, double FunctInpRewardPercentage, int FunctInpMagicNumber)
  {  
    // Enter a sell position
    if (FunctEntryPrice == 0.0)
    {
      // Open a new trade
      double LotSize = NormalizeDouble(FunctRiskAmount / (FunctInpStopLoss * MarketInfo(Symbol(), MODE_TICKVALUE)), 2);
      if (LotSize < 0.01)
      {
        LotSize = 0.01;
      }
      FunctEntryPrice = Ask;
      FunctStopLoss = FunctEntryPrice - FunctInpStopLoss * Point;
      FunctTakeProfit = FunctEntryPrice + (FunctInpRewardPercentage * FunctInpStopLoss) * Point;
      if (OrderSend(Symbol(), OP_BUY, LotSize, Bid, 0, FunctStopLoss, FunctTakeProfit, "Buy order", FunctInpMagicNumber, 0, Green))
      {
        Print("BUY order sent successfully.");
        return;
      }
      else
      {
        Print("Issues with sending BUY order, last error: ", GetLastError());
        return;
      }
    }
  }

  // Function for opening Sell trades
  void OpenSellTrade(double FunctEntryPrice, double FunctStopLoss, double FunctTakeProfit, double FunctRiskAmount, double FunctInpStopLoss, double FunctInpRewardPercentage, int FunctInpMagicNumber)
  {
    // Enter a sell position
    if (FunctEntryPrice == 0.0)
    {
      // Open a new trade
      double LotSize = NormalizeDouble(FunctRiskAmount / (FunctInpStopLoss * MarketInfo(Symbol(), MODE_TICKVALUE)), 2);
      if (LotSize < 0.01)
      {
        LotSize = 0.01;
      }
      FunctEntryPrice = Ask;
      FunctStopLoss = FunctEntryPrice + FunctInpStopLoss * Point;
      FunctTakeProfit = FunctEntryPrice - (FunctInpRewardPercentage * FunctInpStopLoss) * Point;
      if (OrderSend(Symbol(), OP_SELL, LotSize, Bid, 0, FunctStopLoss, FunctTakeProfit, "Sell order", FunctInpMagicNumber, 0, Red))
      {
        Print("SELL order sent successfully.");
        return;
      }
      else
      {
        Print("Issues with sending SELL order, last error: ", GetLastError());
        return;
      }
    }
  }
  
  // Function that determines if there has been a crossover
  bool CrossoverCheck(double FunctPreviousIndicatorOne, double FunctPreviousIndicatorTwo, double FunctCurrentIndicatorOne, double FunctCurrentIndicatorTwo)
  {
    if (FunctPreviousIndicatorOne > FunctPreviousIndicatorTwo && FunctCurrentIndicatorOne > FunctCurrentIndicatorTwo)
    {
      return true;
    }
    return false;
  }
  
  // Function for closing trades
  void CloseAllTrades(int FunctOrderType)
  {
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol())
      {
        if (FunctOrderType == -1 || FunctOrderType == OrderType())
        {
          double LotSize = OrderLots();
          if (FunctOrderType == OP_BUY)
          {
            EntryPrice = MarketInfo(OrderSymbol(), MODE_BID);
          }
          else if (FunctOrderType == OP_SELL)
          {
            EntryPrice = MarketInfo(OrderSymbol(), MODE_ASK);
          }
          int Ticket = OrderClose(OrderTicket(), LotSize, EntryPrice, 3, clrNONE);

          if (Ticket > 0)
          {
            // OrderClose was successful
            Print("Closed ", (FunctOrderType == OP_BUY) ? "Buy" : "Sell", " Trade #", Ticket, " Lots: ", LotSize);
          }
          else if (Ticket == -1)
          {
            // Error: OrderClose returned -1 (trade is already closed)
            Print((FunctOrderType == OP_BUY) ? "Buy" : "Sell", " Trade #", OrderTicket(), " is already closed.");
          }
          else
          {
            // Error: OrderClose failed
            Print("Error closing ", (FunctOrderType == OP_BUY) ? "Buy" : "Sell", " Trade #", OrderTicket(), " Error: ", GetLastError());
          }
        }
      }
    }
  }



  // Function for trailing stop loss
  void TrailingStop(double FunctInpStopLoss)
  {
    int TotalOrders = OrdersTotal();
    for (int i = 0; i < TotalOrders; i++)
    {
      if (OrderType() == OP_BUY)
      {
        double StopLossLevel = NormalizeDouble(Bid - FunctInpStopLoss * Point, Digits);
        if (StopLossLevel > OrderStopLoss())
        {
          if (OrderModify(OrderTicket(), OrderOpenPrice(), StopLossLevel, OrderTakeProfit(), 0, 0))
          {
            Print("Buy Position: Ticket=", OrderTicket(), ", Symbol=", Symbol(), ", Stop Loss=", StopLossLevel);
          }
          else
          {
            Print("Error modifying order, Error: ", GetLastError());
          }
        }
        else
        {
          Print("Issues with modifying BUY order, last error: ", GetLastError());
        }
      }
      if (OrderType() == OP_SELL)
      {
        double StopLossLevel = NormalizeDouble(Bid + FunctInpStopLoss * Point, Digits);
        if (StopLossLevel < OrderStopLoss())
        {
          if (OrderModify(OrderTicket(), OrderOpenPrice(), StopLossLevel, OrderTakeProfit(), 0, 0))
          {
            Print("Buy Position: Ticket=", OrderTicket(), ", Symbol=", Symbol(), ", Stop Loss=", StopLossLevel);
          }
          else
          {
            Print("Issues with modifying BUY order, last error: ", GetLastError());
          }
        }
        else
        {
          Print("Issues with modifying SELL order, last error: ", GetLastError());
        }
      }
    } 
  }

  // Function for printing text to chart
  void PrintTextChart( string FunctObjectName, string FunctObjText, color FunctObjColor, int FunctTextPixelSpace)
  {
     ObjectCreate(FunctObjectName, OBJ_LABEL, 0, 0, 0);
     ObjectSetText(FunctObjectName, FunctObjText, 7, "Verdana", FunctObjColor);
     ObjectSet(FunctObjectName, OBJPROP_CORNER, 0);
     ObjectSet(FunctObjectName, OBJPROP_XDISTANCE, 20);
     ObjectSet(FunctObjectName, OBJPROP_YDISTANCE, FunctTextPixelSpace);
  }
