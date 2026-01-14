# frozen_string_literal: true

module ApplicationHelper
  def breadcrumbs(items)
    return "" if items.blank?

    content_tag :nav, aria: { label: "Breadcrumb" }, class: "mb-6" do
      content_tag :ol, class: "flex flex-wrap items-center gap-2 text-sm text-slate-600" do
        items.each_with_index.map do |item, index|
          is_last = index == items.size - 1
          separator = is_last ? "" : content_tag(:span, "›", class: "mx-1 text-slate-400", aria: { hidden: true })

          content_tag(:li, class: "inline-flex items-center") do
            if item[:url].present? && !is_last
              link_to(item[:text], item[:url], class: "hover:text-rose-500 transition-colors truncate max-w-[200px] sm:max-w-none") + separator
            else
              content_tag(:span, item[:text], class: "font-semibold text-slate-900 truncate max-w-[200px] sm:max-w-none") + separator
            end
          end
        end.join.html_safe
      end
    end
  end
end
