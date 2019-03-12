require 'register_client'
require 'in_memory_data_store'
require 'fileutils'

class Test < Thor
  def self.file
    return @@file
  end

  desc "example FILE", "an example task that does something with a file"
  def example(file)
    @@file = file
    puts('deleting existing build directory')
    FileUtils.remove_dir('build') if File.directory?('build')

    
    puts "You supplied the file #{file}"
    
    registers_client = RegistersClient::RegisterClient.new(nil, RegistersClient::InMemoryDataStore.new({page_size: 5000}), nil)
    fields = registers_client.get_register_definition.item.value['fields']
    user_items = registers_client.get_items.select {|i| i.value[fields.first]}
    FileUtils.mkdir_p('build/items')
    user_items.each do |i|
      File.write("build/items/#{i.hash}.json", i.value.to_json)  
      CSV.open("build/items/#{i.hash}.csv", "wb") do |csv|
        csv << fields
        csv << fields.map{|f| i.value[f]}
      end
    end    
  end
end

class RegistersClient::RegisterClient
  def register_http_request(path)
    puts('path is ' + Test.file)
    File.read(Test.file)
  end
end