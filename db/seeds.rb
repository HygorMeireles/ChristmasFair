# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
products = [
  { code: "brownie", name_pt: "Brownie", name_en: "Brownie", stock_unit: "unit", serving_size: 1 },
  { code: "hot_chocolate", name_pt: "Chocolate quente", name_en: "Hot chocolate", stock_unit: "ml", serving_size: 250 },
  { code: "fishing", name_pt: "Pescaria", name_en: "Fishing game", stock_unit: "unit", serving_size: 1 }
]

products.each do |attributes|
  product = Product.find_or_initialize_by(code: attributes[:code])
  product.assign_attributes(attributes) if product.new_record?
  product.price_cents ||= 0
  product.stock_quantity ||= 0
  product.capacity_quantity ||= 0
  product.active = true if product.active.nil?
  product.lock_version ||= 0
  product.save!
end
