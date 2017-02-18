//+------------------------------------------------------------------+
//|                                               SlopeAmaJma_EA.mq5 |
//|                                        Copyright 2017, Wade Pei. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Wade Pei."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define AMA_JMA_MAGIC 12343213
#define INDICATOR_NAME "SlopeAmaJma_JMAed"
#define INDICATOR_NAME_AMA "AMA"
#define INDICATOR_NAME_JMA "Kositsin/JJMA"
#define CONTINUOUS_TICK_NUM 3
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
//---
enum Applied_price_ //Type of constant
 {
  PRICE_CLOSE_ = 1,     //PRICE_CLOSE
  PRICE_OPEN_,          //PRICE_OPEN
  PRICE_HIGH_,          //PRICE_HIGH
  PRICE_LOW_,           //PRICE_LOW
  PRICE_MEDIAN_,        //PRICE_MEDIAN
  PRICE_TYPICAL_,       //PRICE_TYPICAL
  PRICE_WEIGHTED_,      //PRICE_WEIGHTED
  PRICE_SIMPL_,         //PRICE_SIMPL_
  PRICE_QUARTER_,       //PRICE_QUARTER_
  PRICE_TRENDFOLLOW0_, //PRICE_TRENDFOLLOW0_
  PRICE_TRENDFOLLOW1_  //PRICE_TRENDFOLLOW1_
 };
input Applied_price_ IPC = PRICE_MEDIAN_;//price constant
input int LengthJMA = 7; // depth of JMA                   
input int AmaPeriod = 9; // period of AMABuffer
input int LengthJMASmooth = 5; // depth of smoothing     
input double AmaSlopeThreshold = 0.37;
input double MaximumRisk        = 0.02;    // Maximum Risk in percentage
input double DecreaseFactor     = 3;       // Descrease factor
input int DeviationPeriod  = 7; // parameter of smoothing,
input bool CloseToOpen = true;

int PhaseJMA  = 0; // parameter of JMA
int FastMaPeriod = 2; // period of fast MA
int SlowMaPeriod = 30; // period of slow MA
double G = 2.0; // a power the smoothing constant is raised to
int AMAShift = 0; // horizontal shift of the indicator in bar 
int PhaseJMASmooth  = 0; // parameter of smoothing
int MinBarForJma = 33;
long MiTickNoBetweenTrade=100;
int BufferCountToCopy=2;
int ExtTimeOut=0; // time out in seconds between trade operations
enum Tick_type //Type of Tick
 {
  EMPTY = 0,
  OSCILLATION = 1,  
  TREND_BULL,
  TREND_BEAR,   
  OSCI_TO_BULL,        
  OSCI_TO_BEAR,        
  BULL_TO_OSCI,     
  BEAR_TO_OSCI
 };
enum Trade_type //Type of trade
 {
  EMPTY_TD = 0,
  OSCILLATION_TD = 1,  
  TREND_BULL_TD,
  TREND_BEAR_TD,   
  OSCI_TO_BULL_TD,        
  OSCI_TO_BEAR_TD,        
  BULL_TO_OSCI_TD,     
  BEAR_TO_OSCI_TD
 };
Trade_type CurrTradeType=EMPTY_TD;

