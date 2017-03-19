include SmartListing::Helper::ControllerExtensions
class EmailsController < ApplicationController
  before_action :set_email, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /emails
  # GET /emails.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    emails_scope = Email.select(:id, :address, :email_type)
    emails_scope = emails_scope.where(["address #{like_command} ?", "%"+params[:filter]+"%"]).
      or(emails_scope.where(["email_type #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @emails = smart_listing_create(:emails, emails_scope, partial: 'emails/listing', default_sort: {address: "asc"})
  end

  # GET /emails/1
  # GET /emails/1.json
  def show
  end

  # GET /emails/new
  def new
    @email = Email.new
  end

  # GET /emails/1/edit
  def edit
  end

  # POST /emails
  # POST /emails.json
  def create
    @email = Email.new(email_params)
    @email.save
  end

  # PATCH/PUT /emails/1
  # PATCH/PUT /emails/1.json
  def update
    @email.update(email_params)
  end

  # DELETE /emails/1
  # DELETE /emails/1.json
  def destroy
    @email.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_email
    @email = Email.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def email_params
    params.require(:email).permit(:address, :email_type)
  end
end
