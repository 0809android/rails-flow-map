class NotificationService
  def self.send_welcome_email(user)
    # In a real app, this would send an email
    Rails.logger.info "Welcome email sent to #{user.email}"
  end
  
  def self.notify_followers(user, post)
    # In a real app, this would notify all followers
    follower_count = user.follower_users.count
    Rails.logger.info "Notified #{follower_count} followers about new post: #{post.title}"
  end
  
  def self.notify_comment_created(comment)
    # In a real app, this would notify the post author
    Rails.logger.info "Comment notification sent for post: #{comment.post.title}"
  end
  
  def self.notify_new_follower(user, follower)
    # In a real app, this would send a notification
    Rails.logger.info "#{user.name} has a new follower: #{follower.name}"
  end
end