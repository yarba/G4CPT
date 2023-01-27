
int make_plots(char *filename)
{

  char cmdline1[256];
  char cmdline2[256];

  std::string filepath = "/work1/g4p/g4p/G4CPT/work/root/taskinganal/src/intel";
  sprintf(cmdline1,".L %s/MyPad.C",filepath.c_str());
  sprintf(cmdline2,".x %s/%s.C",filepath.c_str(),filename);

  gROOT->ProcessLine(cmdline1);
  gROOT->ProcessLine("setTDRStyle()");
  gROOT->ProcessLine(cmdline2);
  gROOT->ProcessLine(".q");

  return 0;

}
