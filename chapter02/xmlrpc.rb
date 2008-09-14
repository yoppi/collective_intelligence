require 'net/http'
require 'xmlrpc/client'
require 'pp'

end_point = "http://b.hatena.ne.jp/xmlrpc"

client = XMLRPC::Client.new2(end_point)
begin
  result = client.call("bookmark.getCount", "http://d.hatena.ne.jp/yoppiblog")
rescue XMLRPC::FaultExeption => e
  puts "Error: "
  puts e.faultCode
  puts faultString
end

result.each

