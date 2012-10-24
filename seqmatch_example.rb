require 'soap/wsdlDriver'
require 'pp'

WSDL_URL = 'http://rdp.cme.msu.edu:80/services/seqmatch?wsdl'
seqmatchService = SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
#driver.generate_explicit_type = true
#driver.wiredump_dev = STDOUT


require "fileutils"
# seqFile = ARGV[0]
seqFile = "/scratch/rdp_download_4seqs.fa"

seqStr = File.new(seqFile).read

result = seqmatchService.seqmatch(seqStr)

puts "#RDP Release: " + result.rdpRelease
puts "#Date Run: " + result.dateRun

if result.respond_to?('error')
  puts "#Error String: " + result.error
  exit 1
end

result.query.each { |i| 
  puts i.queryId + "\t" + i.queryWordCount
  i.match.each { |j| 
    puts "\t" + j.sab + "\t" + j.oligos + "\t" + j.sid + "\t" + j.definition + "\t" + j.lineageStr
  }
}
