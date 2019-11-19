#include "TPad.h"
#include "TH1F.h"
#include "TH2F.h"
#include "TStyle.h"

void MakePad1x1(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];
   const float x41[1] = {0.005};
   const float y41[1] = {0.005};
   const float x42[1] = {0.995};
   const float y42[1] = {0.995};

   for(Int_t i = 0 ; i < 1 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x41[i],y41[i],x42[i],y42[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.15);
     pd[i]->SetRightMargin(0.15);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad1x2(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];
   const float x41[2] = {0.005,0.505};
   const float y41[2] = {0.005,0.005};
   const float x42[2] = {0.495,0.995};
   const float y42[2] = {0.995,0.995};

   for(Int_t i = 0 ; i < 2 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x41[i],y41[i],x42[i],y42[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad2x1(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x41[2] = {0.005,0.005};
   const float y41[2] = {0.505,0.005};
   const float x42[2] = {0.995,0.995};
   const float y42[2] = {0.995,0.495};

   for(Int_t i = 0 ; i < 2 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x41[i],y41[i],x42[i],y42[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.12);
     pd[i]->SetRightMargin(0.05);
     pd[i]->SetBottomMargin(0.12);
   }
}


void MakePad2x2(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];
   const float x41[4] = {0.010,0.510,0.010,0.510};
   const float y41[4] = {0.505,0.505,0.005,0.005};
   const float x42[4] = {0.490,0.990,0.490,0.990};
   const float y42[4] = {1.000,1.000,0.495,0.495};

   //
   for(Int_t i = 0 ; i < 4 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x41[i],y41[i],x42[i],y42[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad1x3(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[3] = {0.010,0.010,0.010};
   const float y61[3] = {0.670,0.335,0.000};
   const float x62[3] = {0.990,0.990,0.990};
   const float y62[3] = {1.000,0.665,0.330};

   for(Int_t i = 0 ; i < 3 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.08);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}


void MakePad2x3(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[6] = {0.010,0.510,0.010,0.510,0.010,0.510};
   const float y61[6] = {0.670,0.670,0.335,0.335,0.000,0.000};
   const float x62[6] = {0.490,0.990,0.490,0.990,0.490,0.990};
   const float y62[6] = {1.000,1.000,0.665,0.665,0.330,0.330};

   for(Int_t i = 0 ; i < 6 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad3x1(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[3] = {0.010,0.340,0.670};
   const float y61[3] = {0.005,0.005,0.005};
   const float x62[3] = {0.330,0.660,0.990};
   const float y62[3] = {1.000,1.000,1.000};

   for(Int_t i = 0 ; i < 3 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad3x2(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[6] = {0.010,0.340,0.670,0.010,0.340,0.670};
   const float y61[6] = {0.505,0.505,0.505,0.005,0.005,0.005};
   const float x62[6] = {0.330,0.660,0.990,0.330,0.660,0.990};
   const float y62[6] = {1.000,1.000,1.000,0.495,0.495,0.495};

   for(Int_t i = 0 ; i < 6 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}


void MakePad3x3(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[9] = {0.010,0.340,0.670,0.010,0.340,0.670,0.010,0.340,0.670};
   const float y61[9] = {0.670,0.670,0.670,0.335,0.335,0.335,0.000,0.000,0.000};
   const float x62[9] = {0.330,0.660,0.990,0.330,0.660,0.990,0.330,0.660,0.990};
   const float y62[9] = {1.000,1.000,1.000,0.665,0.665,0.665,0.330,0.330,0.330};

   for(Int_t i = 0 ; i < 9 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}


void MakePad3x4(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[12] = {0.010,0.340,0.670,0.010,0.340,0.670,0.010,0.340,0.670,0.010,0.340,0.670};
   const float y61[12] = {0.760,0.760,0.760,0.510,0.510,0.510,0.260,0.260,0.260,0.000,0.000,0.000};
   const float x62[12] = {0.330,0.660,0.990,0.330,0.660,0.990,0.330,0.660,0.990,0.330,0.660,0.990};
   const float y62[12] = {1.000,1.000,1.000,0.750,0.750,0.750,0.500,0.500,0.500,0.250,0.250,0.250};

   for(Int_t i = 0 ; i < 12 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad4x4(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[16] = {0.000,0.250,0.500,0.750,0.000,0.250,0.500,0.750,0.000,0.250,0.500,0.750,0.000,0.250,0.500,0.750};
   const float x62[16] = {0.240,0.490,0.740,0.990,0.240,0.490,0.740,0.990,0.240,0.490,0.740,0.990,0.240,0.490,0.740,0.990};

   const float y61[16] = {0.760,0.760,0.760,0.760,0.510,0.510,0.510,0.510,0.260,0.260,0.260,0.260,0.000,0.000,0.000,0.000};
   const float y62[16] = {1.000,1.000,1.000,1.000,0.750,0.750,0.750,0.750,0.500,0.500,0.500,0.500,0.250,0.250,0.250,0.250};

   for(Int_t i = 0 ; i < 16 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad5x2(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[10] = {0.005,0.205,0.405,0.605,0.805,0.005,0.205,0.405,0.605,0.805};
   const float y61[10] = {0.335,0.335,0.335,0.335,0.335,0.000,0.000,0.000,0.000,0.000};
   const float x62[10] = {0.195,0.395,0.595,0.795,0.995,0.195,0.395,0.595,0.795,0.995};
   const float y62[10] = {1.000,1.000,1.000,1.000,1.000,0.330,0.330,0.330,0.330,0.330};

   for(Int_t i = 0 ; i < 10 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad5x3(TPad *pd[], char *pdname, char *pdtitle){

   char idx[16];
   char name[16];
   char title[16];

   const float x61[15] = {0.005,0.205,0.405,0.605,0.805,0.005,0.205,0.405,0.605,0.805,0.005,0.205,0.405,0.605,0.805};
   const float y61[15] = {0.670,0.670,0.670,0.670,0.670,0.335,0.335,0.335,0.335,0.335,0.000,0.000,0.000,0.000,0.000};
   const float x62[15] = {0.195,0.395,0.595,0.795,0.995,0.195,0.395,0.595,0.795,0.995,0.195,0.395,0.595,0.795,0.995};
   const float y62[15] = {1.000,1.000,1.000,1.000,1.000,0.665,0.665,0.665,0.665,0.665,0.330,0.330,0.330,0.330,0.330};

   for(Int_t i = 0 ; i < 15 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad5x5(TPad *pd[], char *pdname, char *pdtitle){

   char idx[25];
   char name[25];
   char title[25];

   const float x61[25] = {0.0,0.2,0.4,0.6,0.8,0.0,0.2,0.4,0.6,0.8,0.0,0.2,0.4,0.6,0.8,0.0,0.2,0.4,0.6,0.8,0.0,0.2,0.4,0.6,0.8};
   const float x62[25] = {0.2,0.4,0.6,0.8,1.0,0.2,0.4,0.6,0.8,1.0,0.2,0.4,0.6,0.8,1.0,0.2,0.4,0.6,0.8,1.0,0.2,0.4,0.6,0.8,1.0};

   const float y61[25] = {0.8,0.8,0.8,0.8,0.8,0.6,0.6,0.6,0.6,0.6,0.4,0.4,0.4,0.4,0.4,0.2,0.2,0.2,0.2,0.2,0.0,0.0,0.0,0.0,0.0};
   const float y62[25] = {1.0,1.0,1.0,1.0,1.0,0.8,0.8,0.8,0.8,0.8,0.6,0.6,0.6,0.6,0.6,0.4,0.4,0.4,0.4,0.4,0.2,0.2,0.2,0.2,0.2};

   for(Int_t i = 0 ; i < 25 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}

void MakePad5x8(TPad *pd[], char *pdname, char *pdtitle){

   char idx[40];
   char name[40];
   char title[40];

   const float x61[40] = {0.0,0.125,0.250,0.375,0.500,0.625,0.750,0.875,
			  0.0,0.125,0.250,0.375,0.500,0.625,0.750,0.875,
			  0.0,0.125,0.250,0.375,0.500,0.625,0.750,0.875,
			  0.0,0.125,0.250,0.375,0.500,0.625,0.750,0.875,
			  0.0,0.125,0.250,0.375,0.500,0.625,0.750,0.875};
   const float x62[40] = {0.125,0.250,0.375,0.500,0.625,0.750,0.875,1.0,
			  0.125,0.250,0.375,0.500,0.625,0.750,0.875,1.0,
			  0.125,0.250,0.375,0.500,0.625,0.750,0.875,1.0,
			  0.125,0.250,0.375,0.500,0.625,0.750,0.875,1.0,
			  0.125,0.250,0.375,0.500,0.625,0.750,0.875,1.0};

   const float y61[40] = {0.8,0.8,0.8,0.8,0.8,0.8,0.8,0.8,
			  0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,
			  0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,
			  0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,
			  0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
   const float y62[40] = {1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,
			  0.8,0.8,0.8,0.8,0.8,0.8,0.8,0.8,
			  0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,
			  0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,
			  0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2};

   for(Int_t i = 0 ; i < 40 ; i++) {
     strcpy(name,pdname);
     strcpy(title,pdtitle);
     sprintf(idx,"%d",i);
     strcat(name,idx);
     strcat(title,idx);

     pd[i] = new TPad(name,title,x61[i],y61[i],x62[i],y62[i]);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.18);
     pd[i]->SetRightMargin(0.02);
     pd[i]->SetBottomMargin(0.12);
   }
}



/*
void DivideHisto(TH1F* h1, TH1F* h2, TH1F *h1_over_h2, int const NBIN) {

  Float_t s1[NBIN],s2[NBIN],s[NBIN];
  Float_t e1[NBIN],e2[NBIN],e[NBIN];

  for(int i=0 ; i < NBIN ; i++) {
    s1[i]  = h1->GetBinContent(i+1);
    s2[i]  = h2->GetBinContent(i+1);
    e1[i]  = h1->GetBinError(i+1);
    e2[i]  = h2->GetBinError(i+1);
    if(s2[i]!=0) { 
      s[i] = s1[i]/s2[i];
      e[i] = s[i]*TMath::Sqrt(TMath::Power(e1[i]/s1[i],2)+TMath::Power(e2[i]/s2[i],2));
    }
    else {
      s[i] = 0.0;
      e[i] = 0.0;
    }

    h1_over_h2->SetBinContent(i+1,s[i]);
    h1_over_h2->SetBinError(i+1,e[i]);
  }
}
*/

/*
void setHistogram(TH1F* h1, char* title = "", char* xtitle = "", char* ytitle = "")
{
   h1->GetXaxis()->SetTitleOffset(1.0);    
   h1->GetXaxis()->SetLabelOffset(0.01);
   h1->GetXaxis()->SetTitleSize(0.05);
   h1->GetXaxis()->SetLabelSize(0.04);
   h1->GetXaxis()->SetTitleColor(kBlack);
    
   h1->GetYaxis()->SetTitleOffset(1.5);  
   h1->GetYaxis()->SetLabelOffset(0.01); 
   h1->GetYaxis()->SetTitleSize(0.05);
   h1->GetYaxis()->SetLabelSize(0.04);
   h1->GetYaxis()->SetTitleColor(kBlack);

   h1->SetTitle(title); 
   h1->SetXTitle(xtitle); 
   h1->SetYTitle(ytitle); 
   //   h1->SetLineColor(kBlue);
   h1->SetMarkerSize(1.2);

}

void setHistogram(TH2F* h2, char* title = "", char* xtitle = "", char* ytitle = "")
{
   h2->GetXaxis()->SetTitleOffset(1.0);    
   h2->GetXaxis()->SetLabelOffset(0.01);
   h2->GetXaxis()->SetTitleSize(0.05);
   h2->GetXaxis()->SetLabelSize(0.04);
   h2->GetXaxis()->SetTitleColor(kBlack);
    
   h2->GetYaxis()->SetTitleOffset(1.5);  
   h2->GetYaxis()->SetLabelOffset(0.01); 
   h2->GetYaxis()->SetTitleSize(0.05);
   h2->GetYaxis()->SetLabelSize(0.04);
   h2->GetYaxis()->SetTitleColor(kBlack);

   h2->SetTitle(title); 
   h2->SetXTitle(xtitle); 
   h2->SetYTitle(ytitle); 
   //   h2->SetLineColor(kBlue);
   h2->SetMarkerSize(1.2);
}
*/

void setTDRStyle() {
  TStyle *tdrStyle = new TStyle("tdrStyle","Style for P-TDR");

// For the canvas:
  tdrStyle->SetCanvasBorderMode(0);
  tdrStyle->SetCanvasColor(kWhite);
  tdrStyle->SetCanvasDefH(600); //Height of canvas
  tdrStyle->SetCanvasDefW(600); //Width of canvas
  tdrStyle->SetCanvasDefX(0);   //POsition on screen
  tdrStyle->SetCanvasDefY(0);

// For the Pad:
  tdrStyle->SetPadBorderMode(0);
  // tdrStyle->SetPadBorderSize(Width_t size = 1);
  tdrStyle->SetPadColor(kWhite);
  tdrStyle->SetPadGridX(false);
  tdrStyle->SetPadGridY(false);
  tdrStyle->SetGridColor(0);
  tdrStyle->SetGridStyle(3);
  tdrStyle->SetGridWidth(1);

// For the frame:
  tdrStyle->SetFrameBorderMode(0);
  tdrStyle->SetFrameBorderSize(1);
  tdrStyle->SetFrameFillColor(0);
  tdrStyle->SetFrameFillStyle(0);
  tdrStyle->SetFrameLineColor(1);
  tdrStyle->SetFrameLineStyle(1);
  tdrStyle->SetFrameLineWidth(1);

// For the histo:
  // tdrStyle->SetHistFillColor(1);
  // tdrStyle->SetHistFillStyle(0);
  tdrStyle->SetHistLineColor(1);
  tdrStyle->SetHistLineStyle(0);
  tdrStyle->SetHistLineWidth(1);
  // tdrStyle->SetLegoInnerR(Float_t rad = 0.5);
  // tdrStyle->SetNumberContours(Int_t number = 20);

  tdrStyle->SetEndErrorSize(2);
  //tdrStyle->SetErrorMarker(20);
  //  tdrStyle->SetErrorX(0.);
  
  tdrStyle->SetMarkerStyle(20);

//For the fit/function:
  tdrStyle->SetOptFit(1);
  tdrStyle->SetFitFormat("5.4g");
  tdrStyle->SetFuncColor(2);
  tdrStyle->SetFuncStyle(1);
  tdrStyle->SetFuncWidth(1);

//For the date:
  tdrStyle->SetOptDate(0);
  // tdrStyle->SetDateX(Float_t x = 0.01);
  // tdrStyle->SetDateY(Float_t y = 0.01);

// For the statistics box:
  tdrStyle->SetOptFile(0);
  tdrStyle->SetOptStat(0); // To display the mean and RMS:   SetOptStat("mr");
  tdrStyle->SetStatColor(kWhite);
  tdrStyle->SetStatFont(42);
  tdrStyle->SetStatFontSize(0.025);
  tdrStyle->SetStatTextColor(1);
  tdrStyle->SetStatFormat("6.4g");
  tdrStyle->SetStatBorderSize(1);
  tdrStyle->SetStatH(0.12);
  tdrStyle->SetStatW(0.18);

  tdrStyle->SetTitleH(0.10);
  // tdrStyle->SetStatStyle(Style_t style = 1001);
  // tdrStyle->SetStatX(Float_t x = 0);
  // tdrStyle->SetStatY(Float_t y = 0);

// Margins:
//  tdrStyle->SetPadTopMargin(0.05);
  tdrStyle->SetPadBottomMargin(0.13);
  tdrStyle->SetPadLeftMargin(0.13);
  tdrStyle->SetPadRightMargin(0.05);

// For the Global title:

//  tdrStyle->SetOptTitle(0);
  tdrStyle->SetTitleFont(42);
  tdrStyle->SetTitleColor(1);
  tdrStyle->SetTitleTextColor(1);
  tdrStyle->SetTitleFillColor(10);
  tdrStyle->SetTitleFontSize(0.05);
  // tdrStyle->SetTitleH(0); // Set the height of the title box
  // tdrStyle->SetTitleW(0); // Set the width of the title box
  // tdrStyle->SetTitleX(0); // Set the position of the title box
  // tdrStyle->SetTitleY(0.985); // Set the position of the title box
  // tdrStyle->SetTitleStyle(Style_t style = 1001);
  // tdrStyle->SetTitleBorderSize(2);

// For the axis titles:

  tdrStyle->SetTitleColor(1, "XYZ");
  tdrStyle->SetTitleFont(42, "XYZ");
  tdrStyle->SetTitleSize(0.06, "XYZ");
  // tdrStyle->SetTitleXSize(Float_t size = 0.02); // Another way to set the size?
  // tdrStyle->SetTitleYSize(Float_t size = 0.02);
  tdrStyle->SetTitleXOffset(0.9);
  tdrStyle->SetTitleYOffset(1.05);
  // tdrStyle->SetTitleOffset(1.1, "Y"); // Another way to set the Offset

// For the axis labels:

  tdrStyle->SetLabelColor(1, "XYZ");
  tdrStyle->SetLabelFont(42, "XYZ");
  tdrStyle->SetLabelOffset(0.007, "XYZ");
  tdrStyle->SetLabelSize(0.05, "XYZ");

// For the axis:

  tdrStyle->SetAxisColor(1, "XYZ");
  tdrStyle->SetStripDecimals(kTRUE);
  tdrStyle->SetTickLength(0.03, "XYZ");
  tdrStyle->SetNdivisions(510, "XYZ");
  tdrStyle->SetPadTickX(1);  // To get tick marks on the opposite side of the frame
  tdrStyle->SetPadTickY(1);

// Change for log plots:
  tdrStyle->SetOptLogx(0);
  tdrStyle->SetOptLogy(0);
  tdrStyle->SetOptLogz(0);

// Postscript options:
  // tdrStyle->SetPaperSize(15.,15.);
  // tdrStyle->SetLineScalePS(Float_t scale = 3);
  // tdrStyle->SetLineStyleString(Int_t i, const char* text);
  // tdrStyle->SetHeaderPS(const char* header);
  // tdrStyle->SetTitlePS(const char* pstitle);

  // tdrStyle->SetBarOffset(Float_t baroff = 0.5);
  // tdrStyle->SetBarWidth(Float_t barwidth = 0.5);
  // tdrStyle->SetPaintTextFormat(const char* format = "g");
  // tdrStyle->SetPalette(Int_t ncolors = 0, Int_t* colors = 0);
  // tdrStyle->SetTimeOffset(Double_t toffset);
  // tdrStyle->SetHistMinimumZero(kTRUE);

  tdrStyle->cd();
}
