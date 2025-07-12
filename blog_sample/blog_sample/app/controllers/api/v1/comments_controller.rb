class Api::V1::CommentsController < ApplicationController
  before_action :set_post, except: [:index]
  before_action :set_comment, only: [:show, :update, :destroy]
  
  def index
    if params[:post_id].present?
      set_post
      @comments = CommentService.post_comments(@post, params)
    else
      @comments = CommentService.recent_comments(params)
    end
    
    comments_data = @comments.map do |comment|
      CommentPresenter.new(comment).to_hash
    end
    
    render_success(comments_data)
  end
  
  def show
    comment_data = CommentPresenter.new(@comment).detailed_hash
    render_success(comment_data)
  end
  
  def create
    @comment = CommentService.create_comment(@post, current_user, comment_params)
    
    if @comment.persisted?
      NotificationService.notify_comment_created(@comment)
      ModerationService.check_comment_content(@comment)
      
      render_success(CommentPresenter.new(@comment).to_hash, 'Comment created successfully')
    else
      render_error(@comment.errors.full_messages.join(', '))
    end
  end
  
  def update
    if CommentService.update_comment(@comment, comment_params)
      ModerationService.recheck_comment(@comment)
      render_success(CommentPresenter.new(@comment).to_hash, 'Comment updated successfully')
    else
      render_error(@comment.errors.full_messages.join(', '))
    end
  end
  
  def destroy
    CommentService.soft_delete_comment(@comment)
    render_success(nil, 'Comment deleted successfully')
  end
  
  private
  
  def set_post
    if params[:user_id].present?
      user = User.find(params[:user_id])
      @post = user.posts.find(params[:post_id])
    else
      @post = Post.find(params[:post_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_error('Post not found', :not_found)
  end
  
  def set_comment
    @comment = @post.comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Comment not found', :not_found)
  end
  
  def comment_params
    params.require(:comment).permit(:content, :parent_comment_id)
  end
end