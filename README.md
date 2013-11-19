
[![Build Status](https://secure.travis-ci.org/tehtorq/uomi.png)](http://travis-ci.org/tehtorq/uomi)

Basic Usage

    seller = Seller.find(3)
    book = Book.find(1) # implements CostItem
    decorations = {whatever_you_want: 'here'}

    invoice = Uomi::generate_invoice do
      from seller
      line_item book
      due Time.now + 7.days
      payment_reference "REF2345"
      decorate_with decorations
    end

Invoice Numbering:

A default invoice number will be set with the format INV[invoice id].

A custom invoice number can be specified as follows:

    invoice = Uomi::generate_invoice do
      numbered "CUSTOMREF123"
    end

You can specify a custom invoice number containing the invoice id as follows:

    invoice = Uomi::generate_invoice do
      numbered "CUSTOMREF{id}"
    end

  
    
