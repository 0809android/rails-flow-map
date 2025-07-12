class Post < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :liked_users, through: :likes, source: :user
  
  # Nested associations
  has_many :comment_users, through: :comments, source: :user
  
  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :status, inclusion: { in: %w[draft published archived] }
  
  # Scopes
  scope :published, -> { where(status: 'published') }
  scope :draft, -> { where(status: 'draft') }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { joins(:likes).group(:id).order('COUNT(likes.id) DESC') }
  
  # Enums
  enum status: { draft: 0, published: 1, archived: 2 }
  
  # Methods
  def excerpt(limit = 150)
    content.truncate(limit)
  end
  
  def reading_time
    words_per_minute = 200
    words = content.split.size
    (words / words_per_minute.to_f).ceil
  end
  
  def like_count
    likes.count
  end
  
  def comment_count
    comments.count
  end
end