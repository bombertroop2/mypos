include SmartListing::Helper::ControllerExtensions
class ModelsController < ApplicationController
  load_and_authorize_resource
  before_action :set_model, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /models
  # GET /models.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end    
    models_scope = Model.select(:id, :code, :name, :description)
    models_scope = models_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(models_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(models_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @models = smart_listing_create(:models, models_scope, partial: 'models/listing', default_sort: {code: "asc"})
  end

  # GET /models/1
  # GET /models/1.json
  def show
  end

  # GET /models/new
  def new
    @model = Model.new
  end

  # GET /models/1/edit
  def edit
  end

  # POST /models
  # POST /models.json
  def create
    @model = Model.new(model_params)

    begin
      @model.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{models_url}'"
    end
  end

  # PATCH/PUT /models/1
  # PATCH/PUT /models/1.json
  def update
    begin        
      @model.update(model_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{models_url}'"
    end
  end

  # DELETE /models/1
  # DELETE /models/1.json
  def destroy
    @model.destroy
    
    if @model.errors.present? and @model.errors.messages[:base].present?
      flash[:alert] = @model.errors.messages[:base].to_sentence
      render js: "window.location = '#{models_url}'"
    end

  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_model
    @model = Model.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def model_params
    params[:model].permit(:code, :name, :description)
  end
end
