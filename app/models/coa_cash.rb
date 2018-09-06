class CoaCash < ApplicationRecord
  audited on: [:create, :update]

  belongs_to :coa

  validates :date, :coa_id, presence: true
  validates :value, numericality: {greater_than_or_equal_to: 0}, presence:true
  validate :coa_available, :greater_than_current_date, :transaction_open

  before_destroy :delete_tracks


  private
  def delete_tracks
    audits.destroy_all
  end

  def coa_available
    errors.add(:coa_id, "does not exist!") if coa_id_changed? && Coa.select("1 AS one").where(:id => coa_id).blank?
  end

  def greater_than_current_date
    errors.add(:date, "can't greater than today") if date > Date.current
  end

  def transaction_open
    errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
  end

end
