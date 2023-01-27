#include <iostream>
#include <iomanip>

void MakePad1x1(TPad* pd[], char*, char*);

int memeff_cmsExpMT_elec_E5()
{
   gROOT->Reset();

   TCanvas* c2 = new TCanvas("c2","c2",0,0,500,400);
   c2->SetTitle("Geant4 MT/Tasking Performance: cmsExpMT, Tasking RM");

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

//   const int nb = 8;
//   int beam[nb] = {0,1,2,4,6,8,10,12};

   const int nb = 10;
   int beam[nb] = {0,1,2,4,6,8,10,12,14,16};

   char gffilename[256];

   FILE *gffile[nb];    

   for(int i = 0 ; i < nb ; i++) {
     sprintf(gffilename,"./meminfo_e-_E5_t%d.dat",beam[i]);
     gffile[i] = fopen(gffilename,"r");
   }

   Float_t vsize;
   Float_t rss;
   Float_t share;

   double gf_vsize_mean[nb];
   double gf_vsize_rms[nb];
   double gf_rss_mean[nb];
   double gf_rss_rms[nb];

   TH1F *h_vsize[nb];
   TH1F *h_rss[nb];

   char hname[128];
   char htitle[256];

   double pbin[nb], epbin[nb];

   for(int i = 0 ; i < nb ; i++) {
     pbin[i] = beam[i];
     epbin[i] = 0.0;

     sprintf(hname,"vsize_%d",i);
     sprintf(htitle,"vsize for %d tracks",beam[i]);
     h_vsize[i] = new TH1F(hname,htitle, 100,0.0,10000.0);

     sprintf(hname,"rss_%d",i);
     sprintf(htitle,"rss for %d tracks",beam[i]);
     h_rss[i] = new TH1F(hname,htitle, 100,0.0,10000.0);

     while ( !feof(gffile[i]) ) {
       fscanf(gffile[i],"%f %f %f",&vsize,&rss,&share);
       h_vsize[i]->Fill(vsize);
       h_rss[i]->Fill(rss-share);
     }

     gf_vsize_mean[i] = h_vsize[i]->GetMean();
     gf_rss_mean[i]   = h_rss[i]->GetMean();

     gf_vsize_rms[i]  = h_vsize[i]->GetRMS()/sqrt(1028.);
     gf_rss_rms[i]  = h_rss[i]->GetRMS()/sqrt(1028.);

     std::cout << "i-core VSIZE and RSS " << beam[i] << " " << gf_vsize_mean[i] 
	       << " " << gf_rss_mean[i] << std::endl;
     fclose(gffile[i]);
   }

   //data for serial information beam=0;
   double pbin1[1] = {1.0};
   double epbin1[1] = {0.0};
   double gf_serial_rss[1];   
   double gf_serial_vsize[1];   

   gf_serial_rss[0] = gf_rss_mean[0];   
   gf_serial_vsize[0] =  gf_vsize_mean[0];   

   const int nt = nb -1;
// -->   double pbin[nt], epbin[nt];

   double gf_mt_rss_mean[nt];   
   double gf_mt_rss_rms[nt];   

   double gf_mt_vsize_mean[nt];   
   double gf_mt_vsize_rms[nt];   

   for(int i = 0 ; i < nt ; i++) {
     pbin[i] = beam[i+1];
     epbin[i] = 0.0;
     gf_mt_rss_mean[i] = gf_rss_mean[i+1]/(pbin[i]*gf_serial_rss[0]);
     gf_mt_rss_rms[i]  = 0.0;

     gf_mt_vsize_mean[i] = gf_vsize_mean[i+1]/(pbin[i]*gf_serial_vsize[0]);
     gf_mt_vsize_rms[i]  = 0.0;
   }

   c2->cd();
   TPostScript *ps2 = new TPostScript("memeff_cmsExpMT_elec_E5.eps",113);

   TH2F   *hhf2;
   TGraph *hgr3;
   TGraph *hgr4;

   pd2[0]->cd();
   pd2[0]->SetLogx();
   pd2[0]->SetGridy();
   
// -->   TH2F* hhf3 = new TH2F("hhf3","Memory Reduction - 5 GeV e^{-}", 1,0.7,15.,1,0.,1.6);
   TH2F* hhf3 = new TH2F("hhf3","Memory Reduction - 5 GeV e^{-}", 1,0.7,20.,1,0.,1.6);
   hgr4 = new TGraphErrors(nt,pbin,gf_mt_rss_mean,epbin,gf_mt_rss_rms);
   hgr3 = new TGraphErrors(nt,pbin,gf_mt_vsize_mean,epbin,gf_mt_vsize_rms);

   hhf3->GetYaxis()->SetTitleSize(0.05);
   hhf3->GetYaxis()->SetTitleOffset(1.5);
   hhf3->GetYaxis()->SetTitleColor(4);
   hhf3->GetXaxis()->SetTitleSize(0.05);
   hhf3->GetXaxis()->SetTitleOffset(1.2);
   hhf3->GetXaxis()->SetTitleColor(4);
   hhf3->SetXTitle("N Core");
   hhf3->SetYTitle("[Mem(Tasking)/Ncore]/Mem(SEQUENTIAL)");
   hhf3->Draw();
   
   hgr4->SetMarkerColor(kRed);
   hgr4->SetMarkerStyle(20);
   hgr4->SetMarkerSize(1.2);
   hgr4->SetLineColor(kRed);
   hgr4->Draw("LPsame");

   hgr3->SetMarkerColor(kBlue);
   hgr3->SetMarkerStyle(20);
   hgr3->SetMarkerSize(1.2);
   hgr3->SetLineColor(kBlue);
   hgr3->Draw("LPsame");

// -->   TLine* ll = new TLine(0.7, 1.0, 15, 1.0);
   TLine* ll = new TLine(0.7, 1.0, 20, 1.0);
   ll->SetLineColor(2);
   ll->SetLineStyle(2);
   ll->Draw();

   TLegend *lg1 = new TLegend(0.50,0.72,0.80,0.86);
   lg1->AddEntry(hgr4,"RSS-SHARED","PL");
   lg1->AddEntry(hgr3,"VSIZE","PL");
   lg1->SetTextSize(0.035);
   lg1->Draw();

   char pngtitle[256];   
   sprintf(pngtitle,"memeff_cmsExpMT_elec_E5.%s","png");

   c2->Update(); 
   c2->Print(pngtitle);   
   ps2->Close();
   
   return 0;

}
