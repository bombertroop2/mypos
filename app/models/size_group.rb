class SizeGroup < ApplicationRecord
  audited on: [:create, :update]
  has_associated_audits
  has_many :products, dependent: :restrict_with_error
  has_many :sizes, dependent: :destroy
  has_one :product_relation, -> {select("1 AS one")}, class_name: "Product"
  validates :code, presence: true, uniqueness: true
  validate :code_not_changed#, :validate_unique_sizes

  accepts_nested_attributes_for :sizes, allow_destroy: true

  before_validation :upcase_code, :strip_string_values
  
  before_destroy :delete_tracks

  private
  
  def delete_tracks
    audits.destroy_all
  end

  def strip_string_values
    self.code = code.strip
  end
  
  #  def validate_unique_sizes
  #    collection = sizes
  #    attrs = [:size, :size_group_id]
  #    message = "Duplicate size."
  #    hashes = collection.inject({}) do |hash, record|
  #      key = attrs.map {|a| record.send(a).to_s }.join
  #      if key.blank? || record.marked_for_destruction?
  #        key = record.object_id
  #      end
  #      hash[key] = record unless hash[key]
  #      hash
  #    end
  #    if collection.length > hashes.length
  #      self.errors.add(:base, message)
  #    end
  #  end

  def upcase_code
    self.code = code.upcase.gsub(" ","")
  end
  
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && product_relation.present?
  end

end
