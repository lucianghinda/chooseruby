# frozen_string_literal: true

require "test_helper"

class ActiveStorageImageProcessingTest < ActionDispatch::IntegrationTest
  test "analyzes an uploaded image and processes its representation" do
    assert_equal :vips, ActiveStorage.variant_processor

    author = Author.create!(name: "Image Processing Test")
    author.avatar.attach(fixture_file_upload("test_image.png", "image/png"))

    blob = author.avatar.blob
    blob.analyze

    assert_equal 2, blob.metadata[:width]
    assert_equal 2, blob.metadata[:height]

    representation = blob.representation(resize_to_limit: [ 1, 1 ])
    representation.processed
    processed_image = Vips::Image.new_from_buffer(representation.download, "")

    assert_equal 1, processed_image.width
    assert_equal 1, processed_image.height
  ensure
    if blob
      blob.service.delete(representation.key) if representation&.key
      blob.service.delete(blob.key)
    end
  end
end
