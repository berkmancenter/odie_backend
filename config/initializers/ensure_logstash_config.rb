begin
  StreamingDataCollector.write_conf
rescue
  StreamingDataCollector.write_basic_conf
end
