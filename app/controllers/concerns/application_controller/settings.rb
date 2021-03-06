module Concerns::ApplicationController::Settings
  extend ActiveSupport::Concern

  # sets the locale based on the locale param (grabbed from the path by the router)
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # Loads the user-specified timezone from configatron, if one exists
  def set_timezone
    Time.zone = configatron.timezone.to_s if configatron.timezone?
  end

  # loads settings for the mission, or no mission (admin mode), into configatron
  def load_settings_for_mission_into_config
    @setting = Setting.load_for_mission(current_mission)
  end
end