class Profile < ApplicationRecord
  # Associations
  belongs_to :user
  
  # Validations
  validates :bio, length: { maximum: 500 }
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  
  # Methods
  def full_location
    [city, country].compact.join(', ')
  end
  
  def social_links
    {
      twitter: twitter_handle,
      linkedin: linkedin_url,
      github: github_username
    }.compact
  end
end