# frozen_string_literal: true

require_relative 'lib/workflow/version'

Gem::Specification.new do |spec|
  spec.name = 'workflow_engine'
  spec.version = Workflow::VERSION
  spec.authors = ['Marco van Kampen']
  spec.email = ['m.kampen@hotmail.com']

  spec.summary = 'Distributed workflow orchestration primitives'
  spec.description = 'A Ruby workflow engine with separated orchestrator, transport, and worker execution layers.'
  spec.homepage = 'https://github.com/mvkampen/workflow_engine'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir[
    'README.md',
    'bin/*',
    'lib/**/*.rb',
    'spec/**/*.rb'
  ]
  spec.bindir = 'bin'
  spec.executables = %w[]
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
end
