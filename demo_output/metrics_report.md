# 📊 Rails Application Metrics Report
Generated at: 2025-07-12 20:34:53

============================================================

## 📈 Overview Statistics
- Total Nodes: 10
- Total Edges: 9
- Models: 3
- Controllers: 2
- Actions: 2
- Services: 1
- Routes: 2

## 🏆 Complexity Analysis

### Most Connected Models (by relationships)
1. User (connections: 3)
2. Post (connections: 2)
3. Comment (connections: 2)

### Most Complex Controllers (by actions)
1. UsersController (actions: 1)
2. PostsController (actions: 1)

## 🔗 Dependency Analysis

### Models with Most Dependencies
1. User
   - Outgoing: 0 ()
   - Incoming: 3 (belongs_to, accesses_model)
2. Post
   - Outgoing: 1 (belongs_to)
   - Incoming: 1 (belongs_to)
3. Comment
   - Outgoing: 2 (belongs_to)
   - Incoming: 0 ()

## 🛠️ Service Layer Analysis
- Total Services: 1
- Services per Controller: 0.5

### Most Used Services
1. UserService (used by 1 actions)

## ⚠️ Potential Issues

### ✅ No circular dependencies detected

### Potential God Objects (high connectivity)
- ✅ No god objects detected

## 💡 Recommendations