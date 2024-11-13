require 'openai'

class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'], log_errors: true)
    @assistant_id = ENV['ASSISTANT_ID'] # Set your existing assistant_id here
  end

  # Create a new thread
  def create_thread
    response = @client.threads.create
    response["id"]
  end

  # Send a text message to the assistant thread
  def send_text_message(thread_id, content)
    @client.messages.create(
      thread_id: thread_id,
      parameters: {
        role: "user", # Required for manually created messages
        content: [
          {
            type: "text",
            text: content
          }
        ]
      }
    )
  end

  # Send an image message to the assistant thread
  def send_image_message(thread_id, file_id, question = "What do you see in this image?")
    @client.messages.create(
      thread_id: thread_id,
      parameters: {
        role: "user", # Required for manually created messages
        content: [
          {
            type: "text",
            text: question
          },
          {
            type: "image_file",
            image_file: { file_id: file_id }
          }
        ]
      }
    )
  end

  # Upload an image file and return the file_id
  def upload_image(file_path)
    response = @client.files.upload(
      parameters: {
        file: File.open(file_path),
        purpose: "assistants"
      }
    )
    response["id"]
  end

  def create_run(thread_id)
    response = @client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: @assistant_id
      }
    )
    response["id"] # Only return the run_id, not the full response
  end
  

# Retrieve the status of a specific run
def retrieve_run(run_id, thread_id)
    # Ensure only the ID and thread_id are passed here
    response = @client.runs.retrieve(id: run_id, thread_id: thread_id)
    response['status'] # Return only the status to check in the controller
  end
  

  # List all messages in the thread to get the latest response
  def list_messages(thread_id)
    @client.messages.list(thread_id: thread_id, parameters: { order: "asc" })
  end
end