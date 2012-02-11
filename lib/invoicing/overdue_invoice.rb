module Invoicing
  class OverdueInvoice
  
    def self.all
      Invoice.owing.select{|invoice| invoice.overdue?}
    end
  
    def self.record_late_payments!
      OverdueInvoice.all.each do |invoice|
        invoice.late_payment = LatePayment.new amount: invoice.balance.abs
        invoice.save!
      end
    end
  
  end
end