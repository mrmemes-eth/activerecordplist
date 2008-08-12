module ActiveRecordPlist
  module Base
    include Plist::Emit
    def to_plist_node(options = {})
      Plist::Emit.dump({
        self.class.to_s.underscore => self.attributes.reject{ |key,value| value.blank? }
      }, {:envelope => false})
    end
  end
  module Errors
    include Plist::Emit
    def to_plist_node(options = {})
      Plist::Emit.dump({
        :errors => self.full_messages.map{ |message| { :error => message } }
      }, {:envelope => false})
    end
  end
end
