class Api::ThreadsController < ApplicationController
    before_action :set_openai_service
  
    # 1. Start a new thread
    def start_thread
      response = @openai_service.start_thread
      if response.success?
        render json: { thread_id: response['id'] }, status: :ok
      else
        render json: { error: "Failed to start thread" }, status: :unprocessable_entity
      end
    end
  
    # 2. Send a message in a thread
    def send_message
      thread_id = params[:thread_id]
      user_message = params[:user_message]
      response = @openai_service.send_message(thread_id, user_message)
      if response.success?
        assistant_reply = response['choices'][0]['message']['content']
        render json: { assistant_reply: assistant_reply }, status: :ok
      else
        render json: { error: "Failed to send message" }, status: :unprocessable_entity
      end
    end
  
    # 3. Get all messages in a thread
    def get_thread_messages
      thread_id = params[:thread_id]
      response = @openai_service.get_thread_messages(thread_id)
      if response.success?
        render json: response['messages'], status: :ok
      else
        render json: { error: "Failed to retrieve thread messages" }, status: :unprocessable_entity
      end
    end
  
    private
  
    def set_openai_service
      @openai_service = OpenaiService.new
    end
  end
  