require "test_helper"

class Financial::ProfitDistributionTest < ActiveSupport::TestCase
  test "splits seventy percent equally and thirty percent among preparation leads" do
    distribution = Financial::ProfitDistribution.new(profit_cents: 10_000)

    assert_equal 7_000, distribution.base_pool_cents
    assert_equal 3_000, distribution.preparation_pool_cents
    assert_equal 10_000, distribution.entries.sum(&:amount_cents)
    assert_equal [ 2_167, 2_167, 2_167, 1_167, 1_166, 1_166 ], distribution.entries.map(&:amount_cents)
  end

  test "does not distribute a negative balance" do
    distribution = Financial::ProfitDistribution.new(profit_cents: -500)

    assert_equal 0, distribution.profit_cents
    assert_equal [ 0, 0, 0, 0, 0, 0 ], distribution.entries.map(&:amount_cents)
  end
end
