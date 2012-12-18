module Invoicing
  class Buyer < ActiveRecord::Base
    has_many :invoices
    belongs_to :buyerable, polymorphic: true

    def self.for(buyerable)
      Buyer.where(buyerable_type: buyerable.class.name, buyerable_id: buyerable.id).first || Buyer.create!(buyerable_type: buyerable.class.name, buyerable_id: buyerable.id)
    end
  end
end