class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale
  before_action :require_authentication

  helper_method :current_locale, :authenticated?

  private

  def require_authentication
    return if authenticated?

    session[:return_to] = request.fullpath if request.get? || request.head?
    redirect_to login_path, alert: t("authentication.required")
  end

  def authenticated?
    session[:operator_authenticated] == true
  end

  def operator_password
    ENV["CHRISTMAS_FAIR_OPERATOR_PASSWORD"].presence || Rails.application.credentials.dig(:authentication, :operator_password)
  end

  def set_locale
    requested = params[:locale].presence_in(I18n.available_locales.map(&:to_s))
    I18n.locale = requested || I18n.default_locale
  end

  def current_locale
    I18n.locale.to_s
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
