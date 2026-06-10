require 'rake/testtask'

# Runs the core library gem unit tests
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

# Runs the local web application sandbox integration tests
namespace :test do
  Rake::TestTask.new(:sandbox) do |t|
    t.libs << 'lib' << 'examples/web_app'
    t.pattern = 'examples/web_app/test/**/*_test.rb'
    t.verbose = true
  end
end

task default: :test
