#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'optparse'

# Contains classes and functions for generating Dockerfiles
module ImageBuilder
  def self.write_dockerfiles(image = nil, build_dir = nil) # rubocop:disable Metrics/AbcSize
    tags_paths = {}
    objects(image).each do |o|
      Dir.mkdir(build_dir) unless Dir.exist?(build_dir)
      os_dir = File.join(build_dir, o.os.to_s)
      Dir.mkdir(os_dir) unless Dir.exist?(os_dir)
      File.open(File.join(os_dir, 'Dockerfile'), 'w+') { |f| f.write(o.build) }
      tags_paths[o.tag] = os_dir
    end
    tags_paths
  end

  def self.objects(image)
    image.nil? ? create_objects(build_all_specs) : create_objects(build_spec(image))
  end

  def self.build_spec(spec_name)
    name = spec_name.delete_suffix('.yaml')
    { name.to_sym => YAML.safe_load(File.read("./build_specs/#{name}.yaml")) }
  end

  def self.build_all_specs
    specs = {}
    Dir['./build_specs/*.yaml'].each do |f|
      specs[File.basename(f, '.yaml').to_sym] = YAML.safe_load(File.read(f))
    end
    specs
  end

  def self.create_objects(build_specs)
    specs = []
    build_specs.each do |key, val|
      specs << Dockerfile.new(key, val)
    end
    specs
  end

  # Represents the Dockerfile
  class Dockerfile
    attr_reader :os

    TAG_PREFIX = 'hsnodgrass/cem_litmusimages'

    def initialize(os, build_spec)
      @os = os
      @build_spec = build_spec
      @from = build_spec['FROM']
      @entrypoint = build_spec['ENTRYPOINT']
      @package_install = build_spec.fetch('package_install')
      @service_enable = build_spec.fetch('service_enable')
      @indent_map = {}
    end

    def build
      image = ["FROM #{@from}"]
      image << parse_body
      image << "ENTRYPOINT #{@entrypoint}"
      image.join("\n")
    end

    def tag
      "#{TAG_PREFIX}:#{@os}"
    end

    private

    def parse_body
      body = []
      @build_spec['body'].each do |statement|
        next if statement.key?('taint')

        body << parse_package_install(statement['package_install']) if statement.key?('package_install')
        body << parse_service_enable(statement['service_enable']) if statement.key?('service_enable')
        body << parse_docker_native(statement) if docker_native?(statement)
      end
      body.join("\n")
    end

    def docker_native?(statement)
      return false if statement.keys.length > 1

      return true if statement.keys[0] == statement.keys[0].upcase

      false
    end

    def docker_statement(*statements)
      return "#{statements[0].keys[0]} #{statements[0].values[0]}" if statements[0].is_a?(Hash)

      "#{statements[0]} #{statements[1]}"
    end

    def parse_docker_native(statement)
      return parse_build_stage(statement.values[0]) if statement.keys[0] == 'FROM'
      return parse_run(statement.values[0]) if statement.keys[0] == 'RUN'

      docker_statement(statement)
    end

    def parse_run(commands)
      return docker_statement('RUN', commands) unless commands.is_a?(Array)
      return docker_statement('RUN', commands[0]) unless commands.length > 1

      formatted_commands = [commands[0]]
      commands[1..-1].each { |c| formatted_commands << "#{indent}#{c}" }
      docker_statement('RUN', formatted_commands.join(" && \\\n"))
    end

    def parse_build_stage(stage)
      "\nFROM #{stage}"
    end

    def parse_package_install(packages)
      prefix = "RUN #{@package_install['command']} "
      return "#{prefix}#{packages[0]}" unless packages.length > 1

      statement = ["#{prefix}#{packages[0]}"]
      packages[1..-1].each do |pkg|
        statement << "#{indent(prefix.length)}#{pkg}"
      end
      statement.join(" \\\n")
    end

    def parse_service_enable(services)
      prefix = "RUN echo \"#{@service_enable['command']} "
      suffix = "\" >> #{@service_enable['startup_script']} && chmod +x #{@service_enable['startup_script']}"
      return "#{prefix}#{services[0]}#{suffix}" unless services.length > 1

      statement = ["#{prefix}#{services[0]}"]
      services[1..-1].each { |s| statement << s }
      statement << suffix
      statement.join(' ')
    end

    def indent(length = 4)
      return @indent_map[length] if @indent_map.key?(length)

      idnt = []
      length.times { idnt << ' ' }
      @indent_map[length] = idnt.join
      @indent_map[length]
    end
  end
end

options = {}
OptionParser.new do |parser|
  parser.on('-i', '--image-os', 'The OS code for the image') do |v|
    options[:image] = v
  end
  parser.on('-b', '--build-images', 'Build images from Dockerfiles') do
    options[:build] = true
  end
  parser.on('-p', '--push-images', 'Push images to specified registry') do |v|
    options[:push] = v
  end
  parser.on('-D', '--build-directory', 'Base directory for Dockerfiles') do |v|
    options[:build_dir] = v
  end
  parser.on('-r', '--registry-url', 'The container registry URL for docker image push') do |v|
    options[:registry_url] = v
  end
  parser.on('-a', '--all', 'Run all commands. Registry URL is taken from envvar REGISTRY_URL. Build directory is default.') do
    options[:image] = all
    options[:write] = true
    options[:build] = true
    options[:push] = true
    options[:registry_url] = ENV['REGISTRY_URL']
    options[:build_dir] = File.join(__dir__, 'dockerfiles')
  end
end.parse!

image = options.fetch(:image, nil)
build_dir = options.fetch(:build_dir, File.join(__dir__, 'dockerfiles'))
build_images = options.fetch(:build, false)
push_images = options.fetch(:push, false)
registry_url = options.fetch(:registry_url, ENV['REGISTRY_URL'])
tags_paths = ImageBuilder.write_dockerfiles image, build_dir
if build_images
  tags_paths.each do |key, val|
    Open3.popen3(['docker', 'image', 'build', "--tag #{registry_url}/#{key}", val]) do |_, o, e, _|
      raise Error, e unless e.read.chomp.empty?

      puts o
    end
  end
end
if push_images
  raise Error, 'Must supply a container registry URL' if registry_url.nil? || registry_url.empty?

  tags_paths.each do |key, _|
    Open3.popen3(['docker', 'image', 'push', "#{registry_url}/#{key}"]) do |_, o, e, _|
      raise Error, e unless e.read.chomp.empty?

      puts o
    end
  end
end
