class ApplicationController < ActionController::API
  before_action :authenticate_user, except: [:health]
  
  def health
    render json: { status: 'ok', timestamp: Time.current }
  end
  
  private
  
  def authenticate_user
    # Simple authentication logic for demo
    @current_user = User.first
  end
  
  def current_user
    @current_user
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
  
  def render_success(data, message = 'Success')
    render json: { data: data, message: message }
  end
end