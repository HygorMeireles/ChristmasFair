module ApplicationHelper
  def money(cents)
    number_to_currency(cents.to_i / 100.0, unit: "R$", separator: ",", delimiter: ".")
  end

  def locale_switch_path(locale)
    url_for(request.query_parameters.merge(locale: locale))
  end
end
