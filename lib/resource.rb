class Resource
  pattr_initialize :resolver

  delegate :find, to: :finder

  delegate :foreign_key, :name, :pluralized_name,
           :attributes, :id, :path,
           to: :resolver

  def build(attributes)
    factory.new attributes
  end

  def search(scope = :all, *args, &block)
    finder.send scope, *args, &block
  end

  def serialize(record)
    serializer.new record: record
  end

  private

  delegate :factory, :finder, :serializer,
           to: :resolver
end
