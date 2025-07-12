graph TD
    model_user[User]
    model_post[Post]
    model_comment[Comment]
    route_users_index[GET /api/v1/users]
    route_posts_index[GET /api/v1/posts]
    controller_users[[UsersController]]
    action_users_index(index)
    controller_posts[[PostsController]]
    action_posts_index(index)
    service_user[UserService]
    service_post[PostService]

    model_user ==>|posts| model_post
    model_user ==>|comments| model_comment
    model_post -->|user| model_user
    model_post ==>|comments| model_comment
    model_comment -->|user| model_user
    model_comment -->|post| model_post
    route_users_index --> action_users_index
    route_posts_index --> action_posts_index
    controller_users -.-> action_users_index
    controller_posts -.-> action_posts_index
    action_users_index -->|fetch_users| service_user
    action_posts_index -->|list_posts| service_post
    service_user -->|User.all| model_user
    service_post -->|Post.published| model_post
    service_post -->|includes(:user)| model_user

%% Styling
classDef model fill:#f9f,stroke:#333,stroke-width:2px;
classDef controller fill:#bbf,stroke:#333,stroke-width:2px;
classDef action fill:#bfb,stroke:#333,stroke-width:2px;
class model_user,model_post,model_comment model;
class controller_users,controller_posts controller;
class action_users_index,action_posts_index action;