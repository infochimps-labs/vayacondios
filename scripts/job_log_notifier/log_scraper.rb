#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'ostruct'
require 'logger'
require 'pp'
require 'gorillib/hash/compact'
require 'gorillib/string/inflections'

def parse_cmdline(argv)

  config = OpenStruct.new

  config.hadoop_output_dir = argv.first
  if config.hadoop_output_dir[-1] == '/' then
    config.hadoop_output_dir = config.hadoop_output_dir[0..-2]
  end

  m = /(^(?:[[:alnum:]]+:\/\/|\/)[[:alnum:].]+\/)/i.
    match(config.hadoop_output_dir)
  config.hadoop_prefix = m[1] if m

  return config

end

def parse_key key
  return (parse_atom key).underscore
end

def parse_atom a

  if /[0-9][ \r\t\n]*\/[ \r\t\n]*[0-9]+/.match a
    return a.split("/").collect{|s| s.to_i}
  elsif /^[0-9,]*$/.match a
    return a.gsub(',', '').to_i
  else
    return a.gsub(/([^\\])\\(.)/, '\1\2')
  end
end

def scan_until b
  return /(?:[^\\#{b}]|\\.)*/
end

def parse_counters counters
  result = {}
  counters.scan /{(#{scan_until '\['})(#{scan_until "\}"})}/ do |headers,table|
    headers.scan(/\((#{scan_until ')'})\)
                  \((#{scan_until ')'})\)/x) do |type, description|
      type = parse_key type
      result[type] = {}
      table.scan(/\[\((#{scan_until ')'})\)
                    \((#{scan_until ')'})\)
                    \((#{scan_until ')'})\)\]/x) do |name,description,val|
        result[type][parse_key name] = parse_atom val
      end
    end
  end
  return result
end

def each_record log
  log.scan /(#{scan_until '.'})\./ do |record,|
    yield parse_record(record)
  end
end

def parse_record line
  line.strip!
  type,l = line.strip.split ' ', 2
  type = parse_key type
  cur = {}
  l.scan(/([A-Z_]+)="(#{scan_until '"'})"/m).each do |k,v|
    if k.downcase.end_with? "counters" then
      v = parse_counters v
    else
      v = parse_atom v
    end
    cur[parse_key k] = v
  end
  return {"type"=>type,"record"=>cur}
end

def init_hsh(hsh, key, mk_att_key = true)
  hsh[key] = if hsh[key] == nil then
               {'attempts' => ({} if mk_att_key), 'info' => {}}.compact
             else
               hsh[key]
             end
end

def parsed_records log
  job_info = {'info' => {}, 'tasks' => {}}
  jobid = nil
  each_record(log) do |record|
    case record['type']
    when 'job'
      cur = job_info['info']
      parent = nil
      idkey = 'jobid'
      jobid = record['record']['jobid']
    when 'task'
      taskid = record['record']['taskid']
      parent = job_info['info']['_id']
      cur = init_hsh(job_info['tasks'], taskid)['info']
      idkey = 'taskid'
    when lambda {|x| x.end_with? 'attempt'}
      attid = record['record']['task_attempt_id']
      parent = taskid = record['record']['taskid']

      cur = init_hsh(init_hsh(job_info['tasks'], taskid)['attempts'], attid, false)['info']
      idkey = 'task_attempt_id'
    else
      next
    end

    cur['type'] = record['type']
    cur['_id'] = record['record'][idkey]
    cur['parent_id'] = parent if parent
    record['record'].delete idkey
    record['record'].each do |k,v|
      cur[k] = v
    end
  end

  job_info['tasks'] = (job_info['tasks'].values.collect do |t|
                         t['attempts'] = t['attempts'].values.collect { |a| a }
                         t
                       end)

  tasks = job_info['tasks']
  job_info.delete 'tasks'

  task_attempts = []

  tasks.each do |t|
    task_attempts << t['attempts']
    task_attempts.flatten!
    t.delete 'attempts'
  end

  return [[job_info] + tasks + task_attempts, jobid]
end

conf = parse_cmdline ARGV

def find_files(files)
  log_file, conf_file = nil, nil
  
  files.each do |p|
    p.strip!
    if p.end_with? '.xml'
    then
      conf_file = p
    elsif not p.end_with? '.'
      log_file = p
    end
  end

  return log_file, conf_file
end

def parse_properties(conf_lines, jobid)
  properties = {}
  conf_lines.each do |line|
    m = /<name>([^<]+)<\/name><value>([^<]+)<\/value>/.match line
    if m and not m[2].index('SecretAccessKey') then
      properties[m[1]] = m[2]
    end
  end
  return {'parent' => jobid, 'type' => 'conf', 'properties' => properties}
end

if conf.hadoop_prefix then
  proc = IO.popen("hadoop fs -ls #{conf.hadoop_output_dir}/_logs/history",
                  :err => ['/dev/null'])
  log_file, conf_file = find_files(proc.readlines[1..-1].
                                   map {|l| l.split('/', 2)[-1]})
  
  log = IO.popen("hadoop fs -cat #{conf.hadoop_prefix}/#{log_file}",
                 :err => ['/dev/null']).read
  conf = IO.popen("hadoop fs -cat #{conf.hadoop_prefix}/#{conf_file}",
                  :err => ['/dev/null']).readlines

else
  log_file, conf_file = find_files(Dir.new(File.join(conf.hadoop_output_dir,
                                                     "_logs/history")).entries)

  log = open(File.join(conf.hadoop_output_dir, "_logs/history/#{log_file}"),
             :err => ['/dev/null']).read
  conf = open(File.join(conf.hadoop_output_dir, "_logs/history/#{conf_file}"),
              :err => ['/dev/null']).readlines
end

job_info = {'info' => {}, 'tasks' => {}}

records, jobid = parsed_records(log)

records.each do |entry|
    puts JSON.generate(entry['info'])
end

puts JSON.generate(parse_properties(conf, jobid))
