# app/controllers/api/whatsapp_controller.rb

require_dependency Rails.root.join("app/services/openai_image_analyzer").to_s

class Api::WhatsappController < ActionController::API
    before_action :set_openai_service, :set_whatsapp_service
  # Verification endpoint for WhatsApp webhook
  def verify_webhook
    mode = params['hub.mode']
    token = params['hub.verify_token']
    challenge = params['hub.challenge']

    # Replace 'your_verify_token' with the token you set up in WhatsApp configuration
    if mode == 'subscribe' && token == ENV['WHATSAPP_VERIFY_TOKEN']
      render plain: challenge
    else
      head :forbidden
    end
  end


    # Webhook for receiving WhatsApp messages
    def receive_message
      changes = params.dig("entry", 0, "changes", 0)
      # params contains the parameters received in the request, and Rails automatically parses incoming JSON requests into a hash-like structure
      messages = changes.dig("value", "messages")
      user_number = messages&.dig(0, "from")
      Rails.logger.debug "Processing message from #{user_number}"
  
      if messages
        message = messages[0]
        message_type = message["type"]
  
        case message_type
        when "text"
          user_message = message["text"]["body"]
          Rails.logger.debug "Received text message: #{user_message}"
          assistant_reply = process_text_message(user_message)
          Rails.logger.debug "Assistant reply: #{assistant_reply}"
          send_reply_to_whatsapp(user_number, assistant_reply) if assistant_reply
        when "image"
          media_id = message["image"]["id"]
          media_url = @whatsapp_service.get_media_url(media_id)
          Rails.logger.debug "Received image message with media URL: #{media_url}"
  
          if media_url
            # Upload image to S3 and get the S3 URL
            s3_image_url = download_and_upload_to_s3(media_url)
            assistant_reply = analyze_image_with_openai(s3_image_url)
            send_reply_to_whatsapp(user_number, assistant_reply) if assistant_reply
          else
            send_reply_to_whatsapp(user_number, "Sorry, I couldn't retrieve the image.")
          end
        else
          send_reply_to_whatsapp(user_number, "Sorry, this type of message is not supported.")
        end
      end
  
      head :ok
    end
  
    private
  
    def set_openai_service
      @openai_service = OpenaiService.new
    end
  
    def set_whatsapp_service
      @whatsapp_service = WhatsappService.new
    end
  
    # Process text message with OpenAI Assistant
    def process_text_message(user_message)
      thread_id = @openai_service.create_thread
      Rails.logger.debug "Created thread with ID: #{thread_id}"
      @openai_service.send_text_message(thread_id, user_message)
      run_id = @openai_service.create_run(thread_id)
      Rails.logger.debug "Created run with ID: #{run_id}"
      retrieve_assistant_response(run_id, thread_id)
    end
  
    # Helper method to upload image to S3 and get the URL
    def download_and_upload_to_s3(media_url)
      begin
        AwsImageService.new.upload_image_to_s3(media_url)
      rescue StandardError => e
        Rails.logger.error "Error uploading image to S3: #{e.message}"
        nil
      end
    end
  
    # Analyze the image with OpenAI using the S3 URL
    def analyze_image_with_openai(s3_image_url)
      OpenAIImageAnalyzer.new.analyze_image(s3_image_url)
    end
  
    # Poll OpenAI for the assistant's response and retrieve the latest message
    def retrieve_assistant_response(run_id, thread_id)
      status = poll_until_complete(run_id, thread_id)
      return "No response from assistant." unless status == "completed"
  
      messages = @openai_service.list_messages(thread_id)
      latest_message = messages.dig("data", -1, "content", 0, "text", "value")
      Rails.logger.debug "Retrieved assistant response: #{latest_message}"
      latest_message || "No response from assistant."
    end
  
    # Poll OpenAI until the run status is "completed"
    def poll_until_complete(run_id, thread_id)
      status = nil
      until status == "completed"
        sleep(1)
        status = @openai_service.retrieve_run(run_id, thread_id)
        Rails.logger.debug "Polling run status: #{status}"
      end
      status
    end
  
    def send_reply_to_whatsapp(user_number, message)
      Rails.logger.debug "Sending reply to WhatsApp: #{message}"
      @whatsapp_service.send_text_message(user_number, message)
    end
  end


  