class Like < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :likeable, polymorphic: true
  
  # Validations
  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id] }
  
  # Scopes
  scope :for_posts, -> { where(likeable_type: 'Post') }
  scope :for_comments, -> { where(likeable_type: 'Comment') }
end