//+------------------------------------------------------------------+
//| MACD Sample expert class                                         |
//+------------------------------------------------------------------+
class CAmaJmaExpert
  {
protected:
   CTrade            m_trade;                      // trading object
   CSymbolInfo       m_symbol;                     // symbol info object
   CPositionInfo     m_position;                   // trade position object
   CAccountInfo      m_account;                    // account info wrapper
   //--- indicators
   int               m_handle;                     // indicator handle
   int               m_handle_ama;                // indicator handle
   int               m_handle_jma;                // indicator handle
   //--- indicator buffers
   double            m_price[];           
   double            m_ama[];           
   double            m_jma[];         
   double            m_sslope_ama[];                 // smoothed slope of Ama
   double            m_sslope_jma[];                 // smoothed slope of Jma
   double            m_bideriv_ama[];                 // bi-derivative of Ama
   double            m_bideriv_jma[];                 // bi-derivative of Jma
   double            m_tick_volume_ma[];           
   double            m_tick_volume_dev[];   
   
   double            m_price_prev;
   double            m_ama_prev;           
   double            m_jma_prev;         
   double            m_sslope_ama_prev;                
   double            m_sslope_jma_prev;                 
   double            m_bideriv_ama_prev;               
   double            m_bideriv_jma_prev;             
   double            m_tick_volume_ma_prev;           
   double            m_tick_volume_dev_prev; 
     
   double            m_price_curr;
   double            m_ama_curr;           
   double            m_jma_curr;         
   double            m_sslope_ama_curr;                
   double            m_sslope_jma_curr;                 
   double            m_bideriv_ama_curr;               
   double            m_bideriv_jma_curr;             
   double            m_tick_volume_ma_curr;           
   double            m_tick_volume_dev_curr;   
       
   MqlRates          m_rates[];
   //--- indicator values at the moment the position opened
   double            m_open_price;           
   double            m_open_ama;           
   double            m_open_jma;         
   double            m_open_sslope_ama;            
   double            m_open_sslope_jma;   
   int               m_open_bar_no;                   // bars number at that moment   
   long              m_open_tick_no;  
   Trade_type        m_open_trade_type;
       
   double            m_close_price;           
   double            m_close_ama;           
   double            m_close_jma;         
   double            m_close_sslope_ama;            
   double            m_close_sslope_jma;   
   int               m_close_bar_no;                   // bars number at that moment         
   long              m_close_tick_no;      
   Trade_type        m_close_trade_type;
   //--- other variables
   Tick_type         m_tick_types[CONTINUOUS_TICK_NUM];
   int               m_tick_type_index;
   bool              m_is_first_tick;

public:
                     CAmaJmaExpert(void);
                    ~CAmaJmaExpert(void);
   bool              Init(void);
   void              Deinit(void);
   bool              Processing(void);

protected:
   bool              InitIndicators(void);
   bool              PositionClosed(void);
   bool              LongOpened(void);
   bool              ShortOpened(void);
   double            TradeSizeOptimized(void);
   bool              InOscillation(void);
   bool              InTrendBull(void);
   bool              InTrendBear(void);
   bool              FromOsciToTrendBull(void);
   bool              FromOsciToTrendBear(void);
   bool              FromTrendBullToOsci(void);
   bool              FromTrendBearToOsci(void);
   //--- the following seven methods are the above methods in continuously
   bool              InOscillationCont(void);
   bool              InTrendBullCont(void);
   bool              InTrendBearCont(void);
   bool              FromOsciToTrendBullCont(void);
   bool              FromOsciToTrendBearCont(void);
   bool              FromTrendBullToOsciCont(void);
   bool              FromTrendBearToOsciCont(void);
   
   void              RecordTickType(void);
   bool              IsBullArrange(void);
   bool              IsBearArrange(void);
   bool              ShouldCloseLong(void);
   bool              ShouldCloseShort(void);
   bool              ShouldOpenLong(void);
   bool              ShouldOpenShort(void);
   void              RecordValuesOfOpenedPosition(void);
   void              RecordValuesOfClosedPosition(void);
   bool              IsTooFrequent(void);
   bool              IsReachedTickVolumeToOpen(void);
   void              CopyIndicatorValuesToCurr(void);
   void              CopyCurrValuesToPrev(void);

  };
