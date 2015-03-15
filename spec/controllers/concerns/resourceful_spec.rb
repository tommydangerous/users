require "rails_helper"

describe Resourceful do
  described_class.tap do |mod|
    controller ApplicationController do
      include mod
      respond_to :json
    end
  end

  before do
    request.headers["accept"] = "application/json"

    dependencies = Payload::RailsLoader.load
                   .service(:examples) { finder }
                   .factory(:example) do |container, attributes|
                     container[:examples].new attributes
                   end

    allow(controller).to receive(:dependencies).and_return dependencies

    allow(controller).to receive(:controller_name).and_return "examples"
    allow(controller).to receive(:controller_path).and_return "api/examples"

    def controller.api_example_path(record)
      "/api/examples/#{record.id}"
    end

    def controller.example_url(record)
      "/api/examples/#{record.id}"
    end

    def controller.examples_url
      "/api/examples"
    end
  end

  def json
    JSON.parse response.body
  end

  let(:finder)     { double "finder", all: records, new: factory, ransack: ransack }
  let(:ransack)    { double "ransack", result: records }
  let(:record)     { double "record" }
  let(:records)    { [record] }
  let(:saved)      { true }
  let(:model)      { double "model", model_name: model_name, id: 1 }
  let(:model_name) { double "model_name", route_key: "examples", singular_route_key: "example" }

  let(:errors) { Hash.new }

  let(:factory) do
    double "factory", id: 1,
                      persisted?: saved,
                      save: saved,
                      errors: errors,
                      to_model: model
  end

  context "with missing required params" do
    it "should not raise ActionController::ParameterMissing" do
      action = -> { post :create }
      expect(action).not_to raise_error
    end
  end

  describe "#create" do
    before { post :create, example: attributes }

    let(:attributes) { { test: "value" } }

    context "with valid attributes" do
      it { should respond_with :created }

      it "should set the Location header" do
        expect(response.headers.fetch "Location").to eq "/api/examples/1"
      end

      it "should call save on the resource" do
        expect(factory).to have_received :save
      end
    end

    context "with invalid attributes" do
      let(:errors) { { field: ["is invalid"] } }
      let(:saved) { false }

      it { should respond_with :unprocessable_entity }

      it "should call save on the resource" do
        expect(factory).to have_received :save
      end
    end
  end

  describe "#destroy" do
    context "with a valid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return factory
        allow(factory).to receive :destroy
        allow(factory).to receive(:destroyed?).and_return true
        delete :destroy, id: 1
      end

      it { should respond_with :no_content }
    end

    context "with an invalid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return nil
        delete :destroy, id: 1
      end

      it { should respond_with :not_found }
    end

    context "with a missing resource id" do
      before do
        error = ActiveRecord::RecordNotFound
        allow(finder).to receive(:find).with("1").and_raise error
        delete :destroy, id: 1
      end

      it { should respond_with :not_found }
    end

    context "with an undestroyable record" do
      before do
        allow(finder).to receive(:find).with("1").and_return factory
        allow(factory).to receive :destroy

        allow(factory).to receive(:errors)
          .and_return(field: ["is invalid"])

        delete :destroy, id: 1
      end

      it { should respond_with :unprocessable_entity }
    end
  end

  describe "#edit" do
    context "with a valid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return factory
        get :edit, id: 1
      end

      it { should respond_with :success }
    end

    context "with an invalid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return nil
        get :edit, id: 1
      end

      it { should respond_with :not_found }
    end

    context "with a missing resource id" do
      before do
        error = ActiveRecord::RecordNotFound
        allow(finder).to receive(:find).with("1").and_raise error
        get :edit, id: 1
      end

      it { should respond_with :not_found }
    end
  end

  describe "#index" do
    before { get :index }

    it { should respond_with :success }

    it "should return records in view" do
      expect(json.size).to eq records.size
    end
  end

  describe "#show" do
    context "with a valid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return factory
        get :show, id: 1
      end

      it { should respond_with :success }
    end

    context "with an invalid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return nil
        get :show, id: 1
      end

      it { should respond_with :not_found }
    end

    context "with a missing resource id" do
      before do
        error = ActiveRecord::RecordNotFound
        allow(finder).to receive(:find).with("1").and_raise error
        get :show, id: 1
      end

      it { should respond_with :not_found }
    end
  end

  describe "#update" do
    context "with a valid resource id and attributes" do
      before do
        allow(finder).to receive(:find).with("1").and_return factory
        allow(factory).to receive(:update)
          .with(attributes)
          .and_return true

        put :update, id: 1, **attributes
      end

      let(:attributes) { { test: "value" } }

      it { should respond_with 204 }
    end

    context "with an invalid resource id" do
      before do
        allow(finder).to receive(:find).with("1").and_return nil
        put :update, id: 1
      end

      it { should respond_with :not_found }
    end

    context "with a missing resource id" do
      before do
        error = ActiveRecord::RecordNotFound
        allow(finder).to receive(:find).with("1").and_raise error
        put :update, id: 1
      end

      it { should respond_with :not_found }
    end

    context "with invalid attributes" do
      before do
        allow(finder).to receive(:find).with("1").and_return factory

        allow(factory).to receive(:update)
          .with(attributes)
          .and_return false

        allow(factory).to receive(:errors)
          .and_return(field: ["is invalid"])

        put :update, id: 1, **attributes
      end

      let(:attributes) { { test: "value" } }

      it { should respond_with :unprocessable_entity }
    end
  end
end
