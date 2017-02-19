include SmartListing::Helper::ControllerExtensions
class SizeGroupsController < ApplicationController
  before_action :set_size_group, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /size_groups
  # GET /size_groups.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    size_groups_scope = SizeGroup.joins("LEFT JOIN sizes on size_groups.id = sizes.size_group_id").select("size_groups.id, code, description, size")
    size_groups_scope = size_groups_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(size_groups_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])).
      or(size_groups_scope.where(["size #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    size_groups_scope = if params[:size_groups_smart_listing].present? && params[:size_groups_smart_listing][:sort].present?
      size_groups_scope.order("#{params[:size_groups_smart_listing][:sort].keys.first} #{params[:size_groups_smart_listing][:sort][params[:size_groups_smart_listing][:sort].keys.first]}")
    else
      size_groups_scope.order("code ASC")
    end
    size_groups = []
    size_group_hash = Hash.new    
    sizes = ""
    size_groups_scope.each_with_index do |size_group, index|
      if index == 0 && size_groups_scope.length < 2
        size_group_hash["id"] = size_group.id
        size_group_hash["code"] = size_group.code
        size_group_hash["description"] = size_group.description
        size_group_hash["sizes"] = size_group.size
        size_group_hash["has_product_realtion"] = size_group.product_relation.present?
        size_groups << size_group_hash
      elsif index == 0
        size_group_hash["id"] = size_group.id
        size_group_hash["code"] = size_group.code
        size_group_hash["description"] = size_group.description
        size_group_hash["has_product_realtion"] = size_group.product_relation.present?
        sizes = size_group.size
      else
        if size_group_hash["id"] != size_group.id
          size_group_hash["sizes"] = sizes
          size_groups << size_group_hash
          size_group_hash = Hash.new
          size_group_hash["id"] = size_group.id
          size_group_hash["code"] = size_group.code
          size_group_hash["description"] = size_group.description
          size_group_hash["has_product_realtion"] = size_group.product_relation.present?
          if index == size_groups_scope.length - 1
            size_group_hash["sizes"] = size_group.size
            size_groups << size_group_hash
          else
            sizes = size_group.size
          end
        elsif index == size_groups_scope.length - 1
          sizes = "#{sizes}, #{size_group.size}"
          size_group_hash["sizes"] = sizes
          size_groups << size_group_hash          
        else
          sizes = "#{sizes}, #{size_group.size}"
        end
      end
    end
    
    # reverse back array karena smart listing secara aneh me-reverse order
    size_groups = size_groups.reverse if params[:size_groups_smart_listing].present? && params[:size_groups_smart_listing][:sort].present?
    @size_groups = smart_listing_create(:size_groups, size_groups, partial: 'size_groups/listing', array: true)
  end

  # GET /size_groups/1
  # GET /size_groups/1.json
  def show
  end

  # GET /size_groups/new
  def new
    @size_group = SizeGroup.new
  end

  # GET /size_groups/1/edit
  def edit
  end

  # POST /size_groups
  # POST /size_groups.json
  def create
    @size_group = SizeGroup.new(size_group_params)

    begin
      @size_group.save
      render js: "alert('#{@size_group.errors[:base].first}')" if !@size_group.valid? && @size_group.errors[:base].present?
      if @size_group.valid?
        @new_sizes = []
        params[:size_group][:sizes_attributes].each do |key, value|
          @new_sizes << params[:size_group][:sizes_attributes][key][:size]
        end if params[:size_group][:sizes_attributes].present?
      end
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = if $!.message.include? "size_group_id"
        "Size should be unique!"
      else
        "That code has already been taken"
      end        
      render js: "window.location = '#{size_groups_url}'"
    end
  end

  # PATCH/PUT /size_groups/1
  # PATCH/PUT /size_groups/1.json
  def update
    begin        
      @size_group.update(size_group_params)
      render js: "alert('#{@size_group.errors[:base].first}')" if !@size_group.valid? && @size_group.errors[:base].present?
      if @size_group.valid?
        @new_sizes = []
        params[:size_group][:sizes_attributes].each do |key, value|
          if !params[:size_group][:sizes_attributes][key][:_destroy].eql?("1") && !params[:size_group][:sizes_attributes][key][:_destroy].eql?("true")
            @new_sizes << params[:size_group][:sizes_attributes][key][:size]
          end
        end if params[:size_group][:sizes_attributes].present?
      end
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{size_groups_url}'"
    rescue ActiveRecord::RecordNotDestroyed => e
      flash[:alert] = "Cannot delete size because dependent product exist"
      render js: "window.location = '#{size_groups_url}'"
    end
  end

  # DELETE /size_groups/1
  # DELETE /size_groups/1.json
  def destroy
    begin
      @size_group.destroy    
      if @size_group.errors.present? and @size_group.errors.messages[:base].present?
        flash[:alert] = @size_group.errors.messages[:base].to_sentence
        render js: "window.location = '#{size_groups_url}'"
      end
    rescue Exception => exc
      flash[:alert] = exc.message
      render js: "window.location = '#{size_groups_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_size_group
    @size_group = SizeGroup.where(id: params[:id]).select(:id, :code, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def size_group_params
    params.require(:size_group).permit(:code, :description, sizes_attributes: [:id, :size, :_destroy])
  end
end
