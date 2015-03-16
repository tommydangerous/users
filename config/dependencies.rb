factory :resource do |_container, controller|
  Resource.new ResourceResolver.new(controller)
end

names = %w()

names.each do |name|
  symbol = name.pluralize.to_sym
  service symbol do
    name.capitalize.constantize
  end
  factory name.to_sym do |container, attributes|
    container[symbol].new attributes
  end
end