//--- global expert
CAmaJmaExpert ExtExpert;
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAmaJmaExpert::CAmaJmaExpert(void) : m_handle(INVALID_HANDLE),
                                     m_handle_ama(INVALID_HANDLE),
                                     m_handle_jma(INVALID_HANDLE),
                                     m_open_bar_no(0),
                                     m_close_bar_no(0),
                                     m_tick_type_index(-1),
                                     m_is_first_tick(true)
  {
   ArraySetAsSeries(m_price,true);
   ArraySetAsSeries(m_ama,true);
   ArraySetAsSeries(m_jma,true);
   ArraySetAsSeries(m_sslope_ama,true);
   ArraySetAsSeries(m_sslope_jma,true);
   ArraySetAsSeries(m_bideriv_ama,true);
   ArraySetAsSeries(m_bideriv_jma,true);
   ArraySetAsSeries(m_tick_volume_ma,true);
   ArraySetAsSeries(m_tick_volume_dev,true);
   ArraySetAsSeries(m_rates,true);
   
   ArrayResize(m_price, BufferCountToCopy);
   ArrayResize(m_ama, BufferCountToCopy);
   ArrayResize(m_jma, BufferCountToCopy);
   ArrayResize(m_sslope_ama, BufferCountToCopy);
   ArrayResize(m_sslope_jma, BufferCountToCopy);
   ArrayResize(m_bideriv_ama, BufferCountToCopy);
   ArrayResize(m_bideriv_jma, BufferCountToCopy);
   ArrayResize(m_tick_volume_ma, BufferCountToCopy);
   ArrayResize(m_tick_volume_dev, BufferCountToCopy);
   ArrayResize(m_rates, 2);
   
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++)
    {
      m_tick_types[i]=EMPTY;
    }
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAmaJmaExpert::~CAmaJmaExpert(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::Init(void)
  {
//--- initialize common information
   m_symbol.Name(Symbol());                  // symbol
   m_trade.SetExpertMagicNumber(AMA_JMA_MAGIC); // magic
   m_trade.SetMarginMode();
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
//--- set default deviation for trading in adjusted points
   m_trade.SetDeviationInPoints(3*digits_adjust);
//---
   if(!InitIndicators())
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void CAmaJmaExpert::Deinit(void) {
//---
   IndicatorRelease(m_handle);
   IndicatorRelease(m_handle_ama);
   IndicatorRelease(m_handle_jma);
//---   
}
//+------------------------------------------------------------------+
//| Initialization of the indicators                                 |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::InitIndicators(void)
  {
//--- create MACD indicator
   if(m_handle==INVALID_HANDLE)
      if((m_handle=iCustom(NULL,0,INDICATOR_NAME,IPC,LengthJMA,PhaseJMA,AmaPeriod,FastMaPeriod,SlowMaPeriod,G,AMAShift,LengthJMASmooth,PhaseJMASmooth,DeviationPeriod))==INVALID_HANDLE)
        {
         printf("Error creating indicator "+INDICATOR_NAME);
         return(false);
        }
   m_handle_ama=iCustom(NULL,0,INDICATOR_NAME_AMA,IPC,AmaPeriod,FastMaPeriod,SlowMaPeriod,G,AMAShift);
   m_handle_jma=iCustom(NULL,0,INDICATOR_NAME_JMA,IPC,LengthJMA,PhaseJMA,0,0);
//--- succeed
   return(true);
  }
double CAmaJmaExpert::TradeSizeOptimized(void)
  {
   double price=0.0;
   double margin=0.0;
//--- select lot size
   if(!SymbolInfoDouble(Symbol(),SYMBOL_ASK,price))
      return(0.0);
   if(!OrderCalcMargin(ORDER_TYPE_BUY,Symbol(),1.0,price,margin))
      return(0.0);
   if(margin<=0.0)
      return(0.0);

   double lot=NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)*MaximumRisk/margin,2);
//--- calculate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int    orders=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of losses orders without a break

      for(int i=orders-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
           {
            Print("HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=Symbol())
            continue;
         //--- check profit
         double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(profit>0.0)
            break;
         if(profit<0.0)
            losses++;
        }
      //---
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- normalize and check limits
   double stepvol=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   lot=stepvol*NormalizeDouble(lot/stepvol,0);

   double minvol=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(lot<minvol)
      lot=minvol;

   double maxvol=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }

bool CAmaJmaExpert::InOscillation(void)
  {
   return MathAbs(m_sslope_ama_prev)<AmaSlopeThreshold && MathAbs(m_sslope_ama_curr)<AmaSlopeThreshold;
  }

bool CAmaJmaExpert::InTrendBull(void)
  {
   return m_sslope_ama_prev>AmaSlopeThreshold && m_sslope_ama_curr>AmaSlopeThreshold;
  }

bool CAmaJmaExpert::InTrendBear(void)
  {
   return m_sslope_ama_prev+AmaSlopeThreshold<0 && m_sslope_ama_curr+AmaSlopeThreshold<0;
  }

bool CAmaJmaExpert::FromOsciToTrendBull(void)
  {
   return m_sslope_ama_prev<AmaSlopeThreshold && m_sslope_ama_curr>AmaSlopeThreshold;
  }

bool CAmaJmaExpert::FromOsciToTrendBear(void)
  {
   return m_sslope_ama_prev+AmaSlopeThreshold>0 && m_sslope_ama_curr+AmaSlopeThreshold<0;
  }

bool CAmaJmaExpert::FromTrendBullToOsci(void)
  {
   return m_sslope_ama_prev>AmaSlopeThreshold && m_sslope_ama_curr<AmaSlopeThreshold;
  }

bool CAmaJmaExpert::FromTrendBearToOsci(void)
  {
   return m_sslope_ama_prev+AmaSlopeThreshold<0 && m_sslope_ama_curr+AmaSlopeThreshold>0;
  }

bool CAmaJmaExpert::InOscillationCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++)
    {
      if(m_tick_types[i]!=OSCILLATION) return false;
    }
    return true;
  }

