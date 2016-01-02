module ApplicationHelper
  def remove_empty_space_from_phone_number(number)
    number.gsub("_", "") rescue nil
  end
end
