require 'plist'
require File.join(File.dirname(__FILE__),'lib','generator')
require File.join(File.dirname(__FILE__),'lib','active_record_plist')

ActiveRecord::Base.send(:include, ActiveRecordPlist::Base)
ActiveRecord::Errors.send(:include, ActiveRecordPlist::Errors)

Mime::Type.register 'application/x-plist', :plist, %w( text/plist application/plist )

ActionController::Base.param_parsers[Mime::PLIST] = Proc.new do |data|
  Plist::parse_xml(data)
end