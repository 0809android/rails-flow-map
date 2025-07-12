class Category < ApplicationRecord
  # Associations
  has_many :posts, dependent: :nullify
  belongs_to :parent_category, class_name: 'Category', optional: true
  has_many :subcategories, class_name: 'Category', foreign_key: 'parent_category_id'
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  
  # Scopes
  scope :top_level, -> { where(parent_category_id: nil) }
  scope :active, -> { where(active: true) }
  
  # Methods
  def posts_count
    posts.published.count
  end
  
  def hierarchy_name
    return name if parent_category.nil?
    "#{parent_category.hierarchy_name} > #{name}"
  end
end