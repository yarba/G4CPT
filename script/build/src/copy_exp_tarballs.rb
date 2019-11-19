#!/usr/bin/env ruby

# svn keywords:
# $Rev: 604 $: Revision of last commit
# $Author: paterno $: Author of last commit
# $Date: 2010-04-11 15:20:47 -0500 (Sun, 11 Apr 2010) $: Date of last commit

# TODO: Move this to g4profiling specific directory, preparing for move out of perfdb.

$doc = <<ENDDOC
 - copy resulting experimental run tarballs to the analysis area

SYNOPSIS
  ruby script/copy_exp_tarballs Experiment-number GEANT4-release [Application]

  Experiment-number should be in a form like 47
  GEANT4-release    should be in a form like 9.4.p01
  Application       should be in a form like SimplifiedCalo or cmssw426    

ENDDOC

require 'rubygems'
require 'getoptlong'
require 'fileutils'

def usage
  puts $doc
end

class MainScript
  attr_accessor :local_dir_base, :local_dir, :geant_release, :experiment_number, :remote_host, :application, 
  :remote_dir_base, :remote_dir
  
  def initialize
    opts = 
      GetoptLong.new( [ "--help", "-h", GetoptLong::NO_ARGUMENT ] )
    opts.quiet = true
    opts.each do |opt, arg|
      case opt
      when "-h", "--help"
	usage
	exit	
      end
    end

    case ARGV.length
    when 0..2
      puts "Too few arguments"
      usage
      exit 1
    else
      self.experiment_number = ARGV[0]
      self.geant_release     = ARGV[1]
      self.application       = ARGV[2]
      self.local_dir_base    = ARGV[3] || '/uscms_data/d2/genser/geant_output'
      self.remote_host       = 'perfanalysis@oink.fnal.gov'
      self.remote_dir_base   = ARGV[4] || '~/g4profiling'
    end  
  end

  def run
    self.local_dir  = "#{local_dir_base}/exp_#{experiment_number}"
    self.remote_dir = "#{remote_dir_base}/g4.#{geant_release}_#{application}_#{experiment_number}/exp_#{experiment_number}"
    check_directories
    create_remote_directory
    copy_tarballs(local_dir)
  end

  private
  def check_directories
    puts "Checking if #{local_dir} exists"
    unless File.directory?(local_dir)
      puts "Source directory '#{local_dir}' does not exist"
      exit 1
    end
    fork do
      puts "Process #{Process.pid} will check if #{remote_dir} already exists on #{remote_host}"
      result = `ssh #{remote_host} "if [ -d #{remote_dir} ]; then echo \"Directory already exists Will not overwrite it\" ;exit 1; fi"`
      status = $?.exitstatus
      if status != 0
        puts "Process #{Process.pid} failed"
        puts result
        exit 1
      end
#      if result.include?("does exists")
#        puts result
#        puts "will not overwrite it; exiting"
#        exit 1
#      end
      puts result
    end
    children = Process.waitall
    children.each do |pid, status|
      if status.exitstatus == 0
        puts "Process #{pid} OK"
      else
        raise Exception.new("Process #{pid} FAILED")
      end
    end
  end

  def create_remote_directory
    fork do
      puts "Process #{Process.pid} will create #{remote_dir} on #{remote_host}"
      result = `ssh #{remote_host} "mkdir -p #{remote_dir}"`
      status = $?.exitstatus
      if status != 0
        puts "Process #{Process.pid} failed"
        puts result
        exit 1
      end
      puts result
    end
    children = Process.waitall
    children.each do |pid, status|
      if status.exitstatus == 0
        puts "Process #{pid} OK"
      else
        raise Exception.new("Process #{pid} FAILED")
      end
    end
  end

  def copy_tarballs(*dirs)
    dirs.each do |dir|
      fork do
        puts "is it simplified calo? " + application
        if application.index("SimplifiedCalo") 
          fileToCopy = "exercise.g4"
        elsif application.index("cmssw") 
          fileToCopy = "run_sim_g4" + geant_release.tr(".","") + "_" + application + "_cfg.py"
        else
          fileToCopy = "UnknownApplicationSpecified"
        end
        puts "Process #{Process.pid} will copy #{fileToCopy} from #{dir} to #{remote_host}:#{remote_dir}"
        result = `scp  #{dir}/#{fileToCopy} #{remote_host}:#{remote_dir}`
        status = $?.exitstatus
        if status != 0
          puts "Process #{Process.pid} failed"
          puts result
        end
      end
    end
    children = Process.waitall
    children.each do |pid, status|
      if status.exitstatus == 0
        puts "Process #{pid} OK"
      else
        raise Exception.new("Process #{pid} FAILED")
      end
    end
    dirs.each do |dir|
      fork do
        puts "Process #{Process.pid} will copy g4profiling_\*_\*.tgz from #{dir} to #{remote_host}:#{remote_dir}"
        result = `scp  #{dir}/g4profiling_\*_\*.tgz #{remote_host}:#{remote_dir}`
        status = $?.exitstatus
        if status != 0
          puts "Process #{Process.pid} failed"
          puts result
        end
      end
    end
    children = Process.waitall
    children.each do |pid, status|
      if status.exitstatus == 0
        puts "Process #{pid} OK"
      else
        raise Exception.new("Process #{pid} FAILED")
      end
    end
  end
end


#-----------------------------------------------------------------------
# Main program
#-----------------------------------------------------------------------

if __FILE__ == $0
  begin
    MainScript.new.run
    puts "#{$0} ended normally"
  rescue GetoptLong::Error => x
    puts "copy_exp_tarballs error: " + x
    exit 1
  end
end
