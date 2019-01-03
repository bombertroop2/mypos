class GeneralVariable < ApplicationRecord
  validates :pieces_per_koli, presence: true
  validates :pieces_per_koli, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc{|gv| gv.pieces_per_koli.present? && gv.pieces_per_koli_changed?}
  end
