require 'parser/current'

module RailsFlowMap
  class ModelAnalyzer
    def initialize(graph)
      @graph = graph
    end

    def analyze
      model_files.each do |file|
        analyze_model_file(file)
      end
    end

    private

    def model_files
      Dir.glob(Rails.root.join('app', 'models', '**', '*.rb'))
    end

    def analyze_model_file(file)
      content = File.read(file)
      ast = Parser::CurrentRuby.parse(content)
      return unless ast

      ModelVisitor.new(@graph, file).process(ast)
    rescue Parser::SyntaxError => e
      Rails.logger.warn "Failed to parse #{file}: #{e.message}"
    end

    class ModelVisitor < Parser::AST::Processor
      def initialize(graph, file_path)
        @graph = graph
        @file_path = file_path
        @current_class = nil
      end

      def on_class(node)
        class_name_node, superclass_node, body_node = *node
        class_name = extract_class_name(class_name_node)
        
        if class_name && is_active_record_model?(superclass_node)
          @current_class = class_name
          node_id = "model_#{class_name.downcase}"
          
          model_node = FlowNode.new(
            id: node_id,
            name: class_name,
            type: :model,
            file_path: @file_path,
            line_number: node.loc.line
          )
          
          @graph.add_node(model_node)
        end

        super
      ensure
        @current_class = nil
      end

      def on_send(node)
        return unless @current_class

        receiver, method_name, *args = *node
        
        if receiver.nil? && association_method?(method_name)
          process_association(method_name, args)
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

      def is_active_record_model?(superclass_node)
        return true if superclass_node.nil?
        
        if superclass_node.type == :const
          const_name = superclass_node.children[1].to_s
          ['ApplicationRecord', 'ActiveRecord::Base'].include?(const_name)
        else
          false
        end
      end

      def association_method?(method_name)
        [:belongs_to, :has_one, :has_many, :has_and_belongs_to_many, :has_many_through].include?(method_name)
      end

      def process_association(method_name, args)
        return if args.empty?
        
        association_name = extract_association_name(args.first)
        return unless association_name

        target_model = infer_model_name(association_name, method_name)
        from_id = "model_#{@current_class.downcase}"
        to_id = "model_#{target_model.downcase}"

        edge = FlowEdge.new(
          from: from_id,
          to: to_id,
          type: method_name,
          label: association_name.to_s
        )

        @graph.add_edge(edge)
      end

      def extract_association_name(node)
        case node.type
        when :sym
          node.children.first
        when :str
          node.children.first.to_sym
        end
      end

      def infer_model_name(association_name, method_name)
        if [:has_many, :has_and_belongs_to_many].include?(method_name)
          association_name.to_s.singularize.camelize
        else
          association_name.to_s.camelize
        end
      end
    end
  end
end