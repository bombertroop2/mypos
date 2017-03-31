module ApplicationHelper    
  def remove_empty_space_from_phone_number(number)
    number.gsub("_", "") rescue nil
  end
  
  def control_group_error(model, field_name)
    " has-error" unless model.errors[field_name].blank?
  end

  def error_help_text(model, field_name)
    "<span class='help-block'>#{model.errors[field_name].join(", ")}</span>".html_safe unless model.errors[field_name].blank?
  end
end
