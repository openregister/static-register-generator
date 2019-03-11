require 'register_client'
require 'in_memory_data_store'


class Test < Thor
  def self.file
    return @@file
  end

  desc "example FILE", "an example task that does something with a file"
  def example(file)
    @@file = file

    
    puts "You supplied the file #{file}"
    
    registers_client = RegistersClient::RegisterClient.new(nil, RegistersClient::InMemoryDataStore.new(5000), 5000)
    Dir.mkdir('build')
    Dir.mkdir('build/items')
    registers_client.get_items.each do |i|
      IO.write("build/items/#{i.hash}.json", i.value.to_json)  
    end    

  end
end

class RegistersClient::RegisterClient
  def register_http_request(path)
    puts('path is ' + Test.file)
    File.read(Test.file)
  end
end