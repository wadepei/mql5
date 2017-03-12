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
#define CONTINUOUS_TICK_NUM 10          // Continuous tick num for oscillation
#define CONTINUOUS_TICK_NUM_TREND 4    // Continuous tick num for trend
#define CONTINUOUS_TICK_NUM_CHANGE 2    // Continuous tick num for change state from osci to trend or vice versa
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
double GoldenSectionRatio=0.618;
double NearZeroRatio=0.05;
int ExtTimeOut=0; // time out in seconds between trade operations
enum Tick_type //Type of Tick
 {
  EMPTY = 0,
  OSCILLATION = 1,  
  OSCILLATION_OPEN_LONG,
//  OSCILLATION_OPEN_LONG_LIMIT,
  OSCILLATION_OPEN_SHORT,
//  OSCILLATION_OPEN_SHORT_LIMIT,
  OSCILLATION_CLOSE_LONG,
  OSCILLATION_CLOSE_LONG_LIMIT,
  OSCILLATION_CLOSE_SHORT,
  OSCILLATION_CLOSE_SHORT_LIMIT,
  BULL,
  BULL_OPEN_LONG,
  BULL_OPEN_SHORT,
  BULL_CLOSE_LONG,
  BULL_CLOSE_SHORT,
  BEAR,   
  BEAR_OPEN_LONG,   
  BEAR_OPEN_SHORT,   
  BEAR_CLOSE_LONG,   
  BEAR_CLOSE_SHORT,   
  OSCI_TO_BULL,        
  OSCI_TO_BULL_OPEN_LONG,        
  OSCI_TO_BULL_OPEN_LONG2,        
  OSCI_TO_BULL_OPEN_SHORT,        
  OSCI_TO_BULL_OPEN_SHORT2,        
  OSCI_TO_BULL_CLOSE_LONG,        
  OSCI_TO_BULL_CLOSE_LONG2,        
  OSCI_TO_BULL_CLOSE_SHORT,        
  OSCI_TO_BULL_CLOSE_SHORT2,        
  OSCI_TO_BEAR,        
  OSCI_TO_BEAR_OPEN_LONG,        
  OSCI_TO_BEAR_OPEN_LONG2,        
  OSCI_TO_BEAR_OPEN_SHORT,        
  OSCI_TO_BEAR_OPEN_SHORT2,        
  OSCI_TO_BEAR_CLOSE_LONG,        
  OSCI_TO_BEAR_CLOSE_LONG2,        
  OSCI_TO_BEAR_CLOSE_SHORT,        
  OSCI_TO_BEAR_CLOSE_SHORT2,        
  BULL_TO_OSCI,     
  BULL_TO_OSCI_OPEN_LONG,     
  BULL_TO_OSCI_OPEN_LONG2,     
  BULL_TO_OSCI_OPEN_SHORT,     
  BULL_TO_OSCI_OPEN_SHORT2,     
  BULL_TO_OSCI_CLOSE_LONG,     
  BULL_TO_OSCI_CLOSE_LONG2,     
  BULL_TO_OSCI_CLOSE_SHORT,     
  BULL_TO_OSCI_CLOSE_SHORT2,     
  BEAR_TO_OSCI,
  BEAR_TO_OSCI_OPEN_LONG,
  BEAR_TO_OSCI_OPEN_LONG2,
  BEAR_TO_OSCI_OPEN_SHORT,
  BEAR_TO_OSCI_OPEN_SHORT2,
  BEAR_TO_OSCI_CLOSE_LONG,
  BEAR_TO_OSCI_CLOSE_LONG2,
  BEAR_TO_OSCI_CLOSE_SHORT,
  BEAR_TO_OSCI_CLOSE_SHORT2
 };
