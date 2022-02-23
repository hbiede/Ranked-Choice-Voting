# frozen_string_literal: true

# Author: Hundter Biede (hbiede.com)
# Version: 1.0
# License:

require 'test-unit'
require 'simplecov'
SimpleCov.start do
  add_filter '/tests/'
  enable_coverage :branch
  primary_coverage :branch
end

SimpleCov.minimum_coverage(line: 100, branch: 100)
SimpleCov.maximum_coverage_drop(line: 1)

Test::Unit::AutoRunner.run(true, File.dirname(__FILE__))

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
else
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
end
