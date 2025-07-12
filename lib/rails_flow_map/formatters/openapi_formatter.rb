module RailsFlowMap
  # Generates OpenAPI 3.0 specification from Rails application routes
  #
  # This formatter analyzes Rails routes and generates a complete OpenAPI/Swagger
  # specification that can be used with tools like Swagger UI, Postman, or Insomnia.
  #
  # @example Basic usage
  #   formatter = OpenapiFormatter.new(graph)
  #   spec = formatter.format
  #   File.write('openapi.yaml', spec)
  #
  # @example With custom configuration
  #   formatter = OpenapiFormatter.new(graph, {
  #     api_version: '2.0.0',
  #     title: 'My API',
  #     description: 'Custom API documentation',
  #     servers: [{ url: 'https://api.myapp.com', description: 'Production' }]
  #   })
  #
  class OpenapiFormatter
      # Creates a new OpenAPI formatter instance
      #
      # @param graph [FlowGraph] The graph containing route information
      # @param options [Hash] Configuration options
      # @option options [String] :api_version The API version (default: '1.0.0')
      # @option options [String] :title The API title
      # @option options [String] :description The API description
      # @option options [Array<Hash>] :servers Custom server definitions
      def initialize(graph, options = {})
        @graph = graph
        @options = options
        @api_version = options[:api_version] || '1.0.0'
        @title = options[:title] || 'Rails API Documentation'
        @description = options[:description] || 'Auto-generated API documentation by RailsFlowMap'
      end

      # Generates the OpenAPI specification
      #
      # @param graph [FlowGraph] Optional graph to format (uses instance graph by default)
      # @return [String] OpenAPI 3.0 specification in YAML format
      def format(graph = @graph)
        {
          openapi: '3.0.0',
          info: generate_info,
          servers: generate_servers,
          paths: generate_paths,
          components: {
            schemas: generate_schemas,
            securitySchemes: generate_security_schemes
          }
        }.to_yaml
      end

      private

      def generate_info
        {
          title: @title,
          description: @description,
          version: @api_version,
          contact: {
            name: 'API Support',
            email: 'api@example.com'
          }
        }
      end

      def generate_servers
        [
          {
            url: 'http://localhost:3000',
            description: 'Development server'
          },
          {
            url: 'https://api.example.com',
            description: 'Production server'
          }
        ]
      end

      def generate_paths
        paths = {}
        
        # Build edge index for O(1) lookups
        @edge_index = build_edge_index
        
        # ルートノードから情報を収集
        route_nodes = @graph.nodes_by_type(:route)
        
        route_nodes.each do |route_node|
          path = route_node.attributes[:path]
          verb = route_node.attributes[:verb]&.downcase || 'get'
          
          # パスパラメータを OpenAPI 形式に変換
          openapi_path = path.gsub(/:(\w+)/, '{\1}')
          
          paths[openapi_path] ||= {}
          paths[openapi_path][verb] = generate_operation(route_node)
        end
        
        paths
      end
      
      def build_edge_index
        index = Hash.new { |h, k| h[k] = [] }
        @graph.edges.each do |edge|
          index[[edge.from, edge.type]] << edge
        end
        index
      end

      def generate_operation(route_node)
        # ルートに接続されているアクションを探す
        action_edge = @edge_index[[route_node.id, :routes_to]]&.first
        action_node = action_edge ? @graph.find_node(action_edge.to) : nil
        
        controller_name = extract_controller_name(route_node)
        action_name = action_node&.name || 'index'
        
        operation = {
          summary: generate_summary(controller_name, action_name),
          description: generate_description(route_node, action_node),
          operationId: "#{controller_name}_#{action_name}".gsub(/[^a-zA-Z0-9_]/, '_'),
          tags: [controller_name],
          parameters: generate_parameters(route_node),
          responses: generate_responses(route_node, action_node)
        }
        
        # POSTやPUTの場合はリクエストボディを追加
        if ['post', 'put', 'patch'].include?(route_node.attributes[:verb]&.downcase)
          operation[:requestBody] = generate_request_body(route_node, controller_name)
        end
        
        operation
      end

      def extract_controller_name(route_node)
        controller = route_node.attributes[:controller] || 'application'
        camelize(controller.split('/').last.gsub('_controller', ''))
      end

      def generate_summary(controller_name, action_name)
        case action_name
        when 'index'
          "List all #{pluralize(controller_name)}"
        when 'show'
          "Get a specific #{singularize(controller_name)}"
        when 'create'
          "Create a new #{singularize(controller_name)}"
        when 'update'
          "Update a #{singularize(controller_name)}"
        when 'destroy'
          "Delete a #{singularize(controller_name)}"
        else
          "#{humanize(action_name)} #{controller_name}"
        end
      end

      def generate_description(route_node, action_node)
        desc = "Endpoint: #{route_node.attributes[:verb]} #{route_node.attributes[:path]}\n"
        
        if action_node
          # アクションに接続されているサービスを探す
          service_edges = @graph.edges.select { |e| e.from == action_node.id && e.type == :calls_service }
          if service_edges.any?
            desc += "\nServices used:\n"
            service_edges.each do |edge|
              service_node = @graph.find_node(edge.to)
              desc += "- #{service_node.name}"
              desc += " (#{edge.label})" if edge.label
              desc += "\n"
            end
          end
        end
        
        desc
      end

      def generate_parameters(route_node)
        parameters = []
        path = route_node.attributes[:path]
        
        # パスパラメータを抽出
        path.scan(/:(\w+)/).each do |param|
          parameters << {
            name: param[0],
            in: 'path',
            required: true,
            description: "ID of the #{singularize(param[0])}",
            schema: {
              type: 'integer',
              format: 'int64'
            }
          }
        end
        
        # クエリパラメータを追加（index アクションの場合）
        if route_node.name.include?('index') || route_node.attributes[:action] == 'index'
          parameters.concat([
            {
              name: 'page',
              in: 'query',
              description: 'Page number for pagination',
              schema: {
                type: 'integer',
                default: 1
              }
            },
            {
              name: 'per_page',
              in: 'query',
              description: 'Number of items per page',
              schema: {
                type: 'integer',
                default: 20,
                maximum: 100
              }
            },
            {
              name: 'sort',
              in: 'query',
              description: 'Sort field',
              schema: {
                type: 'string',
                enum: ['created_at', 'updated_at', 'name']
              }
            },
            {
              name: 'order',
              in: 'query',
              description: 'Sort order',
              schema: {
                type: 'string',
                enum: ['asc', 'desc'],
                default: 'desc'
              }
            }
          ])
        end
        
        parameters
      end

      def generate_responses(route_node, action_node)
        responses = {}
        
        case route_node.attributes[:action] || action_node&.name
        when 'index'
          responses['200'] = {
            description: 'Successful response',
            content: {
              'application/json' => {
                schema: {
                  type: 'array',
                  items: {
                    '$ref' => "#/components/schemas/#{extract_model_name(route_node)}"
                  }
                }
              }
            }
          }
        when 'show'
          responses['200'] = {
            description: 'Successful response',
            content: {
              'application/json' => {
                schema: {
                  '$ref' => "#/components/schemas/#{extract_model_name(route_node)}"
                }
              }
            }
          }
          responses['404'] = {
            description: 'Resource not found'
          }
        when 'create'
          responses['201'] = {
            description: 'Resource created successfully',
            content: {
              'application/json' => {
                schema: {
                  '$ref' => "#/components/schemas/#{extract_model_name(route_node)}"
                }
              }
            }
          }
          responses['422'] = {
            description: 'Validation errors',
            content: {
              'application/json' => {
                schema: {
                  '$ref' => '#/components/schemas/ValidationError'
                }
              }
            }
          }
        when 'update'
          responses['200'] = {
            description: 'Resource updated successfully',
            content: {
              'application/json' => {
                schema: {
                  '$ref' => "#/components/schemas/#{extract_model_name(route_node)}"
                }
              }
            }
          }
          responses['404'] = {
            description: 'Resource not found'
          }
          responses['422'] = {
            description: 'Validation errors'
          }
        when 'destroy'
          responses['204'] = {
            description: 'Resource deleted successfully'
          }
          responses['404'] = {
            description: 'Resource not found'
          }
        else
          responses['200'] = {
            description: 'Successful response'
          }
        end
        
        # 共通のエラーレスポンス
        responses['401'] = {
          description: 'Unauthorized'
        }
        responses['500'] = {
          description: 'Internal server error'
        }
        
        responses
      end

      def generate_request_body(route_node, controller_name)
        model_name = extract_model_name(route_node)
        
        {
          required: true,
          content: {
            'application/json' => {
              schema: {
                type: 'object',
                properties: {
                  model_name.downcase => {
                    '$ref' => "#/components/schemas/#{model_name}Input"
                  }
                }
              }
            }
          }
        }
      end

      def extract_model_name(route_node)
        controller = route_node.attributes[:controller] || ''
        camelize(singularize(controller.split('/').last.gsub('_controller', '')))
      end

      def generate_schemas
        schemas = {}
        
        # モデルノードからスキーマを生成
        model_nodes = @graph.nodes_by_type(:model)
        
        model_nodes.each do |model|
          schemas[model.name] = generate_model_schema(model)
          schemas["#{model.name}Input"] = generate_input_schema(model)
        end
        
        # 共通スキーマ
        schemas['ValidationError'] = {
          type: 'object',
          properties: {
            errors: {
              type: 'object',
              additionalProperties: {
                type: 'array',
                items: {
                  type: 'string'
                }
              }
            }
          }
        }
        
        schemas['Pagination'] = {
          type: 'object',
          properties: {
            current_page: { type: 'integer' },
            total_pages: { type: 'integer' },
            total_count: { type: 'integer' },
            per_page: { type: 'integer' }
          }
        }
        
        schemas
      end

      def generate_model_schema(model)
        properties = {
          id: {
            type: 'integer',
            format: 'int64',
            readOnly: true
          },
          created_at: {
            type: 'string',
            format: 'date-time',
            readOnly: true
          },
          updated_at: {
            type: 'string',
            format: 'date-time',
            readOnly: true
          }
        }
        
        # モデルの関連から属性を推測
        if model.attributes[:associations]
          model.attributes[:associations].each do |assoc|
            if assoc.include?('belongs_to')
              foreign_key = assoc.split(' ').last.downcase + '_id'
              properties[foreign_key.to_sym] = {
                type: 'integer',
                format: 'int64',
                description: "Foreign key for #{assoc}"
              }
            end
          end
        end
        
        # モデル固有の属性を追加（推測）
        case model.name
        when 'User'
          properties.merge!({
            name: { type: 'string' },
            email: { type: 'string', format: 'email' },
            avatar_url: { type: 'string', format: 'uri', nullable: true }
          })
        when 'Post'
          properties.merge!({
            title: { type: 'string' },
            body: { type: 'string' },
            published: { type: 'boolean', default: false },
            published_at: { type: 'string', format: 'date-time', nullable: true }
          })
        when 'Comment'
          properties.merge!({
            body: { type: 'string' },
            approved: { type: 'boolean', default: true }
          })
        end
        
        {
          type: 'object',
          properties: properties,
          required: generate_required_fields(model)
        }
      end

      def generate_input_schema(model)
        schema = deep_dup(generate_model_schema(model))
        
        # 読み取り専用フィールドを削除
        schema[:properties].delete(:id)
        schema[:properties].delete(:created_at)
        schema[:properties].delete(:updated_at)
        
        # 入力時のみのフィールドを追加
        if model.name == 'User'
          schema[:properties][:password] = {
            type: 'string',
            format: 'password',
            minLength: 8
          }
          schema[:properties][:password_confirmation] = {
            type: 'string',
            format: 'password'
          }
        end
        
        schema
      end

      def generate_required_fields(model)
        case model.name
        when 'User'
          ['name', 'email']
        when 'Post'
          ['title', 'body']
        when 'Comment'
          ['body']
        else
          []
        end
      end

      def generate_security_schemes
        {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT'
          },
          apiKey: {
            type: 'apiKey',
            in: 'header',
            name: 'X-API-Key'
          }
        }
      end
      
      # String manipulation helpers (avoid monkey-patching)
      def camelize(str)
        str.to_s.split('_').map(&:capitalize).join
      end
      
      def singularize(str)
        str = str.to_s
        case str
        when /ies$/
          str.sub(/ies$/, 'y')
        when /ses$/, /xes$/, /zes$/, /ches$/, /shes$/
          str.sub(/es$/, '')
        when /s$/
          str.sub(/s$/, '')
        else
          str
        end
      end
      
      def pluralize(str)
        str = str.to_s
        case str
        when /y$/
          str.sub(/y$/, 'ies')
        when /s$/, /x$/, /z$/, /ch$/, /sh$/
          str + 'es'
        else
          str + 's'
        end
      end
      
      def humanize(str)
        str.to_s.gsub('_', ' ').capitalize
      end
      
      def deep_dup(hash)
        Marshal.load(Marshal.dump(hash))
      end
  end
end

