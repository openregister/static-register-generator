module EntryFormatters
    CSV_HEADER = ['index-entry-number', 'entry-number', 'entry-timestamp', 'key', 'item-hash']
  
    def self.entry_hash(e) {
        'index-entry-number': e.entry_number.to_s,
        'entry-number': e.entry_number.to_s,
        'entry-timestamp': e.timestamp,
        'key': e.key,
        'item-hash': [
          e.item_hash
        ]
      }
    end
  
    def self.entry_csv_row(e)
      [e.entry_number, e.entry_number, e.timestamp, e.key, "#{e.item_hash}"] 
    end
  
  end