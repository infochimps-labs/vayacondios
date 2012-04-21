#!/usr/bin/env ruby

require 'configliere'
require 'json'

Settings.use :commandline
Settings.define :machine_count, :type => Integer, :description => "number of machines running tasktrackers"
Settings.define :print_keys, :type => :boolean, :description => "output keys on command line"
Settings.resolve!

result = {}
map_end_times = []
map_run_durations = []
reducer_end_times = []
reducer_run_durations = []

result['count_of_machines'] = Settings.machine_count

launch_time = -1

STDIN.each_line do |line|
  h = JSON.parse line

  case h['type']
  when 'conf'
    prop = h['properties']
    output = prop['mapred.output.dir']
    input = prop['mapred.input.dir']
    reduce_child_opts = prop['mapred.reduce.child.java.opts']
    child_opts = prop['mapred.child.java.opts']
    pig_command = prop['pig.command.line']
    result['persexaginta'] = persexaginta = /PERSEXAGINTA=(\d\d)/.match(pig_command)[1]

    result['map_function']               = "filter tweets by ((tstamp) % 100l) < #{persexaginta};"

    result['mapper_child_heap_size'] = (/-Xmx(\d+)m/.match(child_opts) || [])[1].to_i
    result['reducer_child_heap_size'] = (/-Xmx(\d+)m/.match(reduce_child_opts) || [])[1].to_i

    result['map_slots'] = prop['mapred.tasktracker.map.tasks.maximum'].to_i * Settings.machine_count
    result['reduce_slots'] = prop['mapred.tasktracker.reduce.tasks.maximum'].to_i * Settings.machine_count

    result['script_name'] = prop['sun.java.command']

    result['output_filesystem'] = output[/^(s3n|s3)/] || 'hdfs'

  when 'job'
    map_counters = h['map_counters']['org.apache.hadoop.mapred.task$counter']
    map_fs_counters = h['map_counters']['file_system_counters']
    reduce_fs_counters = h['reduce_counters']['file_system_counters']
    launch_time = h['launch_time']

    result['map_tasks'] = map_tasks = h['total_maps']
    result['reduce_tasks'] = reduce_tasks = h['total_reduces']

    result['map_tasks'] = map_tasks = h['total_maps']
    result['reduce_tasks'] = reduce_tasks = h['total_reduces']

    result['total_mapper_input_gb'] = map_fs_counters['hdfs_bytes_read'] / (2.0 ** 30)
    result['total_mapper_output_gb'] = map_counters['map_output_bytes'] / (2.0 ** 30)
    result['total_reducer_output_gb'] = reduce_fs_counters['hdfs_bytes_written'] / (2.0 ** 30)

    result['mapper_input_gb_per_task']   = result['total_mapper_input_gb'] / map_tasks
    result['mapper_output_gb_per_task']  = result['total_mapper_output_gb'] / map_tasks
    result['reducer_output_gb_per_task'] = result['total_reducer_output_gb'] / reduce_tasks
    
    result['reduce_function']            = "distinct"

  when 'task'
    case h['task_type']
    when 'MAP'
      map_run_durations << (h['finish_time'] - h['start_time']) / 1000.0
      map_end_times << (h['finish_time'] - launch_time) / 1000.0
    when 'REDUCE'
      reducer_run_durations << (h['finish_time'] - h['start_time']) / 1000.0
      reducer_end_times << (h['finish_time'] - launch_time) / 1000.0
    end
  end
end

[map_end_times, map_run_durations, reducer_end_times, reducer_run_durations].each {|x| x.sort!}

indices = [10,50,90,100]
def ix array, percentile
  return array[(((array.size-1) * percentile) / 100).to_i]
end

indices.each {|i| result["map_end_time_#{i}"] = ix(map_end_times, i)}
indices.each {|i| result["map_duration_#{i}"] = ix(map_run_durations, i)}
indices.each {|i| result["reducer_end_time_#{i}"] = ix(reducer_end_times, i)}
indices.each {|i| result["reducer_duration_#{i}"] = ix(reducer_run_durations, i)}

first_keys = ['persexaginta']
last_keys = ['map_function', 'script_name']

case Settings.print_keys
when true
  puts (first_keys + (result.keys - last_keys - first_keys) + last_keys).join "\t"
else
  puts (first_keys + (result.keys - last_keys - first_keys) + last_keys).map{|k| result[k]}.join "\t"
end

#puts JSON.generate(result)
  
#puts [
#      lambda {|x| x['map_function'][-4..-2]},               # fraction over 60
#      lambda {|x| x['reduce_end_time'][-1] - 921404},       # runtime - 4 runtime
#      lambda {|x| x['map_end_time'][-1]},                   # 100 map end time
#      lambda {|x| x['map_end_time'][-2]},                   # 90 map end time
#      lambda {|x| x['reduce_end_time'][-1] - x['map_end_time'][-1]},                   # 100 reduce - map end time
#      lambda {|x| x['reduce_end_time'][-2] - x['map_end_time'][-1]},                   # 90 reduce - map end time
#     ].collect {|x| x.call(result)}.join "\t"
