class User < ApplicationRecord
  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_many :followers, class_name: 'UserFollowing', foreign_key: 'followed_user_id'
  has_many :following, class_name: 'UserFollowing', foreign_key: 'follower_user_id'
  has_many :followed_users, through: :following, source: :followed_user
  has_many :follower_users, through: :followers, source: :follower_user
  
  # Through associations
  has_many :post_comments, through: :posts, source: :comments
  has_many :liked_posts, through: :likes, source: :post
  has_many :likes, dependent: :destroy
  
  # Validations
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true
  validates :name, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :verified, -> { where(verified: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def posts_count
    posts.published.count
  end
  
  def can_follow?(user)
    user != self && !following?(user)
  end
  
  def following?(user)
    followed_users.include?(user)
  end
end