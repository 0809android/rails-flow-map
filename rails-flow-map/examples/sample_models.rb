# Sample Rails models to demonstrate RailsFlowMap analysis

class User < ApplicationRecord
  has_many :posts
  has_many :comments
  has_one :profile
  has_and_belongs_to_many :roles
end

class Post < ApplicationRecord
  belongs_to :user
  has_many :comments
  has_many :tags, through: :post_tags
  has_many :post_tags
end

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :child_comments, class_name: 'Comment', foreign_key: 'parent_comment_id'
end

class Profile < ApplicationRecord
  belongs_to :user
end

class Role < ApplicationRecord
  has_and_belongs_to_many :users
end

class Tag < ApplicationRecord
  has_many :post_tags
  has_many :posts, through: :post_tags
end

class PostTag < ApplicationRecord
  belongs_to :post
  belongs_to :tag
end