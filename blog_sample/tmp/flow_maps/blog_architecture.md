graph TD
    user[User]
    post[Post]
    comment[Comment]
    category[Category]
    tag[Tag]
    like[Like]
    users_controller[[Api::V1::UsersController]]
    posts_controller[[Api::V1::PostsController]]
    comments_controller[[Api::V1::CommentsController]]
    user_service[UserService]
    post_service[PostService]
    comment_service[CommentService]
    users_index_route[GET /api/v1/users]
    posts_index_route[GET /api/v1/posts]

    post --> user
    comment --> user
    comment --> post
    like --> user
    like --> post
    users_controller --> user
    posts_controller --> post
    comments_controller --> comment
    users_controller --> user_service
    posts_controller --> post_service
    comments_controller --> comment_service
    users_index_route --> users_controller
    posts_index_route --> posts_controller

%% Styling
classDef model fill:#f9f,stroke:#333,stroke-width:2px;
classDef controller fill:#bbf,stroke:#333,stroke-width:2px;
classDef action fill:#bfb,stroke:#333,stroke-width:2px;
class user,post,comment,category,tag,like model;
class users_controller,posts_controller,comments_controller controller;