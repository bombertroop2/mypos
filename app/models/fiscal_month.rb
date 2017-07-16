class FiscalMonth < ApplicationRecord
  attr_accessor :year
  
  audited associated_with: :fiscal_year, on: :update

  belongs_to :fiscal_year
  
  MONTHS = [
    ["January", "January"],
    ["February", "February"],
    ["March", "March"],
    ["April", "April"],
    ["May", "May"],
    ["June", "June"],
    ["July", "July"],
    ["August", "August"],
    ["September", "September"],
    ["October", "October"],
    ["November", "November"],
    ["December", "December"],
  ]
  
  STATUSES = [
    ["Open", "Open"],
    ["Close", "Close"]
  ]

  validates :month, presence: true, uniqueness: {scope: :fiscal_year_id}
  validates :status, presence: true
  validate :month_available, :status_available, :current_and_next_month_should_be_opened

  before_destroy :delete_tracks
  
  private
  
  def current_and_next_month_should_be_opened
    errors.add(:month, "cannot be closed") if month.present? && Date::MONTHNAMES.index(month) >= Date.current.month && status.eql?("Close") && year.to_i >= Date.current.year
  end
  
  def delete_tracks
    audits.destroy_all
  end

  def month_available
    MONTHS.select{ |x| x[1].eql?(month) }.first.first
  rescue
    errors.add(:month, "does not exist!") if month.present?
  end

  def status_available
    STATUSES.select{ |x| x[1].eql?(status) }.first.first
  rescue
    errors.add(:status, "does not exist!") if status.present?
  end  
end
