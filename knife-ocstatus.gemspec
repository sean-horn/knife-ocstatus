$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-ocstatus/version'

Gem::Specification.new do |s|
  s.name        = 'knife-ocstatus'
  s.version     = KnifeOCStatus::VERSION
  s.date        = '2013-04-11'
  s.summary     = 'Knife plugin for updating status via e-mail and twitter'
  s.description = s.summary
  s.authors     = ["Paul Mooring"]
  s.email       = ['paul@opscode.com']

  s.add_dependency "chef"
  s.require_paths = ["lib"]
  s.files = %w(LICENSE README.rdoc) + Dir.glob("lib/**/*")
end
