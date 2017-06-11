include SmartListing::Helper::ControllerExtensions
class ColorsController < ApplicationController
  load_and_authorize_resource
  before_action :set_color, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /colors
  # GET /colors.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    colors_scope = Color.select(:id, :code, :name, :description)
    colors_scope = colors_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(colors_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(colors_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @colors = smart_listing_create(:colors, colors_scope, partial: 'colors/listing', default_sort: {code: "asc"})
  end

  # GET /colors/1
  # GET /colors/1.json
  def show
  end

  # GET /colors/new
  def new
    @color = Color.new
  end

  # GET /colors/1/edit
  def edit
  end

  # POST /colors
  # POST /colors.json
  def create
    @color = Color.new(color_params)
    
    begin
      @color.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{colors_url}'"
    end

  end

  # PATCH/PUT /colors/1
  # PATCH/PUT /colors/1.json
  def update
    begin        
      @color.update(color_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{colors_url}'"
    end
  end

  # DELETE /colors/1
  # DELETE /colors/1.json
  def destroy
    @color.destroy
    
    if @color.errors.present? and @color.errors.messages[:base].present?
      error_message = @color.errors.messages[:base].to_sentence
      error_message.slice! "details "
      flash[:alert] = error_message
      render js: "window.location = '#{colors_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_color
    @color = Color.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def color_params
    params[:color].permit(:code, :name, :description)
  end
end
