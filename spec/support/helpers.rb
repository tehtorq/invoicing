module Helpers
  def tear_it_down
    Uomi::Invoice.delete_all
    Uomi::LineItem.delete_all
    Uomi::Transaction.delete_all
    Uomi::LatePayment.delete_all
    Uomi::PaymentReference.delete_all
    Uomi::Seller.delete_all
  end
end                                                                                                                                   
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      