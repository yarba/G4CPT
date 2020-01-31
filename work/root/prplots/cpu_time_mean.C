#include <iostream>
#include <iomanip>

int cpu_time_mean()
{

   gROOT->Reset();

   // read performance data

   const int ns = 9;

   const int nb = 6;

   char *release[nb] = {
                        "10.1.p03static",
			"10.2.p03static",
                        "10.3.p03static",
			"10.4.p03static",
			"10.5.p01static",
			"10.6"
   };

   char *version[nb] = {
                        "10.1.p03",
			"10.2.p03",
			"10.3.p03",
			"10.4.p03",
			"10.5.p01",
			"10.6"
   };

   const int iref = 4; //reference 10.5.p01

   char cfilename[256];
   FILE *cfile[nb];    

   char cfilename_s[256];
   FILE *cfile_s[nb];    

   for(int i = 0 ; i < nb ; i++) {
     sprintf(cfilename,"/lfstev/g4p/g4p/work/root/prplots/cpu_summary_%s_cmsExp.data",release[i]);  
     cfile[i] = fopen(cfilename,"r");

     sprintf(cfilename_s,"/lfstev/g4p/g4p/work/root/prplots/cpu_summary_%s_SimplifiedCalo.data",release[i]);  
     cfile_s[i] = fopen(cfilename_s,"r");
   }

   double amd_cputime[ns][nb];
   double amd_error[ns][nb];

   double amd_cputime_s[ns][nb];
   double amd_error_s[ns][nb];

   string sample_id[ns];

   Float_t mcputime;
   Float_t ecputime;
   char sample[256];
   char processor[256];

   double hmin[ns];
   double hmax[ns];

   for(int i = 0 ; i < nb ; i++) {
     for(int j = 0 ; j < ns ; j++) {
       fscanf(cfile[i],"%f %f %s %s", &mcputime, &ecputime, sample, processor);
       amd_cputime[j][i] = mcputime;
       amd_error[j][i] = ecputime;

       if(i==iref) { //10.0 (reference)
	 sample_id[j] = sample;
         hmax[j] = mcputime*1.4;
         hmin[j] = mcputime*0.6;
       }
     }
     fclose(cfile[i]);
   }

   for(int i = 0 ; i < nb ; i++) {
     for(int j = 0 ; j < ns ; j++) {
       fscanf(cfile_s[i],"%f %f %s %s", &mcputime, &ecputime, sample, processor);
       amd_cputime_s[j][i] = mcputime;
       amd_error_s[j][i] = ecputime;

     }
     fclose(cfile_s[i]);
   }

   //ratio

   double r_amd_cputime[ns][nb];
   double r_amd_error[ns][nb];
   for(int i = 0 ; i < nb ; i++) {
     for(int j = 0 ; j < ns ; j++) {
       r_amd_cputime[j][i] = amd_cputime[j][i]/amd_cputime[j][iref];
       double a0 = amd_error[j][2]/amd_cputime[j][iref];  
       double a1 =  amd_error[j][i]/amd_cputime[j][i];  
       r_amd_error[j][i] = r_amd_cputime[j][i]*(a0*a0+a1*a1);
     }
   }

   // canvas and pad

   TCanvas* cv[ns];
   TPad* pd[ns];

   char cvname[256];
   char cvtitle[256];
   char pdname[256];
   char pdtitle[256];
   char pstitle[256];

   for (int i = 0; i < ns ; i++) {
     sprintf(cvname,"cv%d",i);
     sprintf(cvtitle,"Mean CPU Time for cmsExp: %s",(sample_id[i]).c_str());

     cv[i]= new TCanvas(cvname,cvtitle,0,0,800,500);
     cv[i]->cd();

     sprintf(pdname,"pd%d",i);
     sprintf(pdtitle,"pad%d",i);

     pd[i] = new TPad(pdname,pdtitle,0.005,0.005,0.995,0.995);
     pd[i]->Draw();
     pd[i]->SetLeftMargin(0.15);
     pd[i]->SetRightMargin(0.15);
     pd[i]->SetBottomMargin(0.12);
   }

   double pbin[nb], epbin[nb];

   for(int i = 0 ; i < nb ; i++) {
     pbin[i] = 0.5+1.0*i;
     epbin[i] = 0.0;
   }

   //styple

   gStyle->SetOptStat(0);
   gStyle->SetOptFit(0);
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

   gStyle->SetTitleXOffset(1.25);

   gStyle->SetLegendBorderSize(0);
   gStyle->SetLegendFillColor(0);

   //histograms

   char hname[256];
   char htitle[256];

   TH2F   *hhf[ns];
   TGraph *hgr1[ns]; 
   TGraph *hgr2[ns]; 

   TLegend *lg1[ns];

   char* ggtitle[ns] = {"H #rightarrow ZZ @ #sqrt{s}=14TeV",
			"1 GeV e^{-} ",
			"50 GeV e^{-} ",
                        "1 GeV #pi^{-}",
                        "50 GeV #pi^{-}",
                        "1 GeV anti-proton",
                        "50 GeV anti-proton",
                        "1 GeV proton",
                        "50 GeV proton" };

   Float_t gpos[ns];
   gpos[0] = 610;
   for(int i = 1; i < ns ; ++i) gpos[i] = 5.2; 

   Float_t ipos[ns];
   ipos[0] = 555;
   for(int i = 1; i < ns ; ++i) ipos[i] = 4.55; 

   Float_t jpos[ns];
   jpos[0] = 510;
   for(int i = 1; i < ns ; ++i) jpos[i] = 4.1; 

   for(int i = 0 ; i < ns ; i++) {

     cv[i]->cd();

     pd[i]->cd();
     pd[i]->SetGridy();

     //1GeV
     if( i==1 || i==3 || i==5 || i==7 )  {
       gpos[i] = 1.12; 
       ipos[i] = 0.6;
       jpos[i] = 0.4; 
       pd[i]->SetLogy();
     }


     sprintf(hname,"hhf%d",i);
     sprintf(htitle,"",(sample_id[i]).c_str());
     //hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,hmin[i],hmax[i]);
//     if(i==0) hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,200,600); 
     if(i==0) hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,100,600); 
     else if(i==1)  hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.005,1.0); 
     else if(i==3) hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.005,1.0); 
     else if(i==5) hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.005,1.0); 
     else if(i==7) hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.005,1.0); 
