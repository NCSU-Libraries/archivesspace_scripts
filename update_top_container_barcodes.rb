require 'bundler/setup'
Bundler.require
require 'csv'
require 'pp'

class AddTopContainerBarcodes
  @@csv_path = './ASX_Satellite_2022-02-03-2.csv'
  @@batch_size = 50

  # Specify the CSV column header containing the new barcodes
  @@barcode_column = 'updated_barcode'

  # NOTE: This script only works if you are using ArchivesSpace with an external MySQL database.
  # You will need these connection details:
  #   * MySQL host
  #   * MySQL username + password
  #   * MySQL port (probably 3306)
  #   * ArchivesSpace database name

  # If you have multiple environments (e.g. staging and production)
  # you can specify the environment here and set different connection options for each below.
  @@environment = :production

  case @@environment
    when :production
      @@mysql_client_config = { :host => "your.database.host", :username => "archivesspace",
      :password => "password", :database => "archivesspace", :port => 3306 }
    when :staging
      @@mysql_client_config = { :host => "your.database.host", :username => "archivesspace",
      :password => "password", :database => "archivesspace_staging", :port => 3306 }
  end


  def self.call
    object= new
    object.call
  end

  def initialize
    @mysql_client = Mysql2::Client.new(@@mysql_client_config)
  end

  def call
    execute
  end

  
  private


  def execute
    get_data_from_csv
    # check_barcodes
    update_top_containers
    puts
  end


  def get_data_from_csv
    @data = []
    puts "Processing CSV..."

    CSV.foreach(@@csv_path, headers: true) do |row|
      if row[@@barcode_column] && row[@@barcode_column].length > 1
        uri = row['top_container_uri']
        id = Pathname.new(uri).basename.to_s.to_i
        row_data = { id: id, barcode: row[@@barcode_column] }
        @data << row_data
        # puts row_data.inspect
      end
    end

    puts @data.length
    @data
  end


  def check_barcodes
    @data.each do |d|
      q = "SELECT barcode from top_container WHERE id = #{d[:id]}"
      result = @mysql_client.query(q)
      if result.count == 1
        b = result.first['barcode']
        print b != d[:barcode] ? '+' : '.'
      else
        print result.count
      end
    end
    puts
  end


  def update_top_containers
    @data.each do |d|
      q = "UPDATE top_container SET barcode = '#{d[:barcode]}' WHERE id = #{d[:id]}"
      # puts q
      @mysql_client.query(q)
      print '.'
    end
  end

end


AddTopContainerBarcodes.call
