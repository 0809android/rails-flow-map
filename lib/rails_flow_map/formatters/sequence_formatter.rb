module RailsFlowMap
  class SequenceFormatter
      def initialize(graph, options = {})
        @graph = graph
        @endpoint = options[:endpoint]
        @include_middleware = options[:include_middleware] || false
        @include_callbacks = options[:include_callbacks] || false
        @include_validations = options[:include_validations] || false
        @include_database = options[:include_database] || true
      end

      def format(graph = @graph)
        output = []
        output << "```mermaid"
        output << "sequenceDiagram"
        output << "    autonumber"
        
        # 参加者の定義
        output.concat(define_participants(graph))
        
        # エンドポイントに関連するノードを取得
        route_nodes = filter_route_nodes(graph)
        
        if route_nodes.empty?
          output << "    Note over Client: No routes found for endpoint: #{@endpoint}"
        else
          route_nodes.each do |route|
            output << ""
            output << "    Note over Client: === #{route.attributes[:verb]} #{route.attributes[:path]} ==="
            output.concat(generate_sequence_for_route(route, graph))
          end
        end
        
        output << "```"
        output.join("\n")
      end

      private

      def define_participants(graph)
        participants = ["    participant Client", "    participant Router"]
        
        if @include_middleware
          participants << "    participant Middleware"
        end
        
        # コントローラーの追加
        controllers = graph.nodes_by_type(:controller).map(&:name).uniq
        controllers.each do |controller|
          participants << "    participant #{sanitize_name(controller)}"
        end
        
        # サービスの追加
        services = graph.nodes_by_type(:service).map(&:name).uniq
        services.each do |service|
          participants << "    participant #{sanitize_name(service)}"
        end
        
        # モデルの追加
        models = graph.nodes_by_type(:model).map(&:name).uniq
        models.each do |model|
          participants << "    participant #{sanitize_name(model)}"
        end
        
        if @include_database
          participants << "    participant Database"
        end
        
        participants
      end

      def filter_route_nodes(graph)
        route_nodes = graph.nodes_by_type(:route)
        
        if @endpoint
          # エンドポイントの正確なマッチング
          route_nodes = route_nodes.select do |node|
            path = node.attributes[:path]
            path == @endpoint || path&.gsub(/:[\w_]+/, '*') == @endpoint.gsub(/\d+/, '*')
          end
        end
        
        route_nodes
      end

      def generate_sequence_for_route(route, graph)
        lines = []
        
        # ミドルウェア処理
        if @include_middleware
          lines << "    Client->>Router: #{route.attributes[:verb]} #{route.attributes[:path]}"
          lines << "    Router->>Middleware: Process request"
          lines << "    activate Middleware"
          lines << "    Note right of Middleware: Authentication<br/>CORS<br/>Rate limiting"
          lines << "    Middleware->>Router: Continue"
          lines << "    deactivate Middleware"
        else
          lines << "    Client->>+Router: #{route.attributes[:verb]} #{route.attributes[:path]}"
        end
        
        # ルートからアクションへの処理
        route_edges = graph.edges.select { |e| e.from == route.id && e.type == :routes_to }
        
        route_edges.each do |edge|
          action = graph.find_node(edge.to)
          next unless action
          
          controller_name = sanitize_name(action.attributes[:controller] || "Controller")
          
          # コントローラーアクションの開始
          lines << "    Router->>+#{controller_name}: #{action.name}(params)"
          
          # コールバック処理
          if @include_callbacks
            lines << "    activate #{controller_name}"
            lines << "    Note over #{controller_name}: before_action callbacks"
          end
          
          # バリデーション
          if @include_validations && ['create', 'update'].include?(action.name)
            lines << "    #{controller_name}->>#{controller_name}: validate_params"
            lines << "    alt Invalid parameters"
            lines << "        #{controller_name}-->>Client: 422 Unprocessable Entity"
            lines << "    else Valid parameters"
          end
          
          # サービス呼び出し
          lines.concat(generate_service_calls(action, controller_name, graph))
          
          # バリデーションの終了
          if @include_validations && ['create', 'update'].include?(action.name)
            lines << "    end"
          end
          
          # レスポンスの生成
          lines << "    #{controller_name}->>#{controller_name}: render_response"
          
          # コールバック処理の終了
          if @include_callbacks
            lines << "    Note over #{controller_name}: after_action callbacks"
            lines << "    deactivate #{controller_name}"
          end
          
          # クライアントへのレスポンス
          lines << "    #{controller_name}-->>-Router: Response data"
          lines << "    Router-->>-Client: #{generate_response_code(action.name)} {data}"
        end
        
        lines
      end

      def generate_service_calls(action, controller_name, graph)
        lines = []
        
        # アクションからサービスへの呼び出し
        service_edges = graph.edges.select { |e| e.from == action.id && e.type == :calls_service }
        
        service_edges.each_with_index do |service_edge, index|
          service = graph.find_node(service_edge.to)
          next unless service
          
          service_name = sanitize_name(service.name)
          method_name = service_edge.label || "process"
          
          # サービスメソッドの呼び出し
          lines << "    #{controller_name}->>+#{service_name}: #{method_name}(params)"
          
          # サービス内の処理
          lines << "    activate #{service_name}"
          lines << "    Note over #{service_name}: Business logic"
          
          # モデルアクセス
          lines.concat(generate_model_access(service, service_name, graph))
          
          # サービスからのレスポンス
          lines << "    deactivate #{service_name}"
          lines << "    #{service_name}-->>-#{controller_name}: ServiceResult"
          
          # エラーハンドリング
          if index == 0  # 最初のサービス呼び出しのみ
            lines << "    alt Service error"
            lines << "        #{controller_name}-->>Client: 500 Internal Server Error"
            lines << "    else Success"
          end
        end
        
        # エラーハンドリングの終了
        if service_edges.any?
          lines << "    end"
        end
        
        lines
      end

      def generate_model_access(service, service_name, graph)
        lines = []
        
        # サービスからモデルへのアクセス
        model_edges = graph.edges.select { |e| e.from == service.id && e.type == :accesses_model }
        
        model_edges.each do |model_edge|
          model = graph.find_node(model_edge.to)
          next unless model
          
          model_name = sanitize_name(model.name)
          query = model_edge.label || "query"
          
          # モデルへのクエリ
          lines << "    #{service_name}->>+#{model_name}: #{query}"
          
          # データベースアクセス
          if @include_database
            lines << "    #{model_name}->>+Database: SQL Query"
            lines << "    Note right of Database: SELECT * FROM #{model_name.downcase}s<br/>WHERE ..."
            lines << "    Database-->>-#{model_name}: ResultSet"
          else
            lines << "    activate #{model_name}"
            lines << "    Note over #{model_name}: Database query"
            lines << "    deactivate #{model_name}"
          end
          
          # モデルからの結果
          lines << "    #{model_name}-->>-#{service_name}: [#{model_name} objects]"
        end
        
        # 関連モデルの読み込み
        if model_edges.any? && @include_database
          lines << "    Note over #{service_name}: Load associations (N+1 prevention)"
        end
        
        lines
      end

      def generate_response_code(action_name)
        case action_name
        when 'index', 'show'
          '200 OK'
        when 'create'
          '201 Created'
        when 'update'
          '200 OK'
        when 'destroy'
          '204 No Content'
        else
          '200 OK'
        end
      end

      def sanitize_name(name)
        # Mermaidで使用できない文字を置換
        sanitized = name.to_s.gsub(/[^a-zA-Z0-9_]/, '_').gsub(/^_+|_+$/, '')
        # 空文字列になった場合はデフォルト値を返す
        sanitized.empty? ? "node_#{name.hash.abs}" : sanitized
      end
  end
end