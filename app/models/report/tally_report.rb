# contains methods common to all tally reports
class Report::TallyReport < Report::Report
  protected
    # extracts the row header values from the db_result object
    def get_row_header
      hashes = @db_result.extract_unique_tuples("pri_name", "pri_type").collect do |tuple| 
        {:name => Report::Formatter.format(tuple[0], tuple[1]), :key => tuple[0]}
      end
      Report::Header.new(:title => header_title(:row), :cells => hashes)
    end
  
    # extracts the col header values from the db_result object
    def get_col_header
      hashes = @db_result.extract_unique_tuples("sec_name", "sec_value", "sec_type").collect do |tuple| 
        {:name => Report::Formatter.format(tuple[0], tuple[2]), :key => tuple[0], :sort_value => tuple[1]}
      end
      Report::Header.new(:title => header_title(:col), :cells => hashes)
    end

    # processes a row from the db_result by adding the contained data to the result
    def extract_data_from_row(db_row, db_row_idx)
      # get row and column indices (for result table) by looking them up in the header list
      r, c = @header_set.find_indices(:row => db_row["pri_name"], :col => db_row["sec_name"])

      # set the matching cell value
      @data.set_cell(r, c, get_result_value(db_row))
    end
  
    # extracts and casts the result value from the given result row
    def get_result_value(row)
      # counts will always be integers so we just cast to integer
      row["tally"].to_i
    end
    
    # totaling is appropriate
    def can_total?
      return true
    end
end
