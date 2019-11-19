#include <iostream>
#include <iomanip>

int speedup_cmsExpMT_pi_E5()
{
   gROOT->Reset();

   c2 = new TCanvas("c2","c2",0,0,500,400);
   c2->SetTitle("Geant4 MT Performance: cmsExpMT");

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
//   int beam[nb] = {0,1,2,4,8,16,24,32};
   const int nb = 7;
   int beam[nb] = {0,1,2,4,8,16,24};

   char gffilename[256];

   FILE *gffile[nb];    

   for(int i = 0 ; i < nb ; i++) {
     sprintf(gffilename,"./scaling_pi-_E5_t%d.dat",beam[i]);
     gffile[i] = fopen(gffilename,"r");
   }

   Float_t total;

   double gf_total_mean[nb];
   double gf_total_rms[nb];

   TH1F *h_total[nb];

   char hname[128];
   char htitle[256];

   double pbin[nb], epbin[nb];

   for(int i = 0 ; i < nb ; i++) {
     pbin[i] = beam[i];
     epbin[i] = 0.0;

     sprintf(hname,"total_%d",i);
     sprintf(htitle,"Time/Event for %d tracks",beam[i]);
     h_total[i] = new TH1F(hname,htitle, 100,0.0,10000.0);

     while ( !feof(gffile[i]) ) {
       fscanf(gffile[i],"%f",&total);
       if(i==0) h_total[i]->Fill(total);
       else     h_total[i]->Fill(gf_total_mean[0]/total);
     }

     gf_total_mean[i] = h_total[i]->GetMean();
     gf_total_rms[i]  = h_total[i]->GetRMS()/sqrt(1028.);

     std::cout << "i-core Total CPU and RMS " << beam[i] << " " << gf_total_mean[i] << " " << gf_total_rms[i] << std::endl;
     fclose(gffile[i]);
   }

   //data for serial information beam=0;
   double pbin1[1] = {1.0};
   double epbin1[1] = {0.0};
   double gf_serial_mean[1] = {1.0};   
   double gf_serial_rms[1] = {0.0};   

   gf_total_mean[0] = gf_serial_mean[0];
   gf_total_rms[0]  = gf_serial_rms[0];
     
   c2->cd();
   TPostScript *ps2 = new TPostScript("speedup_cmsExpMT_pi_E5.eps",113);

   TH2F   *hhf2;
   TGraph *hgr2;
   TGraph *hgr3;

   pd2[0]->cd();
   pd2[0]->SetLogx();
   pd2[0]->SetLogy();
   pd2[0]->SetGridy();
   
   hhf3 = new TH2F("hhf3","Performance with 5 GeV #pi^{-}", 1,0.7,40.,1,0.5,50.);
   hgr3 = new TGraphErrors(nb,pbin,gf_total_mean,epbin,gf_total_rms);
   hgr2 = new TGraphErrors(1,pbin1,gf_serial_mean,epbin1,gf_serial_rms);

   hhf3->GetYaxis()->SetTitleSize(0.05);
   hhf3->GetYaxis()->SetTitleOffset(1.5);
   hhf3->GetYaxis()->SetTitleColor(4);
   hhf3->GetYaxis()->SetNdivisions(5);
   hhf3->GetXaxis()->SetTitleSize(0.05);
   hhf3->GetXaxis()->SetTitleOffset(1.2);
   hhf3->GetXaxis()->SetTitleColor(4);
   hhf3->SetXTitle("N Core");
   hhf3->SetYTitle("Speedup (MT/Sequential)");
   hhf3->Draw();
   
   hgr3->SetMarkerColor(kBlue);
   hgr3->SetMarkerStyle(20);
   hgr3->SetMarkerSize(1.2);
   hgr3->SetLineColor(kBlue);
   hgr3->Draw("LPsame");

   hgr2->SetMarkerColor(kRed);
   hgr2->SetMarkerStyle(20);
   hgr2->SetMarkerSize(1.2);
   hgr2->SetLineColor(kRed);
   hgr2->Draw("LPsame");
  
   llow = new TLine(1.0, 1.0, 32, 32);
   llow->SetLineColor(2);
   llow->SetLineStyle(2);
   llow->Draw();

   //   hlow = new TLine(1.0, 0.731736, 32, 0.731736*32);
   //   hlow->SetLineColor(4);
   //   hlow->SetLineStyle(2);
   //   hlow->Draw();
 
   TLegend *lg1 = new TLegend(0.18,0.74,0.68,0.86);
   lg1->AddEntry(hgr3,"cmsExpMT + Geant4 10-00-beta","PL");
   lg1->AddEntry(hgr2,"cmsExp + Geant4 10-00-beta","PL");
   lg1->SetTextSize(0.03);
   lg1->Draw();

   char pngtitle[256];   
   sprintf(pngtitle,"speedup_cmsExpMT_pi_E5.%s","png");

   c2->Update(); 
   c2->Print(pngtitle);   
   ps2->Close();

}
