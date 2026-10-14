require_relative "boot"

require "rails"
# Only the frameworks this app actually uses (no jobs, mailers, storage,
# cable or websockets — it is a plain server-rendered CRUD app).
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LockerPlatform
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
  end
end
