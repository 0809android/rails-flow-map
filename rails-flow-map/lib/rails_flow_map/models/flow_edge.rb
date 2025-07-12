module RailsFlowMap
  class FlowEdge
    attr_accessor :from, :to, :type, :label, :attributes

    def initialize(from:, to:, type:, label: nil, attributes: {})
      @from = from
      @to = to
      @type = type
      @label = label
      @attributes = attributes || {}
    end

    def association?
      [:belongs_to, :has_one, :has_many, :has_and_belongs_to_many].include?(type)
    end

    def action_flow?
      type == :action_flow
    end

    def route_flow?
      type == :routes_to
    end

    def model_access?
      type == :accesses_model
    end

    def service_call?
      type == :calls_service
    end

    def response_flow?
      type == :responds_with
    end

    def to_h
      {
        from: from,
        to: to,
        type: type,
        label: label,
        attributes: attributes
      }
    end

    def ==(other)
      other.is_a?(FlowEdge) && 
        other.from == from && 
        other.to == to && 
        other.type == type
    end

    def hash
      [from, to, type].hash
    end
  end
end