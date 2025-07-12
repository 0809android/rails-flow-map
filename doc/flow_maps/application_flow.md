graph TD
    model_user[User]
    model_post[Post]
    model_comment[Comment]
    model_category[Category]
    model_tag[Tag]
    model_like[Like]
    route_users_index[GET /api/v1/users]
    route_users_show[GET /api/v1/users/:id]
    route_posts_index[GET /api/v1/posts]
    route_posts_create[POST /api/v1/posts]
    route_comments_index[GET /api/v1/posts/:post_id/comments]
    route_analytics_users[GET /api/v1/analytics/users]
    controller_users[[Api::V1::UsersController]]
    action_controller_users_index(index)
    action_controller_users_show(show)
    action_controller_users_create(create)
    action_controller_users_update(update)
    controller_posts[[Api::V1::PostsController]]
    action_controller_posts_index(index)
    action_controller_posts_show(show)
    action_controller_posts_create(create)
    action_controller_posts_update(update)
    controller_comments[[Api::V1::CommentsController]]
    action_controller_comments_index(index)
    action_controller_comments_create(create)
    controller_analytics[[Api::V1::AnalyticsController]]
    action_controller_analytics_users(users)
    action_controller_analytics_posts(posts)
    service_user[UserService]
    service_post[PostService]
    service_comment[CommentService]
    service_analytics[AnalyticsService]
    service_follow[FollowService]

    model_user ==>|posts| model_post
    model_user ==>|comments| model_comment
    model_post -->|user| model_user
    model_post ==>|comments| model_comment
    model_comment -->|user| model_user
    model_comment -->|post| model_post
    route_users_index --> action_controller_users_index
    route_posts_index --> action_controller_posts_index
    route_analytics_users --> action_controller_analytics_users
    controller_users -.-> action_controller_users_index
    controller_posts -.-> action_controller_posts_index
    controller_analytics -.-> action_controller_analytics_users
    action_controller_users_index -->|fetch_active_users| service_user
    action_controller_posts_index -->|public_posts| service_post
    action_controller_analytics_users -->|user_stats| service_analytics
    service_user -->|User.active| model_user
    service_post -->|Post.published| model_post
    service_analytics -->|User.statistics| model_user
    service_analytics -->|Post.metrics| model_post

%% Styling
classDef model fill:#f9f,stroke:#333,stroke-width:2px;
classDef controller fill:#bbf,stroke:#333,stroke-width:2px;
classDef action fill:#bfb,stroke:#333,stroke-width:2px;
class model_user,model_post,model_comment,model_category,model_tag,model_like model;
class controller_users,controller_posts,controller_comments,controller_analytics controller;
class action_controller_users_index,action_controller_users_show,action_controller_users_create,action_controller_users_update,action_controller_posts_index,action_controller_posts_show,action_controller_posts_create,action_controller_posts_update,action_controller_comments_index,action_controller_comments_create,action_controller_analytics_users,action_controller_analytics_posts action;