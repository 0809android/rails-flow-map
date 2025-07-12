class UserFollowing < ApplicationRecord
  # Associations
  belongs_to :follower_user, class_name: 'User'
  belongs_to :followed_user, class_name: 'User'
  
  # Validations
  validates :follower_user_id, uniqueness: { scope: :followed_user_id }
  validate :cannot_follow_self
  
  private
  
  def cannot_follow_self
    errors.add(:followed_user, "can't follow yourself") if follower_user_id == followed_user_id
  end
end