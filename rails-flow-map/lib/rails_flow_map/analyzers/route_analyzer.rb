module RailsFlowMap
  class RouteAnalyzer
    def initialize(graph)
      @graph = graph
    end

    def analyze
      unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        Rails.logger&.warn "Rails application not found, skipping route analysis"
        return
      end

      begin
        Rails.application.routes.routes.each do |route|
          analyze_route(route)
        end
      rescue => e
        Rails.logger&.warn "Failed to analyze routes: #{e.message}"
      end
    end

    private

    def analyze_route(route)
      return unless route.defaults[:controller] && route.defaults[:action]

      controller_name = route.defaults[:controller]
      action_name = route.defaults[:action]
      
      # Create route node
      route_id = generate_route_id(route)
      route_node = FlowNode.new(
        id: route_id,
        name: route_path_for_display(route),
        type: :route,
        attributes: {
          verb: route.verb,
          path: route.path.spec.to_s,
          controller: controller_name,
          action: action_name,
          requirements: route.requirements,
          defaults: route.defaults
        }
      )
      
      @graph.add_node(route_node)
      
      # Connect route to controller action
      controller_id = "controller_#{controller_name.underscore}"
      action_id = "action_#{controller_name.underscore}_#{action_name}"
      
      # Create controller node if it doesn't exist
      unless @graph.find_node(controller_id)
        controller_node = FlowNode.new(
          id: controller_id,
          name: "#{controller_name.camelize}Controller",
          type: :controller
        )
        @graph.add_node(controller_node)
      end
      
      # Create action node if it doesn't exist
      unless @graph.find_node(action_id)
        action_node = FlowNode.new(
          id: action_id,
          name: action_name,
          type: :action,
          attributes: { controller: controller_name.camelize }
        )
        @graph.add_node(action_node)
        
        # Connect controller to action
        controller_action_edge = FlowEdge.new(
          from: controller_id,
          to: action_id,
          type: :has_action
        )
        @graph.add_edge(controller_action_edge)
      end
      
      # Connect route to action
      route_edge = FlowEdge.new(
        from: route_id,
        to: action_id,
        type: :routes_to,
        label: "#{route.verb} #{route.path.spec}"
      )
      @graph.add_edge(route_edge)
    end

    def generate_route_id(route)
      verb = route.verb.is_a?(Regexp) ? 'ANY' : route.verb
      path = route.path.spec.to_s.gsub(/[^a-zA-Z0-9_]/, '_')
      "route_#{verb}_#{path}".downcase.gsub(/__+/, '_')
    end

    def route_path_for_display(route)
      verb = route.verb.is_a?(Regexp) ? 'ANY' : route.verb
      path = route.path.spec.to_s
      "#{verb} #{path}"
    end
  end
end