int make_plots(char *filename)
{
  char cmdline1[256];
  char cmdline2[256];

// --> migrate -->  char* filepath = "/g4/g4p/work/root/mtanal/src/intel";
  char* filepath = "/lfstev/g4p/g4p/work/root/mtanal/src/intel";

  sprintf(cmdline1,".L %s/MyPad_C.so",filepath);
  sprintf(cmdline2,".x %s/%s.C",filepath,filename);

  gROOT->ProcessLine(cmdline1);
  gROOT->ProcessLine("setTDRStyle()");
  gROOT->ProcessLine(cmdline2);
  gROOT->ProcessLine(".q");
}
