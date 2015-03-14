class ResourceResolver
  pattr_initialize :controller

  def factory
    dependencies[name]
  end

  def finder
    dependencies[pluralized_name]
  end

  def foreign_key
    name.to_s.foreign_key.to_sym
  end

  def name
    if controller.respond_to?(:resource_name)
      controller.resource_name
    else
      controller_name.singularize.to_sym
    end
  end

  def path(record)
    controller.send route, record
  end

  def pluralized_name
    name.to_s.pluralize.to_sym
  end

  def route
    controller_path
      .singularize
      .concat("_path")
      .gsub(/\W+/, "_")
      .to_sym
  end

  def serializer
    dependencies["#{name}_serializer".to_sym]
  rescue Payload::UndefinedDependencyError
    dependencies[:default_serializer]
  end

  private

  delegate(
    *%i(controller_name controller_path dependencies params resource_name),
    to: :controller
  )
end
