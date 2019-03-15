module RecordFormatters

    def self.record_hash(record)
     {
       record.entry.key => {
        'index-entry-number': record.entry.entry_number.to_s,
        'entry-number': record.entry.entry_number.to_s,
        'entry-timestamp': record.entry.timestamp,
        'key': record.entry.key,
        'item': [
          record.item.value
        ]
       }
      }
    end
  
    def self.record_csv_header(fields)
      [['index-entry-number','entry-number','entry_timestamp','key'], fields].flatten
    end
  
    def self.record_csv_row(fields, record)
      [[record.entry.entry_number,record.entry.entry_number,record.entry.timestamp,record.entry.key], fields.map{|f| record.item.value[f]}].flatten
    end
  
  end