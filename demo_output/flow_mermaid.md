graph TD
    user[User]
    post[Post]
    comment[Comment]
    users_controller[[UsersController]]
    posts_controller[[PostsController]]
    users_index(index)
    posts_create(create)
    user_service[UserService]
    route_users[GET /api/v1/users]
    route_posts[POST /api/v1/posts]

    post --> user
    comment --> user
    comment --> post
    users_controller -.-> users_index
    posts_controller -.-> posts_create
    users_index -->|fetch_active_users| user_service
    user_service -->|User.active| user
    route_users --> users_index
    route_posts --> posts_create

%% Styling
classDef model fill:#f9f,stroke:#333,stroke-width:2px;
classDef controller fill:#bbf,stroke:#333,stroke-width:2px;
classDef action fill:#bfb,stroke:#333,stroke-width:2px;
class user,post,comment model;
class users_controller,posts_controller controller;
class users_index,posts_create action;