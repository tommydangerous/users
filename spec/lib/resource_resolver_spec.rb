require "rails_helper"

describe ResourceResolver do
  subject { described_class.new controller }

  let :controller do
    double "controller",
           controller_name: "tests",
           controller_path: "api/v1/examples",
           dependencies: dependencies,
           params: params
  end

  let(:dependencies) { double "dependencies" }
  let(:params)       { double "params" }

  describe "#factory" do
    it "should lookup dependencies by the resource name" do
      expect(dependencies).to receive(:[]).with(:test).and_return :example
      expect(subject.factory).to eq :example
    end
  end

  describe "#finder" do
    it "should lookup dependencies by the pluralized resource name" do
      expect(dependencies).to receive(:[]).with(:tests).and_return :example
      expect(subject.finder).to eq :example
    end
  end

  describe "#foreign_key" do
    it "should use the inflector to foreign-keyify the resource name" do
      expect(subject.foreign_key).to eq :test_id
    end
  end

  describe "#name" do
    it "should delegate to the controller's name then singularize and symbolize it" do
      expect(controller).to receive :controller_name
      expect(subject.name).to eq :test
    end
  end

  describe "#path" do
    it "should send route to the controller with the associated record" do
      record = double "record"
      expect(controller).to receive(:api_v1_example_path).with(record).and_return :example
      expect(subject.path record).to eq :example
    end
  end

  describe "#pluralized_name" do
    it "should use the inflector to pluralize the resource name" do
      expect(subject.pluralized_name).to eq :tests
    end
  end

  describe "#route" do
    it "should use an underscored singularized version of the controller path" do
      expect(subject.route).to eq :api_v1_example_path
    end
  end

  describe "#serializer" do
    it "should lookup dependencies for the resource serializer" do
      expect(dependencies).to receive(:[]).with(:test_serializer).and_return :example
      expect(subject.serializer).to eq :example
    end

    it "should lookup dependencies for a default serializer if missing" do
      error = Payload::UndefinedDependencyError
      expect(dependencies).to receive(:[]).with(:test_serializer).and_raise error
      expect(dependencies).to receive(:[]).with(:default_serializer).and_return :default
      expect(subject.serializer).to eq :default
    end
  end
end
