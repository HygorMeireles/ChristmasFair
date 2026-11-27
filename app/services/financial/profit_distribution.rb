module Financial
  class ProfitDistribution
    Entry = Data.define(:name_field, :role, :preparation_lead, :amount_cents)

    PARTICIPANTS = [
      [ :brownie_lead_name, :brownie_lead, true ],
      [ :hot_chocolate_lead_name, :hot_chocolate_lead, true ],
      [ :fishing_lead_name, :fishing_lead, true ],
      [ :member_four_name, :team_member, false ],
      [ :member_five_name, :team_member, false ],
      [ :member_six_name, :team_member, false ]
    ].freeze

    attr_reader :profit_cents, :base_pool_cents, :preparation_pool_cents, :entries

    def initialize(profit_cents:)
      @profit_cents = [ profit_cents.to_i, 0 ].max
      @base_pool_cents = (@profit_cents * 70) / 100
      @preparation_pool_cents = @profit_cents - @base_pool_cents
      @entries = build_entries
    end

    private

    def build_entries
      base_amounts = split(base_pool_cents, PARTICIPANTS.size)
      bonus_amounts = split(preparation_pool_cents, PARTICIPANTS.count(&:last))
      bonus_index = 0

      PARTICIPANTS.each_with_index.map do |(name_field, role, lead), index|
        bonus = lead ? bonus_amounts.fetch(bonus_index).tap { bonus_index += 1 } : 0
        Entry.new(name_field:, role:, preparation_lead: lead, amount_cents: base_amounts.fetch(index) + bonus)
      end
    end

    def split(total, count)
      quotient, remainder = total.divmod(count)
      Array.new(count) { |index| quotient + (index < remainder ? 1 : 0) }
    end
  end
end
