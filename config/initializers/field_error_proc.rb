# Styles field errors with Bulma
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  html = html_tag
  Nokogiri::HTML::DocumentFragment.parse(html_tag).css('input').each do |e|
    e['class'] ||= ''
    e['class'] += " is-danger"
    e['class'] = e['class'].strip
    html = e.to_s.html_safe
  end
  html
end
