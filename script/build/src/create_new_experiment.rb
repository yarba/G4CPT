#!/usr/bin/env ruby

# svn keywords:
# $Rev: 717 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-03-24 16:12:58 -0500 (Thu, 24 Mar 2011) $: Date of last commit

# TODO: Move this to g4-specific directory, preparing for move out of perfdb.

require 'digest/sha1'

# and mainStatAccepTest name should be changed to simplifiedCalo (or so)

$doc = <<ENDDOC
create_new_experiment - write a Condor submission script to profile a g4 native application

SYNOPSIS
ruby create_new_experiment [options] program-to-run purpose-name geant-version build-type configfile numrepeats numqueueings

DESCRIPTION

Write a submission script (to be submitted with condor_sumbit) that
will run cmsRun using the configuration file named by configfile, and
create the output directories to which the jobs run by this submission
script will write. The script will submit an experiment that does
numqueueings queueing of the same script; each queueing will run a
shell script that runs cmsRun numrepeats times.
The script will also copy the configfile to the sandbox area

 * program-to-run e.g. Simplifiedcalo
 * purpose-name usually g4profiling
 * geant-version must be in a format like 9.2.p01
 * build-type must be 'modified' or 'unmodified'
 * config-file e.g. 'exercise.g4'
 * num-repeats withing one job/queuing e.g. 1
 * num-queueings e.g. 5

OPTIONS

  -h, --help
  Print this help and exit.

  -e, --experiment_id 
  The experiment number

  -n, --dry-run
  Print what would be done, but do not actually do it.

  -o, --output=DIR
  Create output directory DIR. If not specified, a default appropriate
  for the Fermilab BlueArc space is used.

  -r, --runbase=DIR
  The name of the directory from which we run the program. If not
  specified, a default appropriate for the Fermilab BlueArc space is 
  used.

  -v, --version
  Print the version number and exit.

ENDDOC

$vers = '2.0.0'
require 'erb'
require 'fileutils'
require 'getoptlong'
require 'rubygems'

def usage
  puts $doc
end

def version
  puts $vers
end


