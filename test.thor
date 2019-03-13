require 'register_client'
require 'in_memory_data_store'
require 'fileutils'
require 'csv'

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
    generate_item_files(fields, registers_client.get_items)
    generate_entry_files(registers_client.get_entries)
  end
  
  private
  
  def generate_item_files(fields, items)
    user_items = items.select {|i| i.value[fields.first]}
    FileUtils.mkdir_p('build/items')
    user_items.each do |i|
      File.write("build/items/#{i.hash}.json", i.value.to_json)  
      CSV.open("build/items/#{i.hash}.csv", "wb") do |csv|
        csv << fields
        csv << fields.map{|f| i.value[f]}
      end
    end    
  end

  def generate_entry_files(entries)
    FileUtils.mkdir_p('build/entries')
    headers = ['index-entry-number', 'entry-number', 'entry-timestamp', 'key', 'item-hash']
    entry_csv_row = lambda { |e| [e.entry_number, e.entry_number, e.timestamp, e.key, "#{e.item_hash}"] }
    entry_json = lambda { |e| [
      {
        'index-entry-number': e.entry_number.to_s,
        'entry-number': e.entry_number.to_s,
        'entry-timestamp': e.timestamp,
        'key': e.key,
        'item-hash': [
          e.item_hash
        ]
      }
    ].to_json
  }
    entries.each do |e|
      File.write("build/entries/#{e.entry_number}.json", entry_json.call(e))  
      CSV.open("build/entries/#{e.entry_number}.csv", "wb") do |csv|
        csv << headers
        csv << entry_csv_row.call(e)
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