enum Trade_type //Type of trade
 {
  EMPTY_TD = 0,
  OSCILLATION_TD = 1,  
  OSCILLATION_OPEN_LONG_TD,
  OSCILLATION_OPEN_SHORT_TD,
  OSCILLATION_CLOSE_LONG_TD,
  OSCILLATION_CLOSE_LONG_LIMIT_TD,
  OSCILLATION_CLOSE_SHORT_TD,
  OSCILLATION_CLOSE_SHORT_LIMIT_TD,
  BULL_TD,
  BULL_OPEN_LONG_TD,
  BULL_OPEN_SHORT_TD,
  BULL_CLOSE_LONG_TD,
  BULL_CLOSE_SHORT_TD,
  BEAR_TD,   
  BEAR_OPEN_LONG_TD,   
  BEAR_OPEN_SHORT_TD,   
  BEAR_CLOSE_LONG_TD,   
  BEAR_CLOSE_SHORT_TD,   
  OSCI_TO_BULL_TD,        
  OSCI_TO_BULL_OPEN_LONG_TD,        
  OSCI_TO_BULL_OPEN_SHORT_TD,        
  OSCI_TO_BULL_CLOSE_LONG_TD,        
  OSCI_TO_BULL_CLOSE_SHORT_TD,        
  OSCI_TO_BEAR_TD,        
  OSCI_TO_BEAR_OPEN_LONG_TD,        
  OSCI_TO_BEAR_OPEN_SHORT_TD,        
  OSCI_TO_BEAR_CLOSE_LONG_TD,        
  OSCI_TO_BEAR_CLOSE_SHORT_TD,        
  BULL_TO_OSCI_TD,     
  BULL_TO_OSCI_OPEN_LONG_TD,     
  BULL_TO_OSCI_OPEN_SHORT_TD,     
  BULL_TO_OSCI_CLOSE_LONG_TD,     
  BULL_TO_OSCI_CLOSE_SHORT_TD,     
  BEAR_TO_OSCI_TD,
  BEAR_TO_OSCI_OPEN_LONG_TD,
  BEAR_TO_OSCI_OPEN_SHORT_TD,
  BEAR_TO_OSCI_CLOSE_LONG_TD,
  BEAR_TO_OSCI_CLOSE_SHORT_TD
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
   bool              m_has_opened_position;

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
   bool              InOscillationOpenLong(void);
   bool              InOscillationOpenShort(void);
   bool              InOscillationCloseLong(void);
   bool              InOscillationCloseLongLimit(void);
   bool              InOscillationCloseShort(void);
   bool              InOscillationCloseShortLimit(void);
   bool              InBull(void);
   bool              InBullOpenLong(void);
   bool              InBullOpenShort(void);
   bool              InBullCloseLong(void);
   bool              InBullCloseShort(void);
   bool              InBear(void);
   bool              InBearOpenLong(void);
   bool              InBearOpenShort(void);
   bool              InBearCloseLong(void);
   bool              InBearCloseShort(void);
   bool              FromOsciToBull(void);
   bool              FromOsciToBullOpenLong(void);
   bool              FromOsciToBullOpenShort(void);
   bool              FromOsciToBullCloseLong(void);
   bool              FromOsciToBullCloseShort(void);
   bool              FromOsciToBear(void);
   bool              FromOsciToBearOpenLong(void);
   bool              FromOsciToBearOpenShort(void);
   bool              FromOsciToBearCloseLong(void);
   bool              FromOsciToBearCloseShort(void);
   bool              FromBullToOsci(void);
   bool              FromBullToOsciOpenLong(void);
   bool              FromBullToOsciOpenShort(void);
   bool              FromBullToOsciCloseLong(void);
   bool              FromBullToOsciCloseShort(void);
   bool              FromBearToOsci(void);
   bool              FromBearToOsciOpenLong(void);
   bool              FromBearToOsciOpenShort(void);
   bool              FromBearToOsciCloseLong(void);
   bool              FromBearToOsciCloseShort(void);
   //--- the following seven methods are the above methods in continuously
   bool              InOscillationCont(void);
   bool              InOscillationOpenLongCont(void);
   bool              InOscillationOpenShortCont(void);
   bool              InOscillationCloseLongCont(void);
   bool              InOscillationCloseLongLimitCont(void);
   bool              InOscillationCloseShortCont(void);
   bool              InOscillationCloseShortLimitCont(void);
   bool              InBullCont(void);
   bool              InBullOpenLongCont(void);
   bool              InBullOpenShortCont(void);
   bool              InBullCloseLongCont(void);
   bool              InBullCloseShortCont(void);
   bool              InBearCont(void);
   bool              InBearOpenLongCont(void);
   bool              InBearOpenShortCont(void);
   bool              InBearCloseLongCont(void);
   bool              InBearCloseShortCont(void);
   bool              FromOsciToBullCont(void);
   bool              FromOsciToBullOpenLongCont(void);
   bool              FromOsciToBullOpenShortCont(void);
   bool              FromOsciToBullCloseLongCont(void);
   bool              FromOsciToBullCloseShortCont(void);
   bool              FromOsciToBearCont(void);
   bool              FromOsciToBearOpenLongCont(void);
   bool              FromOsciToBearOpenShortCont(void);
   bool              FromOsciToBearCloseLongCont(void);
   bool              FromOsciToBearCloseShortCont(void);
   bool              FromBullToOsciCont(void);
   bool              FromBullToOsciOpenLongCont(void);
   bool              FromBullToOsciOpenShortCont(void);
   bool              FromBullToOsciCloseLongCont(void);
   bool              FromBullToOsciCloseShortCont(void);
   bool              FromBearToOsciCont(void);
   bool              FromBearToOsciOpenLongCont(void);
   bool              FromBearToOsciOpenShortCont(void);
   bool              FromBearToOsciCloseLongCont(void);
   bool              FromBearToOsciCloseShortCont(void);
   
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
                                     m_is_first_tick(true),
                                     m_has_opened_position(false)
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
   ArrayResize(m_rates, BufferCountToCopy);
   
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
   IndicatorRelease(m_handle);
   IndicatorRelease(m_handle_ama);
   IndicatorRelease(m_handle_jma);
}
//+------------------------------------------------------------------+
//| Initialization of the indicators                                 |
//+------------------------------------------------------------------+
bool CAmaJmaExpert::InitIndicators(void)
  {
   if(m_handle==INVALID_HANDLE)
      if((m_handle=iCustom(NULL,0,INDICATOR_NAME,IPC,LengthJMA,PhaseJMA,AmaPeriod,FastMaPeriod,SlowMaPeriod,G,AMAShift,LengthJMASmooth,PhaseJMASmooth,DeviationPeriod))==INVALID_HANDLE)
        {
         printf("Error creating indicator "+INDICATOR_NAME);
         return(false);
        }
   m_handle_ama=iCustom(NULL,0,INDICATOR_NAME_AMA,IPC,AmaPeriod,FastMaPeriod,SlowMaPeriod,G,AMAShift);
   m_handle_jma=iCustom(NULL,0,INDICATOR_NAME_JMA,IPC,LengthJMA,PhaseJMA,0,0);
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

bool CAmaJmaExpert::InOscillationOpenLong(void)
  {
   return InOscillation() && IsBearArrange() && m_sslope_ama_curr<0 && m_sslope_jma_curr<0 && m_bideriv_jma_prev<m_bideriv_jma_curr && 
        m_bideriv_jma_curr>0 && m_bideriv_ama_prev<m_bideriv_ama_curr && m_bideriv_ama_curr>0 && m_sslope_ama_curr>-AmaSlopeThreshold*GoldenSectionRatio &&
        m_sslope_jma_curr>-AmaSlopeThreshold/GoldenSectionRatio;
  }

bool CAmaJmaExpert::InOscillationOpenShort(void)
  {
   return InOscillation() && IsBullArrange() && m_sslope_ama_curr>0 && m_sslope_jma_curr>0 && m_bideriv_jma_prev>m_bideriv_jma_curr && 
        m_bideriv_jma_curr<0 && m_bideriv_ama_prev>m_bideriv_ama_curr && m_bideriv_ama_curr<0 && m_sslope_ama_curr<AmaSlopeThreshold*GoldenSectionRatio &&
        m_sslope_jma_curr<AmaSlopeThreshold/GoldenSectionRatio;
  }

bool CAmaJmaExpert::InOscillationCloseLong(void)
  {
   return InOscillation() && m_sslope_ama_curr<AmaSlopeThreshold*GoldenSectionRatio && m_sslope_jma_curr<AmaSlopeThreshold/GoldenSectionRatio && 
        m_bideriv_jma_curr<=0 && m_bideriv_ama_prev>m_bideriv_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr;
  }

bool CAmaJmaExpert::InOscillationCloseLongLimit(void)
  {
   return !InOscillationCloseShort() && InOscillation() && m_sslope_ama_curr<AmaSlopeThreshold*GoldenSectionRatio && m_sslope_jma_curr<AmaSlopeThreshold/GoldenSectionRatio && 
        (IsBullArrange() || m_price_curr-m_ama_curr>=m_open_ama-m_open_price && m_open_price<m_price_curr) &&/* m_bideriv_jma_prev>m_bideriv_jma_curr*/m_bideriv_jma_curr<0;
  }

bool CAmaJmaExpert::InOscillationCloseShort(void)
  {
   return InOscillation() && m_sslope_ama_curr>-AmaSlopeThreshold*GoldenSectionRatio && m_sslope_jma_curr>-AmaSlopeThreshold/GoldenSectionRatio && 
        m_bideriv_jma_curr>=0 && m_bideriv_ama_prev<m_bideriv_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr;
  }

bool CAmaJmaExpert::InOscillationCloseShortLimit(void)
  {
   return !InOscillationCloseLong() && InOscillation() && m_sslope_ama_curr>-AmaSlopeThreshold*GoldenSectionRatio && m_sslope_jma_curr>-AmaSlopeThreshold/GoldenSectionRatio && 
        (IsBearArrange() || m_ama_curr-m_price_curr>=m_open_price-m_open_ama && m_open_price>m_price_curr) &&/* m_bideriv_jma_prev<m_bideriv_jma_curr*/m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::InBull(void)
  {
   return m_sslope_ama_prev>AmaSlopeThreshold && m_sslope_ama_curr>AmaSlopeThreshold;
  }

bool CAmaJmaExpert::InBullOpenLong(void)
  {
   return InBull() && m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr &&
         m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::InBullOpenShort(void)
  {
   return InBull() && IsBullArrange()/* && m_bideriv_ama_prev>m_bideriv_ama_curr/* && m_bideriv_jma_curr<0 && m_sslope_jma_prev>m_sslope_jma_curr*/ &&
          /*m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio && */m_bideriv_jma_prev>m_bideriv_jma_curr/* && (m_sslope_jma_curr<m_sslope_ama_curr||m_bideriv_jma_curr<-AmaSlopeThreshold)*/;
  }

bool CAmaJmaExpert::InBullCloseLong(void)
  {
   return InBull() && m_bideriv_ama_prev>m_bideriv_ama_curr && m_bideriv_jma_curr<0 && m_sslope_jma_prev>m_sslope_jma_curr &&
          /*m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio && */m_bideriv_jma_prev>m_bideriv_jma_curr && (m_sslope_jma_curr<m_sslope_ama_curr||m_bideriv_jma_curr<-AmaSlopeThreshold);
  }

bool CAmaJmaExpert::InBullCloseShort(void)
  {
   return InBull() && m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr &&
         m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::InBear(void)
  {
   return m_sslope_ama_prev+AmaSlopeThreshold<0 && m_sslope_ama_curr+AmaSlopeThreshold<0;
  }

bool CAmaJmaExpert::InBearOpenLong(void)
  {
   return InBear() && IsBearArrange() && m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && (m_sslope_ama_curr<m_sslope_jma_curr||m_bideriv_jma_curr>AmaSlopeThreshold) &&
         /*m_sslope_ama_curr>-AmaSlopeThreshold/GoldenSectionRatio && */m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::InBearOpenShort(void)
  {
   return InBear() && IsBearArrange() && m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_sslope_ama_curr>-AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::InBearCloseLong(void)
  {
   return InBear() && m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::InBearCloseShort(void)
  {
   return InBear()/* && m_jma_prev<m_jma_curr && IsBearArrange() && m_sslope_ama_prev<m_sslope_ama_curr*/ && m_sslope_jma_prev<m_sslope_jma_curr/* && (m_sslope_ama_curr<m_sslope_jma_curr||m_bideriv_jma_curr>AmaSlopeThreshold) &&
         /*m_sslope_ama_curr>-AmaSlopeThreshold/GoldenSectionRatio*/ && m_bideriv_jma_curr>0 && m_bideriv_jma_prev<m_bideriv_jma_curr;
  }

bool CAmaJmaExpert::FromOsciToBull(void)
  {
   return m_sslope_ama_prev<AmaSlopeThreshold && m_sslope_ama_curr>AmaSlopeThreshold;
  }

bool CAmaJmaExpert::FromOsciToBullOpenLong(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0 &&
         m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio;
  }

bool CAmaJmaExpert::FromOsciToBullOpenShort(void)
  {
   return m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromOsciToBullCloseLong(void)
  {
   return m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromOsciToBullCloseShort(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr &&
         m_sslope_ama_curr<AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::FromOsciToBear(void)
  {
   return m_sslope_ama_prev+AmaSlopeThreshold>0 && m_sslope_ama_curr+AmaSlopeThreshold<0;
  }

bool CAmaJmaExpert::FromOsciToBearOpenLong(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0 &&
         m_sslope_ama_curr>-AmaSlopeThreshold/GoldenSectionRatio;
  }

bool CAmaJmaExpert::FromOsciToBearOpenShort(void)
  {
   if(m_bideriv_jma_curr<0 && m_sslope_jma_prev>m_sslope_jma_curr)
   {
      1+1;
   }
   return m_bideriv_jma_curr<0 && m_sslope_jma_prev>m_sslope_jma_curr/* &&
          m_sslope_ama_curr>-AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr*/;
  }

bool CAmaJmaExpert::FromOsciToBearCloseLong(void)
  {
   return m_bideriv_jma_curr<0 && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromOsciToBearCloseShort(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr &&
         m_sslope_ama_curr>-AmaSlopeThreshold/GoldenSectionRatio && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::FromBullToOsci(void)
  {
   return m_sslope_ama_prev>AmaSlopeThreshold && m_sslope_ama_curr<AmaSlopeThreshold;
  }

bool CAmaJmaExpert::FromBullToOsciOpenLong(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0 &&
         m_sslope_ama_curr<AmaSlopeThreshold*GoldenSectionRatio;
  }

bool CAmaJmaExpert::FromBullToOsciOpenShort(void)
  {
   return m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromBullToOsciCloseLong(void)
  {
   return m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromBullToOsciCloseShort(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr &&
         m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::FromBearToOsci(void)
  {
   return m_sslope_ama_prev+AmaSlopeThreshold<0 && m_sslope_ama_curr+AmaSlopeThreshold>0;
  }

bool CAmaJmaExpert::FromBearToOsciOpenLong(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr && m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::FromBearToOsciOpenShort(void)
  {
   return m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromBearToOsciCloseLong(void)
  {
   return m_bideriv_ama_curr<0 && m_bideriv_jma_curr<0 && m_sslope_ama_prev>m_sslope_ama_curr && m_sslope_jma_prev>m_sslope_jma_curr &&
          m_bideriv_jma_prev>m_bideriv_jma_curr && m_bideriv_ama_prev>m_bideriv_ama_curr;
  }

bool CAmaJmaExpert::FromBearToOsciCloseShort(void)
  {
   return m_sslope_ama_prev<m_sslope_ama_curr && m_sslope_jma_prev<m_sslope_jma_curr && m_sslope_ama_curr<m_sslope_jma_curr &&
         m_bideriv_ama_curr>0 && m_bideriv_jma_curr>0;
  }

bool CAmaJmaExpert::InOscillationCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++) { if(m_tick_types[i]!=OSCILLATION) return false; }
   return true;
  }

bool CAmaJmaExpert::InOscillationOpenLongCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++) { if(m_tick_types[i]!=OSCILLATION_OPEN_LONG) return false; }
   return true;
  }

bool CAmaJmaExpert::InOscillationOpenShortCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++) { if(m_tick_types[i]!=OSCILLATION_OPEN_SHORT) return false; }
   return true;
  }

bool CAmaJmaExpert::InOscillationCloseLongCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++) { if(m_tick_types[i]!=OSCILLATION_CLOSE_LONG) return false; }
   return true;
  }

bool CAmaJmaExpert::InOscillationCloseLongLimitCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=OSCILLATION_CLOSE_LONG_LIMIT) return false; }
   return true;
  }

bool CAmaJmaExpert::InOscillationCloseShortCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM; i++) { if(m_tick_types[i]!=OSCILLATION_CLOSE_SHORT) return false; }
   return true;
  }

bool CAmaJmaExpert::InOscillationCloseShortLimitCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=OSCILLATION_CLOSE_SHORT_LIMIT) return false; }
   return true;
  }

bool CAmaJmaExpert::InBullCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BULL) return false; }
   return true;
  }

