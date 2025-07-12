module RailsFlowMap
  class FlowEdge
    attr_accessor :from, :to, :type, :label, :attributes

    def initialize(from:, to:, type:, label: nil, attributes: {})
      @from = from
      @to = to
      @type = type
      @label = label
      @attributes = attributes
    end

    def association?
      [:belongs_to, :has_one, :has_many, :has_and_belongs_to_many].include?(type)
    end

    def action_flow?
      type == :action_flow
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
  end
end