
%w[

  ut_16

].collect { |prefix|
  Dir[File.join(File.dirname(__FILE__), "#{prefix}_*.rb")].first
}.each { |file|
  require(file)
}

