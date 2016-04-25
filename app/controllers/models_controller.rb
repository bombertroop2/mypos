class ModelsController < ApplicationController
  before_action :set_model, only: [:show, :edit, :update, :destroy]

  # GET /models
  # GET /models.json
  def index
    @models = Model.select :id, :code, :name
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

    respond_to do |format|
      begin
        if @model.save
          format.html { redirect_to @model, notice: 'Model was successfully created.' }
          format.json { render :show, status: :created, location: @model }
        else
          format.html { render :new }
          format.json { render json: @model.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @model.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /models/1
  # PATCH/PUT /models/1.json
  def update
    respond_to do |format|
      begin
        if @model.update(model_params)
          format.html { redirect_to @model, notice: 'Model was successfully updated.' }
          format.json { render :show, status: :ok, location: @model }
        else
          format.html { render :edit }
          format.json { render json: @model.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @model.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /models/1
  # DELETE /models/1.json
  def destroy
    @model.destroy
    if @model.errors.present? and @model.errors.messages[:base].present?
      alert = @model.errors.messages[:base].to_sentence
    else
      notice = 'Model was successfully deleted.'
    end
    respond_to do |format|
      format.html do
        if notice.present?
          redirect_to models_url, notice: notice
        else
          redirect_to models_url, alert: alert
        end
      end
      format.json { head :no_content }
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
