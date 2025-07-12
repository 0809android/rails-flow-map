class PostService
  def self.public_posts(params = {})
    posts = Post.published.includes(:user, :category, :tags, :comments)
    
    posts = posts.where('title ILIKE ? OR content ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    posts = posts.where(category_id: params[:category_id]) if params[:category_id].present?
    posts = posts.limit(params[:limit] || 20)
    posts = posts.offset(params[:offset] || 0)
    
    case params[:sort]
    when 'popular'
      posts.popular
    when 'recent'
      posts.recent
    else
      posts.recent
    end
  end
  
  def self.user_posts(user, params = {})
    posts = user.posts.includes(:category, :tags, :comments)
    
    posts = posts.where(status: params[:status]) if params[:status].present?
    posts = posts.limit(params[:limit] || 20)
    posts = posts.offset(params[:offset] || 0)
    
    posts.recent
  end
  
  def self.find_post_with_details(post_id)
    Post.includes(:user, :category, :tags, comments: :user).find(post_id)
  end
  
  def self.create_post(user, post_params)
    user.posts.create(post_params)
  end
  
  def self.update_post(post, post_params)
    post.update(post_params)
  end
  
  def self.soft_delete_post(post)
    post.update(status: 'archived')
  end
end