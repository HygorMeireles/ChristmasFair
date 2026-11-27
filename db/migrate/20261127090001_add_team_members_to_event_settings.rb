class AddTeamMembersToEventSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :event_settings, :brownie_lead_name, :string
    add_column :event_settings, :hot_chocolate_lead_name, :string
    add_column :event_settings, :fishing_lead_name, :string
    add_column :event_settings, :member_four_name, :string
    add_column :event_settings, :member_five_name, :string
    add_column :event_settings, :member_six_name, :string
  end
end
