#!/usr/bin/env ruby

# svn keywords:
# $Rev: 604 $: Revision of last commit
# $Author: paterno $: Author of last commit
# $Date: 2010-04-11 15:20:47 -0500 (Sun, 11 Apr 2010) $: Date of last commit

# run me like this:
#    ruby script/do_scram_build.rb <work-dir <geant-release <cmssw-release>>>
#

# a script to check g4 env variables and do the scram build step

# basically this:

#cd /storage/local/data1/geant4work/g4.9.2.p01_cms_3_3_6/modified/CMSSW_3_3_6/src
#source /uscmst1/prod/sw/cms/bashrc prod
#scramv1 runtime -sh | grep G4NEUTRONHPDATA
#cmsenv
#env | grep G4NEUTRONHPDATA
# it needs to be in /storage/local/data1/geant4work/
#G4NEUTRONHPDATA=/storage/local/data1/geant4work/g4.9.2.p01_cms_3_3_6/modified/geant4.9.2.p01/data/G4NDL3.13
#time scramv1 --debug build --verbose -j 16 -k 2>&1 | tee scram_build.log_`date +%Y%m%d_%H%M%S`
#cd /storage/local/data1/geant4work/g4.9.2.p01_cms_3_3_6/unmodified/CMSSW_3_3_6/src
#time scramv1 --debug build --verbose -j 16 -k 2>&1 | tee scram_build.log_`date +%Y%m%d_%H%M%S`
#
#egrep "Error|error:" scram_build.log_20100106_165520 | more
#cd -
#egrep "Error|error:" scram_build.log_20100106_164835 | more

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.


class TheBuilder

  @@our_dir = ""
  @@our_rc  = 0

  attr_accessor :base_dir, :work_dir, :geant_release, :cmssw_release

  def initialize(base, geant, cmssw)
    self.work_dir = base + "/g4.#{geant}_cms_#{cmssw}/"
    self.geant_release = geant
    self.cmssw_release = cmssw
    self.base_dir = base
    @@our_dir = File.dirname(__FILE__)
    puts "initializing with #{work_dir}, #{geant_release}, #{cmssw_release}, #{@@our_dir}"
  end

  def do_build(places)
    places.each do |which|
      where = cmssw_src_dir(which)
      puts "which: #{which}"
      puts "where: #{where}"
      puts "pwd:   #{ENV['PWD']}"
      fork do
	result = `#{@@our_dir}/do_scram_build.sh #{where}`
        our_rc=$?.exitstatus
        puts "scram return code is #{our_rc}"
	puts "pid: #{Process.pid}"
	puts "#{result}"
        exit our_rc
      end
    end
    children = Process.waitall
    children.each do |pid, status|
      if status.exitstatus == 0
	puts "Process #{pid} OK"
      else
	puts "Process #{pid} FAILED, return code is " + status.exitstatus.to_s
        @@our_rc += status.exitstatus.to_i
#        puts @@our_rc.to_s
      end
    end
#    puts @@our_rc.to_s
  end

  def do_checks(places)
    # check if base is part of e.g. the G4NEUTRONHPDATA; i.e. if it is "our" geant4
    places.each do |which|
      where = cmssw_src_dir(which)
      puts "which: #{which}"
      puts "where: #{where}"
      puts "pwd:   #{ENV['PWD']}"
      fork do
        pattern = %r{#{base_dir}}m
#        pattern = %r{#{base_dir}not}m
        puts "checking for  #{base_dir} in: ..."
	result = `cd #{where}; source /uscmst1/prod/sw/cms/bashrc prod; scramv1 runtime -sh | grep G4NEUTRONHPDATA`
        our_rc=$?.exitstatus
	puts "#{result}"
        puts "grep sequence return code is #{our_rc}"
	puts "pid: #{Process.pid}"
#        if our_rc==0 && ( "#{result}" =~ /geant4work/m )
        if our_rc==0 && ( "#{result}".match(pattern) )
            exit our_rc
        else
          puts "we were looking for #{pattern} in:"
          puts "result: #{result}"
          puts "WRONG geant4 set up; was fix_tool_description run?"
          exit 1
        end
      end
    end
    children = Process.waitall
    children.each do |pid, status|
      if status.exitstatus == 0
	puts "Process #{pid} OK"
      else
	puts "Process #{pid} FAILED, return code is " + status.exitstatus.to_s
        @@our_rc += status.exitstatus.to_i
#        puts @@our_rc.to_s
      end
    end
#    puts @@our_rc.to_s
  end

  def get_rc
    @@our_rc
  end

 private

  def cmssw_base(which)
    work_dir + which + '/CMSSW_' + cmssw_release + '/'    
  end

  def cmssw_src_dir(which)
    work_dir + which + '/CMSSW_' + cmssw_release + '/src'
  end

  def geant_base(which)
    work_dir + which + '/geant4.' + geant_release
  end

end

base_dir      = ARGV[0] || '/storage/local/data1/geant4work'
geant_release = ARGV[1] || '9.2.p01'
cmssw_release = ARGV[2] || '3_3_6'

builder = TheBuilder.new(base_dir, geant_release, cmssw_release)

builder.do_checks(['unmodified', 'modified'])

if builder.get_rc == 0 
  builder.do_build(['unmodified', 'modified'])
end

exit builder.get_rc
