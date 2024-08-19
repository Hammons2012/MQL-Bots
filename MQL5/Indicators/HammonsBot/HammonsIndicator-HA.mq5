//+------------------------------------------------------------------+
//|                                          HammonsIndicator-HA.mq5 |
//|                                                  Joshua Mashburn |
//+------------------------------------------------------------------+
#property copyright         "Copyright 2023, Joshua Mashburn"
#property version           "1.0"

// Indicator properties
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDarkGreen, clrCrimson
#property indicator_label1  "Heiken Ashi Open;Heiken Ashi High;Heiken Ashi Low;Heiken Ashi Close"

// Indicator buffers
double haOpenBuffer[];
double haHighBuffer[];
double haLowBuffer[];
double haCloseBuffer[];
double haColorBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, haOpenBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, haHighBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, haLowBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, haCloseBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, haColorBuffer, INDICATOR_COLOR_INDEX);

    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

    IndicatorSetString(INDICATOR_SHORTNAME, "Heiken Ashi");

    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator calculation function                           |
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
                const int &spread[])
{
    // Validate array sizes
    if (ArraySize(open) != rates_total || ArraySize(high) != rates_total || ArraySize(low) != rates_total || ArraySize(close) != rates_total)
    {
        Print("Array size mismatch. Ensure that all input arrays have the same size.");
        return(INIT_FAILED);
    }

    int start;

    // Preliminary calculations
    if (prev_calculated == 0)
    {
        haLowBuffer[0] = low[0];
        haHighBuffer[0] = high[0];
        haOpenBuffer[0] = open[0];
        haCloseBuffer[0] = close[0];
        start = 1;
    }
    else
    {
        start = prev_calculated - 1;
    }

    // Main loop of calculations
    for (int i = start; i < rates_total && !IsStopped(); i++)
    {
        double haOpenCloseAvg = (haOpenBuffer[i - 1] + haCloseBuffer[i - 1]) / 2;
        double haClose = (open[i] + high[i] + low[i] + close[i]) / 4;
        double haHigh = MathMax(high[i], MathMax(haOpenCloseAvg, haClose));
        double haLow = MathMin(low[i], MathMin(haOpenCloseAvg, haClose));

        haLowBuffer[i] = haLow;
        haHighBuffer[i] = haHigh;
        haOpenBuffer[i] = haOpenCloseAvg;
        haCloseBuffer[i] = haClose;

        // Set candle color
        if (haOpenCloseAvg < haClose)
            haColorBuffer[i] = 0.0; // Bullish (DodgerBlue)
        else
            haColorBuffer[i] = 1.0; // Bearish (Red)
    }

    return(rates_total);
}