require 'rubygems'
require 'mysql2'
require 'csv'
require 'json'


# NOTE: This script only works if you are using ArchivesSpace with an external MySQL database.
# You will need these connection details:
#   * MySQL host
#   * MySQL username + password
#   * MySQL port (probably 3306)
#   * ArchivesSpace database name

# If you have multiple environments (e.g. staging and production)
# you can specify the environment here and set different connection options for each below.
@environment = :production
case @environment
  when :production
    $mysql_client = Mysql2::Client.new(:host => "your.database.host", :username => "archivesspace",
      :password => "password", :database => "archivesspace", :port => 3306)
  when :staging
    $mysql_client = Mysql2::Client.new(:host => "your.database.host", :username => "archivesspace",
      :password => "password", :database => "archivesspace_staging", :port => 3306)
end


def get_top_containers_locations_results
  q = "select distinct tc.id as top_container_id, tc.indicator, tc.barcode, ev.value as type,
    l.id, l.building,
    l.coordinate_1_label, l.coordinate_1_indicator,
    l.coordinate_2_label, l.coordinate_2_indicator,
    l.coordinate_3_label, l.coordinate_3_indicator
    from top_container tc
    join top_container_link_rlshp tl on tl.top_container_id = tc.id
    join top_container_housed_at_rlshp tch on tch.top_container_id = tc.id
    join location l on l.id = tch.location_id
    join enumeration_value ev on ev.id = tc.type_id
    where tl.top_container_id is not null
    AND l.building like \"%Hill%\""
  $mysql_client.query(q)
end


def parse_results(results)
  data = []
  data << [ 'location_id', 'building', 'coordinate1', 'coordinate2', 'coordinate3',
    'barcode', 'top_container', 'accession_identifier',
    'accession_title', 'resource_identifier', 'resource_title' ]
  results.each do |r|
    id = r['id']
    building = r['building']
    coordinate1 = "#{r['coordinate_1_label']} #{r['coordinate_1_indicator']}"
    coordinate2 = "#{r['coordinate_2_label']} #{r['coordinate_2_indicator']}"
    coordinate3 = "#{r['coordinate_3_label']} #{r['coordinate_3_indicator']}"
    barcode = r['barcode']
    top_container_id = r['top_container_id']
    top_container = "#{ r['type'] } #{ r['indicator'] }"

    accession_or_resource = get_accession_or_resource_for_top_container(top_container_id)

    accession_identifier = accession_or_resource[:accession_identifier]
    accession_title = accession_or_resource[:accession_title]
    resource_identifier = accession_or_resource[:resource_identifier]
    resource_title = accession_or_resource[:resource_title]

    row = [ id, building, coordinate1, coordinate2, coordinate3, barcode, top_container,
      accession_identifier, accession_title, resource_identifier, resource_title ]
    puts row.inspect
    data << row
  end
  data
end


def get_instance_for_top_container(top_container_id)
  q = "select i.* from instance i
    join sub_container c on c.instance_id = i.id
    join top_container_link_rlshp tcl on tcl.sub_container_id = c.id
    where tcl.top_container_id = #{ top_container_id }"
  results = $mysql_client.query(q)
  results.first
end


def get_resource_for_instance(instance)
  q = nil
  if instance['resource_id']
    q = "select * from resource where id = #{ instance['resource_id'] }"
  elsif instance['archival_object_id']
    q = "select r.* from resource r
      join archival_object ao on ao.root_record_id = r.id
      where ao.id = #{ instance['archival_object_id'] }"
  end
  results = $mysql_client.query(q)
  results.first
end


def get_accession_for_instance(instance)
  if instance['accession_id']
    q = " select * from accession where id = #{ instance['accession_id'] }"
    results = $mysql_client.query(q)
    results.first
  end
end


def get_accession_or_resource_for_top_container(top_container_id)

  get_identifier = lambda do |string|
    a = JSON.parse(string)
    return a[0]
  end

  data = { acession_identifier: nil, acession_title: nil, resource_identifier: nil, resource_title: nil }

  instance = get_instance_for_top_container(top_container_id)

  if instance
    if instance['resource_id'] || instance['archival_object_id']
      resource = get_resource_for_instance(instance)
      data[:resource_title] = resource['title']
      data[:resource_identifier] = get_identifier.call( resource['identifier'] )
    elsif instance['accession_id']
      accession = get_accession_for_instance(instance)
      data[:accession_title] = accession['title']
      data[:accession_identifier] = get_identifier.call( accession['identifier'] )
    end
  end

  data
end


def execute
  top_container_results = get_top_containers_locations_results

  rows = parse_results(top_container_results)


  @report_filename = "shelf_list_#{ Date.today.to_s }.txt"

  f = File.new("./#{ @report_filename }",'w')

  rows.each do |row|
    f.puts row.join("\t")
  end

  f.puts
  f.close

  puts
  puts "Report complete - see #{@report_filename}"
end


execute()
