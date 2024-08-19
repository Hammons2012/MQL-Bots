//+------------------------------------------------------------------+
//|                                                   HammonsBot.mq4 |
//|                                                  Joshua Mashburn |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Joshua Mashburn"
#property link      ""
#property version   "1.00"
#property strict

// Configurable variables for the EA
// Time based configurations
input int InpTimeFrameStart = 9;                                           // Start time for trade execution (in hours)
input int InpTimeFrameEnd = 17;                                            // End time for trade execution (in hours)

input bool InpTradeOnMonday = true;                                        // Allow trades on Monday
input bool InpTradeOnTuesday = true;                                       // Allow trades on Tuesday
input bool InpTradeOnWednesday = true;                                     // Allow trades on Wednesday
input bool InpTradeOnThursday = true;                                      // Allow trades on Thursday
input bool InpTradeOnFriday = true;                                        // Allow trades on Friday

//Trade based configurations
input int InpTDICrossoverFiftyMiddleMagicNumber = 66666;     				   // Magic number for trades opened by TDI crossover and middle above 50 strategy
input int InpTDICrossoverAboveBelowMiddleMagicNumber = 77777;              // Magic Number for trades opened by TDI crossover and price and signal above/below middle
input int InpTDICrossoverFiftyAboveBelowMIddleHAMagicNumber = 88888;       // Magic Number for trades opened by TDI Crossover, middle above 50, price and signal above middle, and HA
input int InpTDICrossoverFiftyAboveBelowMIddleHAVWAPMagicNumber = 99999;   // Magic Number for trades opened by TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP

input double InpRiskPercentage = 1.0;                                      // User-defined risk percentage
input double InpRewardPercentage = 2.0;                                    // User defined reward percentage
input double InpStopLoss = 20.0;                                           // User-defined  stop loss value
input bool InpEnableTrailingStop = false;                                  // Enable trailing stop loss
input int InpTrailingStopSleep = 3000;                                     // Time, in milliseconds, to sleep after checking for trailing stop
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

// VWAP indicator based configurations
input double InpVWAPDeviation = 10.0;                                      // Deviation for VWAP deviation for trade execution in points

// Allow EA to trade on multiple/spefic strategies
input bool InpTDICrossoverFiftyMiddleStrategy = false;      				   // Open trades based on TDI crossover and middle abce 50 indicators
input bool InpTDICrossoverAboveBelowMiddleStrategy = false;             	// Open trades based on TDI crossover and price and signal above/below middle indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAStrategy = false;         // Open trades based on TDI Crossover, middle above 50, price and signal above middle, and HA indicators
input bool InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy = false;     // Open trades based on TDI Crossover, middle above 50, price and signal above middle, HA, and VWAP indicators

// Info based configurations
input color InpInfoColor = clrWhite;                                       // Color used for color for info to chart

