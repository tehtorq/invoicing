Basic Usage


    seller = Seller.find(3)
    book = Book.find(1) # implements CostItem
    decorations = {whatever_you_want: 'here'}

    invoice = Invoicing::generate do
      from seller
      line_item book
      due Time.now + 7.days
      payment_reference "REF2345"
      decorate_with decorations
    end
    