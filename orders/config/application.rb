require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module Orders
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[tasks])
    config.api_only = true
  end
end
