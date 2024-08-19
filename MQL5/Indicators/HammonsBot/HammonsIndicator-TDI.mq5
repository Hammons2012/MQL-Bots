//+------------------------------------------------------------------+
//|                                         HammonsIndicator-TDI.mq5 |
//|                                  Copyright 2023, Joshua Mashburn |
//+------------------------------------------------------------------+
#property copyright         "Copyright 2023, Joshua Mashburn"
#property version           "1.0"

// Constants
#define LEVEL_OVERBOUGHT  70
#define LEVEL_NEUTRAL     50
#define LEVEL_OVERSOLD    30

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   5

// Indicator labels
#property indicator_label1  "RSI Price"
#property indicator_label2  "RSI Signal"
#property indicator_label3  "BBand Upper"
#property indicator_label4  "Market Base"
#property indicator_label5  "BBand Lower"

// Indicator colors and styles
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type1    DRAW_LINE

#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_type2    DRAW_LINE

#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_type3    DRAW_LINE

#property indicator_color4  clrYellow
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_type4    DRAW_LINE

#property indicator_color5  clrDodgerBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
#property indicator_type5    DRAW_LINE

// Indicator user inputs
input int    rsiPeriod        = 13;                      // RSI_Period: 8-25
input int    volatilityBand   = 34;                      // Volatility_Band: 20-40
input double stdDev           = 1.6185;                  // Standard deviations: 1-3
input int    priceLine        = 2;                       // MA period for price
input ENUM_MA_METHOD priceType = MODE_SMA;               // MA type for price
input int    signalLine       = 7;                       // MA period for signal
input ENUM_MA_METHOD signalType = MODE_SMA;              // MA type for signal

