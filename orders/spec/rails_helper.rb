ENV["RAILS_ENV"] = "test"
ENV["JWT_KEY"] ||= "test-key"

require_relative "../config/environment"
require "rspec/rails"

ActiveRecord::Migration.maintain_test_schema!

# Request headers carrying a signed-in user's jwt cookie.
def sign_in_as(user_id = SecureRandom.uuid)
  token = JWT.encode({ id: user_id, email: "test@test.com" }, ENV.fetch("JWT_KEY"), "HS256")
  { "Cookie" => "jwt=#{token}" }
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.before { allow(Events).to receive(:publish) }
end
