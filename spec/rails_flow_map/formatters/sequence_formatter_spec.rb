require 'spec_helper'

RSpec.describe RailsFlowMap::SequenceFormatter do
  let(:graph) { RailsFlowMap::FlowGraph.new }
  let(:formatter) { described_class.new(graph, endpoint: '/api/v1/users') }

  before do
    # Create route node
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

    # Create controller node
    users_controller = RailsFlowMap::FlowNode.new(
      id: 'users_controller',
      name: 'UsersController',
      type: :controller
    )

    # Create action node
    index_action = RailsFlowMap::FlowNode.new(
      id: 'users_index',
      name: 'index',
      type: :action,
      attributes: { controller: 'UsersController' }
    )

    # Create service node
    user_service = RailsFlowMap::FlowNode.new(
      id: 'user_service',
      name: 'UserService',
      type: :service
    )

    # Create model node
    user_model = RailsFlowMap::FlowNode.new(
      id: 'user',
      name: 'User',
      type: :model,
      attributes: { associations: ['has_many :posts'] }
    )

    # Add nodes to graph
    [users_route, users_controller, index_action, user_service, user_model].each do |node|
      graph.add_node(node)
    end

    # Add edges
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'route_users', to: 'users_index', type: :routes_to))
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'users_controller', to: 'users_index', type: :has_action))
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'users_index', to: 'user_service', type: :calls_service, label: 'fetch_active_users'))
    graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'user_service', to: 'user', type: :accesses_model, label: 'User.active'))
  end

  describe '#initialize' do
    it 'initializes with default options' do
      formatter = described_class.new(graph)
      
      expect(formatter.instance_variable_get(:@graph)).to eq(graph)
      expect(formatter.instance_variable_get(:@endpoint)).to be_nil
      expect(formatter.instance_variable_get(:@include_middleware)).to be false
      expect(formatter.instance_variable_get(:@include_callbacks)).to be false
      expect(formatter.instance_variable_get(:@include_validations)).to be false
      expect(formatter.instance_variable_get(:@include_database)).to be true
    end

    it 'initializes with custom options' do
      options = {
        endpoint: '/api/users',
        include_middleware: true,
        include_callbacks: true,
        include_validations: true,
        include_database: false
      }
      formatter = described_class.new(graph, options)
      
      expect(formatter.instance_variable_get(:@endpoint)).to eq('/api/users')
      expect(formatter.instance_variable_get(:@include_middleware)).to be true
      expect(formatter.instance_variable_get(:@include_callbacks)).to be true
      expect(formatter.instance_variable_get(:@include_validations)).to be true
      expect(formatter.instance_variable_get(:@include_database)).to be false
    end
  end

  describe '#format' do
    let(:sequence_output) { formatter.format }

    it 'generates mermaid sequence diagram' do
      expect(sequence_output).to include('```mermaid')
      expect(sequence_output).to include('sequenceDiagram')
      expect(sequence_output).to include('autonumber')
      expect(sequence_output).to include('```')
    end

    it 'includes participants' do
      expect(sequence_output).to include('participant Client')
      expect(sequence_output).to include('participant Router')
      expect(sequence_output).to include('participant UsersController')
      expect(sequence_output).to include('participant UserService')
      expect(sequence_output).to include('participant User')
    end

    it 'includes database participant when enabled' do
      expect(sequence_output).to include('participant Database')
    end

    it 'includes request flow' do
      expect(sequence_output).to include('Client->>+Router: GET /api/v1/users')
      expect(sequence_output).to include('Router->>+UsersController: index(params)')
    end

    it 'includes service calls' do
      expect(sequence_output).to include('UsersController->>+UserService: fetch_active_users(params)')
      expect(sequence_output).to include('UserService-->>-UsersController: ServiceResult')
    end

    it 'includes model access' do
      expect(sequence_output).to include('UserService->>+User: User.active')
      expect(sequence_output).to include('User-->>-UserService: [User objects]')
    end

    it 'includes database queries when enabled' do
      expect(sequence_output).to include('User->>+Database: SQL Query')
      expect(sequence_output).to include('Database-->>-User: ResultSet')
    end

    it 'includes response codes' do
      expect(sequence_output).to include('200 OK')
    end

    context 'without database access' do
      let(:formatter) do
        described_class.new(graph, {
          endpoint: '/api/v1/users',
          include_database: false
        })
      end

      it 'excludes database participant' do
        output = formatter.format
        expect(output).not_to include('participant Database')
        expect(output).not_to include('Database-->>-User: ResultSet')
      end

      it 'includes model processing note' do
        output = formatter.format
        expect(output).to include('Note over User: Database query')
      end
    end

    context 'with middleware enabled' do
      let(:formatter) do
        described_class.new(graph, {
          endpoint: '/api/v1/users',
          include_middleware: true
        })
      end

      it 'includes middleware participant' do
        output = formatter.format
        expect(output).to include('participant Middleware')
      end

      it 'includes middleware processing' do
        output = formatter.format
        expect(output).to include('Router->>Middleware: Process request')
        expect(output).to include('Note right of Middleware: Authentication<br/>CORS<br/>Rate limiting')
        expect(output).to include('Middleware->>Router: Continue')
      end
    end

    context 'with callbacks enabled' do
      let(:formatter) do
        described_class.new(graph, {
          endpoint: '/api/v1/users',
          include_callbacks: true
        })
      end

      it 'includes callback processing' do
        output = formatter.format
        expect(output).to include('Note over UsersController: before_action callbacks')
        expect(output).to include('Note over UsersController: after_action callbacks')
      end
    end

    context 'with validations enabled for create action' do
      before do
        # Add create route and action
        create_route = RailsFlowMap::FlowNode.new(
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

        create_action = RailsFlowMap::FlowNode.new(
          id: 'users_create',
          name: 'create',
          type: :action,
          attributes: { controller: 'UsersController' }
        )

        graph.add_node(create_route)
        graph.add_node(create_action)
        graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'route_users_create', to: 'users_create', type: :routes_to))
      end

      let(:formatter) do
        described_class.new(graph, {
          endpoint: '/api/v1/users',
          include_validations: true
        })
      end

      it 'includes validation steps for create/update actions' do
        output = formatter.format
        expect(output).to include('validate_params')
        expect(output).to include('alt Invalid parameters')
        expect(output).to include('422 Unprocessable Entity')
      end
    end
  end

  describe 'participant definition' do
    let(:participants) { formatter.send(:define_participants, graph) }

    it 'includes basic participants' do
      expect(participants).to include('    participant Client')
      expect(participants).to include('    participant Router')
    end

    it 'includes controllers from graph' do
      expect(participants).to include('    participant UsersController')
    end

    it 'includes services from graph' do
      expect(participants).to include('    participant UserService')
    end

    it 'includes models from graph' do
      expect(participants).to include('    participant User')
    end

    it 'sanitizes participant names' do
      # Add node with special characters
      special_node = RailsFlowMap::FlowNode.new(
        id: 'special',
        name: 'Special-Controller@#',
        type: :controller
      )
      graph.add_node(special_node)

      participants = formatter.send(:define_participants, graph)
      expect(participants.join(' ')).to include('Special_Controller_')
    end
  end

  describe 'route filtering' do
    context 'with specific endpoint' do
      let(:filtered_routes) { formatter.send(:filter_route_nodes, graph) }

      it 'filters routes by endpoint' do
        expect(filtered_routes.size).to eq(1)
        expect(filtered_routes.first.attributes[:path]).to eq('/api/v1/users')
      end
    end

    context 'without endpoint filter' do
      let(:formatter) { described_class.new(graph) }
      let(:filtered_routes) { formatter.send(:filter_route_nodes, graph) }

      it 'returns all routes' do
        expect(filtered_routes.size).to eq(1)
      end
    end

    context 'with parameterized routes' do
      before do
        show_route = RailsFlowMap::FlowNode.new(
          id: 'route_user_show',
          name: 'GET /api/v1/users/:id',
          type: :route,
          attributes: {
            path: '/api/v1/users/:id',
            verb: 'GET'
          }
        )
        graph.add_node(show_route)
      end

      it 'matches parameterized routes' do
        formatter = described_class.new(graph, endpoint: '/api/v1/users/123')
        filtered_routes = formatter.send(:filter_route_nodes, graph)
        
        expect(filtered_routes.size).to eq(1)
        expect(filtered_routes.first.attributes[:path]).to eq('/api/v1/users/:id')
      end
    end
  end

  describe 'response code generation' do
    it 'generates appropriate response codes for different actions' do
      expect(formatter.send(:generate_response_code, 'index')).to eq('200 OK')
      expect(formatter.send(:generate_response_code, 'show')).to eq('200 OK')
      expect(formatter.send(:generate_response_code, 'create')).to eq('201 Created')
      expect(formatter.send(:generate_response_code, 'update')).to eq('200 OK')
      expect(formatter.send(:generate_response_code, 'destroy')).to eq('204 No Content')
      expect(formatter.send(:generate_response_code, 'custom')).to eq('200 OK')
    end
  end

  describe 'name sanitization' do
    it 'sanitizes names for Mermaid compatibility' do
      expect(formatter.send(:sanitize_name, 'hello-world@#')).to eq('hello_world')
      expect(formatter.send(:sanitize_name, 'API::V1::Controller')).to eq('API_V1_Controller')
      expect(formatter.send(:sanitize_name, '___hello___')).to eq('hello')
    end

    it 'handles empty names gracefully' do
      result = formatter.send(:sanitize_name, '@#$%')
      expect(result).to match(/node_\d+/)
      expect(result).not_to be_empty
    end

    it 'handles nil names gracefully' do
      result = formatter.send(:sanitize_name, nil)
      expect(result).to match(/node_\d+/)
      expect(result).not_to be_empty
    end
  end

  describe 'error handling' do
    context 'with empty graph' do
      let(:empty_graph) { RailsFlowMap::FlowGraph.new }
      let(:formatter) { described_class.new(empty_graph, endpoint: '/api/users') }

      it 'handles empty graph gracefully' do
        output = formatter.format
        
        expect(output).to include('```mermaid')
        expect(output).to include('sequenceDiagram')
        expect(output).to include('No routes found for endpoint: /api/users')
      end
    end

    context 'with missing edges' do
      before do
        # Remove all edges to test missing connections
        graph.edges.clear
      end

      it 'handles missing edges gracefully' do
        expect { formatter.format }.not_to raise_error
        
        output = formatter.format
        expect(output).to include('```mermaid')
        expect(output).to include('sequenceDiagram')
      end
    end

    context 'with missing nodes' do
      before do
        # Add edge pointing to non-existent node
        bad_edge = RailsFlowMap::FlowEdge.new(
          from: 'users_index',
          to: 'non_existent',
          type: :calls_service
        )
        graph.add_edge(bad_edge)
      end

      it 'handles missing nodes gracefully' do
        expect { formatter.format }.not_to raise_error
      end
    end
  end

  describe 'service and model call generation' do
    let(:action_node) { graph.find_node('users_index') }
    let(:controller_name) { 'UsersController' }
    let(:service_calls) { formatter.send(:generate_service_calls, action_node, controller_name, graph) }

    it 'generates service call sequences' do
      expect(service_calls).to include('UsersController->>+UserService: fetch_active_users(params)')
      expect(service_calls).to include('UserService-->>-UsersController: ServiceResult')
    end

    it 'includes error handling' do
      expect(service_calls).to include('alt Service error')
      expect(service_calls).to include('500 Internal Server Error')
      expect(service_calls).to include('else Success')
      expect(service_calls).to include('end')
    end

    context 'with model access' do
      let(:service_node) { graph.find_node('user_service') }
      let(:service_name) { 'UserService' }
      let(:model_calls) { formatter.send(:generate_model_access, service_node, service_name, graph) }

      it 'generates model access sequences' do
        expect(model_calls).to include('UserService->>+User: User.active')
        expect(model_calls).to include('User-->>-UserService: [User objects]')
      end

      it 'includes database queries when enabled' do
        expect(model_calls).to include('User->>+Database: SQL Query')
        expect(model_calls).to include('Database-->>-User: ResultSet')
      end

      it 'includes N+1 prevention note' do
        expect(model_calls).to include('Note over UserService: Load associations (N+1 prevention)')
      end
    end
  end
end