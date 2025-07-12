class CommentService
  def self.post_comments(post, params = {})
    comments = post.comments.includes(:user, :child_comments)
    
    if params[:top_level_only] == 'true'
      comments = comments.top_level
    end
    
    comments = comments.limit(params[:limit] || 50)
    comments = comments.offset(params[:offset] || 0)
    
    comments.recent
  end
  
  def self.recent_comments(params = {})
    comments = Comment.includes(:user, :post)
    
    comments = comments.limit(params[:limit] || 20)
    comments = comments.offset(params[:offset] || 0)
    
    comments.recent
  end
  
  def self.create_comment(post, user, comment_params)
    post.comments.create(comment_params.merge(user: user))
  end
  
  def self.update_comment(comment, comment_params)
    comment.update(comment_params)
  end
  
  def self.soft_delete_comment(comment)
    comment.update(content: '[deleted]', deleted_at: Time.current)
  end
end