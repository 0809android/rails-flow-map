# 📊 Rails Application Metrics Report
Generated at: 2025-07-12 19:40:35

============================================================

## 📈 Overview Statistics
- Total Nodes: 13
- Total Edges: 17
- Models: 3
- Controllers: 1
- Actions: 8
- Services: 1
- Routes: 0

## 🏆 Complexity Analysis

### Most Connected Models (by relationships)
1. User (connections: 5)
2. Post (connections: 4)
3. Comment (connections: 4)

### Most Complex Controllers (by actions)
1. UsersController (actions: 8)

## 🔗 Dependency Analysis

### Models with Most Dependencies
1. User
   - Outgoing: 2 (has_many)
   - Incoming: 3 (belongs_to, accesses_model)
2. Post
   - Outgoing: 2 (belongs_to, has_many)
   - Incoming: 2 (has_many, belongs_to)
3. Comment
   - Outgoing: 2 (belongs_to)
   - Incoming: 2 (has_many)

## 🛠️ Service Layer Analysis
- Total Services: 1
- Services per Controller: 1.0

### Most Used Services
1. UserService (used by 2 actions)

## ⚠️ Potential Issues

### Circular Dependencies Detected: 1
- User → Post

### Potential God Objects (high connectivity)
- ✅ No god objects detected

## 💡 Recommendations
- These controllers have too many actions: UsersController
  Consider splitting into multiple controllers or using namespaces