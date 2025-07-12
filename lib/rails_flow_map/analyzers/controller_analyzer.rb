require 'parser/current'

module RailsFlowMap
  class ControllerAnalyzer
    def initialize(graph)
      @graph = graph
    end

    def analyze
      controller_files.each do |file|
        analyze_controller_file(file)
      end
    end

    private

    def controller_files
      Dir.glob(Rails.root.join('app', 'controllers', '**', '*.rb'))
    end

    def analyze_controller_file(file)
      content = File.read(file)
      ast = Parser::CurrentRuby.parse(content)
      return unless ast

      ControllerVisitor.new(@graph, file).process(ast)
    rescue Parser::SyntaxError => e
      Rails.logger.warn "Failed to parse #{file}: #{e.message}"
    end

    class ControllerVisitor < Parser::AST::Processor
      def initialize(graph, file_path)
        @graph = graph
        @file_path = file_path
        @current_controller = nil
      end

      def on_class(node)
        class_name_node, superclass_node, body_node = *node
        class_name = extract_class_name(class_name_node)
        
        if class_name && is_controller?(class_name, superclass_node)
          @current_controller = class_name
          node_id = "controller_#{class_name.underscore}"
          
          controller_node = FlowNode.new(
            id: node_id,
            name: class_name,
            type: :controller,
            file_path: @file_path,
            line_number: node.loc.line
          )
          
          @graph.add_node(controller_node)
        end

        super
      ensure
        @current_controller = nil
      end

      def on_def(node)
        return unless @current_controller

        method_name = node.children[0].to_s
        
        if action_method?(method_name)
          action_id = "action_#{@current_controller.underscore}_#{method_name}"
          controller_id = "controller_#{@current_controller.underscore}"
          
          action_node = FlowNode.new(
            id: action_id,
            name: method_name,
            type: :action,
            attributes: { controller: @current_controller },
            file_path: @file_path,
            line_number: node.loc.line
          )
          
          @graph.add_node(action_node)
          
          edge = FlowEdge.new(
            from: controller_id,
            to: action_id,
            type: :has_action
          )
          
          @graph.add_edge(edge)
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
    end
  end
end