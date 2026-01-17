#property copyright "Copyright 2025, (C) TraderRecehan"
#property link      "https://www.traderrecehan.com"
#property version   "2.1"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "GMR-ZZ"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input int   MaxBarsToProcess = 500;
input int   TotalPoints = 15;  // Number of ZZ points analyzed
input int   TouchNum = 3;      // Number of times the price touches the level
input int   Deviation = 10;    // High/low max. deviation around level
input int   Retracement = 0;  // Typical retracement size


int            Goal;
int            LastExtrBar;

// indicator buffers
double         ZZPoints[];

// other parameters
double         Scale;
double         LLow;
double         LHigh;
double         PLow;
double         PHigh;
double         TLow;
double         THigh;
double         Level;

string         com;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // indicator buffers mapping
   SetIndexBuffer(0, ZZPoints, INDICATOR_DATA);

   // set short name and digits   
   PlotIndexSetString(0,PLOT_LABEL,"SiZZ ConZones("+(string)Scale+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
      
   // set plot empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   // setup Scale value
   Scale = Retracement * Point();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // remove all line objects
   ObjectsDeleteAll( 0, "Level_", 0, OBJ_RECTANGLE);
   
   // remove comments, if any
   ChartSetString( 0, CHART_COMMENT, "");
   Scale = 0;
  }  

  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int        rates_total,
                const int        prev_calculated,
                const datetime   &time[],
                const double     &open[],
                const double     &high[],
                const double     &low[],
                const double     &close[],
                const long       &tick_volume[],
                const long       &volume[],
                const int        &spread[])
  {
   int Start;
   int total_bar;
   
   if(rates_total < MaxBarsToProcess+3) return(0);
   
   total_bar = rates_total - MaxBarsToProcess;
   
   if(prev_calculated == 0)  // in case there is no previous calculations
     {
      ArrayInitialize(ZZPoints,0.0); // initialize buffer with zero volues

      Start = total_bar+2;
      if(low[total_bar] < high[total_bar+1])  // ll pertama lebih rendah dari h baru
             {
              PLow = LLow = low[total_bar];
              PHigh = LHigh = high[total_bar+1];
              Goal     = 1;
             }
      else 
             {
              PHigh = LHigh = high[total_bar];
              PLow = LLow  = low[total_bar+1];
              Goal     = 2;
             }
   
     }
   else Start = total_bar - 1;

   // searching for Last High and Last Low
   for(int bar = Start; bar < rates_total - 1; bar++)
     {
      switch(Goal)
           {

            case 1 : // Last was a low - goal is high

                if(low[bar] <= LLow || low[bar] <= ZZPoints[LastExtrBar]) 
                     {
                      LLow = low[bar];
                      ZZPoints[LastExtrBar] = 0;  
                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LLow;
                      THigh = 0;
                      THigh = high[bar];
                      Goal = 1;
                      break;
                     }
                
                if(THigh > high[bar])
                     {
                      ZZPoints[LastExtrBar] = LLow;
                      Goal = 1;
                      break;
                     }
                if(low[bar] >= low[bar-1] && high[bar] < high[bar - 1]) 
                     {
                      ZZPoints[LastExtrBar] = LLow;
                      Goal = 1;
                      break;
                     }
                     
                /**/
                     
                if(high[bar] > high[bar-1] && low[bar] <= low[bar-1]) 
                     {
                      PHigh = LHigh;
                      LHigh = high[bar];
                      TLow  = low[bar];
                      
                    // check if High touches any level
                      Level = CZone( Goal, TotalPoints, TouchNum, LastExtrBar, Deviation, time);

                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LHigh;
                      Goal = 2;
                      break;
                     }
                     
        
                if(high[bar] > (LLow + Scale))
                     {
                      PHigh = LHigh;
                      LHigh = high[bar];
                      TLow  = low[bar];
                      
                    // check if High touches any level
                      Level = CZone( Goal, TotalPoints, TouchNum, LastExtrBar, Deviation, time);

                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LHigh;
                      Goal = 2;
                     }
                break;

            case 2: // Last was a high - goal is low
                   
                   if(high[bar] >= LHigh || high[bar] >= ZZPoints[LastExtrBar])
                     {
                      LHigh = high[bar];
                      ZZPoints[LastExtrBar] = 0;
                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LHigh;
                      TLow = 0;
                      TLow = low[bar];
                      break;
                     }
                   
                   if(TLow < low[bar])
                     {
                      ZZPoints[LastExtrBar] = LHigh;
                      Goal = 2;
                      break;
                     }
                   
                   if(low[bar] > low[bar-1] && high[bar] < high[bar-1]) 
                     {
                      ZZPoints[LastExtrBar] = LHigh;
                      Goal = 2;
                      break;
                     }
                     
                  if(low[bar] >= low[bar-1] && high[bar] <= high[bar-1])
                     {
                      PLow = LLow;
                      LLow  = low[bar];
                      THigh = high[bar];
                      
                    // check if LLow touches any level
                      Level = CZone( Goal, TotalPoints, TouchNum, LastExtrBar, Deviation, time);

                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LLow;
                      Goal = 1;
                      break;
                     }
                     
                   if(low[bar] < (LHigh - Scale))
                     {
                      PLow = LLow;
                      LLow  = low[bar];
                      THigh = high[bar];
                      
                    // check if LLow touches any level
                      Level = CZone( Goal, TotalPoints, TouchNum, LastExtrBar, Deviation, time);

                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LLow;
                      Goal = 1;
                     }
                   break;
           }
     }
   
   return(rates_total);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator CheckLevel  function                            |
//+------------------------------------------------------------------+
   double        CZone(int                par_Goal,
                       int                par_TotalPoints,
                       int                par_TouchNum,
                       int                par_LastExtrBar,
                       int                par_Deviation,
                       const datetime     &time[])
      {
       int     points = 0;
       int     touch_num = 0;
       int     touch_bar;
       int     shift = 1;
       int     high_low;
       double  level = 0;
       double  width = Point() * par_Deviation;
       color   level_color;

       // searchin for non-zero ZZ points
       while(points <= par_TotalPoints && shift <= par_LastExtrBar)
         {
          if(ZZPoints[par_LastExtrBar - shift] != 0)
            {
             switch(high_low)
                  {
                   case 0:
                      if(fabs(ZZPoints[par_LastExtrBar] - ZZPoints[par_LastExtrBar - shift]) > width)
                                 width = ZZPoints[par_LastExtrBar - shift];
                      high_low = 1;
                      break;
                   case 1:
                      if(fabs(ZZPoints[par_LastExtrBar] - ZZPoints[par_LastExtrBar - shift]) < Point() * par_Deviation)
                        {
                         // in case non-zero point is close enough to current point - increase touch counter by one and store the bar index
                         touch_num++;
                         touch_bar = par_LastExtrBar - shift;
                         high_low = 0;
                        }
                      break;
                  }
             points++;
            }
          shift++;
         }
       level_color = clrGray;
       if(touch_num >= par_TouchNum)
         {
          level = ZZPoints[LastExtrBar];
          if(ObjectCreate( 0, "Level_" + IntegerToString(par_LastExtrBar, 4, '0'), OBJ_RECTANGLE, 0, time[touch_bar], width, time[par_LastExtrBar], level))
            {
             switch(par_Goal)
               {
                case 1:
                  level_color = clrBlue;
                  break;
                case 2:
                  level_color = clrRed;
                  break;
               }
             ObjectSetInteger( 0, "Level_" + IntegerToString(par_LastExtrBar, 4, '0'), OBJPROP_COLOR, level_color);
             ObjectSetInteger( 0, "Level_" + IntegerToString(par_LastExtrBar, 4, '0'), OBJPROP_WIDTH, 3);
            }
         }
       return(level);
      }
  
//+------------------------------------------------------------------+
