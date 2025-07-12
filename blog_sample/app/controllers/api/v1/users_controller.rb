class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy, :follow, :unfollow]
  
  def index
    @users = UserService.fetch_active_users(params)
    user_data = @users.map do |user|
      UserPresenter.new(user).to_hash
    end
    
    render_success(user_data)
  end
  
  def show
    user_data = UserPresenter.new(@user).detailed_hash
    render_success(user_data)
  end
  
  def create
    @user = UserService.create_user(user_params)
    
    if @user.persisted?
      NotificationService.send_welcome_email(@user)
      render_success(UserPresenter.new(@user).to_hash, 'User created successfully')
    else
      render_error(@user.errors.full_messages.join(', '))
    end
  end
  
  def update
    if UserService.update_user(@user, user_params)
      render_success(UserPresenter.new(@user).to_hash, 'User updated successfully')
    else
      render_error(@user.errors.full_messages.join(', '))
    end
  end
  
  def destroy
    UserService.deactivate_user(@user)
    render_success(nil, 'User deactivated successfully')
  end
  
  def follow
    result = FollowService.follow_user(current_user, @user)
    
    if result.success?
      render_success(nil, 'User followed successfully')
    else
      render_error(result.error)
    end
  end
  
  def unfollow
    result = FollowService.unfollow_user(current_user, @user)
    
    if result.success?
      render_success(nil, 'User unfollowed successfully')
    else
      render_error(result.error)
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('User not found', :not_found)
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :username, :bio)
  end
end