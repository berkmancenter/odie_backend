class TimespanSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :start, :end, :in_seconds
end