//     else hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.,5.0); 
     else hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,-1.,5.0); // CPU can't be negative, of course;
                                                              // using -1 as ymin is simply to make room for the legend

     hhf[i]->SetBit(TH1::kCanRebin);   
     
     for(int j = 1 ; j <= nb ; j++) {
       hhf[i]->GetXaxis()->SetBinLabel(j,version[j-1]);
     }
     
     hhf[i]->GetYaxis()->SetTitleSize(0.055);
     hhf[i]->GetYaxis()->SetTitleOffset(1.3);
     hhf[i]->GetYaxis()->SetTitleColor(4);
     hhf[i]->GetYaxis()->SetNdivisions(5);
     hhf[i]->GetXaxis()->SetTitleSize(0.055);
     hhf[i]->GetXaxis()->SetTitleOffset(1.2);
     hhf[i]->GetXaxis()->SetTitleColor(4);
     hhf[i]->GetXaxis()->SetLabelSize(0.075);

     hhf[i]->SetYTitle("Mean CPU Time/Event [sec]");
     hhf[i]->SetXTitle("Geant4 Version");
     
     hhf[i]->Draw("text");
     
     hgr1[i] = new TGraphErrors(nb,pbin,amd_cputime[i],epbin,amd_error[i]);
     hgr1[i]->SetMarkerColor(kRed);
     hgr1[i]->SetMarkerStyle(20);
     hgr1[i]->SetMarkerSize(1.3);
     hgr1[i]->Draw("P");

     hgr2[i] = new TGraphErrors(nb,pbin,amd_cputime_s[i],epbin,amd_error_s[i]);
     hgr2[i]->SetMarkerColor(kBlue);
     hgr2[i]->SetMarkerStyle(25);
     hgr2[i]->SetMarkerSize(1.3);
     hgr2[i]->Draw("sameP");
     
     lg1[i] = new TLegend(0.16,0.14,0.84,0.27);
     //     lg1[i]->AddEntry(hgr1[i],"AMD Opteron 6128 HE @2.00 GHz","PL");
     lg1[i]->AddEntry(hgr1[i],"CMS Geometry and Magnetic Field Map","PL");
     lg1[i]->AddEntry(hgr2[i],"Simple Calorimeter (Cu-Scintilator) and B=4T","PL");
     lg1[i]->Draw();

     TLatex *tnd2 = new TLatex();
     tnd2->SetTextFont(42);
     tnd2->SetTextSize(0.06);
     tnd2->SetTextColor(kBlack);

     sprintf(htitle,"%s",ggtitle[i]);
     tnd2->DrawLatex(0.2,gpos[i],htitle);
     
     TLatex *tnd0 = new TLatex();
     tnd0->SetTextFont(42);
     tnd0->SetTextSize(0.06);
     tnd0->SetTextColor(kBlack);
//     tnd0->DrawLatex(4.4,gpos[i],"FTFP_BERT");
     tnd0->DrawLatex(3.,gpos[i],"FTFP_BERT");

     TLatex *tnd1 = new TLatex();
     tnd1->SetTextFont(12);
     tnd1->SetTextSize(0.06);
     tnd1->SetTextColor(kBlack);
//     tnd1->DrawLatex(1.5,ipos[i],"AMD Opteron 6128 HE @2.00 GHz");
     tnd1->DrawLatex(1.,ipos[i],"AMD Opteron 6128 HE @2.00 GHz");

     TLatex *tnd11 = new TLatex();
     tnd11->SetTextFont(12);
     tnd11->SetTextSize(0.06);
     tnd11->SetTextColor(kBlack);
//     tnd11->DrawLatex(2.8,jpos[i],"GCC4.9.2/Linux x86_64");
     tnd11->DrawLatex(1.8,jpos[i],"GCC7.1.0/Linux x86_64");

     // check if proper directory exists
     string outdir = "/geant4-perf/g4p/prplots." + std::string(release[nb-1]);
     // string outdir = "/geant4-perf/g4p/test1";
     //
     // keep in mind that AccessPathName returns FALSE if directory EXISTS !
     //
     bool ok = gSystem->AccessPathName( outdir.c_str() );
     if (ok)
     {
        int iok = gSystem->MakeDirectory( outdir.c_str() );
     }
     
     //     sprintf(pstitle,"./cpu_time_cmsExp_%s.png",(sample_id[i]).c_str());
     // sprintf(pstitle,"/geant4-perf/g4p/prplots.10.5/geant4_cpu_performance_mean_%s.png",(sample_id[i]).c_str());
     
     string outfile = outdir + "/geant4_cpu_performance_mean_" + sample_id[i] + ".png";

     cv[i]->Update(); 
     // cv[i]->Print(pstitle); 
     cv[i]->Print( outfile.c_str() );
   }
}

