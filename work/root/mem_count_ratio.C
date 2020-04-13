#include <iostream>
#include <iomanip>

int mem_count_ratio()
{
   gROOT->Reset();

   // read performance data

//   const int ns = 48;
   const int ns = 52; // 48 "original" 
                      // + added gamma 250MeV & 1GeV with Auger ON/OFF
		      // NOT YET: + higgs+0-field

/*
   const int nb = 16;

   char *release[nb] = {"10.2.p03",
                        "10.3.p03",
			"10.4.p03",
			"10.5.p01static",
			"10.5.r02static",
			"10.5.r03",
			"10.5.r04",
			"10.5.r05",
			"10.5.r06",
			"10.5.r07",
			"10.5.r08",
			"10.5.r09",
			"10.5.r10",
//			"10.5.r10c",
			"10.6.c00",
			"10.6.c01",
			"10.6"
   };

   char *version[nb] = {"10.2.p03",
                        "10.3.p03",
			"10.4.p03",
			"10.5.p01", // static",
			"10.5.r02", // static",
			"10.5.r03",
			"10.5.r04",
			"10.5.r05",
			"10.5.r06", // --> 6.beta",
			"10.5.r07",
			"10.5.r08",
			"10.5.r09",
			"10.5.r10",
//			"10.5.r10c",
			"10.6.c00",
			"10.6.c01",
			"10.6"
   };


//   const int iref = 2; //reference 10.4.p03
   const int iref = 3; //reference 10.5
*/

   const int nb = 9;

   char *release[nb] = {"10.2.p03static",
                        "10.3.p03static",
			"10.4.p03static",
			"10.5.p01static",
			"10.6",
			"10.6.p01",
			"10.6.r01",
			"10.6.r02",
			"10.6.r03"
   }; // internal name used for profiling jobs

   char *version[nb] = {"10.2.p03",
                        "10.3.p03",
			"10.4.p03", 
			"10.5.p01", 
			"10.6",
			"10.6.p01",
			"10.6.r01",
			"10.6.r02",
			"10.6.r03"
   }; // legend for plots

   const int iref = 4; //reference 10.6


   char cfilename[256];
   FILE *cfile[nb];    
   char dfilename[256];
   FILE *dfile[nb];    

   for(int i = 0 ; i < nb ; i++) {
// --> migrate     sprintf(cfilename,"/g4/g4p/work/root/igprof/mem_summary_%s_SimplifiedCalo.oss.1",release[i]);  
     sprintf(cfilename,"/lfstev/g4p/g4p/work/root/igprof/mem_summary_%s_SimplifiedCalo.oss.1",release[i]);  
     cfile[i] = fopen(cfilename,"r");
// -->     sprintf(dfilename,"/g4/g4p/work/root/igprof/mem_summary_%s_SimplifiedCalo.oss.END",release[i]);  
     sprintf(dfilename,"/lfstev/g4p/g4p/work/root/igprof/mem_summary_%s_SimplifiedCalo.oss.END",release[i]);  
     dfile[i] = fopen(dfilename,"r");
   }

   double total_at_1[ns][nb];
   double total_at_e[ns][nb];
   double dummy_error[ns][nb];

   string sample_id[ns];

   Float_t totalmem;
   char sample[256];
   char processor[256];
   char atevent[256];

   double hmin[ns];
   double hmax[ns];

   for(int i = 0 ; i < nb ; i++) {
     for(int j = 0 ; j < ns ; j++) {
       fscanf(cfile[i],"%f %s %s %s", &totalmem, sample, processor, atevent);
       total_at_1[j][i] = totalmem;
       dummy_error[j][i] = 0.0;
     }

     for(int j = 0 ; j < ns ; j++) {
       fscanf(dfile[i],"%f %s %s %s", &totalmem, sample, processor, atevent);
       total_at_e[j][i] = totalmem;
       if(i==iref) { //reference 10.0
	 sample_id[j] = sample;
         hmax[j] = totalmem*2.0;
         hmin[j] = totalmem*0.0;
       }
     }
     fclose(cfile[i]);
     fclose(dfile[i]);
   }

   //ratio

   double r_total_at_1[ns][nb];
   double r_total_at_e[ns][nb];
   for(int i = 0 ; i < nb ; i++) {
     for(int j = 0 ; j < ns ; j++) {
       r_total_at_1[j][i] = total_at_1[j][i]/total_at_1[j][iref];
       r_total_at_e[j][i] = total_at_e[j][i]/total_at_e[j][iref];
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
     sprintf(cvtitle,"TOTAL MEM Ratio for SimplifiedCalo: %s",(sample_id[i]).c_str());

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

   //histogram

   char hname[256];
   char htitle[256];

   TH2F   *hhf[ns];
   TGraph *hgr[ns];

   TLegend *lg1[ns];
   TGraph *hgr1[ns]; 
   TGraph *hgr2[ns]; 

   TLine *llow[ns]; 
   TLine *lhigh[ns]; 

   for(int i = 0 ; i < ns ; i++) {
     cv[i]->cd();

     pd[i]->cd();
     pd[i]->SetGridy();

     sprintf(hname,"hhf%d",i);
     sprintf(htitle,"Ratio - SimplifiedCalo %s",(sample_id[i]).c_str());

     if(i==0) hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.0,2.);
     else hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.0,2.);

     hhf[i]->SetBit(TH1::kCanRebin);   
     
     for(int j = 1 ; j <= nb ; j++) {
       //       hhf[i]->GetXaxis()->SetBinLabel(j,release[j-1]);
       hhf[i]->GetXaxis()->SetBinLabel(j,version[j-1]);
     }
     
     hhf[i]->GetYaxis()->SetTitleSize(0.05);
     hhf[i]->GetYaxis()->SetTitleOffset(1.5);
     hhf[i]->GetYaxis()->SetTitleColor(4);
     hhf[i]->GetYaxis()->SetNdivisions(5);
     hhf[i]->GetXaxis()->SetTitleSize(0.05);
     hhf[i]->GetXaxis()->SetTitleOffset(1.2);
     hhf[i]->GetXaxis()->SetTitleColor(4);
     std::string ytitle = "Total Memory Ratio <10.X.X/" + std::string(version[iref]) + ">";
     hhf[i]->SetYTitle(ytitle.c_str());
     // hhf[i]->SetYTitle("Total Memory Ratio <10.X.X/10.5>");
     hhf[i]->SetXTitle("Geant4 Version");
     
     hhf[i]->Draw("text");
     
     hgr1[i] = new TGraphErrors(nb,pbin,r_total_at_1[i],epbin,dummy_error[i]);
     hgr1[i]->SetMarkerColor(kBlue);
     hgr1[i]->SetMarkerStyle(20);
     hgr1[i]->SetMarkerSize(1.0);
     hgr1[i]->Draw("P");
     
     hgr2[i] = new TGraphErrors(nb,pbin,r_total_at_e[i],epbin,dummy_error[i]);
     hgr2[i]->SetMarkerColor(kRed);
     hgr2[i]->SetMarkerStyle(20);
     hgr2[i]->SetMarkerSize(1.0);
     hgr2[i]->Draw("P");
    
     lg1[i] = new TLegend(0.18,0.70,0.65,0.88);
     lg1[i]->AddEntry(hgr1[i],"After First Event","PL");
     lg1[i]->AddEntry(hgr2[i],"After Last of Event","PL");
     lg1[i]->Draw();
     
     llow[i] = new TLine(0.0, 0.95, nb, 0.95);
     llow[i]->SetLineColor(2);
     llow[i]->SetLineStyle(2);
     llow[i]->Draw();

     lhigh[i] = new TLine(0.0, 1.05, nb, 1.05);
     lhigh[i]->SetLineColor(2);
     lhigh[i]->SetLineStyle(2);
     lhigh[i]->Draw();

     sprintf(pstitle,"/home/g4p/webpages/g4p/summary/igprof/mem_ratio_%s.png",(sample_id[i]).c_str());
     cv[i]->Update(); 
     cv[i]->Print(pstitle); 
   }
}