bool CAmaJmaExpert::InBullOpenLongCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BULL_OPEN_LONG) return false; }
   return true;
  }

bool CAmaJmaExpert::InBullOpenShortCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BULL_OPEN_SHORT) return false; }
   return true;
  }

bool CAmaJmaExpert::InBullCloseLongCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BULL_CLOSE_LONG) return false; }
   return true;
  }

bool CAmaJmaExpert::InBullCloseShortCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BULL_CLOSE_SHORT) return false; }
   return true;
  }

bool CAmaJmaExpert::InBearCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BEAR) return false; }
   return true;
  }

bool CAmaJmaExpert::InBearOpenLongCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BEAR_OPEN_LONG) return false; }
   return true;
  }

bool CAmaJmaExpert::InBearOpenShortCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BEAR_OPEN_SHORT) return false; }
   return true;
  }

bool CAmaJmaExpert::InBearCloseLongCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BEAR_CLOSE_LONG) return false; }
   return true;
  }

bool CAmaJmaExpert::InBearCloseShortCont(void)
  {
   for(int i=0; i<CONTINUOUS_TICK_NUM_TREND; i++) { if(m_tick_types[i]!=BEAR_CLOSE_SHORT) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBullCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BULL) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBullOpenLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_OPEN_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_OPEN_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBullOpenShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_OPEN_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_OPEN_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBullCloseLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_CLOSE_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_CLOSE_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBullCloseShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_CLOSE_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BULL_CLOSE_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBearCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BEAR) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBearOpenLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_OPEN_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_OPEN_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBearOpenShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_OPEN_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_OPEN_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBearCloseLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_CLOSE_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_CLOSE_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromOsciToBearCloseShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_CLOSE_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCI_TO_BEAR_CLOSE_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBullToOsciCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCILLATION) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBullToOsciOpenLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_OPEN_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_OPEN_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBullToOsciOpenShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_OPEN_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_OPEN_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBullToOsciCloseLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_CLOSE_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_CLOSE_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBullToOsciCloseShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_CLOSE_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BULL_TO_OSCI_CLOSE_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBearToOsciCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=OSCILLATION) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBearToOsciOpenLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_OPEN_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_OPEN_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBearToOsciOpenShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_OPEN_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_OPEN_SHORT2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBearToOsciCloseLongCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_CLOSE_LONG) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_CLOSE_LONG2) return false; }
   return true;
  }

