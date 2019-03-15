require 'register_client'
require 'in_memory_data_store'
require 'fileutils'
require 'csv'
require './record_formatters'
require './entry_formatters'

class GenerateRegister < Thor

  def self.file
    return @@file
  end

  desc "generate static site", "generate static site from RSF"
  def generate_from_rsf(file)
    @@file = file
    puts('deleting existing build directory')
    FileUtils.remove_dir('build') if File.directory?('build')
    puts('making new build directory')
    FileUtils.mkdir('build')
    puts "You supplied the file #{file}"
    registers_client = RegistersClient::RegisterClient.new(nil, RegistersClient::InMemoryDataStore.new({page_size: 5000}), nil)
    fields = registers_client.get_register_definition.item.value['fields']
    generate_item_files(fields, registers_client.get_items)
    generate_entry_files(registers_client.get_entries)
    generate_entry_list(registers_client.get_entries)
    generate_entry_slices(registers_client.get_entries)
    generate_record_files(fields, registers_client.get_records)
    generate_record_list(fields, registers_client.get_records)
    generate_record_entries(fields, registers_client.get_records_with_history)
    generate_register_metadata(registers_client.get_register_definition, registers_client.get_custodian, registers_client.get_records, registers_client.get_entries)
    generate_rsf(registers_client.get_entries, registers_client)
    puts("generated output at #{FileUtils.pwd}/build")
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
    entries.each do |e|
      File.write("build/entries/#{e.entry_number}.json", [ EntryFormatters.entry_hash(e) ].to_json)  
      CSV.open("build/entries/#{e.entry_number}.csv", "wb") do |csv|
        csv << EntryFormatters::CSV_HEADER
        csv << EntryFormatters.entry_csv_row(e)
      end
    end    
  end

  def generate_record_files(fields, records)
    FileUtils.mkdir_p('build/records')
    records.each do |r|
      File.write("build/records/#{r.entry.key}.json", RecordFormatters.record_hash(r).to_json)
      CSV.open("build/records/#{r.entry.key}.csv", 'wb') do |csv|
        csv << RecordFormatters.record_csv_header(fields)
        csv << RecordFormatters.record_csv_row(fields, r)
        end
      end
  end

  def generate_record_list(fields, records)
    # N.B. Records JSON expects keyed hash rather than array hence .reduce(&:merge)
    File.write('build/records/index.json', records.map{|r| RecordFormatters.record_hash(r)}.reduce(&:merge).to_json)
    CSV.open('build/records/index.csv', 'wb' ) do |csv|
      csv << RecordFormatters.record_csv_header(fields)
      records.each do |r| 
        csv <<  RecordFormatters.record_csv_row(fields, r)
      end
    end
  end

  def generate_entry_list(entries)
    File.write('build/entries/index.json', entries.map{|e| EntryFormatters.entry_hash(e)}.to_json )
    CSV.open('build/entries/index.csv', 'wb') do |csv|
      csv << EntryFormatters::CSV_HEADER
      entries.each do |e|
        csv << EntryFormatters.entry_csv_row(e)
      end
    end
    FileUtils.mkdir_p('build/entries/start')

    # Identical to 0 offset entries
    FileUtils.cp('build/entries/index.csv', 'build/entries/start/0.csv')
    FileUtils.cp('build/entries/index.json', 'build/entries/start/0.json')
  end

  def generate_entry_slices(entries)
  FileUtils.mkdir_p('build/entries/start')
  entries.each_with_index do |e, i|
      remaining_entries = entries.drop_while{|e| e.entry_number <= i}
      File.write("build/entries/start/#{e.entry_number}.json", remaining_entries.map{|e| EntryFormatters.entry_hash(e)}.to_json )
      CSV.open("build/entries/start/#{e.entry_number}.csv", 'wb') do |csv|
        csv << EntryFormatters::CSV_HEADER
        remaining_entries.each do |e|
          csv << EntryFormatters.entry_csv_row(e)
        end
      end
    end
  end

  def generate_record_entries(fields, records_with_history)
    records_with_history.each do |rwh|
      FileUtils.mkdir_p("build/records/#{rwh[:key]}")
      File.write("build/records/#{rwh[:key]}/entries.json", rwh[:records].map{|r| EntryFormatters.entry_hash(r.entry)}.to_json )
      CSV.open("build/records/#{rwh[:key]}/entries.csv", 'wb') do |csv|
        csv << EntryFormatters::CSV_HEADER
        rwh[:records].each do |r|
            csv << EntryFormatters.entry_csv_row(r.entry) 
        end
      end
    end
  end

  def generate_register_metadata(register_definition, custodian, records, entries)
    register_hash = {
      'domain' => 'register.gov.uk',
      'total-records' => records.count,
      'total-entries' => entries.count,
      'register-record' => register_definition.item.value,
      'custodian' => custodian.item.value['custodian'],
      'last-updated' => entries.reverse_each.first.timestamp
    }
    File.write('build/register.json', register_hash.to_json)
  end

  def generate_rsf(entries, client)
    FileUtils.mkdir_p('build/download-rsf')
    # RSF 0 is the same as the input file
    FileUtils.cp(GenerateRegister.file, 'build/download-rsf/0')
    entries.each_with_index do |e, i|
      remaining_entries = entries.drop_while{|e| e.entry_number <= i+1}
      add_items = remaining_entries.map{|re| "add-item\t#{client.get_item(re.item_hash).value.to_json}"}
      append_entries = remaining_entries.map{|re| "append-entry\tuser\t#{re.key}\t#{re.timestamp}\t#{re.item_hash}"}
      rsf = [add_items, append_entries].flatten.join("\n")
      File.write("build/download-rsf/#{e.entry_number}", rsf)
    end
  end
end

class RegistersClient::RegisterClient
  def register_http_request(path)
    File.read(GenerateRegister.file)
  end
end