bool CAmaJmaExpert::InTrendBullCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++)
    {
      if(m_tick_types[i]!=TREND_BULL) return false;
    }
    return true;
  }

bool CAmaJmaExpert::InTrendBearCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++)
    {
      if(m_tick_types[i]!=TREND_BEAR) return false;
    }
    return true;
  }

bool CAmaJmaExpert::FromOsciToTrendBullCont(void)
  {
   if(m_tick_types[(1+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL) return false;
   for(int i=2; i<CONTINUOUS_TICK_NUM+1; i++)
    {
      if(m_tick_types[(i+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=TREND_BULL) return false;
    }
    return true;
  }

bool CAmaJmaExpert::FromOsciToTrendBearCont(void)
  {
   if(m_tick_types[(1+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR) return false;
   for(int i=2; i<CONTINUOUS_TICK_NUM+1; i++)
    {
      if(m_tick_types[(i+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=TREND_BEAR) return false;
    }
    return true;
  }

bool CAmaJmaExpert::FromTrendBullToOsciCont(void)
  {
   if(m_tick_types[(1+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI) return false;
   for(int i=2; i<CONTINUOUS_TICK_NUM+1; i++)
    {
      if(m_tick_types[(i+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=OSCILLATION) return false;
    }
    return true;
  }

bool CAmaJmaExpert::FromTrendBearToOsciCont(void)
  {
   if(m_tick_types[(1+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI) return false;
   for(int i=2; i<CONTINUOUS_TICK_NUM+1; i++)
    {
      if(m_tick_types[(i+m_tick_type_index)%CONTINUOUS_TICK_NUM]!=OSCILLATION) return false;
    }
    return true;
  }

void CAmaJmaExpert::RecordTickType(void)
  {
   m_tick_type_index=(m_tick_type_index+1)%CONTINUOUS_TICK_NUM;
   if(InOscillation()) m_tick_types[m_tick_type_index]=OSCILLATION; 
   else if(InTrendBull()) m_tick_types[m_tick_type_index]=TREND_BULL; 
   else if(InTrendBear()) m_tick_types[m_tick_type_index]=TREND_BEAR; 
   else if(FromOsciToTrendBull()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL; 
   else if(FromOsciToTrendBear()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR; 
   else if(FromTrendBullToOsci()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI; 
   else if(FromTrendBearToOsci()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI; 
   else m_tick_types[m_tick_type_index]=EMPTY; 
  }

bool CAmaJmaExpert::IsBearArrange(void)
  {
   return(m_price_curr<m_jma_curr && m_jma_curr<m_ama_curr);
  }

bool CAmaJmaExpert::IsBullArrange(void)
  {
   return(m_price_curr>m_jma_curr && m_jma_curr>m_ama_curr);
  }

bool CAmaJmaExpert::ShouldCloseLong(void)
  {
//   if(m_rates[0].tick_volume-m_open_tick_no<MiTickNoBetweenTrade) return false;
   if(m_open_trade_type==BEAR_TO_OSCI_TD)
   {
     if(m_sslope_jma_curr<m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr) { CurrTradeType=BEAR_TO_OSCI_TD; return true; }
     else return false;
   }
   else if(m_open_trade_type==OSCI_TO_BULL_TD)
   {
     if(m_sslope_jma_curr<m_sslope_ama_curr) { CurrTradeType=OSCI_TO_BULL_TD; return true; }
     else return false;
   }
   else if(m_open_trade_type==OSCILLATION_TD)
   {
     if(m_sslope_ama_curr>0 && m_sslope_jma_curr>0 && 
        m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_jma_curr<=0 && m_bideriv_ama_prev>m_bideriv_ama_curr && m_bideriv_ama_curr<=0 &&
        m_sslope_jma_prev>m_sslope_jma_curr && m_sslope_ama_prev>m_sslope_ama_curr)
       { CurrTradeType=OSCILLATION_TD; return true; }
     else
       return false;
   }
   else if(m_open_trade_type==TREND_BEAR_TD)
   {
     if((m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0) || m_sslope_ama_prev>m_sslope_ama_curr || m_sslope_jma_prev>m_sslope_jma_curr)
       { CurrTradeType=TREND_BEAR_TD; return true; }
     else
       return false;
   }
   return false;
   /*
   if(FromTrendBullToOsciCont())
   {
     if(m_sslope_jma_curr<m_sslope_ama_curr) return true;
     else return false;
   }
   else if(FromOsciToTrendBearCont())
   {
     if(m_sslope_jma_curr<m_sslope_ama_curr) return true;
     else return false;
   }
   if(InOscillationCont())
   {
     if(m_sslope_jma_curr<m_open_sslope_jma) return true;
     if(IsBullArrange() && m_sslope_jma_curr>0 && m_bideriv_jma_prev>m_bideriv_jma_curr && (m_bideriv_jma_curr<=0 || MathAbs(m_bideriv_jma_curr)<AmaSlopeThreshold*0.05))
       return true;
     else
       return false;
   } 
   else
   {
     if(IsBullArrange() && m_sslope_jma_curr>0 && m_sslope_ama_curr>0 && m_bideriv_ama_curr<=0 && m_bideriv_jma_curr<=0 && m_sslope_ama_curr<AmaSlopeThreshold)
       return true;
     else
       return false;
   }
   */
  }

bool CAmaJmaExpert::ShouldCloseShort(void)
  {
//   if(m_rates[0].tick_volume-m_open_tick_no<MiTickNoBetweenTrade) return false;
   if(m_open_trade_type==BULL_TO_OSCI_TD)
   {
     if(m_sslope_jma_curr>m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr) { CurrTradeType=BULL_TO_OSCI_TD; return true; }
     else return false;
   }
   else if(m_open_trade_type==OSCI_TO_BEAR_TD)
   {
     if(m_sslope_jma_curr>m_sslope_ama_curr) { CurrTradeType=OSCI_TO_BEAR_TD; return true; }
     else return false;
   }
   else if(m_open_trade_type==OSCILLATION_TD)
   {
     if(m_sslope_ama_curr<0 && m_sslope_jma_curr<0 && m_bideriv_jma_prev<m_bideriv_jma_curr && (m_bideriv_jma_curr>=0 || m_bideriv_jma_curr+AmaSlopeThreshold*0.05>0))
       { CurrTradeType=OSCILLATION_TD; return true; }
     else
       return false;
   } 
   else if(m_open_trade_type==TREND_BULL_TD)
   {
     if(m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0 || m_sslope_ama_prev<m_sslope_ama_curr || m_sslope_jma_prev<m_sslope_jma_curr)
       { CurrTradeType=TREND_BULL_TD; return true; }
     else
       return false;
   }
   return false;
   /*
   if(FromTrendBearToOsciCont())
   {
     if(m_sslope_jma_curr>m_sslope_ama_curr) return true;
     else return false;
   }
   else if(FromOsciToTrendBullCont())
   {
     if(m_sslope_jma_curr>m_sslope_ama_curr) return true;
     else return false;
   }
   else if(InOscillationCont())
   {
     if(m_sslope_jma_curr>m_open_sslope_jma) return true;
     if(IsBearArrange() && m_ama_curr<0 && m_sslope_jma_curr<0 && m_bideriv_jma_prev<m_bideriv_jma_curr && (m_bideriv_jma_curr>=0 || MathAbs(m_bideriv_jma_curr)<AmaSlopeThreshold*0.05))
       return true;
     else
       return false;
   } 
   else
   {
     if(IsBearArrange() && m_ama_curr>0 && m_sslope_jma_curr<0 && m_sslope_ama_curr<0 && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0 && m_sslope_ama_curr+AmaSlopeThreshold>0)
       return true;
     else
       return false;
   }
   */
  }

bool CAmaJmaExpert::ShouldOpenShort(void)
  {
//   if(Bars(Symbol(),Period())<=m_close_bar_no || !IsReachedTickVolumeToOpen()) return false;
   if(FromTrendBullToOsciCont())
   {
     if(IsBullArrange() && m_sslope_jma_curr<m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr) { CurrTradeType=BULL_TO_OSCI_TD; return true; }
     else return false;
   }
   else if(FromOsciToTrendBearCont())
   {
     if(m_sslope_jma_curr<m_sslope_ama_curr) { CurrTradeType=OSCI_TO_BEAR_TD; return true; }
     else return false;
   }
   else if(InOscillationCont())
   {
     if(IsBullArrange() && m_sslope_ama_curr>0 && m_sslope_jma_curr>0 && m_bideriv_jma_prev>m_bideriv_jma_curr && (m_bideriv_jma_curr<=0 || m_bideriv_jma_curr<AmaSlopeThreshold*0.05))
       { CurrTradeType=OSCILLATION_TD; return true; }
     else
       return false;
   } 
   else if(InTrendBullCont())
   {
     if(IsBullArrange() && m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr)
       { CurrTradeType=TREND_BULL_TD; return true; }
     else
       return false;
   }
   return false;
  }

bool CAmaJmaExpert::ShouldOpenLong(void)
  {
//   if(Bars(Symbol(),Period())<=m_close_bar_no || !IsReachedTickVolumeToOpen()) return false;
   if(FromTrendBearToOsciCont())
   {
     if(IsBearArrange() && m_sslope_jma_curr>m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr) { CurrTradeType=BEAR_TO_OSCI_TD; return true; }
     else return false;
   }
   else if(FromOsciToTrendBullCont())
   {
     if(m_sslope_jma_curr>m_sslope_ama_curr) { CurrTradeType=OSCI_TO_BULL_TD; return true; }
     else return false;
   }
   else if(InOscillationCont())
   {
     if(IsBearArrange() && m_sslope_ama_curr<0 && m_sslope_jma_curr<0 && m_bideriv_jma_prev<m_bideriv_jma_curr && (m_bideriv_jma_curr>=0 || m_bideriv_jma_curr+AmaSlopeThreshold*0.05>0))
       { CurrTradeType=OSCILLATION_TD; return true; }
     else
       return false;
   } 
   else if(InTrendBearCont())
   {
     if(IsBearArrange() && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0 && m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr)
       { CurrTradeType=TREND_BEAR_TD; return true; }
     else
       return false;
   }
   return false;
  }

bool CAmaJmaExpert::IsReachedTickVolumeToOpen(void)
  {
   // Use the last bar's calculation as the current bar's threshold
   long tickVolumeThreshold=(long)(m_tick_volume_ma[1]-m_tick_volume_dev[1]);
   if(tickVolumeThreshold<2) tickVolumeThreshold=2;
   if(m_rates[0].tick_volume<tickVolumeThreshold) return false;
   else return true;
  }
//+------------------------------------------------------------------+
//| Check for long position closing                                  |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::PositionClosed(void)
  {
   bool res=false;
//--- should it be closed?
   if(m_trade.PositionClose(Symbol()))
   {
      RecordValuesOfClosedPosition();
      printf("Long position by %s to be closed with %s",Symbol(),EnumToString(m_close_trade_type));
      res=true;
   }
   else
   {
      printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
      res=false;
   }
   //--- processed and cannot be modified
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::LongOpened(void)
  {
   bool res=false;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return res;
   double lot = TradeSizeOptimized();
   double price=m_symbol.Ask();
   if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_BUY,lot,price)<0.0)
   {
      printf("We have no money. Free Margin = %f",m_account.FreeMargin());
      res=false;
   }
   else
   {
      if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,lot,price,0,0))
        {
         RecordValuesOfOpenedPosition();
         printf("Position by %s to be opened with %s",Symbol(),EnumToString(m_open_trade_type));
         res=true;
        }
      else
        {
         printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
         printf("Open parameters : price=%f",price);
         res=false;
        }
   }    
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::ShortOpened(void)
  {
   bool res=false;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return res;
   double lot = TradeSizeOptimized();
   double price=m_symbol.Bid();
   if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_SELL,lot,price)<0.0)
   {
      printf("We have no money. Free Margin = %f",m_account.FreeMargin());
      res=false;
   }
   else
   {
      if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,lot,price,0,0))
        {
         RecordValuesOfOpenedPosition();
         printf("Position by %s to be opened with %s",Symbol(),EnumToString(m_open_trade_type));
         res=true;
        }
      else
        {
         printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
         printf("Open parameters : price=%f",price);
         res=false;
        }
   }   
   return(res);
  }

void CAmaJmaExpert::RecordValuesOfOpenedPosition(void)
  {
   m_open_price=m_price_curr;
   m_open_ama=m_ama_curr;
   m_open_jma=m_jma_curr;
   m_open_sslope_ama=m_sslope_ama_curr;
   m_open_sslope_jma=m_sslope_jma_curr;
   m_open_bar_no=Bars(Symbol(),Period());
   m_open_tick_no=m_rates[0].tick_volume;
   m_open_trade_type=CurrTradeType;
  }

void CAmaJmaExpert::RecordValuesOfClosedPosition(void)
  {
   m_close_price=m_price_curr;
   m_close_ama=m_ama_curr;
   m_close_jma=m_jma_curr;
   m_close_sslope_ama=m_sslope_ama_curr;
   m_close_sslope_jma=m_sslope_jma_curr;
   m_close_bar_no=Bars(Symbol(),Period());
   m_close_tick_no=m_rates[0].tick_volume;
   m_close_trade_type=CurrTradeType;
  }

void CAmaJmaExpert::CopyIndicatorValuesToCurr(void)
  {
   m_price_curr=m_price[0];
   m_ama_curr=m_ama[0];
   m_jma_curr=m_jma[0];
   m_sslope_ama_curr=m_sslope_ama[0];
   m_sslope_jma_curr=m_sslope_jma[0];
   m_bideriv_ama_curr=m_bideriv_ama[0];
   m_bideriv_jma_curr=m_bideriv_jma[0];
   m_tick_volume_ma_curr=m_tick_volume_ma[0];
   m_tick_volume_dev_curr=m_tick_volume_dev[0];
  }
 
void CAmaJmaExpert::CopyCurrValuesToPrev(void)
  {
   m_price_prev=m_price_curr;
   m_ama_prev=m_ama_curr;
   m_jma_prev=m_jma_curr;
   m_sslope_ama_prev=m_sslope_ama_curr;
   m_sslope_jma_prev=m_sslope_jma_curr;
   m_bideriv_ama_prev=m_bideriv_ama_curr;
   m_bideriv_jma_prev=m_bideriv_jma_curr;
   m_tick_volume_ma_prev=m_tick_volume_ma_curr;
   m_tick_volume_dev_prev=m_tick_volume_dev_curr;
  }
 
bool CAmaJmaExpert::IsTooFrequent(void)
  {
   return Bars(Symbol(),Period())<=m_open_bar_no;
  }
//+------------------------------------------------------------------+
//| main function returns true if any position processed             |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::Processing(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- refresh indicators
   if(BarsCalculated(m_handle)<2*MinBarForJma)
      return(false);
   if(CopyBuffer(m_handle,8,0,BufferCountToCopy,m_price)!=BufferCountToCopy || CopyBuffer(m_handle,4,0,BufferCountToCopy,m_ama)!=BufferCountToCopy || CopyBuffer(m_handle,5,0,BufferCountToCopy,m_jma)!=BufferCountToCopy ||
      CopyBuffer(m_handle,0,0,BufferCountToCopy,m_sslope_ama)!=BufferCountToCopy || CopyBuffer(m_handle,1,0,BufferCountToCopy,m_sslope_jma)!=BufferCountToCopy ||
      CopyBuffer(m_handle,2,0,BufferCountToCopy,m_bideriv_ama)!=BufferCountToCopy || CopyBuffer(m_handle,3,0,BufferCountToCopy,m_bideriv_jma)!=BufferCountToCopy ||
      CopyBuffer(m_handle,9,0,BufferCountToCopy,m_tick_volume_ma)!=BufferCountToCopy || CopyBuffer(m_handle,10,0,BufferCountToCopy,m_tick_volume_dev)!=BufferCountToCopy)
     {
      Print("CopyBuffer of indicator ",INDICATOR_NAME," failed");
      return(false);
     }
   if(!m_is_first_tick) CopyCurrValuesToPrev();
   CopyIndicatorValuesToCurr();
   if(m_is_first_tick)
   {
     m_is_first_tick=false;
     return false;
   }
   if(CopyRates(Symbol(),Period(),0,2,m_rates)!=2)
     {
      Print("CopyRates of ",Symbol()," failed, no history");
      return false;
     }
//--- Record every tick type
   RecordTickType();
//   m_indicators.Refresh();
//--- it is important to enter the market correctly, 
//--- but it is more important to exit it correctly...   
//--- first check if position exists - try to select it
   if(m_position.Select(Symbol()))
     {
      bool closed = false;
      if(m_position.PositionType()==POSITION_TYPE_BUY)
        {
         //--- try to close or modify long position
         if(ShouldCloseLong())
          {
            closed = PositionClosed();
            if(closed && CloseToOpen && ShouldOpenShort()) return(ShortOpened());
            return(closed);
          }
        }
      else
        {
         //--- try to close or modify short position
         if(ShouldCloseShort())
          {
            closed = PositionClosed();
            if(closed && CloseToOpen && ShouldOpenLong()) return(LongOpened());
            return(closed);
          }
        }
     }
//--- no opened position identified
   else
     {
      //--- check for long position (BUY) possibility
      if(ShouldOpenLong()) return(LongOpened());
      //--- check for short position (SELL) possibility
      if(ShouldOpenShort()) return(ShortOpened());
     }
//--- exit without position processing
   return(false);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- create all necessary objects
   if(!ExtExpert.Init())
      return(INIT_FAILED);
//--- secceed
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert new tick handling function                                |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   static datetime limit_time=0; // last trade processing time + timeout
//--- don't process if timeout
   if(TimeCurrent()>=limit_time)
     {
      //--- check for data
      if(Bars(Symbol(),Period())>2*MinBarForJma)
        {
         //--- change limit time by timeout in seconds if processed
         if(ExtExpert.Processing())
            limit_time=TimeCurrent()+ExtTimeOut;
//            limit_time=TimeCurrent();
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
