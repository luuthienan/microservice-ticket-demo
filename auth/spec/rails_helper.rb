ENV["RAILS_ENV"] = "test"
ENV["JWT_KEY"] ||= "test-key"

require_relative "../config/environment"
require "rspec/rails"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
