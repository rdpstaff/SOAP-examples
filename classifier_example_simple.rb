require 'soap/wsdlDriver'
require 'pp'

WSDL_URL = 'http://rdp.cme.msu.edu:80/services/classifier?wsdl'
classifierService = SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
#driver.generate_explicit_type = true
#driver.wiredump_dev = STDOUT


require "fileutils"
# seqFile = ARGV[0]
seqFile = "/scratch/rdp_download_4seqs.fa"

seqStr = File.new(seqFile).read

result = classifierService.classifier(seqStr)

puts "#RDP Classifier: " + result.taxonomyDescription
puts "#Taxonomy Version Number: " + result.taxonomyVersion
puts "#Date Run: " + result.dateRun

if result.respond_to?('error')
  puts "#Error String: " + result.error
  exit 1
end

result.classification.each { |i| 
  puts i.queryID + "\t" + i.assignmentStr
}
