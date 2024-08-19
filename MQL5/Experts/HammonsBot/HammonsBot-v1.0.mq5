//+------------------------------------------------------------------+
//|                                              HammonsBot-v1.0.mq5 |
//|                                                  Joshua Mashburn |
//+------------------------------------------------------------------+
#property copyright         "Copyright 2023, Joshua Mashburn"
#property version           "1.0"
#property strict

#include <Trade/Trade.mqh>;
#include <Trade/PositionInfo.mqh>;

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
input int InpTDICrossoverFiftyMiddleMagicNumber = 11111;                   // Magic number for trades opened by TDI crossover and middle above 50 strategy
input int InpTDICrossoverAboveBelowMiddleMagicNumber = 22222;              // Magic Number for trades opened by TDI crossover and price and signal above/below middle
input int InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber = 33333;       // Magic Number for trades opened by TDI Crossover, middle above 50, price and signal above middle, and HA
input int InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber = 44444;   // Magic Number for trades opened by TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP

input double InpRiskPercentage = 1.0;                                      // User-defined risk percentage
input double InpRewardPercentage = 2.0;                                    // User-defined reward percentage
input double InpStopLoss = 20.0;                                           // User-defined stop loss value
input bool InpEnableTrailingStop = false;                                  // Enable trailing stop loss
input bool InpAllowBothTypePositions = false;                              // Allow both position types to be opened at the same time

// TDI Indicator user inputs
input int InpTDIRsiPeriod = 13;                                            // RSI_Period: 8-25
input int InpTDIBBandVol = 34;                                             // Volatility_Band: 20-40
input double InpTDIStandardDev = 1.6185;                                   // Standard deviations: 1-3
input int InpTDIPriceLine = 2;                                             // MA period for price
input ENUM_MA_METHOD InpTDIPriceType = MODE_SMA;                           // MA type for price
input int InpTDISignalLine = 7;                                            // MA period for signal
input ENUM_MA_METHOD InpTDISignalType = MODE_SMA;                          // MA type for signal

// VWAP Indicator inputs
enum PRICE_TYPE
{
  OPEN,
  CLOSE,
  HIGH,
  LOW,
  OPEN_CLOSE,
  HIGH_LOW,
  CLOSE_HIGH_LOW,
  OPEN_CLOSE_HIGH_LOW
};
input PRICE_TYPE InpVWAPPriceType = CLOSE_HIGH_LOW;                        // Price type that is used to determine VWAP values
input bool InpVWAPEnableDaily = true;                                      // Enable daily VWAP
input bool InpVWAPEnableWeekly = true;                                     // Enable weekly VWAP
input bool InpVWAPEnableMonthly = true;                                    // Enable monthly VWAP

// Allow EA to trade on multiple/specific strategies
input bool InpTDICrossoverFiftyMiddleStrategy = false;                     // Open trades based on TDI crossover and middle above 50 indicators
input bool InpTDICrossoverAboveBelowMiddleStrategy = false;                // Open trades based on TDI crossover and price and signal above/below middle indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAStrategy = false;         // Open trades based on TDI Crossover, middle above 50, price and signal above middle, and HA indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy = false;     // Open trades based on TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP indicators

// Info based configurations
input bool InpShowExpertConfigInfo = true;                                 // Show expert advisor configuration information
input bool InpShowExpertTradeInfo = true;                                  // Show expert advisor trade info (stop loss, take profit, etc.)
input bool InpShowExpertIndicatorValues = true;                            // Show expert advisor indictaor information
input color InpInfoColor = clrWhite;                                       // Color used for color for info to chart

// Global variables
double EntryPrice = 0.0;
double StopLoss = 0.0;
double TakeProfit = 0.0;
double LotSize = 0.0;
datetime LastBarTime = 0;

int TDIIndicatorHandler = 0;
int VWAPIndicatorHandler = 0;
int HAIndicatorHandler = 0;