class ProfileScript
  attr_accessor :program_name, :purpose_name, :geant_version, :build_type, 
  :config_file, :num_repeats, :num_queueings,
  :email, 
  :output_base, :run_base,
  :dry_run, 
  :experiment_parameters, :build_features,
  :experiment_id, :exp_id,
  :target_config_file,
  :local_config_file_dump,
  :local_Config_File_SHA1
   
  # This is where output files go to
  # e.g. /uscms_data/d2/genser/geant_output/exp_ddd
  def output_dir
    if experiment_id.nil?
      raise Exception.new('output_dir is not yet definable')
    end
    File.join(self.output_base, "exp_#{self.experiment_id}")
  end

  #
  def run_dir
    run_base + "/g4.#{geant_version}/#{build_type}/work/#{program_name}"
  end

  def handle_program_options(opts)
    opts.each do | opt, arg |
      case opt
      when '-h', '--help'
	usage
	exit
      when '-v', '--version'
	version
	exit
      when '-e', '--experiment_id'
	self.exp_id = arg
      when '-o', '--output'
	self.output_base = arg
      when '-r', '--runbase'
	self.run_base = arg
      when '-n', '--dry-run'
	self.dry_run = true
	puts __FILE__ + ' Dry run: will not execute any actions'
      end
    end	  
  end

  def establish_defaults
    self.output_base = self.output_base || '/uscms_data/d2/genser/geant_output'
    self.run_base    = self.run_base    || '/uscms_data/d2/genser/geant4run'
    self.dry_run = false
  end

  def handle_program_arguments
    self.program_name  =    ARGV[0] || 'SimplifiedCalo'
    self.purpose_name  =    ARGV[1] || 'g4profiling'
    self.geant_version =    ARGV[2] || '9.4.p01'
    self.build_type =       ARGV[3] || 'unmodified'
    self.config_file =      ARGV[4] || 'exercise.g4'
    self.num_repeats =      ARGV[5].to_i || 1
    self.num_queueings =    ARGV[6].to_i || 10
  end    

  def initialize

    opts = 
      GetoptLong.new([ '--help',         '-h', GetoptLong::NO_ARGUMENT ],
                     [ '--version',      '-v', GetoptLong::NO_ARGUMENT ],
                     [ '--experiment_id','-e', GetoptLong::REQUIRED_ARGUMENT],
                     [ '--output',       '-o', GetoptLong::REQUIRED_ARGUMENT ],
                     [ '--runbase',      '-r', GetoptLong::REQUIRED_ARGUMENT ],
		     [ '--dry-run',      '-n', GetoptLong::NO_ARGUMENT])
    opts.quiet = true

    establish_defaults
    handle_program_options(opts)

    if ARGV.length != 7
      puts "Incorrect number of arguments\n\n"
      usage
      exit 1
    end

    handle_program_arguments

    max_num_queueings=200
    if num_queueings > max_num_queueings
      puts "num_queueings is to large #{num_queueings} must be <= #{max_num_queueings}"
      exit 1
    end

    self.email = (ENV['USER'] || 'genser') + '@fnal.gov'

  end

  def shell_script_name
    @shell_script_name ||= output_dir + '/run_me.sh'
  end

  def condor_script_name
    @condor_script_name ||= output_dir + '/submit_me'
  end

  def handle_config_file_path

    @@config_file_path = "#{self.run_dir}/#{self.config_file}"

    if !File.exist?(@@config_file_path)
      puts "Could not find #{self.config_file} in #{@@config_file_path}"
      exit 1
    end

  end

  # Return the location of the script templates.
  def template_dir
    File.dirname(__FILE__) + '/../cfg'
  end

  def prepare_for_output
    if File.exist?(output_dir)
      puts "\nDirectory '#{output_dir}' already exists."
      puts "There has been a failure in creating the new directory for the experiment id."
      puts "You have to debug this problem."
      exit 1
    end

    puts 'Making experiment output directory...' unless self.dry_run
    FileUtils.mkdir_p(output_dir) unless self.dry_run
    puts "Directory '#{output_dir}' created" unless self.dry_run
    puts "Email will be sent to: #{email}"
    puts "Output will appear in: #{output_dir}"

    handle_config_file_path

    self.target_config_file =  "#{output_dir}/#{self.config_file}"
    puts "Copying #{@@config_file_path} to #{self.target_config_file}" 
    FileUtils.cp(@@config_file_path,self.target_config_file) unless self.dry_run

  end

#   def write_buildenv_data
#     File.open(output_dir + '/build_env.txt', 'w') do |f|
#       f.write("geant4 version: #{geant4_version}\n")
#       f.write("compiler version: gcc #{compiler_version}\n")
#     end
#   end

  def run
    puts "num_queueings: #{num_queueings}"
    puts "-----------------------"
    require 'pp'
    pp self
    puts "-----------------------"
    puts "Run dir: #{run_dir}"

    assign_experiment_id
    prepare_for_output
    #write_buildenv_data
    write_condor_script unless self.dry_run
    write_shell_script  unless self.dry_run
  end

  def write_condor_script
    puts "Writing #{condor_script_name}"

    File.open(condor_script_name, 'w') do | output |
      template = ERB.new(File.read(File.join(template_dir, \
					     'profile.template')))
      output.write(template.result(binding()))
    end

  end

  def write_shell_script
    puts "Writing #{shell_script_name}"

    File.open(shell_script_name, 'w', 0774) do | output |
      template = ERB.new(File.read(File.join(template_dir, \
					     'profile_standard_shell.template')))
      output.write(template.result(binding())) 
    end
  end

  def assign_experiment_id
    if self.dry_run
      self.experiment_id = 99999
    else
      self.experiment_id = exp_id
    end
  end

end



if __FILE__ == $0
  begin
    script = ProfileScript.new
    script.run
  rescue GetoptLong::Error => x
    puts 'create_new_experiment error: ' + x.to_s
    exit 1
  end
end
