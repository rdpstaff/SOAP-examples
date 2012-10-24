# setup the soap driver
require 'soap/wsdlDriver'
WSDL_URL = 'http://rdp.cme.msu.edu:80/services/classifier?wsdl'
classifierService = SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
# uncomment the following lines for debugging purposes.
#driver.generate_explicit_type = true
#driver.wiredump_dev = STDOUT

# define a class that matches the query object expected by the web service method
class Query
  attr_accessor :id, :bases
end
queries = [] # a list of queries

# parse the fasta file into a list of Query objects
require "fileutils"
seqFile = File.new("/scratch/rdp_download_4seqs.fa")
while (line = seqFile.gets)
  if (line =~ /^>/)
    query = Query.new
    query.id = line
    query.bases = ""
    queries << query
  else
    query.bases += line
  end
end

# call the web service method with the list of queries and a confidence of 70%
response = classifierService.classifierWithOptions(:query => queries, :confidenceCutoff => 0.70)

# By convention, WS-I compliant web services wrap the result object in a response object
result = response.return

# output the results
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
