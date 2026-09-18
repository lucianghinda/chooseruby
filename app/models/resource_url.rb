# frozen_string_literal: true

# Canonical comparison form shared by submitted resource links.
class ResourceUrl
  def initialize(url)
    @url = url
  end

  def to_s
    @url.strip.downcase
      .sub(/\Ahttps:\/\//, "http://")
      .sub(/\Ahttp:\/\/www\./, "http://")
      .delete_suffix("/")
  end
end
