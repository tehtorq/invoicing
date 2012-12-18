module Invoicing
  class Seller < ActiveRecord::Base
    has_many :invoices
    belongs_to :sellerable, polymorphic: true

    def self.for(sellerable)
      Seller.where(sellerable_type: sellerable.class.name, sellerable_id: sellerable.id).first || Seller.create!(sellerable_type: sellerable.type, sellerable_id: sellerable.id)
    end
  end
end