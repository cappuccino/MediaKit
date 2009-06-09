#!/usr/bin/env ruby

require 'rake'
require 'objective-j'
require 'objective-j/bundletask'


$BUILD_DIR = "."#ENV['CAPP_BUILD'] || ENV['STEAM_BUILD']
$CONFIGURATION = 'Release'
$BUILD_PATH = File.join($BUILD_DIR, $CONFIGURATION)

ObjectiveJ::BundleTask.new(:MediaKit) do |t|
    t.name          = 'MediaKit'
    t.identifier    = 'com.280n.MediaKit'
    t.version       = '0.1.0'
    t.author        = '280 North, Inc.'
    t.email         = 'feedback @nospam@ 280north.com'
    t.summary       = 'Media framework for Cappuccino'
    t.sources       = FileList['*.j']
    t.resources     = FileList['Resources/*']
    t.license       = ObjectiveJ::License::LGPL_v2_1
    t.build_path    = File.join($BUILD_PATH, 'MediaKit')
    t.flag          = '-DDEBUG -g' if $CONFIGURATION == 'Debug'
    t.flag          = '-O' if $CONFIGURATION == 'Release'
    t.type          = ObjectiveJ::Bundle::Type::Framework
end

task :default => [:MediaKit]
