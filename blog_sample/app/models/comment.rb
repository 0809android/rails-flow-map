class Comment < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :post
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :child_comments, class_name: 'Comment', foreign_key: 'parent_comment_id', dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  
  # Nested associations
  has_many :liked_users, through: :likes, source: :user
  
  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  
  # Scopes
  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :replies, -> { where.not(parent_comment_id: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_post, ->(post) { where(post: post) }
  
  # Methods
  def reply?
    parent_comment_id.present?
  end
  
  def top_level?
    parent_comment_id.nil?
  end
  
  def depth
    return 0 if top_level?
    1 + (parent_comment&.depth || 0)
  end
  
  def replies_count
    child_comments.count
  end
  
  def like_count
    likes.count
  end
end