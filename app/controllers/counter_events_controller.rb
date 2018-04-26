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

    counter_events_scope = CounterEvent.all
    counter_events_scope = counter_events_scope.where(["code #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(counter_events_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string]
    counter_events_scope = counter_events_scope.where(["start_time BETWEEN ? AND ?", start_start_time, end_start_time]) if params[:filter_event_start_time].present?
    counter_events_scope = counter_events_scope.where(["end_time BETWEEN ? AND ?", start_end_time, end_end_time]) if params[:filter_event_end_time].present?
    @counter_events = smart_listing_create(:counter_events, counter_events_scope, partial: 'counter_events/listing', default_sort: {id: "desc"})

  end

  # GET /counter_events/1
  # GET /counter_events/1.json
  def show
  end

  # GET /counter_events/new
  def new
    @counter_event = CounterEvent.new
    @warehouses = Warehouse.select(:id, :code, :name).actived.counter.order(:code)
  end

  # GET /counter_events/1/edit
  def edit
    @counter_event.start_time = @counter_event.start_time.strftime("%d/%m/%Y %H:%M")
    @counter_event.end_time = @counter_event.start_time.strftime("%d/%m/%Y %H:%M")
    @warehouses = Warehouse.select(:id, :code, :name).actived.counter.order(:code)
  end

  # POST /counter_events
  # POST /counter_events.json
  def create
    params[:counter_event][:special_price] = params[:counter_event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:special_price].present?    
    @counter_event = CounterEvent.new(counter_event_params)
    
    begin
      @valid = @counter_event.save
      if !@valid
        if @counter_event.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@counter_event.errors[:base].join("<br/>")}\",size: 'small'});"
        else
          @warehouses = Warehouse.select(:id, :code, :name).actived.counter.order(:code)          
        end
      else
        @counter_event.set_warehouses(params[:warehouse_ids]) if params[:warehouse_ids]
      end
    rescue ActiveRecord::RecordNotUnique => e
      @valid = false
      @counter_event.errors.messages[:code] = ["has already been taken"]
      @warehouses = Warehouse.select(:id, :code, :name).actived.counter.order(:code)      
    end
  end

  # PATCH/PUT /counter_events/1
  # PATCH/PUT /counter_events/1.json
  def update
    params[:counter_event][:special_price] = params[:counter_event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:special_price].present?
    
    begin
      @valid = @counter_event.update(counter_event_params)
      if !@valid
        unless @counter_event.errors[:base].present?
          @warehouses = Warehouse.select(:id, :code, :name).actived.counter.order(:code)          
        else
          render js: "bootbox.alert({message: \"#{@counter_event.errors[:base].join("<br/>")}\",size: 'small'});"
        end
      else
        @counter_event.set_warehouses(params[:warehouse_ids]) if params[:warehouse_ids]
      end
    rescue ActiveRecord::RecordNotUnique => e
      @valid = false
      @counter_event.errors.messages[:code] = ["has already been taken"]
      @warehouses = Warehouse.select(:id, :code, :name).actived.counter.order(:code)      
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
      params.require(:counter_event).permit(:code, :name, :start_time, :end_time, :first_discount, :second_discount, :special_price, :margin, :participation)
    end
end
