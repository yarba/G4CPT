#include <iostream>
#include <iomanip>

int cpu_time_ratio()
{
   gROOT->Reset();

   // read performance data

   const int ns = 48;
//   const int ns = 52; // 48 + added gamma 250MeV & 1GeV with Auger ON/OFF

/*
   const int nb = 20;

   char *release[nb] = {"10.2.p03",
                        "10.3.p03",
			"10.4.p02rrr",
			"10.4.p03",
			"10.5rerun",
			"10.5.p01",
			"10.5.r01rr",
			"10.5.r02",
			"10.5.r02rerun",
			"10.5.r03",
			"10.5.r02static",
			"10.5.r03rr",
			"10.5.r04",
			"10.5.r04rr",
			"10.5.r05",
			"10.5.r05fix1",
			"10.5.r06c00",
			"10.6.b01",
			"10.5.r04rrr",
			"10.5.r06"
   };

   char *version[nb] = {"10.2.p03",
                        "10.3.p03",
			"10.4.p02",
			"10.4.p03",
			"10.5",
			"10.5.p01",
			"10.5.r01",
			"10.5.r02",
			"10.5.r02rerun",
			"10.5.r03",
			"10.5.r02static",
			"10.5.r03static",
			"10.5.r04",
			"10.5.r04rr",
			"10.5.r05",
			"10.5.r05+f1e50db",
			"10.6.b00",
			"10.6.b01",
			"10.6.beta"
   };
*/

   const int nb = 19;

   char *release[nb] = {"10.2.p03",
                        "10.3.p03",
			//			"10.4.p02rrr",
			"10.4.p03",
			"10.5rerun",
			"10.5.p01",
			"10.5.r01rr",
//			"10.5.r02",
			"10.5.r02rerun",
//			"10.5.r03",
			"10.5.r02static",
			"10.5.r03rr",
//			"10.5.r04",
//			"10.5.r04rr",
			"10.5.r04rrr",
			"10.5.r05",
//			"10.5.r05fix1",
//			"10.5.r06c00",
//			"10.6.b01",
//			"10.5.r06",
			"10.5.r06rr",
			"10.5.r07rr",
			"10.5.r08rr",
			"10.5.r09",
			"10.5.r09rr",
			"10.5.r10",
			"10.5.r10c",
			"10.6.c00"
   }; // internal name used for profiling jobs

   char *version[nb] = {"10.2.p03",
                        "10.3.p03",
			//			"10.4.p02",
			"10.4.p03", 
			"10.5",
			"10.5.p01",
			"10.5.r01",
			"10.5.r02",
			//			"10.5.r02rerun",
//			"10.5.r03",
			"10.5.r02static",
			"10.5.r03static",
//			"10.5.r04",
//			"10.5.r04rr",
			"10.5.r04", // --> rrr",
			"10.5.r05",
//			"10.5.r05+f1e50db",
//			"10.6.b00",
//			"10.6.b01",
//			"10.6.beta",
			"10.5.r06", // --> rr",
			"10.5.r07",
			"10.5.r08",
			"10.5.r09",
			"10.5.r09rr",
			"10.5.r10",
			"10.5.r10c",
			"10.6.c00"
   }; // legend for plots


//   const int iref = 2; //reference 10.4.p03
    const int iref = 3; //reference 10.5(rr)

   char cfilename[256];
   FILE *cfile[nb];    

   for(int i = 0 ; i < nb ; i++) {
// -->      sprintf(cfilename,"/g4/g4p/work/root/sprof/cpu_summary_%s_SimplifiedCalo.data",release[i]);  
     sprintf(cfilename,"/lfstev/g4p/g4p/work/root/sprof/cpu_summary_%s_SimplifiedCalo.data",release[i]);  
     cfile[i] = fopen(cfilename,"r");
   }

   double amd_cputime[ns][nb];
   double amd_error[ns][nb];

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

       if(i==iref) { 
	 sample_id[j] = sample;
         hmax[j] = mcputime*1.2;
         hmin[j] = mcputime*0.8;
       }
     }
     fclose(cfile[i]);
   }

   //ratio
   double r_amd_cputime[ns][nb];
   double r_amd_error[ns][nb];
   for(int i = 0 ; i < nb ; i++) {
     for(int j = 0 ; j < ns ; j++) {
       r_amd_cputime[j][i] = amd_cputime[j][i]/amd_cputime[j][iref];
       double a0 = amd_error[j][iref]/amd_cputime[j][iref];  
       double a1 = amd_error[j][i]/amd_cputime[j][i];  
       r_amd_error[j][i] = r_amd_cputime[j][i]*sqrt(a0*a0+a1*a1);
       //       printf("r_amd_error[%d][%d] = %f\n",j,i,r_amd_error[j][i]);
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
     sprintf(cvtitle,"CPU Time Ratio for SimplifiedCalo: %s",(sample_id[i]).c_str());

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
   TLegend *lg1[ns];
   TGraph *hgr1[ns]; 

   TLine *llow[ns]; 
   TLine *lhigh[ns]; 

   for(int i = 0 ; i < ns ; i++) {

     cv[i]->cd();

     pd[i]->cd();
     pd[i]->SetGridy();

     sprintf(hname,"hhf%d",i);
     sprintf(htitle,"Ratio - SimplifiedCalo %s",(sample_id[i]).c_str());

     // TMP measure as CPU w/Shielding has been largely jumping between through 10.4.ref-s 
     if ( sample_id[i].find("Shielding") != string::npos  )
     {
        if ( sample_id[i].find("e-") != string::npos ) then
	{
	   hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.4,6.);
	}
	else if ( sample_id[i].find("proton") != string::npos  )
	{
	    hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.8,1.5);
	}
     }
     else
     {
        if(i==2) {
        hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.4,1.2);
        }
        else if(i>34 && i < 43) {
        hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.4,1.8);
        }
        else {
        hhf[i] = new TH2F(hname,htitle, nb,0,nb,1,0.8,1.2);
        }
     }

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
     hhf[i]->SetYTitle("CPU Time Ratio <10.X.X/10.5>");
     hhf[i]->SetXTitle("Geant4 Version");
     
     hhf[i]->Draw("text");
     
     hgr1[i] = new TGraphErrors(nb,pbin,r_amd_cputime[i],epbin,r_amd_error[i]);
     hgr1[i]->SetMarkerColor(kRed);
     hgr1[i]->SetMarkerStyle(20);
     hgr1[i]->SetMarkerSize(1.0);
     hgr1[i]->Draw("P");
     
     lg1[i] = new TLegend(0.18,0.78,0.72,0.88);
     lg1[i]->AddEntry(hgr1[i],"AMD Opteron 6128 HE @2.00 GHz","PL");
     lg1[i]->Draw();

     llow[i] = new TLine(0.0, 0.95, nb, 0.95);
     llow[i]->SetLineColor(2);
     llow[i]->SetLineStyle(2);
     llow[i]->Draw();

     lhigh[i] = new TLine(0.0, 1.05, nb, 1.05);
     lhigh[i]->SetLineColor(2);
     lhigh[i]->SetLineStyle(2);
     lhigh[i]->Draw();

     sprintf(pstitle,"/home/g4p/webpages/g4p/summary/sprof/cpu_ratio_%s.png",(sample_id[i]).c_str());
     cv[i]->Update(); 
     cv[i]->Print(pstitle); 
   }
}
