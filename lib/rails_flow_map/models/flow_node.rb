module RailsFlowMap
  class FlowNode
    attr_accessor :id, :name, :type, :attributes, :file_path, :line_number

    def initialize(id:, name:, type:, attributes: {}, file_path: nil, line_number: nil)
      @id = id
      @name = name
      @type = type
      @attributes = attributes
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
  end
end