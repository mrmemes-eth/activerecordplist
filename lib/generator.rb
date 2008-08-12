# It was necessary to overwrite several methods in the Plist::Emit module
# to enable the passing of an options hash, which faithfully dumping some
# ActiveRecord objects require.  Implementations needing to take advantage
# of this should overwrite the to_plist_node method included into 
# ActiveRecord::Base, as the needs will likely be application specific

Plist::Emit.module_eval do
  def to_plist(options = {})
    options[:envelope] ||= true
    Plist::Emit.dump(self, options)
  end
  
  def self.dump(obj, options = {})
    output = plist_node(obj,options)
    options[:envelope] ? wrap(output) : output
  end
  
  private
  
    def self.plist_node(element,options)
      output = ''
      if element.respond_to? :to_plist_node
        output << element.to_plist_node(options)
      else
        case element
        when Array
          if element.empty?
            output << "<array/>\n"
          else
            output << tag('array') {
              element.collect {|e| plist_node(e,options)}
            }
          end
        when Hash
          if element.empty?
            output << "<dict/>\n"
          else
            inner_tags = []
  
            element.keys.sort.each do |k|
              v = element[k]
              inner_tags << tag('key', CGI::escapeHTML(k.to_s))
              inner_tags << plist_node(v,options)
            end
  
            output << tag('dict') {
              inner_tags
            }
          end
        when true, false
          output << "<#{element}/>\n"
        when Time
          output << tag('date', element.utc.strftime('%Y-%m-%dT%H:%M:%SZ'))
        when Date # also catches DateTime
          output << tag('date', element.strftime('%Y-%m-%dT%H:%M:%SZ'))
        when String, Symbol, Fixnum, Bignum, Integer, Float
          output << tag(element_type(element), CGI::escapeHTML(element.to_s))
        when IO, StringIO
          element.rewind
          contents = element.read
          # note that apple plists are wrapped at a different length then
          # what ruby's base64 wraps by default.
          # I used #encode64 instead of #b64encode (which allows a length arg)
          # because b64encode is b0rked and ignores the length arg.
          data = "\n"
          Base64::encode64(contents).gsub(/\s+/, '').scan(/.{1,68}/o) { data << $& << "\n" }
          output << tag('data', data)
        else
          output << comment( 'The <data> element below contains a Ruby object which has been serialized with Marshal.dump.' )
          data = "\n"
          Base64::encode64(Marshal.dump(element)).gsub(/\s+/, '').scan(/.{1,68}/o) { data << $& << "\n" }
          output << tag('data', data )
        end
      end
  
      return output
    end
end