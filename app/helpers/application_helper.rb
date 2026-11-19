# frozen_string_literal: true

module ApplicationHelper
  BREADCRUMB_TEXT_CLASSES = "truncate max-w-[200px] sm:max-w-none"
  BREADCRUMB_LINK_CLASSES = "hover:text-rose-500 transition-colors #{BREADCRUMB_TEXT_CLASSES}"
  BREADCRUMB_CURRENT_CLASSES = "font-semibold text-slate-900 #{BREADCRUMB_TEXT_CLASSES}"

  # Renders the trail of pages leading to the page we are on
  #
  # @param items [Array<Hash>] crumbs with a :text and an optional :url, current page last
  # @return [String] the breadcrumb navigation, empty when there is no trail
  def breadcrumbs(items)
    return "" if items.blank?

    content_tag :nav, aria: { label: "Breadcrumb" }, class: "mb-6" do
      content_tag :ol, class: "flex flex-wrap items-center gap-2 text-sm text-slate-600" do
        safe_join(items[0...-1].map { |item| breadcrumb_back_to(item) } << breadcrumb_current(items.last))
      end
    end
  end

  private

  # A crumb we can navigate back to, followed by the separator to the next crumb
  def breadcrumb_back_to(item)
    url = item[:url]
    text = item[:text]
    label = url.present? ? link_to(text, url, class: BREADCRUMB_LINK_CLASSES) : breadcrumb_label(text)

    breadcrumb(label + breadcrumb_separator)
  end

  # The crumb for the page we are on: never a link, and nothing follows it
  def breadcrumb_current(item)
    breadcrumb(breadcrumb_label(item[:text]))
  end

  def breadcrumb(content)
    content_tag(:li, class: "inline-flex items-center") { content }
  end

  def breadcrumb_label(text)
    content_tag(:span, text, class: BREADCRUMB_CURRENT_CLASSES)
  end

  def breadcrumb_separator
    content_tag(:span, "›", class: "mx-1 text-slate-400", aria: { hidden: true })
  end
end
