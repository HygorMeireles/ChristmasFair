require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated visitors to login" do
    delete logout_url

    get financial_url

    assert_redirected_to login_url(locale: "pt-BR")
  end

  test "rejects an invalid password and accepts the operator password" do
    delete logout_url

    post login_url, params: { password: "wrong" }
    assert_redirected_to login_url(locale: "pt-BR")

    post login_url, params: { password: ENV.fetch("CHRISTMAS_FAIR_OPERATOR_PASSWORD") }
    assert_redirected_to root_url(locale: "pt-BR")
  end
end
