graph TD
    route_users_index[GET /api/v1/users]
    controller_users[[Api::V1::UsersController]]
    action_controller_users_index(index)
    service_user[UserService]
    model_user[User]

    route_users_index --> action_controller_users_index
    controller_users -.-> action_controller_users_index
    action_controller_users_index -->|fetch_active_users| service_user
    service_user -->|User.active| model_user

%% Styling
classDef model fill:#f9f,stroke:#333,stroke-width:2px;
classDef controller fill:#bbf,stroke:#333,stroke-width:2px;
classDef action fill:#bfb,stroke:#333,stroke-width:2px;
class model_user model;
class controller_users controller;
class action_controller_users_index action;