// Global variables
double rsiBuffer[], upperBandBuffer[], baselineBuffer[], lowerBandBuffer[], priceBuffer[], signalBuffer[];
int rsiHandle, rsiPriceHandle, rsiSignalHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                       |
//+------------------------------------------------------------------+
int OnInit()
{
    // Indicator buffers
    SetIndexBuffer(0, priceBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, signalBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, upperBandBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, baselineBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, lowerBandBuffer, INDICATOR_DATA);
    SetIndexBuffer(5, rsiBuffer, INDICATOR_DATA);

    // Setting indicator parameters
    IndicatorSetInteger(INDICATOR_DIGITS, Digits());
    IndicatorSetInteger(INDICATOR_LEVELS, 3);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, LEVEL_OVERBOUGHT);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, LEVEL_NEUTRAL);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, LEVEL_OVERSOLD);

    // Setting buffer arrays as timeseries
    ArraySetAsSeries(rsiBuffer, true);
    ArraySetAsSeries(upperBandBuffer, true);
    ArraySetAsSeries(baselineBuffer, true);
    ArraySetAsSeries(lowerBandBuffer, true);
    ArraySetAsSeries(priceBuffer, true);
    ArraySetAsSeries(signalBuffer, true);

    // Calculation handles
    rsiHandle = iRSI(Symbol(), PERIOD_CURRENT, rsiPeriod, PRICE_CLOSE);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(ChartID(), 0);
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
                const int &spread[])
{
    // Check and calculate the number of bars to be processed
    if (rates_total < fmax(volatilityBand, 4))
        return 0;

    // Check and calculate the number of bars to be processed
    int limit = rates_total - prev_calculated;
    if (limit > 1)
    {
        limit = rates_total - volatilityBand - 2;
        ArrayInitialize(rsiBuffer, EMPTY_VALUE);
        ArrayInitialize(upperBandBuffer, EMPTY_VALUE);
        ArrayInitialize(baselineBuffer, EMPTY_VALUE);
        ArrayInitialize(lowerBandBuffer, EMPTY_VALUE);
        ArrayInitialize(priceBuffer, EMPTY_VALUE);
        ArrayInitialize(signalBuffer, EMPTY_VALUE);
    }

    // Prepare data
    int count = (limit > 1 ? rates_total : 1), rsiCopied = 0;
    rsiCopied = CopyBuffer(rsiHandle, 0, 0, count, rsiBuffer);
    if (rsiCopied != count)
        return 0;

    double bufferTmpRsi[100];
    for (int i = limit; i >= 0 && !IsStopped(); i--)
    {
        double ma = 0;
        for (int j = i; j < i + volatilityBand; j++)
        {
            bufferTmpRsi[j - i] = rsiBuffer[j];
            ma += rsiBuffer[j] / volatilityBand;
        }
        upperBandBuffer[i] = (ma + (stdDev * StDev(bufferTmpRsi, volatilityBand)));
        lowerBandBuffer[i] = (ma - (stdDev * StDev(bufferTmpRsi, volatilityBand)));
        baselineBuffer[i] = ((upperBandBuffer[i] + lowerBandBuffer[i]) / 2);

        priceBuffer[i] = iMAOnArray(rsiBuffer, 0, priceLine, 0, priceType, i);
        signalBuffer[i] = iMAOnArray(rsiBuffer, 0, signalLine, 0, signalType, i);
    }

    return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StDev(double &data[], const int period)
{
    return (sqrt(Variance(data, period)));
}

//+------------------------------------------------------------------+
//| Calculate Variance                                                |
//+------------------------------------------------------------------+
double Variance(double &data[], const int period)
{
    double sum = 0, ssum = 0;
    for (int i = 0; i < period; i++)
    {
        sum += data[i];
        ssum += pow(data[i], 2);
    }
    return (ssum * period - sum * sum) / (period * (period - 1));
}

//+------------------------------------------------------------------+
//| Simplified SMA calculation.                                      |
//+------------------------------------------------------------------+
double iMAOnArray(double &array[], int total, int iMAPeriod, int ma_shift, ENUM_MA_METHOD ma_method, int shift)
{
    double buf[];
    switch (ma_method)
    {
        // Simplified SMA. No longer works with ma_shift parameter.
        case MODE_SMA:
        {
            double sum = 0;
            for (int i = shift; i < shift + iMAPeriod; i++)
                sum += array[i] / iMAPeriod;
            return sum;
        }
        case MODE_EMA:
        {
            double pr = 2.0 / (iMAPeriod + 1);
            int pos = total - 2;
            while (pos >= 0)
            {
                if (pos == total - 2) buf[pos + 1] = array[pos + 1];
                buf[pos] = array[pos] * pr + buf[pos + 1] * (1 - pr);
                pos--;
            }
            return buf[shift + ma_shift];
        }
        case MODE_SMMA:
        {
            double sum = 0;
            int i, k, pos;
            pos = total - iMAPeriod;
            while (pos >= 0)
            {
                if (pos == total - iMAPeriod)
                {
                    for (i = 0, k = pos; i < iMAPeriod; i++, k++)
                    {
                        sum += array[k];
                        buf[k] = 0;
                    }
                }
                else sum = buf[pos + 1] * (iMAPeriod - 1) + array[pos];
                buf[pos] = sum / iMAPeriod;
                pos--;
            }
            return buf[shift + ma_shift];
        }
        case MODE_LWMA:
        {
            double sum = 0.0, lsum = 0.0;
            double price;
            int i, weight = 0, pos = total - 1;
            for (i = 1; i <= iMAPeriod; i++, pos--)
            {
                price = array[pos];
                sum += price * i;
                lsum += price;
                weight += i;
            }
            pos++;
            i = pos + iMAPeriod;
            while (pos >= 0)
            {
                buf[pos] = sum / weight;
                if (pos == 0) break;
                pos--;
                i--;
                price = array[pos];
                sum = sum - lsum + price * iMAPeriod;
                lsum -= array[i];
                lsum += price;
            }
            return buf[shift + ma_shift];
        }
        default:
            return 0;
    }
    return 0;
}