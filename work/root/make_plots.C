
// --> int make_plots(char *filename)
int make_plots(std::string filename)
{
  char cmdline1[256];
  char cmdline2[256];

  // --> migrate --> char* filepath = "/g4/g4p/work/root";
  // --> migrate again --> char* filepath = "/lfstev/g4p/g4p/work/root";
  //
  // Jan.2021 migration to WC-IC
  //
  std::string filepath = "/work1/g4p/g4p/G4CPT/work/root";

  sprintf(cmdline1,".L %s/MyPad.C",filepath.c_str());
  sprintf(cmdline2,".x %s/%s.C",filepath.c_str(),filename.c_str());

  gROOT->ProcessLine(cmdline1);
  gROOT->ProcessLine("setTDRStyle()");
  gROOT->ProcessLine(cmdline2);
  gROOT->ProcessLine(".q");

  return 0;
  
}
