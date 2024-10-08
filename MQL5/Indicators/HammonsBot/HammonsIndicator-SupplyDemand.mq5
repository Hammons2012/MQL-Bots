//+------------------------------------------------------------------+
//|                                HammonsIndicator-SupplyDemand.mq5 |
//|                                                  Joshua Mashburn |
//+------------------------------------------------------------------+
#property copyright         "Copyright 2023, Joshua Mashburn"
#property version           "1.0"


#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#define RESET 0
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLightSeaGreen
#property indicator_width1  1
#property indicator_label1  "Support"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrIndianRed
#property indicator_width2  1
#property indicator_label2 "Resistance"

double SellBuffer[];
double BuyBuffer[];
int StartBars;
int FRA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   StartBars=6;
   FRA_Handle=iFractals(NULL,PERIOD_CURRENT);
   if(FRA_Handle==INVALID_HANDLE)
     {
       return(INIT_FAILED);
     }

   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetString(0,PLOT_LABEL,"Support");
   PlotIndexSetInteger(0,PLOT_ARROW,159);
   ArraySetAsSeries(SellBuffer,true);

   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetString(1,PLOT_LABEL,"Resistance");
   PlotIndexSetInteger(1,PLOT_ARROW,159);
   ArraySetAsSeries(BuyBuffer,true);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   string short_name="Support & Resistance";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
   if(BarsCalculated(FRA_Handle)<rates_total || rates_total<StartBars) return(RESET);

   int to_copy,limit,bar;
   double FRAUp[],FRALo[],upVel,loVel;

   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      to_copy=rates_total;
      limit=rates_total-StartBars-1;
     }
   else
     {
      to_copy=rates_total-prev_calculated+3;
      limit=rates_total-prev_calculated+2;
     }
  
   ArraySetAsSeries(FRAUp,true);
   ArraySetAsSeries(FRALo,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   if(CopyBuffer(FRA_Handle,0,0,to_copy,FRAUp)<=0) return(RESET);
   if(CopyBuffer(FRA_Handle,1,0,to_copy,FRALo)<=0) return(RESET);

   for(bar=limit; bar>=0; bar--)
     {
       BuyBuffer[bar]=NULL;
       SellBuffer[bar]=NULL;

       upVel=FRAUp[bar];
       loVel=FRALo[bar];

       if(upVel && upVel!=EMPTY_VALUE) BuyBuffer[bar]=high[bar]; else BuyBuffer[bar]=BuyBuffer[bar+1];
       if(loVel && loVel!=EMPTY_VALUE) SellBuffer[bar]=low[bar]; else SellBuffer[bar]=SellBuffer[bar+1];
     }
   
   return(rates_total);
  }
  