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
  validate :next_fiscal_not_closed, if: proc{|fm| fm.status.present? && fm.status_changed? && fm.status.eql?("Open") && fm.month.present?}
    validate :prev_fiscal_not_opened, if: proc{|fm| fm.status.present? && fm.status_changed? && fm.status.eql?("Close") && fm.month.present?}

      before_destroy :delete_tracks
  
      private
      
      def prev_fiscal_not_opened
        BeginningStockProduct.select(:import_date).order(:import_date).first.import_date
        if import_date.beginning_of_month == "1/#{month}/#{year}".to_date
        else
          prev_month = "1/#{Date::MONTHNAMES.index(month)}/#{year}".to_date.prev_month
          if FiscalYear.joins(:fiscal_months).where(year: prev_month.year).where("fiscal_months.month = '#{Date::MONTHNAMES[prev_month.month]}' AND fiscal_months.status = 'Open'").select("1 AS one").present? || FiscalYear.joins(:fiscal_months).where(year: prev_month.year).where("fiscal_months.month = '#{Date::MONTHNAMES[prev_month.month]}'").select("1 AS one").blank?
            errors.add(:base, "Fiscal (#{Date::MONTHNAMES[prev_month.month]} #{prev_month.year}) is open, please close it first")
          end
        end
      end
  
      def next_fiscal_not_closed
        next_month = "1/#{Date::MONTHNAMES.index(month)}/#{year}".to_date.next_month
        if FiscalYear.joins(:fiscal_months).where(year: next_month.year).where("fiscal_months.month = '#{Date::MONTHNAMES[next_month.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
          errors.add(:base, "Fiscal (#{Date::MONTHNAMES[next_month.month]} #{next_month.year}) is close, please open it first")
        end
      end
  
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
