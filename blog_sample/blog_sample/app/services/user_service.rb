class UserService
  def self.fetch_active_users(params = {})
    users = User.active.includes(:profile, :posts)
    
    users = users.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    users = users.limit(params[:limit] || 50)
    users = users.offset(params[:offset] || 0)
    
    users.recent
  end
  
  def self.create_user(user_params)
    User.create(user_params.merge(active: true))
  end
  
  def self.update_user(user, user_params)
    user.update(user_params)
  end
  
  def self.deactivate_user(user)
    user.update(active: false)
  end
  
  def self.find_user_with_stats(user_id)
    user = User.includes(:posts, :comments, :profile).find(user_id)
    user
  end
end