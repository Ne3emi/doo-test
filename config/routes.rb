Rails.application.routes.draw do
  # Rails.application.routes: This is the part of the application that handles routing. Routing is responsible for directing HTTP requests (like GET and POST requests) to the appropriate controller and action in the Rails application.
  namespace :api do
    post 'whatsapp_webhook', to: 'whatsapp#receive_message'
    # post 'whatsapp_webhook' — This route listens for POST requests from WhatsApp, which are handled by the receive_message action in the WhatsappController.
    get 'whatsapp_webhook', to: 'whatsapp#verify_webhook'
  end
end
