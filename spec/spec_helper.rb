require 'rubygems'
require 'bundler'

Bundler.require :default, :development

Combustion.initialize! :active_record

require 'rspec/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.color_enabled = true
  config.formatter = :documentation

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

end
