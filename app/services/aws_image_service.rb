require 'aws-sdk-s3'
require 'httparty'
require 'mini_mime'
require 'mini_magick'

def convert_to_jpeg(blob)
  image = MiniMagick::Image.read(blob)
  image.format("jpeg")
  image.to_blob
rescue StandardError => e
  puts "Failed to convert image to JPEG with MiniMagick: #{e.message}"
  nil
end

class AwsImageService
  def initialize
    @s3_client = Aws::S3::Client.new(
      region: 'us-east-2',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    @bucket_name = 'feehla-images-uploads'
  end

  
  def upload_image_to_s3(image_url, file_data = nil, mime_type = nil)
    return '' if image_url.nil?

    puts "Image URL: #{image_url}"
    
    # Extract the base filename without query parameters
    file_name = File.basename(URI.parse(image_url).path)

    # Fetch image data if not provided
    blob = file_data || download_image(image_url)
    return '' unless blob

    # Detect MIME type if not provided
    mime_type ||= MiniMime.lookup_by_filename(file_name)&.content_type || 'application/octet-stream'
    puts "MIME type: #{mime_type}"

    # Convert .webp images to .jpeg if necessary
    if mime_type == 'image/webp'
      blob = convert_to_jpeg(blob)
      mime_type = 'image/jpeg'
      file_name = file_name.sub('.webp', '.jpg')
    end

    # Prepare S3 upload parameters
    key = "whatsapp/#{file_name}"
    params = {
      bucket: @bucket_name,
      key: key,
      acl: 'public-read',
      body: blob,
      content_type: mime_type
    }

    # Upload to S3 and return the public URL
    response = @s3_client.put_object(params)
    s3_url = s3_public_url(key)
    puts "Uploaded image to S3 URL: #{s3_url}"
    s3_url
  rescue StandardError => e
    puts "Error uploading to S3: #{e.message}"
    ''
  end

  private

  

  # Download the image
  # Download the image with Authorization header
  def download_image(url)
    response = HTTParty.get(url, headers: { "Authorization" => "Bearer #{ENV['WHATSAPP_API_TOKEN']}" })
    if response.success?
      response.body
    else
      puts "Failed to download image from URL: #{url}, Status: #{response.code}, Response: #{response.body}"
      nil
    end
  end

  # Convert .webp to .jpeg using ImageProcessing and vips
  def convert_to_jpeg(blob)
    image = MiniMagick::Image.read(blob)
    image.format("jpeg")
    image.to_blob
  rescue StandardError => e
    puts "Failed to convert image to JPEG with MiniMagick: #{e.message}"
    nil
  end

  # Generate S3 public URL
  def s3_public_url(key)
    "https://#{@bucket_name}.s3.amazonaws.com/#{key}"
  end
end
