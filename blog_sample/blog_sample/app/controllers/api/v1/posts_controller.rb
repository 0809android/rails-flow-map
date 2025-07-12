class Api::V1::PostsController < ApplicationController
  before_action :set_post, only: [:show, :update, :destroy]
  before_action :set_user, only: [:index, :create], if: -> { params[:user_id].present? }
  
  def index
    if @user
      @posts = PostService.user_posts(@user, params)
    else
      @posts = PostService.public_posts(params)
    end
    
    posts_data = @posts.map do |post|
      PostPresenter.new(post).summary_hash
    end
    
    AnalyticsService.track_post_views(@posts.pluck(:id))
    render_success(posts_data)
  end
  
  def show
    @post = PostService.find_post_with_details(params[:id])
    post_data = PostPresenter.new(@post).detailed_hash
    
    # Track view
    AnalyticsService.track_post_view(@post.id, current_user&.id)
    
    render_success(post_data)
  end
  
  def create
    @post = PostService.create_post(post_author, post_params)
    
    if @post.persisted?
      TagService.attach_tags(@post, params[:tags]) if params[:tags].present?
      NotificationService.notify_followers(@post.user, @post)
      
      render_success(PostPresenter.new(@post).to_hash, 'Post created successfully')
    else
      render_error(@post.errors.full_messages.join(', '))
    end
  end
  
  def update
    if PostService.update_post(@post, post_params)
      TagService.update_tags(@post, params[:tags]) if params[:tags].present?
      render_success(PostPresenter.new(@post).to_hash, 'Post updated successfully')
    else
      render_error(@post.errors.full_messages.join(', '))
    end
  end
  
  def destroy
    PostService.soft_delete_post(@post)
    render_success(nil, 'Post deleted successfully')
  end
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Post not found', :not_found)
  end
  
  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_error('User not found', :not_found)
  end
  
  def post_author
    @user || current_user
  end
  
  def post_params
    params.require(:post).permit(:title, :content, :category_id, :status)
  end
end