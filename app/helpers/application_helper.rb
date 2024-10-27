module ApplicationHelper
  def flash_messages(f, options = {})
    translate_name = { notice: 'success', alert: 'danger' }

    f.map { |name, msg|
      base_class = "alert alert-#{translate_name[name.to_sym]}"
      custom_class = options[:class]
      final_class = [base_class, custom_class].compact.join(' ')

      content_tag(:div, h(msg), class: final_class)
    }.join("\n").html_safe
  end
end