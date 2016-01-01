class SizeGroupsController < ApplicationController
  before_action :set_size_group, only: [:show, :edit, :update, :destroy]

  # GET /size_groups
  # GET /size_groups.json
  def index
    @size_groups = SizeGroup.all
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

    respond_to do |format|
      if @size_group.save
        format.html { redirect_to @size_group, notice: 'Size group was successfully created.' }
        format.json { render :show, status: :created, location: @size_group }
      else
        format.html { render :new }
        format.json { render json: @size_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /size_groups/1
  # PATCH/PUT /size_groups/1.json
  def update
    respond_to do |format|
      if @size_group.update(size_group_params)
        format.html { redirect_to @size_group, notice: 'Size group was successfully updated.' }
        format.json { render :show, status: :ok, location: @size_group }
      else
        format.html { render :edit }
        format.json { render json: @size_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /size_groups/1
  # DELETE /size_groups/1.json
  def destroy
    @size_group.destroy
    respond_to do |format|
      format.html { redirect_to size_groups_url, notice: 'Size group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_size_group
      @size_group = SizeGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def size_group_params
      params.require(:size_group).permit(:code, :description, sizes_attributes: [:id, :size, :_destroy])
    end
end
