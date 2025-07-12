class FollowService
  Result = Struct.new(:success?, :error, :data)
  
  def self.follow_user(follower, user_to_follow)
    return Result.new(false, "Cannot follow yourself") if follower == user_to_follow
    return Result.new(false, "Already following this user") if follower.following?(user_to_follow)
    
    following = UserFollowing.create(
      follower_user: follower,
      followed_user: user_to_follow
    )
    
    if following.persisted?
      NotificationService.notify_new_follower(user_to_follow, follower)
      Result.new(true, nil, following)
    else
      Result.new(false, following.errors.full_messages.join(', '))
    end
  end
  
  def self.unfollow_user(follower, user_to_unfollow)
    following = UserFollowing.find_by(
      follower_user: follower,
      followed_user: user_to_unfollow
    )
    
    return Result.new(false, "Not following this user") unless following
    
    if following.destroy
      Result.new(true, nil)
    else
      Result.new(false, "Failed to unfollow user")
    end
  end
end