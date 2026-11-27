module ApplicationHelper
  def money(cents)
    number_to_currency(cents.to_i / 100.0, unit: "R$", separator: ",", delimiter: ".")
  end

  def locale_switch_path(locale)
    url_for(request.query_parameters.merge(locale: locale))
  end

  def brownie_grid_columns(count)
    return 4 if count <= 12
    return 6 if count <= 30
    return 8 if count <= 56

    10
  end

  def brownie_grid_rows(count)
    (count.to_f / brownie_grid_columns(count)).ceil.clamp(1, 8)
  end
end
