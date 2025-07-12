require 'parser/current'

module RailsFlowMap
  class RequestFlowAnalyzer
    def initialize(graph)
      @graph = graph
    end

    def analyze
      unless defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        return
      end

      controller_files.each do |file|
        analyze_controller_flow(file)
      end
    end

    private

    def controller_files
      return [] unless defined?(Rails) && Rails.root
      Dir.glob(Rails.root.join('app', 'controllers', '**', '*.rb'))
    end

    def analyze_controller_flow(file)
      content = File.read(file)
      ast = Parser::CurrentRuby.parse(content)
      return unless ast

      RequestFlowVisitor.new(@graph, file).process(ast)
    rescue Parser::SyntaxError => e
      Rails.logger.warn "Failed to parse #{file}: #{e.message}"
    end

    class RequestFlowVisitor < Parser::AST::Processor
      def initialize(graph, file_path)
        @graph = graph
        @file_path = file_path
        @current_controller = nil
        @current_action = nil
      end

      def on_class(node)
        class_name_node, superclass_node, body_node = *node
        class_name = extract_class_name(class_name_node)
        
        if class_name && is_controller?(class_name, superclass_node)
          @current_controller = class_name
        end

        super
      ensure
        @current_controller = nil
      end

      def on_def(node)
        return unless @current_controller

        method_name = node.children[0].to_s
        
        if action_method?(method_name)
          @current_action = method_name
          analyze_action_body(node)
        end

        super
      ensure
        @current_action = nil
      end

      def on_send(node)
        return unless @current_controller && @current_action

        receiver, method_name, *args = *node
        
        # Track model interactions
        if model_method?(method_name)
          track_model_interaction(method_name, args, node)
        end
        
        # Track service calls
        if service_call?(node)
          track_service_call(node)
        end
        
        # Track render/redirect calls
        if response_method?(method_name)
          track_response_call(method_name, args, node)
        end

        super
      end

      private

      def extract_class_name(node)
        case node.type
        when :const
          node.children[1].to_s
        when :module
          const_node = node.children.first
          const_node.children[1].to_s if const_node.type == :const
        end
      end

      def is_controller?(class_name, superclass_node)
        return false unless class_name.end_with?('Controller')
        return true if superclass_node.nil?
        
        if superclass_node.type == :const
          const_name = superclass_node.children[1].to_s
          ['ApplicationController', 'ActionController::Base', 'ActionController::API'].include?(const_name)
        else
          false
        end
      end

      def action_method?(method_name)
        !%w[initialize before_action after_action around_action].include?(method_name) &&
          !method_name.start_with?('_')
      end

      def model_method?(method_name)
        %w[find find_by find_by! where create create! update update! destroy delete 
           all first last pluck count exists? includes joins left_joins].include?(method_name.to_s)
      end

      def service_call?(node)
        receiver, method_name, *args = *node
        
        # Check if it's calling a service class (ends with Service)
        if receiver && receiver.type == :const
          class_name = receiver.children[1].to_s
          class_name.end_with?('Service')
        else
          false
        end
      end

      def response_method?(method_name)
        %w[render redirect_to head respond_to respond_with].include?(method_name.to_s)
      end

      def track_model_interaction(method_name, args, node)
        action_id = "action_#{@current_controller.underscore}_#{@current_action}"
        
        # Try to determine the model being accessed
        model_name = infer_model_from_context(node)
        return unless model_name

        model_id = "model_#{model_name.underscore}"
        
        # Create model interaction edge
        edge = FlowEdge.new(
          from: action_id,
          to: model_id,
          type: :accesses_model,
          label: method_name.to_s,
          attributes: {
            method: method_name,
            line_number: node.loc.line
          }
        )
        
        @graph.add_edge(edge)
      end

      def track_service_call(node)
        receiver, method_name, *args = *node
        action_id = "action_#{@current_controller.underscore}_#{@current_action}"
        
        service_class = receiver.children[1].to_s
        service_id = "service_#{service_class.underscore}"
        
        # Create service node if it doesn't exist
        unless @graph.find_node(service_id)
          service_node = FlowNode.new(
            id: service_id,
            name: service_class,
            type: :service
          )
          @graph.add_node(service_node)
        end
        
        # Create service call edge
        edge = FlowEdge.new(
          from: action_id,
          to: service_id,
          type: :calls_service,
          label: method_name.to_s
        )
        
        @graph.add_edge(edge)
      end

      def track_response_call(method_name, args, node)
        action_id = "action_#{@current_controller.underscore}_#{@current_action}"
        response_id = "response_#{@current_controller.underscore}_#{@current_action}_#{method_name}"
        
        # Create response node
        response_node = FlowNode.new(
          id: response_id,
          name: method_name.to_s,
          type: :response,
          attributes: {
            method: method_name,
            line_number: node.loc.line
          }
        )
        
        @graph.add_node(response_node)
        
        # Create response edge
        edge = FlowEdge.new(
          from: action_id,
          to: response_id,
          type: :responds_with,
          label: method_name.to_s
        )
        
        @graph.add_edge(edge)
      end

      def infer_model_from_context(node)
        # Try to infer model from receiver
        if node.children[0] && node.children[0].type == :const
          node.children[0].children[1].to_s
        elsif node.children[0] && node.children[0].type == :send
          # Handle chained calls like User.where(...)
          inner_receiver = node.children[0].children[0]
          if inner_receiver && inner_receiver.type == :const
            inner_receiver.children[1].to_s
          end
        else
          # Fallback: try to infer from controller name
          controller_model = @current_controller.gsub('Controller', '').singularize
          # Only return if it looks like a valid model name
          controller_model if controller_model.match?(/\A[A-Z][a-zA-Z0-9]*\z/)
        end
      rescue => e
        Rails.logger&.warn "Failed to infer model from context: #{e.message}"
        nil
      end

      def analyze_action_body(node)
        # Additional analysis can be added here
        # For example, tracking variable assignments, conditionals, etc.
      end
    end
  end
end