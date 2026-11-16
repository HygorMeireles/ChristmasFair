class SessionsController < ApplicationController
  skip_before_action :require_authentication
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: t("authentication.too_many_attempts") }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    if valid_credentials?
      reset_session
      session[:operator_authenticated] = true
      redirect_to session.delete(:return_to) || root_path, notice: t("authentication.signed_in")
    else
      redirect_to login_path, alert: t("authentication.invalid")
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: t("authentication.signed_out")
  end

  private

  def valid_credentials?
    expected = operator_password
    supplied = params[:password].to_s
    return false if expected.blank? || supplied.blank?

    expected_digest = OpenSSL::Digest::SHA256.hexdigest(expected)
    supplied_digest = OpenSSL::Digest::SHA256.hexdigest(supplied)
    ActiveSupport::SecurityUtils.secure_compare(expected_digest, supplied_digest)
  end
end
