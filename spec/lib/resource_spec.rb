require "rails_helper"

describe Resource do
  subject { described_class.new resolver }

  let(:resolver) { double "resolver" }

  describe "#attributes" do
    it "should delegate to resolver" do
      expect(resolver).to receive(:attributes).and_return :example
      expect(subject.attributes).to eq :example
    end
  end

  describe "#build" do
    it "should delegate to factory with the specified attributes" do
      factory = double "factory"
      attributes = double "attributes"

      expect(resolver).to receive(:factory).and_return factory
      expect(factory).to receive(:new).with(attributes).and_return :example
      expect(subject.build attributes).to eq :example
    end
  end

  describe "#find" do
    it "should delegate to finder with the specified id" do
      finder = double "finder"
      id = double "id"

      expect(resolver).to receive(:finder).and_return finder
      expect(finder).to receive(:find).with(id).and_return :example
      expect(subject.find id).to eq :example
    end
  end

  describe "#id" do
    it "should delegate to resolver" do
      expect(resolver).to receive(:id).and_return :example
      expect(subject.id).to eq :example
    end
  end

  describe "#path" do
    it "should delegate to resolver" do
      expect(resolver).to receive(:path).and_return :example
      expect(subject.path).to eq :example
    end
  end

  describe "#search" do
    before { expect(resolver).to receive(:finder).and_return finder }

    let(:finder) { double "finder" }

    it "should search the finder with :all by default" do
      expect(finder).to receive(:all).and_return :example
      expect(subject.search).to eq :example
    end

    it "should search the finder with specified a method" do
      expect(finder).to receive(:none).and_return :example
      expect(subject.search :none).to eq :example
    end

    it "should search the finder with specified a method and args" do
      block = proc { "testing" }
      expect(finder).to receive(:order).with(id: :desc, &block).and_return :example
      expect(subject.search :order, id: :desc, &block).to eq :example
    end
  end

  describe "#serializer" do
    it "should delegate to serializer with the specified record" do
      serializer = double "serializer"
      record = double "record"

      expect(resolver).to receive(:serializer).and_return serializer
      expect(serializer).to receive(:new).with(record: record).and_return :example
      expect(subject.serialize record).to eq :example
    end
  end
end