// Global variables
double EntryPrice = 0.0;
double StopLoss = 0.0;
double TakeProfit = 0.0;
datetime LastBarTime = 0;

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
  double VWAPDeviationPositivePrevious = VWAPPrevious + InpVWAPDeviation * Point;
  double VWAPDeviationNegativePrevious = VWAPPrevious - InpVWAPDeviation * Point;
  
  // Current bar values
  double VWAPCurrent = iCustom(Symbol(), 0, "VWAP", 0, 0, 0, 1);
  double VWAPDeviationPositiveCurrent = VWAPCurrent + InpVWAPDeviation * Point;
  double VWAPDeviationNegativeCurrent = VWAPCurrent - InpVWAPDeviation * Point;

  // Check if there is an open trade, handle trailing stop loss/take profit if enabled, and prevents more trades from being opened
  double Balance = AccountBalance();
  double RiskAmount = Balance * InpRiskPercentage / 100.0;
  
  bool IsTDICrossoverFiftyMiddleTradeOpen = IsTradeOpen(InpTDICrossoverFiftyMiddleMagicNumber, InpAllowBothTypePositions);
  bool IsTDICrossoverAboveBelowMiddleTradeOpen = IsTradeOpen(InpTDICrossoverAboveBelowMiddleMagicNumber, InpAllowBothTypePositions);
  bool IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen = IsTradeOpen(InpTDICrossoverFiftyAboveBelowMIddleHAMagicNumber, InpAllowBothTypePositions);
  bool IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen = IsTradeOpen(InpTDICrossoverFiftyAboveBelowMIddleHAVWAPMagicNumber, InpAllowBothTypePositions);
  
  if (InpEnableTrailingStop)
  {
    TrailingStop(InpStopLoss, InpTrailingStopSleep);
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
  
    // Trading logic      
    // If strategy is allowed, there are no open trades, there is a buy crossover, Middle BB is above 50, there is no open wick, the bar is bullish
    if (InpTDICrossoverFiftyMiddleStrategy && !IsTDICrossoverFiftyMiddleTradeOpen && TDIBuyCrossover && TDIBBandMiddleCurrent > 50 && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyMiddleMagicNumber);
    }

    // If strategy is allowed, there are no open trades, there is a sell crossover, Middle BB is below 50, there is no open wick, the bar is bearish
    if (InpTDICrossoverFiftyMiddleStrategy && !IsTDICrossoverFiftyMiddleTradeOpen && TDISellCrossover && TDIBBandMiddleCurrent < 50 && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyMiddleMagicNumber);
    }
    
    // If strategy is allowed, there are no open trades, there is a buy crossover, TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish
    if (InpTDICrossoverAboveBelowMiddleStrategy && !IsTDICrossoverAboveBelowMiddleTradeOpen && TDIBuyCrossover && TDIRSIPriceCurrent > TDIBBandMiddleCurrent && TDIRSISignalCurrent > TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverAboveBelowMiddleMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, there is a sell crossover, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish
    if (InpTDICrossoverAboveBelowMiddleStrategy && !IsTDICrossoverAboveBelowMiddleTradeOpen && TDISellCrossover && TDIRSIPriceCurrent < TDIBBandMiddleCurrent && TDIRSISignalCurrent < TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverAboveBelowMiddleMagicNumber);
    }
    // If strategy is allowed, there are no open trades, there has been a buy crossover, Middle BB is above 50, , TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish
    if (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen && TDIBuyCrossover && TDIBBandMiddleCurrent > 50 && TDIRSIPriceCurrent > TDIBBandMiddleCurrent && TDIRSISignalCurrent > TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMIddleHAMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, there has been a sell crossover, Middle BB is below 50, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish
    if (InpTDICrossoverFiftyAboveBelowMiddleHAStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHATradeOpen && TDISellCrossover && TDIBBandMiddleCurrent < 50 && TDIRSIPriceCurrent < TDIBBandMiddleCurrent && TDIRSISignalCurrent < TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMIddleHAMagicNumber);
    }
    
    // If strategy is allowed, there are no open trades, there has been a buy crossover, Middle BB is above 50, , TDI Price is above BB Middle, and TDI Signal is above BB Middle, there is no open wick, the bar is bullish, HAOpen is above VWAP
    if (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen && TDIBuyCrossover && TDIBBandMiddleCurrent > 50 && TDIRSIPriceCurrent > TDIBBandMiddleCurrent && TDIRSISignalCurrent > TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent > HALowCurrent && HAOpenCurrent > VWAPCurrent)
    {
      OpenBuyTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMIddleHAVWAPMagicNumber);
    }
  
    // If strategy is allowed, there are no open trades, there has been a sell crossover, Middle BB is below 50, TDI Price is below BB Middle, and TDI Signal is below BB Middle, there is no open wick, the bar is bearish, HAOpen is below VWAP
    if (InpTDICrossoverFiftyAboveBelowMiddleHAVWAPStrategy && !IsTDICrossoverFiftyAboveBelowMiddleHAVWAPTradeOpen && TDISellCrossover && TDIBBandMiddleCurrent < 50 && TDIRSIPriceCurrent < TDIBBandMiddleCurrent && TDIRSISignalCurrent < TDIBBandMiddleCurrent && HAOpenCurrent == HALowCurrent && HAHighCurrent < HALowCurrent && HAOpenCurrent < VWAPCurrent)
    {
      OpenSellTrade(EntryPrice, StopLoss, TakeProfit, RiskAmount, InpStopLoss, InpRewardPercentage, InpTDICrossoverFiftyAboveBelowMIddleHAVWAPMagicNumber);
    }
  }
  
  Comment("Trade conditions not met."); 
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
      double FunctEntryPrice = Ask;
      double FunctStopLoss = FunctEntryPrice - FunctInpStopLoss * Point;
      double FunctTakeProfit = FunctEntryPrice + (FunctInpRewardPercentage * FunctInpStopLoss) * Point;
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
      double FunctEntryPrice = Ask;
      double FunctStopLoss = FunctEntryPrice + FunctInpStopLoss * Point;
      double FunctTakeProfit = FunctEntryPrice - (FunctInpRewardPercentage * FunctInpStopLoss) * Point;
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
  
  // Function for trailing stop loss
  void TrailingStop(double FunctInpStopLoss, int FunctInpTrailingStopSleep)
  {
    int TotalOrders = OrdersTotal();
    for (int i = 0; i < TotalOrders; i++)
    {
      if (OrderType() == OP_BUY)
      {
        double StopLossLevel = NormalizeDouble(Bid - FunctInpStopLoss * Point, Digits);
        if (StopLossLevel > OrderStopLoss())
        {
          OrderModify(OrderTicket(), OrderOpenPrice(), StopLossLevel, OrderTakeProfit(), 0, 0);
          Print("Buy Position: Ticket=", OrderTicket(), ", Symbol=", Symbol(), ", Stop Loss=", StopLossLevel);
          Sleep(FunctInpTrailingStopSleep);
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
          OrderModify(OrderTicket(), OrderOpenPrice(), StopLossLevel, OrderTakeProfit(), 0, 0);
          Print("Buy Position: Ticket=", OrderTicket(), ", Symbol=", Symbol(), ", Stop Loss=", StopLossLevel);
        }
        else
        {
          Print("Issues with modifying SELL order, last error: ", GetLastError());
        }
      }
    } 
  }
