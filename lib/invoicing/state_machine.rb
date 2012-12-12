module Invoicing
  module StateMachine
    #                           / pay -> paid
    #          issue  -> issued 
    # draft <                   \ void -> void
    #          remove -> deleted

    class NoTransitionAllowed < Exception; end

    def draft?
      self.state == "draft"
    end

    def issue
      raise NoTransitionAllowed, "You cannot issue this invoice as it has already been issued." if self.issued?
      raise NoTransitionAllowed, "You cannot issue this invoice as it has already been settled." if self.paid?

      self.state = "issued"
    end

    def paid?

    end

    def issue!
      self.issue
      self.create_initial_transaction!
      self.mark_items_invoiced!
      save!
    end

    def issued?
      self.state == "issued"
    end

    def void!
      raise NoTransitionAllowed, "You can only void issued invoices." unless self.issued?
      self.state = "void"
      # annul line item transactions
      # set balance and total to 0
    end 

  end
end