//+------------------------------------------------------------------+
//|                                        HammonsIndicator-VWAP.mq5 |
//|                                  Copyright 2023, Joshua Mashburn |
//+------------------------------------------------------------------+
#property copyright         "Copyright 2023, Joshua Mashburn"
#property version           "1.0"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "VWAP Daily"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "VWAP Weekly"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "VWAP Monthly"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

enum DATE_TYPE
{
    DAILY,
    WEEKLY,
    MONTHLY
};

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

datetime CreateDateTime(DATE_TYPE nReturnType = DAILY, datetime dtDay = D'2000.01.01 00:00:00', int pHour = 0, int pMinute = 0, int pSecond = 0)
{
    datetime dtReturnDate;
    MqlDateTime timeStruct;

    TimeToStruct(dtDay, timeStruct);
    timeStruct.hour = pHour;
    timeStruct.min = pMinute;
    timeStruct.sec = pSecond;
    dtReturnDate = (StructToTime(timeStruct));

    if (nReturnType == WEEKLY)
    {
        while (timeStruct.day_of_week != 0)
        {
            dtReturnDate = (dtReturnDate - 86400);
            TimeToStruct(dtReturnDate, timeStruct);
        }
    }

    if (nReturnType == MONTHLY)
    {
        timeStruct.day = 1;
        dtReturnDate = (StructToTime(timeStruct));
    }

    return dtReturnDate;
}

input PRICE_TYPE InpPriceType = CLOSE_HIGH_LOW;
input bool InpEnableDaily = true;
input bool InpEnableWeekly = true;
input bool InpEnableMonthly = true;

bool InpShowDailyValue = true;
bool InpShowWeeklyValue = true;
bool InpShowMonthlyValue = true;

double vwapBufferDaily[];
double vwapBufferWeekly[];
double vwapBufferMonthly[];

double priceArray[];
double totalPriceVolume[];
double totalVolume[];

double sumDailyTPV = 0, sumWeeklyTPV = 0, sumMonthlyTPV = 0;
double sumDailyVol = 0, sumWeeklyVol = 0, sumMonthlyVol = 0;

int indexDaily = 0, indexWeekly = 0, indexMonthly = 0, index = 0;
bool isFirstRun = true;

ENUM_TIMEFRAMES lastTimePeriod = PERIOD_MN1;

datetime lastDay = CreateDateTime(DAILY), lastWeek = CreateDateTime(WEEKLY), lastMonth = CreateDateTime(MONTHLY);

int OnInit()
{
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

    SetIndexBuffer(0, vwapBufferDaily, INDICATOR_DATA);
    SetIndexBuffer(1, vwapBufferWeekly, INDICATOR_DATA);
    SetIndexBuffer(2, vwapBufferMonthly, INDICATOR_DATA);

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    // Cleanup if needed
}

int OnCalculate(const int ratesTotal,
                const int prevCalculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tickVolume[],
                const long &volume[],
                const int &spread[])
{
    if (PERIOD_CURRENT != lastTimePeriod)
    {
        InitializeVariables();
        lastTimePeriod = PERIOD_CURRENT;
    }

    if (ratesTotal > prevCalculated || isFirstRun)
    {
        InitializeArrays(ratesTotal);

        for (; index < ratesTotal; index++)
        {
            UpdateTimeFrames(time);

            CalculatePriceArrays(open, close, high, low);
            CalculateTotalValues(tickVolume, volume);

            UpdateVWAPValues();
        }

        isFirstRun = false;
    }

    return ratesTotal;
}

void InitializeVariables()
{
    isFirstRun = true;
}

void InitializeArrays(const int arraySize)
{
    ArrayResize(priceArray, arraySize);
    ArrayResize(totalPriceVolume, arraySize);
    ArrayResize(totalVolume, arraySize);

    if (InpEnableDaily)
    {
        index = indexDaily;
        sumDailyTPV = 0;
        sumDailyVol = 0;
    }

    if (InpEnableWeekly)
    {
        index = indexWeekly;
        sumWeeklyTPV = 0;
        sumWeeklyVol = 0;
    }

    if (InpEnableMonthly)
    {
        index = indexMonthly;
        sumMonthlyTPV = 0;
        sumMonthlyVol = 0;
    }
}

void UpdateTimeFrames(const datetime &time[])
{
    if (CreateDateTime(DAILY, time[index]) != lastDay)
    {
        indexDaily = index;
        sumDailyTPV = 0;
        sumDailyVol = 0;
    }

    if (CreateDateTime(WEEKLY, time[index]) != lastWeek)
    {
        indexWeekly = index;
        sumWeeklyTPV = 0;
        sumWeeklyVol = 0;
    }

    if (CreateDateTime(MONTHLY, time[index]) != lastMonth)
    {
        indexMonthly = index;
        sumMonthlyTPV = 0;
        sumMonthlyVol = 0;
    }

    lastDay = CreateDateTime(DAILY, time[index]);
    lastWeek = CreateDateTime(WEEKLY, time[index]);
    lastMonth = CreateDateTime(MONTHLY, time[index]);
}

void CalculatePriceArrays(const double &open[], const double &close[], const double &high[], const double &low[])
{
    switch (InpPriceType)
    {
    case OPEN:
        priceArray[index] = open[index];
        break;
    case CLOSE:
        priceArray[index] = close[index];
        break;
    case HIGH:
        priceArray[index] = high[index];
        break;
    case LOW:
        priceArray[index] = low[index];
        break;
    case HIGH_LOW:
        priceArray[index] = (high[index] + low[index]) / 2;
        break;
    case OPEN_CLOSE:
        priceArray[index] = (open[index] + close[index]) / 2;
        break;
    case CLOSE_HIGH_LOW:
        priceArray[index] = (close[index] + high[index] + low[index]) / 3;
        break;
    case OPEN_CLOSE_HIGH_LOW:
        priceArray[index] = (open[index] + close[index] + high[index] + low[index]) / 4;
        break;
    default:
        priceArray[index] = (close[index] + high[index] + low[index]) / 3;
        break;
    }
}

void CalculateTotalValues(const long &tickVolume[], const long &volume[])
{
    if (tickVolume[index])
    {
        totalPriceVolume[index] = (priceArray[index] * tickVolume[index]);
        totalVolume[index] = (double)tickVolume[index];
    }
    else if (volume[index])
    {
        totalPriceVolume[index] = (priceArray[index] * volume[index]);
        totalVolume[index] = (double)tickVolume[index];
    }
}

void UpdateVWAPValues()
{
    if (InpEnableDaily && (index >= indexDaily))
    {
        sumDailyTPV += totalPriceVolume[index];
        sumDailyVol += totalVolume[index];

        if (sumDailyVol)
            vwapBufferDaily[index] = (sumDailyTPV / sumDailyVol);
    }

    if (InpEnableWeekly && (index >= indexWeekly))
    {
        sumWeeklyTPV += totalPriceVolume[index];
        sumWeeklyVol += totalVolume[index];

        if (sumWeeklyVol)
            vwapBufferWeekly[index] = (sumWeeklyTPV / sumWeeklyVol);
    }

    if (InpEnableMonthly && (index >= indexMonthly))
    {
        sumMonthlyTPV += totalPriceVolume[index];
        sumMonthlyVol += totalVolume[index];

        if (sumMonthlyVol)
            vwapBufferMonthly[index] = (sumMonthlyTPV / sumMonthlyVol);
    }
}