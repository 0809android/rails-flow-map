class Api::V1::AnalyticsController < ApplicationController
  def users
    analytics_data = AnalyticsService.user_analytics(params)
    user_stats = UserStatsService.calculate_stats
    
    result = {
      analytics: analytics_data,
      stats: user_stats,
      generated_at: Time.current
    }
    
    render_success(result)
  end
  
  def posts
    analytics_data = AnalyticsService.post_analytics(params)
    post_stats = PostStatsService.calculate_stats
    trending_posts = TrendingService.get_trending_posts
    
    result = {
      analytics: analytics_data,
      stats: post_stats,
      trending: trending_posts.map { |post| PostPresenter.new(post).summary_hash },
      generated_at: Time.current
    }
    
    render_success(result)
  end
end