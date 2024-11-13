# app/services/openai_image_analyzer.rb

require 'httparty'

class OpenAIImageAnalyzer
  include HTTParty
  base_uri 'https://api.openai.com/v1'

  def initialize
    @headers = {
      "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}",
      "Content-Type" => "application/json"
    }
  end

  # Analyze an image from a URL using OpenAI's model
  def analyze_image(image_url)
    payload = {
      model: "gpt-4o",  # Replace with the correct model ID for image analysis
      messages: [
        {
          role: "user",
          content: [
            {
              "type": "text",
              "text": "What's in this image?"
            },
            {
              "type": "image_url",
              "image_url": {
                "url": image_url,
                "detail": "high"
              }
            }
          ]
        }
      ],
      max_tokens: 300
    }

    Rails.logger.debug "Sending image to OpenAI for analysis with payload: #{payload}"

    response = self.class.post("/chat/completions", headers: @headers, body: payload.to_json)

    if response.success?
      Rails.logger.debug "Image analysis successful: #{response.body}"
      response.dig("choices", 0, "message", "content")
    else
      Rails.logger.error "Error analyzing image with OpenAI: #{response.code} - #{response.message} - #{response.body}"
      "Sorry, I couldn't analyze the image."
    end
  end
end
