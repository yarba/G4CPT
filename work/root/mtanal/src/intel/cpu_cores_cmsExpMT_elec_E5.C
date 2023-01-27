#include <iostream>
#include <iomanip>

void MakePad1x1(TPad* pd[], char*, char*);

int cpu_cores_cmsExpMT_elec_E5()
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
     sprintf(gffilename,"./cpu_core_e-_E5_t%d.dat",beam[i]);
     gffile[i] = fopen(gffilename,"r");
   }

   Float_t total;

   double gf_total_mean[nb];
   double gf_total_rms[nb];

   TH1F *h_total[nb];

   char hname[128];
   char htitle[256];

   for(int i = 0 ; i < nb ; i++) {

     sprintf(hname,"total_%d",i);
     sprintf(htitle,"CPU/Event/Core for %d tracks",beam[i]);
     h_total[i] = new TH1F(hname,htitle, 2000,0.0,100.0);

     while ( !feof(gffile[i]) ) {
       fscanf(gffile[i],"%f",&total);
       h_total[i]->Fill(total);
     }

     gf_total_mean[i] = h_total[i]->GetMean();
     gf_total_rms[i]  = h_total[i]->GetRMS();

     std::cout << "elec E5 i-core Mean CPU and RMS " 
               << beam[i] << " " << gf_total_mean[i] << " " << gf_total_rms[i] << std::endl;
     fclose(gffile[i]);
   }

   //data for serial information beam=0;
   double pbin1[1] = {1.0};
   double epbin1[1] = {0.0};
   double gf_serial_mean[1];   
   double gf_serial_rms[1];   

   gf_serial_mean[0] = gf_total_mean[0];   
   gf_serial_rms[0] = gf_total_rms[0];   


   std::cout << "Using serial Mean CPU and RMS " 
             << gf_serial_mean[0] << " " <<  gf_serial_rms[0] << std::endl;

   const int nt = nb -1;
   double pbin[nt], epbin[nt];

   double gf_mt_ratio_mean[nt];   
   double gf_mt_ratio_rms[nt];   

   for(int i = 0 ; i < nt ; i++) {
     pbin[i] = beam[i+1];
     epbin[i] = 0.0;
     gf_mt_ratio_mean[i] = gf_serial_mean[0]/gf_total_mean[i+1];
     double a = gf_total_rms[0]/gf_total_mean[0];
     double b = gf_total_rms[i+1]/gf_total_mean[i+1];
     gf_mt_ratio_rms[i]  = 0.01*gf_mt_ratio_mean[i]*sqrt(a*a+b*b);
   }

   c2->cd();
   TPostScript *ps2 = new TPostScript("cpu_cores_cmsExpMT_elec_E5.eps",113);

   TH2F   *hhf2;
   TGraph *hgr2;
   TGraph *hgr3;

   pd2[0]->cd();
   pd2[0]->SetLogx();
   //   pd2[0]->SetLogy();
   pd2[0]->SetGridy();
   
// -->   TH2F* hhf3 = new TH2F("hhf3"," Speedup Efficiency- 5 GeV e^{-}", 1,0.7,15.,1,0.8,1.1499);
   TH2F* hhf3 = new TH2F("hhf3"," Speedup Efficiency- 5 GeV e^{-}", 1,0.7,20.,1,0.8,1.1499);
   //   hgr3 = new TGraphErrors(nb,pbin,gf_total_mean,epbin,gf_total_rms);
   //   hgr2 = new TGraphErrors(1,pbin1,gf_serial_mean,epbin1,gf_serial_rms);
   hgr3 = new TGraphErrors(nt,pbin,gf_mt_ratio_mean,epbin,gf_mt_ratio_rms);

   hhf3->GetYaxis()->SetTitleSize(0.05);
   hhf3->GetYaxis()->SetTitleOffset(1.5);
   hhf3->GetYaxis()->SetTitleColor(4);
   //   hhf3->GetYaxis()->SetNdivisions(5);
   hhf3->GetXaxis()->SetTitleSize(0.05);
   hhf3->GetXaxis()->SetTitleOffset(1.2);
   hhf3->GetXaxis()->SetTitleColor(4);
   hhf3->SetXTitle("N Core");
   hhf3->SetYTitle("Ratio of <CPU Time>/Event/Core");
   hhf3->Draw();
   
   hgr3->SetMarkerColor(kBlue);
   hgr3->SetMarkerStyle(20);
   hgr3->SetMarkerSize(1.2);
   hgr3->SetLineColor(kBlue);
   hgr3->Draw("LPsame");

   /*
   hgr2->SetMarkerColor(kRed);
   hgr2->SetMarkerStyle(20);
   hgr2->SetMarkerSize(1.2);
   hgr2->SetLineColor(kRed);
   hgr2->Draw("LPsame");
   */

   //   llow = new TLine(1.0, gf_serial_mean[0], 32, gf_serial_mean[0]);
// -->   TLine* llow = new TLine(0.7, 1.0, 15, 1.0);
   TLine* llow = new TLine(0.7, 1.0, 20, 1.0);
   llow->SetLineColor(2);
   llow->SetLineStyle(2);
   llow->Draw();

   /*
   TLegend *lg1 = new TLegend(0.18,0.74,0.60,0.86);
   lg1->AddEntry(hgr3,"MULTITHREAD","PL");
   lg1->AddEntry(hgr2,"SEQUENTIAL","PL");
   lg1->SetTextSize(0.03);
   lg1->Draw();
   */

   TLegend *lg1 = new TLegend(0.18,0.74,0.78,0.86);
   lg1->AddEntry(hgr3,"cmsExpSerial/cmsExpTasking","PL");
   lg1->SetTextSize(0.04);
   lg1->Draw();

   char pngtitle[256];   
   sprintf(pngtitle,"cpu_cores_cmsExpMT_elec_E5.%s","png");

   c2->Update(); 
   c2->Print(pngtitle);   
   ps2->Close();
   
   return 0;

}
