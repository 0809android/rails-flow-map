```mermaid
graph TD
    subgraph Legend
        Added[Added - Green]:::added
        Removed[Removed - Red]:::removed
        Modified[Modified - Yellow]:::modified
    end

    User[User]
    Post[Post]
    Comment[Comment]
    UsersController[[UsersController]]
    PostsController[[PostsController]]
    index(index)
    create(create)
    UserService[UserService]
    GET /api/v1/users[GET /api/v1/users]
    POST /api/v1/posts[POST /api/v1/posts]
    PostService[PostService]

    post --> user
    comment --> user
    comment --> post
    users_controller --> users_index
    posts_controller --> posts_create
    users_index -->|fetch_active_users| user_service
    user_service -->|User.active| user
    route_users --> users_index
    route_posts --> posts_create
    posts_create --> post_service

    classDef added fill:#90EE90,stroke:#006400,stroke-width:3px;
    classDef removed fill:#FFB6C1,stroke:#8B0000,stroke-width:3px,stroke-dasharray: 5 5;
    classDef modified fill:#FFFFE0,stroke:#FFD700,stroke-width:3px;
```

## 変更サマリー

### 📊 メトリクス変化
- ノード数: 11 → 11 (+0)
- エッジ数: 10 → 10 (+0)
- 複雑度: 31 → 31 (+0 / 0.0%)