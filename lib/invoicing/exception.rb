module Invoicing
  class CannotVoidDocumentException < Exception; end
  class CannotAdjustIssuedDocument < Exception; end
end
