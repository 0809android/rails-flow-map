module RailsFlowMap
  class FlowNode
    attr_accessor :id, :name, :type, :attributes, :file_path, :line_number

    def initialize(id:, name:, type:, attributes: {}, file_path: nil, line_number: nil)
      @id = id
      @name = name
      @type = type
      @attributes = attributes || {}
      @file_path = file_path
      @line_number = line_number
    end

    def model?
      type == :model
    end

    def controller?
      type == :controller
    end

    def action?
      type == :action
    end

    def route?
      type == :route
    end

    def service?
      type == :service
    end

    def response?
      type == :response
    end

    def to_h
      {
        id: id,
        name: name,
        type: type,
        attributes: attributes,
        file_path: file_path,
        line_number: line_number
      }
    end

    def ==(other)
      other.is_a?(FlowNode) && other.id == id
    end

    def hash
      id.hash
    end
  end
end