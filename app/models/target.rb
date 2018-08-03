class Target < ApplicationRecord
  audited on: [:create, :update]
  validates :warehouse_id, :month, :year, presence: true
  validates :target_value, presence:true, numericality: { greater_than: 0 }
  validate :warehouse_available, :month_available, :year_available, :check_date
  belongs_to :warehouse
  before_destroy :delete_tracks

  MONTHS = [
    ["January", 1],
    ["February", 2],
    ["March", 3],
    ["April", 4],
    ["May", 5],
    ["June", 6],
    ["July", 7],
    ["August", 8],
    ["September", 9],
    ["October", 10],
    ["November", 11],
    ["December", 12]
  ]

  def month_name
    Date::MONTHNAMES[month]
  end

  private
  def delete_tracks
    audits.destroy_all
  end

  def warehouse_available
    errors.add(:warehouse_id, "does not exist!") if warehouse_id_changed? && Warehouse.not_central.select("1 AS one").where(:id => warehouse_id).blank?
  end

  def month_available
    Target::MONTHS.select{ |x| x[1] == month }.first.first
  rescue
    errors.add(:month, "does not exist!") if month.present?
  end

  def year_available
    errors.add(:year, "does not exist!") if year.present? && year_changed? && !(Date.current.year..(Date.current.year+3)).to_a.select{ |x| x == year}.first.present?
  end

  def check_date
    if month.present? && year.present?
      if year < Date.current.year
        errors.add(:year, "can't less than current year")
      elsif year == Date.current.year && month <= Date.current.month
        errors.add(:month, "can't less than or equal with current month")
      end
    end
  end

end
