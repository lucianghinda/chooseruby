# frozen_string_literal: true

# Renders shared navigation elements for the public directory.
module ApplicationHelper
  def breadcrumbs(items)
    return "" if items.blank?

    content_tag :nav, aria: { label: "Breadcrumb" }, class: "mb-6" do
      breadcrumb_list(items)
    end
  end

  private

  def breadcrumb_list(items)
    content_tag :ol, class: "flex flex-wrap items-center gap-2 text-sm text-slate-600" do
      links = items[0...-1].map { |item| breadcrumb_item(item) }
      links << content_tag(:li, breadcrumb_text(items.last), class: "inline-flex items-center")
      safe_join(links)
    end
  end

  def breadcrumb_item(item)
    content_tag(:li, class: "inline-flex items-center") do
      breadcrumb_link(item) + content_tag(:span, "›", class: "mx-1 text-slate-400", aria: { hidden: true })
    end
  end

  def breadcrumb_link(item)
    text, url = item.values_at(:text, :url)
    return breadcrumb_text(item) if url.blank?

    link_to(text, url, class: "hover:text-rose-500 transition-colors truncate max-w-[200px] sm:max-w-none")
  end

  def breadcrumb_text(item)
    content_tag(:span, item[:text], class: "font-semibold text-slate-900 truncate max-w-[200px] sm:max-w-none")
  end
end
