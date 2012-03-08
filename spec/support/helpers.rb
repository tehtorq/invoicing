module Helpers
  def tear_it_down
    Invoicing::Invoice.delete_all
    Invoicing::LineItem.delete_all
    Invoicing::Transaction.delete_all
    Invoicing::LatePayment.delete_all
    Invoicing::PaymentReference.delete_all
  end
end                                                                                                                                   
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      