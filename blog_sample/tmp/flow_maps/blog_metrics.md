# 📊 Rails Application Metrics Report
Generated at: 2025-07-12 21:15:13

============================================================

## 📈 Overview Statistics
- Total Nodes: 14
- Total Edges: 13
- Models: 6
- Controllers: 3
- Actions: 0
- Services: 3
- Routes: 2

## 🏆 Complexity Analysis

### Most Connected Models (by relationships)
1. User (connections: 4)
2. Post (connections: 4)
3. Comment (connections: 3)
4. Like (connections: 2)
5. Category (connections: 0)

### Most Complex Controllers (by actions)
1. Api::V1::UsersController (actions: 0)
2. Api::V1::PostsController (actions: 0)
3. Api::V1::CommentsController (actions: 0)

## 🔗 Dependency Analysis

### Models with Most Dependencies
1. User
   - Outgoing: 0 ()
   - Incoming: 4 (belongs_to, uses_model)
2. Post
   - Outgoing: 1 (belongs_to)
   - Incoming: 3 (belongs_to, uses_model)
3. Comment
   - Outgoing: 2 (belongs_to)
   - Incoming: 1 (uses_model)
4. Like
   - Outgoing: 2 (belongs_to)
   - Incoming: 0 ()
5. Category
   - Outgoing: 0 ()
   - Incoming: 0 ()

## 🛠️ Service Layer Analysis
- Total Services: 3
- Services per Controller: 1.0

### Most Used Services
1. UserService (used by 0 actions)
2. PostService (used by 0 actions)
3. CommentService (used by 0 actions)

## ⚠️ Potential Issues

### ✅ No circular dependencies detected

### Potential God Objects (high connectivity)
- ✅ No god objects detected

## 💡 Recommendations