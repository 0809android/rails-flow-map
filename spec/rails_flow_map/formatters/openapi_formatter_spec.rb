require 'spec_helper'

RSpec.describe RailsFlowMap::OpenapiFormatter do
  let(:graph) { RailsFlowMap::FlowGraph.new }
  let(:formatter) { described_class.new(graph) }

  before do
    # Create route nodes
    users_route = RailsFlowMap::FlowNode.new(
      id: 'route_users',
      name: 'GET /api/v1/users',
      type: :route,
      attributes: {
        path: '/api/v1/users',
        verb: 'GET',
        controller: 'api/v1/users',
        action: 'index'
      }
    )

    user_create_route = RailsFlowMap::FlowNode.new(
      id: 'route_users_create',
      name: 'POST /api/v1/users',
      type: :route,
      attributes: {
        path: '/api/v1/users',
        verb: 'POST',
        controller: 'api/v1/users',
        action: 'create'
      }
    )

    user_show_route = RailsFlowMap::FlowNode.new(
      id: 'route_user_show',
      name: 'GET /api/v1/users/:id',
      type: :route,
      attributes: {
        path: '/api/v1/users/:id',
        verb: 'GET',
        controller: 'api/v1/users',
        action: 'show'
      }
    )

    # Create action nodes
    index_action = RailsFlowMap::FlowNode.new(
      id: 'users_index',
      name: 'index',
      type: :action,
      attributes: { controller: 'Api::V1::UsersController' }
    )

    create_action = RailsFlowMap::FlowNode.new(
      id: 'users_create',
      name: 'create',
      type: :action,
      attributes: { controller: 'Api::V1::UsersController' }
    )

    # Create model nodes
    user_model = RailsFlowMap::FlowNode.new(
      id: 'user',
      name: 'User',
      type: :model,
      attributes: {
        associations: ['has_many :posts', 'has_many :comments']
      }
    )

    # Add nodes to graph
    [users_route, user_create_route, user_show_route, index_action, create_action, user_model].each do |node|
      graph.add_node(node)
    end

    # Add edges
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'route_users', to: 'users_index', type: :routes_to))
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'route_users_create', to: 'users_create', type: :routes_to))
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'users_index', to: 'user_service', type: :calls_service, label: 'fetch_users'))
  end

  describe '#initialize' do
    it 'initializes with default options' do
      expect(formatter.instance_variable_get(:@api_version)).to eq('1.0.0')
      expect(formatter.instance_variable_get(:@title)).to eq('Rails API Documentation')
    end

    it 'initializes with custom options' do
      options = {
        api_version: '2.0.0',
        title: 'Custom API',
        description: 'Custom description'
      }
      custom_formatter = described_class.new(graph, options)
      
      expect(custom_formatter.instance_variable_get(:@api_version)).to eq('2.0.0')
      expect(custom_formatter.instance_variable_get(:@title)).to eq('Custom API')
      expect(custom_formatter.instance_variable_get(:@description)).to eq('Custom description')
    end
  end

  describe '#format' do
    let(:yaml_output) { formatter.format }
    let(:parsed_spec) { YAML.load(yaml_output) }

    it 'generates valid YAML' do
      expect { YAML.load(yaml_output) }.not_to raise_error
    end

    it 'includes OpenAPI 3.0 specification' do
      expect(parsed_spec['openapi']).to eq('3.0.0')
    end

    it 'includes info section' do
      info = parsed_spec['info']
      expect(info['title']).to eq('Rails API Documentation')
      expect(info['version']).to eq('1.0.0')
      expect(info['description']).to include('Auto-generated')
    end

    it 'includes server definitions' do
      servers = parsed_spec['servers']
      expect(servers).to be_an(Array)
      expect(servers.size).to be >= 2
      expect(servers.first['url']).to eq('http://localhost:3000')
    end

    it 'generates paths from routes' do
      paths = parsed_spec['paths']
      expect(paths).to have_key('/api/v1/users')
      expect(paths).to have_key('/api/v1/users/{id}')
    end

    it 'generates operations for different HTTP methods' do
      users_path = parsed_spec['paths']['/api/v1/users']
      expect(users_path).to have_key('get')
      expect(users_path).to have_key('post')
    end

    it 'includes operation details' do
      get_operation = parsed_spec['paths']['/api/v1/users']['get']
      expect(get_operation['summary']).to include('List all')
      expect(get_operation['operationId']).to be_present
      expect(get_operation['tags']).to be_an(Array)
    end

    it 'includes path parameters' do
      show_operation = parsed_spec['paths']['/api/v1/users/{id}']['get']
      parameters = show_operation['parameters']
      
      id_param = parameters.find { |p| p['name'] == 'id' }
      expect(id_param).to be_present
      expect(id_param['in']).to eq('path')
      expect(id_param['required']).to be true
    end

    it 'includes query parameters for index operations' do
      get_operation = parsed_spec['paths']['/api/v1/users']['get']
      parameters = get_operation['parameters']
      
      param_names = parameters.map { |p| p['name'] }
      expect(param_names).to include('page', 'per_page', 'sort', 'order')
    end

    it 'includes response definitions' do
      get_operation = parsed_spec['paths']['/api/v1/users']['get']
      responses = get_operation['responses']
      
      expect(responses).to have_key('200')
      expect(responses).to have_key('401')
      expect(responses).to have_key('500')
    end

    it 'includes component schemas' do
      components = parsed_spec['components']
      expect(components).to have_key('schemas')
      
      schemas = components['schemas']
      expect(schemas).to have_key('User')
      expect(schemas).to have_key('UserInput')
      expect(schemas).to have_key('ValidationError')
    end

    it 'includes security schemes' do
      components = parsed_spec['components']
      security_schemes = components['securitySchemes']
      
      expect(security_schemes).to have_key('bearerAuth')
      expect(security_schemes).to have_key('apiKey')
    end

    context 'with custom options' do
      let(:custom_formatter) do
        described_class.new(graph, {
          api_version: '2.0.0',
          title: 'Custom API Title',
          description: 'Custom API Description'
        })
      end

      it 'uses custom configuration' do
        output = custom_formatter.format
        parsed = YAML.load(output)
        
        expect(parsed['info']['version']).to eq('2.0.0')
        expect(parsed['info']['title']).to eq('Custom API Title')
        expect(parsed['info']['description']).to eq('Custom API Description')
      end
    end
  end

  describe 'string manipulation helpers' do
    it 'camelizes strings correctly' do
      expect(formatter.send(:camelize, 'hello_world')).to eq('HelloWorld')
      expect(formatter.send(:camelize, 'api_v1_users')).to eq('ApiV1Users')
    end

    it 'singularizes strings correctly' do
      expect(formatter.send(:singularize, 'users')).to eq('user')
      expect(formatter.send(:singularize, 'posts')).to eq('post')
      expect(formatter.send(:singularize, 'categories')).to eq('category')
      expect(formatter.send(:singularize, 'boxes')).to eq('box')
    end

    it 'pluralizes strings correctly' do
      expect(formatter.send(:pluralize, 'user')).to eq('users')
      expect(formatter.send(:pluralize, 'post')).to eq('posts')
      expect(formatter.send(:pluralize, 'category')).to eq('categories')
      expect(formatter.send(:pluralize, 'box')).to eq('boxes')
    end

    it 'humanizes strings correctly' do
      expect(formatter.send(:humanize, 'hello_world')).to eq('Hello world')
      expect(formatter.send(:humanize, 'api_endpoint')).to eq('Api endpoint')
    end
  end

  describe 'edge index optimization' do
    it 'builds edge index for performance' do
      formatter.send(:generate_paths)
      index = formatter.instance_variable_get(:@edge_index)
      
      expect(index).to be_a(Hash)
      expect(index[['route_users', :routes_to]]).to be_an(Array)
    end

    it 'finds edges efficiently using index' do
      formatter.send(:generate_paths)
      
      # This should use the edge index instead of linear search
      route_node = graph.find_node('route_users')
      operation = formatter.send(:generate_operation, route_node)
      
      expect(operation).to be_a(Hash)
      expect(operation[:summary]).to be_present
    end
  end

  describe 'error handling' do
    context 'with missing route attributes' do
      before do
        incomplete_route = RailsFlowMap::FlowNode.new(
          id: 'incomplete',
          name: 'Incomplete Route',
          type: :route,
          attributes: {}
        )
        graph.add_node(incomplete_route)
      end

      it 'handles missing attributes gracefully' do
        expect { formatter.format }.not_to raise_error
      end
    end

    context 'with empty graph' do
      let(:empty_graph) { RailsFlowMap::FlowGraph.new }
      let(:formatter) { described_class.new(empty_graph) }

      it 'generates valid spec even with no routes' do
        output = formatter.format
        parsed = YAML.load(output)
        
        expect(parsed['openapi']).to eq('3.0.0')
        expect(parsed['paths']).to be_empty
      end
    end
  end

  describe 'model schema generation' do
    let(:parsed_spec) { YAML.load(formatter.format) }

    it 'generates schemas for known models' do
      user_schema = parsed_spec['components']['schemas']['User']
      
      expect(user_schema['type']).to eq('object')
      expect(user_schema['properties']).to have_key('id')
      expect(user_schema['properties']).to have_key('created_at')
      expect(user_schema['properties']).to have_key('updated_at')
    end

    it 'generates input schemas without readonly fields' do
      user_input_schema = parsed_spec['components']['schemas']['UserInput']
      
      expect(user_input_schema['properties']).not_to have_key('id')
      expect(user_input_schema['properties']).not_to have_key('created_at')
      expect(user_input_schema['properties']).not_to have_key('updated_at')
    end

    it 'includes model-specific properties' do
      user_schema = parsed_spec['components']['schemas']['User']
      
      expect(user_schema['properties']).to have_key('name')
      expect(user_schema['properties']).to have_key('email')
    end
  end
end