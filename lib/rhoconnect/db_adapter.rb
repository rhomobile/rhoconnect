require 'singleton'

class DBAdapter
  include Singleton

  # Return the database connection...
  # For JRuby platform returned connection has extra missing singleton methods ('execute_batch' and 'close'),
  # and redefined 'transaction' method (to manage DBI auto-commit behavior)
  def get_connection(dbfile)
    if defined?(JRUBY_VERSION) # JRuby
      require 'dbi'

      db = DBI.connect("DBI:Jdbc:SQLite:#{dbfile}", nil, nil, 'driver' => 'org.sqlite.JDBC')
      class << db
        # jdbc/sqlite3 has no Database#execute_batch method
        def execute_batch(batch)
          batch.strip.split(';').each do |sth|
            self.do(sth.strip)
          end
        end

        # jdbc/sqlite3 instead of 'close' uses 'disconnect' method
        def close
          self.disconnect
        end

        alias_method :do_transaction, :transaction
        # Disable auto-commit, perform transaction and restore default DBI auto-commit behavior
        def transaction(&block)
          self['AutoCommit'] = false
          self.do_transaction(&block)
          self['AutoCommit'] = true
        end
      end
    else # MRI Ruby
      require 'sqlite3'
      db = SQLite3::Database.new(dbfile)
    end

    db
  end
end