bool CAmaJmaExpert::FromBearToOsciCloseShortCont(void)
  {
   int startIndex = CONTINUOUS_TICK_NUM - CONTINUOUS_TICK_NUM_CHANGE + 1 + m_tick_type_index;
   if(m_tick_types[startIndex%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_CLOSE_SHORT) return false;
   for(int i=1; i<CONTINUOUS_TICK_NUM_CHANGE; i++) { if(m_tick_types[(i+startIndex)%CONTINUOUS_TICK_NUM]!=BEAR_TO_OSCI_CLOSE_SHORT2) return false; }
   return true;
  }

void CAmaJmaExpert::RecordTickType(void)
  {
   m_tick_type_index=(m_tick_type_index+1)%CONTINUOUS_TICK_NUM;
   if(!m_has_opened_position && InOscillationOpenLong()) m_tick_types[m_tick_type_index]=OSCILLATION_OPEN_LONG; 
   else if(!m_has_opened_position && InOscillationOpenShort()) m_tick_types[m_tick_type_index]=OSCILLATION_OPEN_SHORT; 
   else if(m_has_opened_position && InOscillationCloseLong()) m_tick_types[m_tick_type_index]=OSCILLATION_CLOSE_LONG; 
   else if(m_has_opened_position && InOscillationCloseLongLimit()) m_tick_types[m_tick_type_index]=OSCILLATION_CLOSE_LONG_LIMIT; 
   else if(m_has_opened_position && InOscillationCloseShort()) m_tick_types[m_tick_type_index]=OSCILLATION_CLOSE_SHORT; 
   else if(m_has_opened_position && InOscillationCloseShortLimit()) m_tick_types[m_tick_type_index]=OSCILLATION_CLOSE_SHORT_LIMIT; 
   
   else if(!m_has_opened_position && InBullOpenLong()) m_tick_types[m_tick_type_index]=BULL_OPEN_LONG; 
   else if(!m_has_opened_position && InBullOpenShort()) m_tick_types[m_tick_type_index]=BULL_OPEN_SHORT; 
   else if(m_has_opened_position && InBullCloseLong()) m_tick_types[m_tick_type_index]=BULL_CLOSE_LONG; 
   else if(m_has_opened_position && InBullCloseShort()) m_tick_types[m_tick_type_index]=BULL_CLOSE_SHORT; 
   
   else if(!m_has_opened_position && InBearOpenLong()) m_tick_types[m_tick_type_index]=BEAR_OPEN_LONG; 
   else if(!m_has_opened_position && InBearOpenShort()) m_tick_types[m_tick_type_index]=BEAR_OPEN_SHORT; 
   else if(m_has_opened_position && InBearCloseLong()) m_tick_types[m_tick_type_index]=BEAR_CLOSE_LONG; 
   else if(m_has_opened_position && InBearCloseShort()) m_tick_types[m_tick_type_index]=BEAR_CLOSE_SHORT; 
   
   else if(!m_has_opened_position && FromOsciToBull() && FromOsciToBullOpenLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_OPEN_LONG; 
   else if(!m_has_opened_position && InBull() && FromOsciToBullOpenLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_OPEN_LONG2; 
   else if(!m_has_opened_position && FromOsciToBull() && FromOsciToBullOpenShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_OPEN_SHORT; 
   else if(!m_has_opened_position && InBull() && FromOsciToBullOpenShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_OPEN_SHORT2; 
   else if(m_has_opened_position && FromOsciToBull() && FromOsciToBullCloseLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_CLOSE_LONG; 
   else if(m_has_opened_position && InBull() && FromOsciToBullCloseLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_CLOSE_LONG2; 
   else if(m_has_opened_position && FromOsciToBull() && FromOsciToBullCloseShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_CLOSE_SHORT; 
   else if(m_has_opened_position && InBull() && FromOsciToBullCloseShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL_CLOSE_SHORT2; 
   
   else if(!m_has_opened_position && FromOsciToBear() && FromOsciToBearOpenLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_OPEN_LONG; 
   else if(!m_has_opened_position && InBear() && FromOsciToBearOpenLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_OPEN_LONG2; 
   else if(!m_has_opened_position && FromOsciToBear() && FromOsciToBearOpenShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_OPEN_SHORT;
   else if(!m_has_opened_position && InBear() && FromOsciToBearOpenShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_OPEN_SHORT2; 
   else if(m_has_opened_position && FromOsciToBear() && FromOsciToBearCloseLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_CLOSE_LONG; 
   else if(m_has_opened_position && InBear() && FromOsciToBearCloseLong()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_CLOSE_LONG2; 
   else if(m_has_opened_position && FromOsciToBear() && FromOsciToBearCloseShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_CLOSE_SHORT; 
   else if(m_has_opened_position && InBear() && FromOsciToBearCloseShort()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR_CLOSE_SHORT2; 
   
   else if(!m_has_opened_position && FromBullToOsci() && FromBullToOsciOpenLong()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_OPEN_LONG; 
   else if(!m_has_opened_position && InOscillation() && FromBullToOsciOpenLong()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_OPEN_LONG2; 
   else if(!m_has_opened_position && FromBullToOsci() && FromBullToOsciOpenShort()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_OPEN_SHORT; 
   else if(!m_has_opened_position && InOscillation() && FromBullToOsciOpenShort()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_OPEN_SHORT2; 
   else if(m_has_opened_position && FromBullToOsci() && FromBullToOsciCloseLong()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_CLOSE_LONG; 
   else if(m_has_opened_position && InOscillation() && FromBullToOsciCloseLong()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_CLOSE_LONG2; 
   else if(m_has_opened_position && FromBullToOsci() && FromBullToOsciCloseShort()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_CLOSE_SHORT; 
   else if(m_has_opened_position && InOscillation() && FromBullToOsciCloseShort()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI_CLOSE_SHORT2; 
   
   else if(!m_has_opened_position && FromBearToOsci() && FromBearToOsciOpenLong()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_OPEN_LONG; 
   else if(!m_has_opened_position && InOscillation() && FromBearToOsciOpenLong()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_OPEN_LONG2; 
   else if(!m_has_opened_position && FromBearToOsci() && FromBearToOsciOpenShort()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_OPEN_SHORT; 
   else if(!m_has_opened_position && InOscillation() && FromBearToOsciOpenShort()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_OPEN_SHORT2; 
   else if(m_has_opened_position && FromBearToOsci() && FromBearToOsciCloseLong()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_CLOSE_LONG; 
   else if(m_has_opened_position && InOscillation() && FromBearToOsciCloseLong()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_CLOSE_LONG2; 
   else if(m_has_opened_position && FromBearToOsci() && FromBearToOsciCloseShort()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_CLOSE_SHORT; 
   else if(m_has_opened_position && InOscillation() && FromBearToOsciCloseShort()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI_CLOSE_SHORT2; 
   
   else if(InOscillation()) m_tick_types[m_tick_type_index]=OSCILLATION; 
   else if(InBull()) m_tick_types[m_tick_type_index]=BULL; 
   else if(InBear()) m_tick_types[m_tick_type_index]=BEAR; 
   else if(FromOsciToBull()) m_tick_types[m_tick_type_index]=OSCI_TO_BULL; 
   else if(FromOsciToBear()) m_tick_types[m_tick_type_index]=OSCI_TO_BEAR; 
   else if(FromBullToOsci()) m_tick_types[m_tick_type_index]=BULL_TO_OSCI; 
   else if(FromBearToOsci()) m_tick_types[m_tick_type_index]=BEAR_TO_OSCI; 
   else m_tick_types[m_tick_type_index]=EMPTY; 
  }

bool CAmaJmaExpert::IsBearArrange(void)
  {
   return(m_price_curr<m_jma_curr && m_jma_curr<m_ama_curr);
//   return(m_price_curr<m_ama_curr && m_jma_curr<m_ama_curr);
  }

bool CAmaJmaExpert::IsBullArrange(void)
  {
   return(m_price_curr>m_jma_curr && m_jma_curr>m_ama_curr);
//   return(m_price_curr>m_ama_curr && m_jma_curr>m_ama_curr);
  }

bool CAmaJmaExpert::ShouldCloseLong(void)
  {
//   if(m_rates[0].tick_volume-m_open_tick_no<MiTickNoBetweenTrade) return false;
   if(m_open_trade_type==BEAR_TO_OSCI_OPEN_LONG_TD)
   {
     if(InBearCloseLongCont()) { CurrTradeType=BEAR_CLOSE_LONG_TD; return true; }
     if(FromBearToOsciCloseLongCont()) { CurrTradeType=BEAR_TO_OSCI_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_LIMIT_TD; return true; }
     if(FromOsciToBullCloseLongCont()) { CurrTradeType=OSCI_TO_BULL_CLOSE_LONG_TD; return true; }
     if(InBullCloseLongCont()) { CurrTradeType=BULL_CLOSE_LONG_TD; return true; }
   }
   else if(m_open_trade_type==OSCI_TO_BULL_OPEN_LONG_TD)
   {
     if(InOscillationCloseLongCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_LIMIT_TD; return true; }
     if(FromOsciToBullCloseLongCont()) { CurrTradeType=OSCI_TO_BULL_CLOSE_LONG_TD; return true; }
     if(InBullCloseLongCont()) { CurrTradeType=BULL_CLOSE_LONG_TD; return true; }
   }
   else if(m_open_trade_type==OSCILLATION_OPEN_LONG_TD)
   {
     if(InBearCloseLongCont()) { CurrTradeType=BEAR_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_LIMIT_TD; return true; }
     if(FromOsciToBearCloseLongCont() || FromOsciToBearOpenShortCont()) { CurrTradeType=OSCI_TO_BEAR_CLOSE_LONG_TD; return true; }
     if(FromOsciToBullCloseLongCont()) { CurrTradeType=OSCI_TO_BULL_CLOSE_LONG_TD; return true; }
     if(InBullCloseLongCont()) { CurrTradeType=BULL_CLOSE_LONG_TD; return true; }
   }
   else if(m_open_trade_type==BEAR_OPEN_LONG_TD)
   {
     if(InBearCloseLongCont()) { CurrTradeType=BEAR_CLOSE_LONG_TD; return true; }
     if(FromBearToOsciCloseLongCont()) { CurrTradeType=BEAR_TO_OSCI_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_TD; return true; }
     if(InOscillationCloseLongLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_LONG_LIMIT_TD; return true; }
     if(FromOsciToBullCloseLongCont()) { CurrTradeType=OSCI_TO_BULL_CLOSE_LONG_TD; return true; }
     if(InBullCloseLongCont()) { CurrTradeType=BULL_CLOSE_LONG_TD; return true; }
   }
   return false;
  }

bool CAmaJmaExpert::ShouldCloseShort(void)
  {
//   if(m_rates[0].tick_volume-m_open_tick_no<MiTickNoBetweenTrade) return false;
   if(m_open_trade_type==BULL_TO_OSCI_OPEN_SHORT_TD)
   {
     if(InBullCloseShortCont()) { CurrTradeType=BULL_CLOSE_SHORT_TD; return true; }
     if(FromBullToOsciCloseShortCont()) { CurrTradeType=BULL_TO_OSCI_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_LIMIT_TD; return true; }
     if(FromOsciToBearCloseShortCont()) { CurrTradeType=OSCI_TO_BEAR_CLOSE_SHORT_TD; return true; }
     if(InBearCloseShortCont()) { CurrTradeType=BEAR_CLOSE_SHORT_TD; return true; }
   }
   else if(m_open_trade_type==OSCI_TO_BEAR_OPEN_SHORT_TD)
   {
     if(InOscillationCloseShortCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_LIMIT_TD; return true; }
     if(FromOsciToBearCloseShortCont()) { CurrTradeType=OSCI_TO_BEAR_CLOSE_SHORT_TD; return true; }
     if(InBearCloseShortCont()) { CurrTradeType=BEAR_CLOSE_SHORT_TD; return true; }
   }
   else if(m_open_trade_type==OSCILLATION_OPEN_SHORT_TD)
   {
     if(InBullCloseShortCont()) { CurrTradeType=BULL_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_LIMIT_TD; return true; }
     if(FromOsciToBearCloseShortCont()) { CurrTradeType=OSCI_TO_BEAR_CLOSE_SHORT_TD; return true; }
     if(InBearCloseShortCont()) { CurrTradeType=BEAR_CLOSE_SHORT_TD; return true; }
   } 
   else if(m_open_trade_type==BULL_OPEN_SHORT_TD)
   {
     if(InBullCloseShortCont()) { CurrTradeType=BULL_CLOSE_SHORT_TD; return true; }
     if(FromBullToOsciCloseShortCont()) { CurrTradeType=BULL_TO_OSCI_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_TD; return true; }
     if(InOscillationCloseShortLimitCont()) { CurrTradeType=OSCILLATION_CLOSE_SHORT_LIMIT_TD; return true; }
     if(FromOsciToBearCloseShortCont()) { CurrTradeType=OSCI_TO_BEAR_CLOSE_SHORT_TD; return true; }
     if(InBearCloseShortCont()) { CurrTradeType=BEAR_CLOSE_SHORT_TD; return true; }
   }
   return false;
  }

bool CAmaJmaExpert::ShouldOpenLong(void)
  {
//   if(Bars(Symbol(),Period())<=m_close_bar_no || !IsReachedTickVolumeToOpen()) return false;
   if(FromBearToOsciOpenLongCont() || FromBearToOsciCloseShortCont())
   {
     CurrTradeType=BEAR_TO_OSCI_OPEN_LONG_TD; 
     return true; 
   }
   else if(FromOsciToBullOpenLongCont() || FromOsciToBullCloseShortCont())
   {
     CurrTradeType=OSCI_TO_BULL_OPEN_LONG_TD; 
     return true; 
   }
   else if(InOscillationOpenLongCont() || InOscillationCloseShortCont() || InOscillationCloseShortLimitCont())
   {
     CurrTradeType=OSCILLATION_OPEN_LONG_TD; 
     return true; 
   } 
   else if(InBearOpenLongCont() || InBearCloseShortCont())
   {
     CurrTradeType=BEAR_OPEN_LONG_TD; 
     return true; 
   }
   return false;
  }

bool CAmaJmaExpert::ShouldOpenShort(void)
  {
//   if(Bars(Symbol(),Period())<=m_close_bar_no || !IsReachedTickVolumeToOpen()) return false;
   if(FromBullToOsciOpenShortCont() || FromBullToOsciCloseLongCont())
   {
     CurrTradeType=BULL_TO_OSCI_OPEN_SHORT_TD; 
     return true; 
   }
   else if(FromOsciToBearOpenShortCont() || FromOsciToBearCloseLongCont())
   {
     CurrTradeType=OSCI_TO_BEAR_OPEN_SHORT_TD; 
     return true; 
   }
   else if(InOscillationOpenShortCont() || InOscillationCloseLongCont() || InOscillationCloseLongLimitCont())
   {
     CurrTradeType=OSCILLATION_OPEN_SHORT_TD; 
     return true; 
   } 
   else if(InBullOpenShortCont() || InBullCloseLongCont())
   {
     CurrTradeType=BULL_OPEN_SHORT_TD; 
     return true; 
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
      printf("Position by %s be closed with %s",Symbol(),EnumToString(m_close_trade_type));
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
         printf("Position by %s be opened with %s of lot %f",Symbol(),EnumToString(m_open_trade_type),lot);
         res=true;
        }
      else
        {
         printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
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
         printf("Position by %s be opened with %s of lot %f",Symbol(),EnumToString(m_open_trade_type),lot);
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
   if(CopyRates(Symbol(),Period(),0,BufferCountToCopy,m_rates)!=BufferCountToCopy)
     {
      Print("CopyRates of ",Symbol()," failed, no history");
      return false;
     }
   m_has_opened_position = m_position.Select(Symbol());
//--- Record every tick type
   RecordTickType();
//   m_indicators.Refresh();
//--- it is important to enter the market correctly, 
//--- but it is more important to exit it correctly...   
//--- first check if position exists - try to select it
   if(m_has_opened_position)
     {
      bool closed = false;
      if(m_position.PositionType()==POSITION_TYPE_BUY)
        {
         //--- try to close or modify long position
         if(ShouldCloseLong())
          {
            closed = PositionClosed();
            if(closed && CloseToOpen)
            {
             if(ShouldOpenShort()) return(ShortOpened());
            } 
            return(closed);
          }
        }
      else
        {
         //--- try to close or modify short position
         if(ShouldCloseShort())
          {
            closed = PositionClosed();
            if(closed && CloseToOpen)
            {
             if(ShouldOpenLong()) return(LongOpened());
            } 
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
