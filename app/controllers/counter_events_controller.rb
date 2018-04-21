include SmartListing::Helper::ControllerExtensions
class CounterEventsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_counter_event, only: [:show, :edit, :update, :destroy]

  # GET /counter_events
  # GET /counter_events.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_event_start_time].present?
      splitted_start_time_range = params[:filter_event_start_time].split("-")
      start_start_time = Time.zone.parse splitted_start_time_range[0].strip
      end_start_time = Time.zone.parse splitted_start_time_range[1].strip
    end

    if params[:filter_event_end_time].present?
      splitted_end_time_range = params[:filter_event_end_time].split("-")
      start_end_time = Time.zone.parse splitted_end_time_range[0].strip
      end_end_time = Time.zone.parse splitted_end_time_range[1].strip
    end

    counter_events_scope = CounterEvent.select(:id, :code, :name, :start_date_time, :end_date_time)
    counter_events_scope = counter_events_scope.where(["code #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(counter_events_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string]
    counter_events_scope = counter_events_scope.where(["start_date_time BETWEEN ? AND ?", start_start_time, end_start_time]) if params[:filter_event_start_time].present?
    counter_events_scope = counter_events_scope.where(["end_date_time BETWEEN ? AND ?", start_end_time, end_end_time]) if params[:filter_event_end_time].present?
    @counter_events = smart_listing_create(:counter_events, counter_events_scope, partial: 'counter_events/listing', default_sort: {id: "desc"})
  end

  # GET /counter_events/1
  # GET /counter_events/1.json
  def show
  end

  # GET /counter_events/new
  def new
    @counter_event = CounterEvent.new
    @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
  end

  # GET /counter_events/1/edit
  def edit
  end

  # POST /counter_events
  # POST /counter_events.json
  def create
    params[:counter_event][:special_price] = params[:counter_event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:special_price].present?    
    @counter_event = CounterEvent.new(counter_event_params)
    puts counter_event_params

    begin
      @valid = @event.save
      unless @valid
        if @event.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@event.errors[:base].join("<br/>")}\",size: 'small'});"
        else
          @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
          @brands = Brand.select(:id, :code, :name).order(:code)
          @goods_types = GoodsType.select(:id, :code, :name).order(:code)
          @models = Model.select(:id, :code, :name).order(:code)
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      @valid = false
      @event.errors.messages[:code] = ["has already been taken"]
      @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
      @brands = Brand.select(:id, :code, :name).order(:code)
      @goods_types = GoodsType.select(:id, :code, :name).order(:code)
      @models = Model.select(:id, :code, :name).order(:code)
    end
  end

  # PATCH/PUT /counter_events/1
  # PATCH/PUT /counter_events/1.json
  def update
    respond_to do |format|
      if @counter_event.update(counter_event_params)
        format.html { redirect_to @counter_event, notice: 'Counter event was successfully updated.' }
        format.json { render :show, status: :ok, location: @counter_event }
      else
        format.html { render :edit }
        format.json { render json: @counter_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /counter_events/1
  # DELETE /counter_events/1.json
  def destroy
    @counter_event.destroy
    respond_to do |format|
      format.html { redirect_to counter_events_url, notice: 'Counter event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_counter_event
      @counter_event = CounterEvent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def counter_event_params
      params.require(:counter_event).permit(:code, :name, :start_time, :end_time, :first_discount, :second_discount, :special_price)
    end
end
