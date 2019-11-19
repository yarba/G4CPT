#!/usr/bin/env ruby
$doc = <<ENDDOC
unpack_trial_tarballs - unpack the trials for a given experiment

SYNOPSIS
unpack_trial_tarballs [options] experiment-id

DESCRIPTION

unpack the trials (in tarball form) for the experiment with the given
ID.

OPTIONS

-h, --help
Print this help and exit.

-v, --verbose
Print progress information.

Use the environment variable RAILS_ENV to control which Rails
environment is used; if RAILS_ENV is not defined, the Rails-standard
default of 'development' is used.

ENDDOC

require 'erb'
require 'fileutils'
require 'getoptlong'
require 'yaml'
require File.dirname(__FILE__) + '/../cfg/environment'
require File.dirname(__FILE__) + '/../lib/tarball_unpacker'

def usage
  puts $doc
end

class UnpackScriptError < Exception; end


class UnpackScript
  attr_accessor :experiment_id, :environment, :verbose

  def run_single(tar_name)
    begin
      announce "Running in verbose mode"
      scriptdir = Dir.pwd
      workdir = tarball_dir + "/exp_#{experiment_id}"
      tempdir = workdir + '/temp'
      Dir.chdir(workdir)
      announce "Working directory is: #{workdir}"
      puts "Processing #{tar_name}"
    rescue SystemCallError
      raise
    end
    begin
      Dir.mkdir(tempdir)
      Dir.chdir(tempdir)
      puts "Now in directory: #{Dir.getwd}"
      output = `tar zxf ../#{tar_name}`
      status = $?
      unless status.exitstatus == 0
        puts "Output is:"
        puts output
        raise UnpackScriptError.new("Failure while untarring #{tar_name}")
      end

      # Do the uploading work
      Trial.transaction do
        uploader = TarballUnpacker.new(tar_name, experiment_id, environment, verbose, Dir.pwd)
        uploader.run
      end
      # If we get here, we have succeeded.
      # Rename the tarball, so we don't try to process it again.

      File.rename("../#{tar_name}", "../#{tar_name}-done")
    rescue TarballUnpackerError, UnpackScriptError, Errno::ENOENT => x
      File.rename("../#{tar_name}", "../#{tar_name}-failed")
      puts x
      raise
    ensure
      Dir.chdir(workdir)
      FileUtils.remove_entry_secure(tempdir)
      Dir.chdir(scriptdir)
    end #end begin
  end #end function



  def run
    announce "Running in verbose mode"
    workdir = tarball_dir + "/exp_#{experiment_id}"
    tempdir = workdir + '/temp'
    Dir.chdir(workdir)
    announce "Working directory is: #{workdir}"
    Dir.glob('*.tgz').each do |tarballname|      
      puts "Processing #{tarballname}"
      begin
        Dir.mkdir(tempdir)
        Dir.chdir(tempdir)
        puts "Now in directory: #{Dir.getwd}"
        output = `tar zxf ../#{tarballname}`
        status = $?
        unless status.exitstatus == 0
          puts "Output is:"
          puts output
          raise UnpackScriptError.new("Failure while untarring #{tarballname}")
        end
        # Do the uploading work
        Trial.transaction do
          uploader = TarballUnpacker.new(tarballname, experiment_id, environment, verbose, Dir.pwd)
          uploader.run
        end
        # If we get here, we have succeeded.
        # Rename the tarball, so we don't try to process it again.
        File.rename("../#{tarballname}", "../#{tarballname}-done")
      rescue TarballUnpackerError, UnpackScriptError, Errno::ENOENT => x
        File.rename("../#{tarballname}", "../#{tarballname}-failed")
        puts x
        puts "Continuing with next tarball."
        raise
      ensure
        Dir.chdir(workdir)
        FileUtils.remove_entry_secure(tempdir)
      end
    end
  end

  # Read the deployment YAML file, run it through ERB, and return the
  # resulting hash.
  def self.initialize_deployment_params
    template = ERB.new((File.read(File.dirname(__FILE__) + '/../cfg/deploy.yml')))
    YAML.load(template.result(binding))
  end

  def self.deployment_params
    @@deployment_params ||= UnpackScript.initialize_deployment_params
  end

  private  
  def tarball_dir
    "#{UnpackScript.deployment_params['tarball_base']}/#{environment}"
  end

  def handle_program_options(opts)
    opts.each do | opt, arg |
      case opt
      when '-h', '--help'
        usage
        exit
      when '-v', '--verbose'
        self.verbose = true
      end
    end
  end

  def establish_defaults
    # We do not want to take a default value.
    if ENV["RAILS_ENV"].nil?
      puts "RAILS_ENV is not set"
      usage
      exit
    end
    self.environment = ENV["RAILS_ENV"]
    self.verbose = false
  end

  def handle_program_arguments(expid)
    self.experiment_id = expid 
  end    

  def initialize(expid, verbose)
    establish_defaults
    self.verbose = verbose

    handle_program_arguments(expid)
  end

  def announce(msg)
    puts msg if verbose
  end
end

def getverbose
  opts = GetoptLong.new([ '--help',   '-h', GetoptLong::NO_ARGUMENT ],
                        [ '--verbose','-v', GetoptLong::NO_ARGUMENT ])

  opts.quiet = true

  verbose = false

  opts.each do | opt, arg |
    case opt
    when '-h', '--help'
      usage
      exit
    when '-v', '--verbose'
      verbose = true
    end
  end
  verbose
end

def getarg
  if ARGV.length != 1
    puts "Incorrect number of arguments\n\n"
    usage
    exit 1
  end 
  ARGV[0]
end


if __FILE__ == $0

  verbose = getverbose
  expid = getarg

  begin
    script = UnpackScript.new(expid, verbose)
    script.run 
  rescue Exception => x
    puts 'unpack_trial_tarballs error: ' + x
    raise
    exit 1
  end
end
