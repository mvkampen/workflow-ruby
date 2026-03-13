# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:lint)
rescue LoadError
  desc 'Run RuboCop lint checks'
  task :lint do
    abort 'rubocop is not installed. Run `bundle install` first.'
  end
end

task ci: %i[lint test]
task default: :test
