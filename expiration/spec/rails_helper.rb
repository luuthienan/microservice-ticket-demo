ENV["RAILS_ENV"] = "test"

require_relative "../config/environment"
require "rspec/rails"

RSpec.configure do |config|
  config.before { allow(Events).to receive(:publish) }
end
