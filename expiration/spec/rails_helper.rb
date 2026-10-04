ENV["RAILS_ENV"] = "test"

require_relative "../config/environment"
require "rspec/rails"

# Stands in for every EventPublisher, so specs never reach Redis. Assert on `event_publisher`.
RSpec.shared_context "event publisher" do
  let(:event_publisher) { instance_spy(EventPublisher) }

  before { allow(EventPublisher).to receive(:new).and_return(event_publisher) }
end

RSpec.configure do |config|
  config.include_context "event publisher"
end
