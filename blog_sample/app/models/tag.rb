class Tag < ApplicationRecord
  # Associations
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  
  # Validations
  validates :name, presence: true, uniqueness: true
  
  # Scopes
  scope :popular, -> { joins(:posts).group(:id).order('COUNT(posts.id) DESC') }
  
  # Methods
  def posts_count
    posts.published.count
  end
end