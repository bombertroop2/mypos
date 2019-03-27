include SmartListing::Helper::ControllerExtensions
class MembersController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_member, only: [:show, :edit, :update, :destroy]

  # GET /members
  # GET /members.json
  def index
    like_command = "ILIKE"
    members_scope = Member.select(:id, :name, :address, :mobile_phone, :email)
    members_scope = members_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"]).
      or(members_scope.where(["address #{like_command} ?", "%"+params[:filter]+"%"])).
      or(members_scope.where(["mobile_phone #{like_command} ?", "%"+params[:filter]+"%"])).
      or(members_scope.where(["email #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter].present?
    @members = smart_listing_create(:members, members_scope, partial: 'members/listing', default_sort: {name: "asc"})
  end

  # GET /members/1
  # GET /members/1.json
  def show
  end

  # GET /members/new
  def new
    @member = Member.new
  end

  # GET /members/1/edit
  def edit
  end

  # POST /members
  # POST /members.json
  def create
    @member = Member.new(member_params)
    recreate = false
    begin
      begin
        recreate = false
        @valid = @member.save
      rescue ActiveRecord::RecordNotUnique => e
        recreate = true
      end
    end while recreate
  end

  # PATCH/PUT /members/1
  # PATCH/PUT /members/1.json
  def update
    @valid = @member.update(member_params)
    if !@valid && @member.errors[:base].present?
      render js: "bootbox.alert({message: \"#{@member.errors[:base].join("<br/>")}\",size: 'small'});"
    end
  end

  # DELETE /members/1
  # DELETE /members/1.json
  def destroy
    @deleted = @member.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_member
    @member = Member.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def member_params
    params.require(:member).permit(:name, :address, :phone, :mobile_phone, :gender, :email, :discount, :member_product_event)
  end
end
