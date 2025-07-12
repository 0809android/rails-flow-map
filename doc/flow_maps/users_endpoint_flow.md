graph TD
    route_users_index[GET /api/v1/users]
    controller_users[[UsersController]]
    action_users_index(index)
    service_user[UserService]
    model_user[User]

    route_users_index --> action_users_index
    controller_users -.-> action_users_index
    action_users_index -->|fetch_users| service_user
    service_user -->|User.all| model_user

%% Styling
classDef model fill:#f9f,stroke:#333,stroke-width:2px;
classDef controller fill:#bbf,stroke:#333,stroke-width:2px;
classDef action fill:#bfb,stroke:#333,stroke-width:2px;
class model_user model;
class controller_users controller;
class action_users_index action;