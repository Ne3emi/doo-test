class WhatsappService
  include HTTParty
  base_uri 'https://graph.facebook.com/v17.0'

  def initialize
    @headers = {
      "Authorization" => "Bearer #{ENV['WHATSAPP_API_TOKEN']}",
      "Content-Type" => "application/json"
    }
    @phone_number_id = ENV['WHATSAPP_PHONE_NUMBER_ID']
  end

  # Send text message to WhatsApp
  def send_text_message(user_number, message)
    url = "https://graph.facebook.com/v17.0/#{@phone_number_id}/messages"
    payload = {
      messaging_product: 'whatsapp',
      to: user_number,
      text: { body: message }
    }

    Rails.logger.debug "Sending WhatsApp message with payload: #{payload}"

    response = self.class.post(url, headers: @headers, body: payload.to_json)
    
    if response.success?
      Rails.logger.debug "Message sent successfully to WhatsApp: #{response.body}"
    else
      Rails.logger.error "Error sending message to WhatsApp: #{response.code} - #{response.message} - #{response.body}"
    end

    response.success?
  end

  # Get media URL from WhatsApp
def get_media_url(media_id)
  url = "https://graph.facebook.com/v17.0/#{media_id}?fields=url"

  Rails.logger.debug "Fetching media URL for media_id: #{media_id} with full URL: #{url}"

  response = self.class.get(url, headers: @headers)

  if response.success?
    media_url = response.parsed_response["url"]
    Rails.logger.debug "Retrieved media URL: #{media_url}"
    media_url
  else
    Rails.logger.error "Error fetching media URL: #{response.code} - #{response.message} - #{response.body}"
    nil
  end
end

end
