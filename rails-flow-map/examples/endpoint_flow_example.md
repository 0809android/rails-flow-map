# エンドポイントフロー例: GET /api/users

この例は `GET /api/users` エンドポイントへのリクエストがどのように処理されるかを示しています。

## シーケンス図

```mermaid
sequenceDiagram
    participant Client
    participant Route
    participant Controller
    participant Action
    participant UserService
    participant User
    participant Response

    Client->>+Route: GET /api/users
    Route->>+Action: Execute index
    Action->>+UserService: Call service
    UserService-->>-Action: Return result
    Action->>+User: where
    User-->>-Action: Return data
    Action->>Response: render
    Action-->>-Route: Processing complete
    Route-->>-Client: HTTP Response
```

## リクエストフロー図

```mermaid
graph TD
    route_get_api_users[fa:fa-globe GET /api/users]
    controller_api_users[[fa:fa-cogs Api::UsersController]]
    action_api_users_index(fa:fa-play index)
    model_user[(fa:fa-database User)]
    service_user_service{fa:fa-wrench UserService}
    response_api_users_index_render[fa:fa-reply render]
    
    route_get_api_users ==>|routes to| action_api_users_index
    controller_api_users -.->|has action| action_api_users_index
    action_api_users_index ==>|calls service| service_user_service
    action_api_users_index -->|where| model_user
    action_api_users_index -->|responds with| response_api_users_index_render

%% Styling
classDef route fill:#FFE4E1,stroke:#FF6B6B,stroke-width:2px;
classDef controller fill:#E1F5FE,stroke:#29B6F6,stroke-width:2px;
classDef action fill:#E8F5E8,stroke:#66BB6A,stroke-width:2px;
classDef model fill:#F3E5F5,stroke:#AB47BC,stroke-width:2px;
classDef service fill:#FFF3E0,stroke:#FF9800,stroke-width:2px;
classDef response fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px;

class route_get_api_users route;
class controller_api_users controller;
class action_api_users_index action;
class model_user model;
class service_user_service service;
class response_api_users_index_render response;
```

## 詳細な処理フロー

1. **リクエスト受信**
   - クライアントから `GET /api/users` リクエストが送信される
   - Railsルーターがリクエストを受信

2. **ルーティング**
   - ルーターが `/api/users` パスを `Api::UsersController#index` にマッピング
   - コントローラーのインスタンスが作成される

3. **コントローラー処理**
   - `Api::UsersController` の `index` アクションが実行される
   - 必要に応じて認証・認可チェック

4. **サービス呼び出し**
   - `UserService` を呼び出してビジネスロジックを実行
   - データの変換や追加の処理を行う

5. **モデル操作**
   - `User` モデルに対してデータベースクエリを実行
   - `User.where(...)` などでデータを取得

6. **レスポンス生成**
   - 取得したデータをJSON形式でレンダリング
   - HTTPレスポンスとしてクライアントに送信

## コード例

```ruby
# routes.rb
Rails.application.routes.draw do
  namespace :api do
    resources :users, only: [:index]
  end
end

# app/controllers/api/users_controller.rb
class Api::UsersController < ApplicationController
  def index
    users = UserService.fetch_active_users
    render json: users
  end
end

# app/services/user_service.rb
class UserService
  def self.fetch_active_users
    User.where(active: true)
        .includes(:profile)
        .order(:created_at)
  end
end

# app/models/user.rb
class User < ApplicationRecord
  has_one :profile
  scope :active, -> { where(active: true) }
end
```

この図表により、特定のエンドポイントに対するリクエストがシステム内でどのように処理されるかが視覚的に理解できます。