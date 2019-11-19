#include <iostream>
#include <iomanip>

int threads_time_cmsExpMT5()
{
   gROOT->Reset();

   c2 = new TCanvas("c2","c2",0,0,500,400);
   c2->SetTitle("Geant4MT Performance: cmsExpMT");

   c2->cd();
   TPad *pd2[1];
   MakePad1x1(pd2,"pad2","pad2");

   // Plot test Beam Data

   gStyle->SetOptStat(0);
   gStyle->SetPadBorderMode(0);
   gStyle->SetMarkerSize(0.8);

   gStyle->SetTitleH(0.07);
   gStyle->SetTitleW(0.70);
   gStyle->SetPadBorderMode(0);
   gStyle->SetTitleX(0.15);
   gStyle->SetTitleY(0.98);

   gStyle->SetStatX(0.96);
   gStyle->SetStatY(0.88);
   gStyle->SetStatW(0.16);
   gStyle->SetStatH(0.16);

   const int nb = 1;

   int beam[nb] = {32};

   char gffilename[256];

   FILE *gffile[nb];    

   for(int i = 0 ; i < nb ; i++) {
     sprintf(gffilename,"/home/syjun/pbs/scaling5/%d/scaling5_%d.dat",beam[i],beam[i]);
     gffile[i] = fopen(gffilename,"r");
   }

   Float_t total;

   double gf_total_mean[32];
   double gf_total_rms[32];

   TH1F *h_total[nb];

   char hname[128];
   char htitle[256];

   double pbin[32], epbin[32];


   for(int i = 0 ; i < 32 ; i++) {
     gf_total_mean[i];
     gf_total_rms[i];
     pbin[i] = 0 ; 
     epbin[i] = 0;
   }

   for(int i = 0 ; i < nb ; i++) {

     sprintf(hname,"total_%d",i);
     sprintf(htitle,"CPU/Event/Core for %d tracks",beam[i]);
     h_total[i] = new TH1F(hname,htitle, 10000,0.0,10000.0);

     int idx = 0;

     while ( !feof(gffile[i]) && idx < 32) {
       fscanf(gffile[i],"%f",&total);
       gf_total_mean[idx] = total;     
       gf_total_rms[idx] = 0.0;     
       pbin[idx] = idx+1;
       epbin[idx] = 0.0;
       idx++;
    }

     fclose(gffile[i]);
   }

   //data for serial information beam=0;
   std::cout << "Using serial Total CPU and RMS " << 3771.21 << " " << 0.0 << std::endl;
   double pbin1[1] = {1.0};
   double epbin1[1] = {0.0};
   double gf_serial_mean[1] = {3771.21};   
   double gf_serial_rms[1] = {0.0};   

   c2->cd();
   TPostScript *ps2 = new TPostScript("threads_time_cmsExpMT5.eps",113);

   TH2F   *hhf2;
   TGraph *hgr2;
   TGraph *hgr3;

   pd2[0]->cd();
   //   pd2[0]->SetLogx();
   //   pd2[0]->SetLogy();
   pd2[0]->SetGridy();
   
   hhf3 = new TH2F("hhf3","cmsExpMT Performance with 50 GeV #pi^{-}", 1,0.0,33.,1,0.0,400.);
   hgr3 = new TGraphErrors(32,pbin,gf_total_mean,epbin,gf_total_rms);
   //   hgr2 = new TGraphErrors(1,pbin1,gf_serial_mean,epbin1,gf_serial_rms);

   hhf3->GetYaxis()->SetTitleSize(0.05);
   hhf3->GetYaxis()->SetTitleOffset(1.5);
   hhf3->GetYaxis()->SetTitleColor(4);
   hhf3->GetYaxis()->SetNdivisions(5);
   hhf3->GetXaxis()->SetTitleSize(0.05);
   hhf3->GetXaxis()->SetTitleOffset(1.2);
   hhf3->GetXaxis()->SetTitleColor(4);
   hhf3->SetXTitle("N-th Core");
   hhf3->SetYTitle("Total CPU Time [sec]");
   hhf3->Draw();
   
   hgr3->SetMarkerColor(kBlue);
   hgr3->SetMarkerStyle(20);
   hgr3->SetMarkerSize(1.2);
   hgr3->SetLineColor(kBlue);
   hgr3->Draw("LPsame");

   /*
   llow = new TLine(0.6, 3.68165, 50, 3.68165);
   llow->SetLineColor(2);
   llow->SetLineStyle(2);
   llow->Draw();
   */

   TLegend *lg1 = new TLegend(0.18,0.74,0.70,0.86);
   lg1->AddEntry(hgr3,"cmsExpMT + geant4-MT-09-05-patch-01","PL");
   //   lg1->AddEntry(hgr2,"cmsExp + geant4-09-05-patch-01","PL");
   lg1->SetTextSize(0.03);
   lg1->Draw();

   char pngtitle[256];   
   sprintf(pngtitle,"threads_time_cmsExpMT5.%s","png");

   c2->Update(); 
   c2->Print(pngtitle);   
   ps2->Close();

}
