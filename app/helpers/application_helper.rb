module ApplicationHelper

  def render_markdown(text)
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, hard_wrap: true)
    @markdown.render(text.gsub(/\n/, "\n\n")).html_safe
  end

end