CTrade Trade;
CPositionInfo PositionInfo;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  // Check if EA is attached to a chart
  if (Symbol() == NULL)
  {
    Print("Error: EA is not attached to a chart");
    return (INIT_FAILED);
  }

  // Add your initialization code here
  EntryPrice = 0.0;
  StopLoss = 0.0;
  TakeProfit = 0.0;
  LastBarTime = 0;
    
  // Load indictaors
  TDIIndicatorHandler = iCustom(Symbol(), PERIOD_CURRENT, "HammonsBot/HammonsIndicator-TDI", InpTDIRsiPeriod, InpTDIBBandVol, InpTDIStandardDev, InpTDIPriceLine, InpTDIPriceType, InpTDISignalLine, InpTDISignalType);
  VWAPIndicatorHandler = iCustom(Symbol(), PERIOD_CURRENT, "HammonsBot/HammonsIndicator-VWAP", InpVWAPPriceType, InpVWAPEnableDaily, InpVWAPEnableWeekly, InpVWAPEnableMonthly);
  HAIndicatorHandler = iCustom(Symbol(), PERIOD_CURRENT, "HammonsBot/HammonsIndicator-HA", 0);

  return(INIT_SUCCEEDED);
}
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  ObjectsDeleteAll(ChartID(), 0);
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  // Indicator Information
  // TDI indicator
  double BufferTDIRSI[], BufferTDIBBandUpper[], BufferTDIBaseline[], BufferTDIBBandLower[], BufferTDIPrice[], BufferTDISignal[];
    
  ArraySetAsSeries(BufferTDIBBandUpper, true);
  ArraySetAsSeries(BufferTDIBaseline, true);
  ArraySetAsSeries(BufferTDIBBandLower, true);
  ArraySetAsSeries(BufferTDIPrice, true);
  ArraySetAsSeries(BufferTDISignal, true);
  
  if (CopyBuffer(TDIIndicatorHandler, 0, 0, 20, BufferTDIPrice) < 0){Print("Copy Buffer BufferTDIPrice error: ",GetLastError());}
  if (CopyBuffer(TDIIndicatorHandler, 1, 0, 20, BufferTDISignal) < 0){Print("Copy Buffer BufferTDISignal error: ",GetLastError());}
  if (CopyBuffer(TDIIndicatorHandler, 2, 0, 20, BufferTDIBBandUpper) < 0){Print("Copy Buffer BufferTDIBBandUpper error: ",GetLastError());}
  if (CopyBuffer(TDIIndicatorHandler, 3, 0, 20, BufferTDIBaseline) < 0){Print("Copy Buffer BufferTDIBaseline error: ",GetLastError());}
  if (CopyBuffer(TDIIndicatorHandler, 4, 0, 20, BufferTDIBBandLower) < 0){Print("Copy Buffer BufferTDIBBandLower error: ",GetLastError());}
  
  // TDI Crossovers
  bool TDIBuyCrossover = CrossoverCheck(BufferTDISignal[1], BufferTDIPrice[1], BufferTDIPrice[0], BufferTDISignal[0]);
  bool TDISellCrossover = CrossoverCheck(BufferTDIPrice[1], BufferTDISignal[1], BufferTDISignal[0], BufferTDIPrice[0]);
  
  
  // VWAP indicator
  double BufferVWAPDaily[], BufferVWAPWeekly[], BufferVWAPMonthly[];
  
  ArraySetAsSeries(BufferVWAPDaily, true);
  ArraySetAsSeries(BufferVWAPWeekly, true);
  ArraySetAsSeries(BufferVWAPMonthly, true);
  
  if (CopyBuffer(VWAPIndicatorHandler, 0, 0, 20, BufferVWAPDaily) < 0){Print("Copy Buffer BufferVWAPDaily error: " , GetLastError());}
  if (CopyBuffer(VWAPIndicatorHandler, 1, 0, 20, BufferVWAPWeekly) < 0){Print("Copy Buffer BufferVWAPWeekly error: " , GetLastError());}
  if (CopyBuffer(VWAPIndicatorHandler, 2, 0, 20, BufferVWAPMonthly) < 0){Print("Copy Buffer BufferVWAPMonthly error: " , GetLastError());}
  
  
  //Heiken Ashi indicators
  double BufferHAOpen[], BufferHAHigh[], BufferHALow[], BufferHAClose[];
  
  ArraySetAsSeries(BufferHAOpen, true);
  ArraySetAsSeries(BufferHAHigh, true);
  ArraySetAsSeries(BufferHALow, true);
  ArraySetAsSeries(BufferHAClose, true);
    
  if (CopyBuffer(HAIndicatorHandler, 0, 0, 20, BufferHAOpen) < 0){Print("Copy Buffer BufferHAOpen error: " , GetLastError());}
  if (CopyBuffer(HAIndicatorHandler, 1, 0, 20, BufferHAHigh) < 0){Print("Copy Buffer BufferHAHigh error: " , GetLastError());}
  if (CopyBuffer(HAIndicatorHandler, 2, 0, 20, BufferHALow) < 0){Print("Copy Buffer BufferHALow error: " , GetLastError());}
  if (CopyBuffer(HAIndicatorHandler, 3, 0, 20, BufferHAClose) < 0){Print("Copy Buffer BufferHAClose error: " , GetLastError());}
  
  
  // Checking to see if  there are any open trades
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
    
    string TextTDICrossoverFiftyMiddleTradeOpen = "TDI Cross Fifty Middle: "+ (IsTDICrossoverFiftyMiddleTradeOpen ? "true" : "false");
    PrintTextChart("ObjectTDICrossoverFiftyMiddleTradeOpen", TextTDICrossoverFiftyMiddleTradeOpen, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverAboveBelowMiddleTradeOpen = "TDI Cross Above/Below Middle: "+ (IsTDICrossoverAboveBelowMiddleTradeOpen ? "true" : "false");
    PrintTextChart("ObjectTDICrossoverAboveBelowMiddleTradeOpen", TextTDICrossoverAboveBelowMiddleTradeOpen, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverFiftyAboveBelowMiddleHATradeOpen = "TDI Cross Fifty Above/Below and Middle & HA: "+ (IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen ? "true" : "false");
    PrintTextChart("ObjectTDICrossoverFiftyAboveBelowMiddleHATradeOpen", TextTDICrossoverFiftyAboveBelowMiddleHATradeOpen, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen = "TDI Cross Fifty Above/Below Middle & HA & VWAP: "+ (IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen ? "true" : "false");
    PrintTextChart("ObjectTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen", TextTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextSpaceBreakEndTrade = "==================================================================";
    PrintTextChart("ObjectSpaceBreakEndTrade", TextSpaceBreakEndTrade, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
  }
  
  if (InpShowExpertIndicatorValues)
  {
    if (!InpShowExpertTradeInfo)
    {
      string TextSpaceBreakBeginningIndicators = "==================================================================";
      PrintTextChart("ObjectSpaceBreakBeginningIndicators", TextSpaceBreakBeginningIndicators, InpInfoColor, DashboardYValue);
      DashboardYValue += 15;
    }
    
    string TextTDIBBandUpper = "TDI BBand Upper Current Bar: " + DoubleToString(BufferTDIBBandUpper[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferTDIBBandUpper[1], Digits());
    PrintTextChart("ObjectTDIBBandUpper", TextTDIBBandUpper, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDIBaseline = "TDI Baseline Current Bar: " + DoubleToString(BufferTDIBaseline[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferTDIBaseline[1], Digits());
    PrintTextChart("ObjectTDIBaseline", TextTDIBaseline, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDIBBandLower = "TDI BBand Lower Current Bar: " + DoubleToString(BufferTDIBBandLower[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferTDIBBandLower[1], Digits());
    PrintTextChart("ObjectTDIBBandLower", TextTDIBBandLower, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDIPrice = "TDI Price Current Bar: " + DoubleToString(BufferTDIPrice[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferTDIPrice[1], Digits());
    PrintTextChart("ObjectTDIPrice", TextTDIPrice, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDISignal = "TDI Signal Current Bar: " + DoubleToString(BufferTDISignal[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferTDISignal[1], Digits());
    PrintTextChart("ObjectTDISignal", TextTDISignal, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextTDICross = "TDI Cross Buy: " + (TDIBuyCrossover ? "true" : "false") + " / Sell: " + (TDISellCrossover ? "true" : "false");
    PrintTextChart("ObjectTDICross", TextTDICross, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextVWAPDaily = "VWAP Daily Current Bar: " + DoubleToString(BufferVWAPDaily[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferVWAPDaily[1], Digits());
    PrintTextChart("ObjectVWAPDaily", TextVWAPDaily, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextVWAPWeekly = "VWAP Weekly Current Bar: " + DoubleToString(BufferVWAPWeekly[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferVWAPWeekly[1], Digits());
    PrintTextChart("ObjectVWAPWeekly", TextVWAPWeekly, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextVWAPMonthly = "VWAP Monthly Current Bar: " + DoubleToString(BufferVWAPMonthly[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferVWAPMonthly[1], Digits());
    PrintTextChart("ObjectVWAPMonthly", TextVWAPMonthly, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextHAOpen = "HA Open Current Bar: " + DoubleToString(BufferHAOpen[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferHAOpen[1], Digits());
    PrintTextChart("ObjectHAOpen", TextHAOpen, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextHAHigh = "HA High Current Bar: " + DoubleToString(BufferHAHigh[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferHAHigh[1], Digits());
    PrintTextChart("ObjectHAHigh", TextHAHigh, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextHALow = "HA Low Current Bar: " + DoubleToString(BufferHALow[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferHALow[1], Digits());
    PrintTextChart("ObjectHALow", TextHALow, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextHAClose = "HA Close Current Bar: " + DoubleToString(BufferHAClose[0], Digits()) + " / Previous Bar: " + DoubleToString(BufferHAClose[1], Digits());
    PrintTextChart("ObjectHAClose", TextHAClose, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
    
    string TextSpaceBreakEndIndicator = "==================================================================";
    PrintTextChart("ObjectSpaceBreakEndIndicator", TextSpaceBreakEndIndicator, InpInfoColor, DashboardYValue);
    DashboardYValue += 15;
  }
  
  
  // Check if there is an open trade, handle trailing stop loss/take profit if enabled, and prevents more trades from being opened
  double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
  double RiskAmount = Balance * InpRiskPercentage / 100.0;
  LotSize = NormalizeDouble(RiskAmount / (InpStopLoss * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)), 2);
  
  
  // Check if we are allowed to trade on the current day of the week
  datetime CurrentTime = TimeCurrent();
  MqlDateTime CurrentDatetime;
  TimeToStruct(CurrentTime, CurrentDatetime);


  // Check if we are within the allowed time frame for trade execution
  if (CurrentDatetime.hour < InpTimeFrameStart || CurrentDatetime.hour >= InpTimeFrameEnd)
  {
    Print("Trading not allowed outside of " + IntegerToString(InpTimeFrameStart) + " and " + IntegerToString(InpTimeFrameEnd) + ". Current time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
    return;
  }
    
    datetime CurrentBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
    if (CurrentBarTime != LastBarTime)
    {
      LastBarTime = CurrentBarTime;
    
      // Adjust stoploss
      if (InpEnableTrailingStop)
      {
        TrailingStop(InpStopLoss);
      }
    
    
      int DayOfTheWeek = CurrentDatetime.day_of_week;
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
        Print("Trading not allowed on this day: " + TimeToString(CurrentTime, TIME_DATE|TIME_MINUTES));
        return;
      }
    
    
    // Trading logic      
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there is a buy crossover, Middle BB is above 50, TDI middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverFiftyMiddleStrategy && !IsTDICrossoverFiftyMiddleTradeOpen && TDIBuyCrossover && BufferTDIBaseline[0] > 50 && BufferTDIBaseline[0] < 70 && BufferTDIPrice[0] < 70 && BufferTDISignal[0] < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyMiddleMagicNumber);
    }

    // If strategy is allowed, there are no open trades, TDI sell signal is true, there is a sell crossover, Middle BB is below 50, TDI middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverFiftyMiddleStrategy && !IsTDICrossoverFiftyMiddleTradeOpen && TDISellCrossover && BufferTDIBaseline[0] < 50 && BufferTDIBaseline[0] > 30 && BufferTDIPrice[0] > 30 && BufferTDISignal[0] > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyMiddleMagicNumber);
    }
    
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there is a buy crossover, TDI Price is above BB Middle, and TDI Signal is above BB Middle, TDI middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverAboveBelowMiddleStrategy && !IsTDICrossoverAboveBelowMiddleTradeOpen && TDIBuyCrossover && BufferTDIPrice[0] > BufferTDIBaseline[0] && BufferTDISignal[0] > BufferTDIBaseline[0] && BufferTDIBaseline[0] < 70 && BufferTDIPrice[0] < 70 && BufferTDISignal[0] < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverAboveBelowMiddleMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, TDI sell signal is true,there is a sell crossover, TDI Price is below BB Middle, and TDI Signal is below BB Middle, TDI middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverAboveBelowMiddleStrategy && !IsTDICrossoverAboveBelowMiddleTradeOpen && TDISellCrossover && BufferTDIPrice[0] < BufferTDIBaseline[0] && BufferTDISignal[0] < BufferTDIBaseline[0] && BufferTDIBaseline[0] > 30 && BufferTDIPrice[0] > 30 && BufferTDISignal[0] > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverAboveBelowMiddleMagicNumber);
    }
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there has been a buy crossover, Middle BB is above 50, , TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish, TD middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen && TDIBuyCrossover && BufferTDIBaseline[0] > 50 && BufferTDIPrice[0] > BufferTDIBaseline[0] && BufferTDISignal[0] > BufferTDIBaseline[0] && BufferHAOpen[0] == BufferHALow[0] && BufferHAOpen[0] < BufferHAClose[0] && BufferTDIBaseline[0] < 70 && BufferTDIPrice[0] < 70 && BufferTDISignal[0] < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, TDI sell signal is true, there has been a sell crossover, Middle BB is below 50, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish, TD middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen && TDISellCrossover && BufferTDIBaseline[0] < 50 && BufferTDIPrice[0] < BufferTDIBaseline[0] && BufferTDISignal[0] < BufferTDIBaseline[0] && BufferHAOpen[0] == BufferHAHigh[0] && BufferHAOpen[0] > BufferHAClose[0] && BufferTDIBaseline[0] > 30 && BufferTDIPrice[0] > 30 && BufferTDISignal[0] > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAMagicNumber);
    }
    
    // If strategy is allowed, there are no open trades, TDI buy signal is true, there has been a buy crossover, Middle BB is above 50, , TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish, HAOpen is above VWAP, TD middle under 70, TDI price under 70, TDI signal under 70
    if (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen && TDIBuyCrossover && BufferTDIBaseline[0] > 50 && BufferTDIPrice[0] > BufferTDIBaseline[0] && BufferTDISignal[0] > BufferTDIBaseline[0] && BufferHAOpen[0] == BufferHALow[0] && BufferHAOpen[0] < BufferHAClose[0] && BufferHAOpen[0] > BufferVWAPDaily[0] && BufferTDIBaseline[0] < 70 && BufferTDIPrice[0] < 70 && BufferTDISignal[0] < 70)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, TDI sell signal is true, there has been a sell crossover, Middle BB is below 50, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish, HAOpen is below VWAP, TD middle above 30, TDI price above 30, TDI signal above 30
    if (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen && TDISellCrossover && BufferTDIBaseline[0] < 50 && BufferTDIPrice[0] < BufferTDIBaseline[0] && BufferTDISignal[0] < BufferTDIBaseline[0] && BufferHAOpen[0] == BufferHAHigh[0] && BufferHAOpen[0] > BufferHAClose[0] && BufferHAOpen[0] < BufferVWAPDaily[0] && BufferTDIBaseline[0] > 30 && BufferTDIPrice[0] > 30 && BufferTDISignal[0] > 30)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMiddleHAVWAPMagicNumber);
    }
      
  }
  
  return;
}


//+------------------------------------------------------------------+
// Function for checking for crossovers                              |
//+------------------------------------------------------------------+
bool CrossoverCheck(double FunctInpPreviousIndicatorOne, double FunctInpPreviousIndicatorTwo, double FunctInpCurrentIndicatorOne, double FunctInpCurrentIndicatorTwo)
{
  if (FunctInpPreviousIndicatorOne > FunctInpPreviousIndicatorTwo && FunctInpCurrentIndicatorOne > FunctInpCurrentIndicatorTwo)
  {
    return true;
  }
  return false;
}


//+------------------------------------------------------------------+
// Function for checking if a trade is open                          |
//+------------------------------------------------------------------+
bool IsTradeOpen(int FunctInpMagicNumber, bool FunctInpAllowBothPositions) 
{
  for (int i = 0; i < PositionsTotal(); i++) 
  {
    if (PositionInfo.SelectByIndex(i) && PositionInfo.Symbol() == Symbol() && PositionInfo.Magic() == FunctInpMagicNumber && PositionInfo.PositionType() == POSITION_TYPE_BUY && FunctInpAllowBothPositions == true)
    {
      // Allows for both position types to be opened - specific to buys
      //Print("BUY position found with allow both positions allowed, setting IsTradeOpen to true.");
      return true;
    }

    if (PositionInfo.SelectByIndex(i) && PositionInfo.Symbol() == Symbol() && PositionInfo.Magic() == FunctInpMagicNumber && PositionInfo.PositionType() == POSITION_TYPE_SELL && FunctInpAllowBothPositions == true)
    {
      // Allows for both position types to be opened - specific to sells
      //Print("SELL position found with allow both positions allowed, setting IsTradeOpen to true.");
      return true;
    }
    
    if (PositionInfo.SelectByIndex(i) && PositionInfo.Symbol() == Symbol() && PositionInfo.Magic() == FunctInpMagicNumber) 
    {
      // Allows only a single trade, regardless of position, to be opened.
      //Print("Position found, setting IsTradeOpen to true.");
      return true;
    }
  }

  // No open trade with the specified Magic Number found
  //Print("No trades open, setting IsTradeOpen to false.");
  return false;
}


//+------------------------------------------------------------------+
// Function for controlling trailing stoploss                        |
//+------------------------------------------------------------------+
void TrailingStop(double FunctInpStopLoss) 
{
  for (int i = 0; i < PositionsTotal(); i++)
  {
    if(PositionInfo.SelectByIndex(i) && PositionInfo.Symbol() == Symbol())
    {
      double FunctCurrentStopLoss = PositionInfo.StopLoss();
      double FunctCurrentTakeProfit = PositionInfo.TakeProfit();
      double FunctCurrentPrice = PositionInfo.PriceCurrent();
      double FunctStopLossDistance = FunctInpStopLoss * Point();
 
      if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
      {
        if((FunctCurrentPrice - FunctStopLossDistance > FunctCurrentStopLoss) || FunctCurrentStopLoss == 0.0)
        {
          double FunctNewStopLoss = NormalizeDouble((FunctCurrentPrice - FunctStopLossDistance), Digits());
          if (Trade.PositionModify(PositionInfo.Ticket(), FunctNewStopLoss, PositionInfo.TakeProfit()))
          {
            Print("BUY Position Modified: Ticket=", PositionInfo.Ticket(), ", Symbol=", Symbol(), ", New Stop Loss=", FunctNewStopLoss);
          }
          else
          {
            Print("Failed to modify BUY position. Last error: ", GetLastError());
          }
        }
      }
      if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
      {
        if(FunctCurrentPrice + FunctStopLossDistance < FunctCurrentStopLoss || FunctCurrentStopLoss == 0.0)
        {
          double FunctNewStopLoss = NormalizeDouble((FunctCurrentPrice + FunctStopLossDistance), Digits());
          if (Trade.PositionModify(PositionInfo.Ticket(), FunctNewStopLoss, PositionInfo.TakeProfit()))
          {
            Print("SELL Position Modified: Ticket=", PositionInfo.Ticket(), ", Symbol=", Symbol(), ", New Stop Loss=", FunctNewStopLoss);
          }
          else
          {
            Print("Failed to modify SELL position. Last error: ", GetLastError());
          }
        }
      }
    } 
  }
}


//+------------------------------------------------------------------+
// Function for opening a BUY trade                                  |
//+------------------------------------------------------------------+
void OpenBuyTrade(double FunctEntryPrice, double FunctStopLoss, double FunctTakeProfit, double FunctRiskAmount, double FunctInpStopLoss, double FunctInpRewardPercentage, int FunctInpMagicNumber)
{
  // Enter a buy position
  double FunctLotSize = 0.0;
  if (FunctEntryPrice == 0.0)
  {
    // Create a trade request
    FunctLotSize = NormalizeDouble(FunctRiskAmount / (FunctInpStopLoss * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)), 2);
    if (FunctLotSize < 0.01)
    {
      FunctLotSize = 0.01;
    }
    FunctEntryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    FunctStopLoss = FunctEntryPrice - FunctInpStopLoss * Point();
    FunctTakeProfit = FunctEntryPrice + (FunctInpRewardPercentage * FunctInpStopLoss) * Point();

    // Send the trade request
    Trade.SetExpertMagicNumber(FunctInpMagicNumber);
    if (Trade.Buy(FunctLotSize, Symbol(), FunctEntryPrice, FunctStopLoss, FunctTakeProfit, IntegerToString(FunctInpMagicNumber)))
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


//+------------------------------------------------------------------+
// Function for opening a SELL trade                                 |
//+------------------------------------------------------------------+
void OpenSellTrade(double FunctEntryPrice, double FunctStopLoss, double FunctTakeProfit, double FunctRiskAmount, double FunctInpStopLoss, double FunctInpRewardPercentage, int FunctInpMagicNumber)
{
  // Enter a sell position
  double FunctLotSize = 0.0;
  if (FunctEntryPrice == 0.0)
  {
    // Create a trade request
    FunctLotSize = NormalizeDouble(FunctRiskAmount / (FunctInpStopLoss * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)), 2);
    if (FunctLotSize < 0.01)
    {
      FunctLotSize = 0.01;
    }
    FunctEntryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    FunctStopLoss = FunctEntryPrice + FunctInpStopLoss * Point();
    FunctTakeProfit = FunctEntryPrice - (FunctInpRewardPercentage * FunctInpStopLoss) * Point();

    // Send the trade request
    Trade.SetExpertMagicNumber(FunctInpMagicNumber);
    if (Trade.Sell(FunctLotSize, Symbol(), FunctEntryPrice, FunctStopLoss, FunctTakeProfit, IntegerToString(FunctInpMagicNumber)))
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


//+------------------------------------------------------------------+
// Function for printing text to chart                               |
//+------------------------------------------------------------------+
void PrintTextChart( string FunctObjectName, string FunctObjText, color FunctObjColor, int FunctYTextPixelSpace)
{
   ObjectCreate(0,FunctObjectName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, FunctObjectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, FunctObjectName, OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, FunctObjectName, OBJPROP_YDISTANCE, FunctYTextPixelSpace);
   ObjectSetInteger(0, FunctObjectName, OBJPROP_COLOR, FunctObjColor);
   ObjectSetInteger(0, FunctObjectName, OBJPROP_FONTSIZE, 7);
   ObjectSetString(0, FunctObjectName, OBJPROP_FONT, "Verdana");
   ObjectSetString(0, FunctObjectName, OBJPROP_TEXT, FunctObjText);
}
