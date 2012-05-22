#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'ostruct'
require 'logger'
require 'pp'
require 'gorillib/hash/compact'
require 'gorillib/string/inflections'
require 'swineherd-fs'

module Vayacondios

  module JobLogParser

    public
    
    #
    # dir: output directory of a hadoop job containing _logs
    # properties: hash containing default properties
    # 
    # returns: a list of hashes. One hash represents the job
    # configuration, and every other hash represents an entry in the
    # log.
    # 
    def self.parse_log_dir dir, properties = nil
      # find logs
      dir = File.join dir, "_logs/history"
      conf, log = ["*.xml", "*{[^x]??,[^m]?,[^l]}"].map do |g|
        fs = Swineherd::FileSystem.get dir
        fs.open fs.glob(File.join(dir, g)).first
      end

      parse_log_and_conf log, (properties || conf)
    end
    
    #
    # log: stream of a hadoop log
    # conf: stream of a hadoop job conf, or a hash containing
    #       properties
    # 
    # returns: a list of hashes. One hash represents the job
    # configuration, and every other hash represents an entry in the
    # log.
    # 
    def self.parse_log_and_conf log, properties
      properties = parse_properties properties unless properties.is_a? Hash

      # prime read loop
      jobid = "unknown"
      record_hashes = {}
      %w[meta job task map_attempt reduce_attempt].each do |type|
        record_hashes[type] = {}
      end
      
      # read loop
      log.read.scan /(#{scan_until '.'})\./ do |raw_record,|
        raw_record.strip!

        # parse each record
        type,l = raw_record.strip.split ' ', 2
        type = parse_key type
        record = {}
        l.scan(/([A-Z_]+)="(#{scan_until '"'})"/m).each do |k,v|
          if k.downcase.end_with? "counters" then
            v = parse_counters v
          else
            v = parse_atom v
          end
          record[parse_key k] = v
        end

        # Decide what fields are ids based on type
        case type
        when 'job'
          idfield = 'jobid'
          jobid = record[idfield]
        when 'task'
          idfield = 'taskid'
          parent_prefix = 'job_'
          parent_id_regex = /\d+_\d+/
        when lambda {|x| x.end_with? 'attempt'}
          idfield = 'task_attempt_id'
          parent_prefix = 'task_'
          parent_id_regex = /\d+_\d+_._\d+/
        else
          next
        end

        # Eliminate duplicate records and set up parent ids.
        cur = record_hashes[type][record[idfield]] = record
        cur['_id'] = cur[idfield]
        cur['parent_id'] = parent_prefix + cur[idfield][/#{parent_id_regex}/] if
          parent_prefix
        cur.delete idfield
        cur['type'] = type
        
      end
      
      # return all records and a properties hash
      record_hashes.values.map{|hash| hash.values}.flatten << {
        'parent' => jobid,
        'type' => 'conf',
        'properties' => properties,
        '_id' => jobid + "_properties"
      }
      
    end

    #
    # Return a hash containing a name => value hash representing the
    # config for a hadoop job.
    #
    def self.parse_properties conf
      properties = {}
      conf.read.scan /[^\n]*\n/ do |line,|
        m = /<name>([^<]+)<\/name><value>([^<]+)<\/value>/.match line
        if m and m[1] !~ /fs\.s3n?\.awsSecretAccessKey/ then
          properties[parse_key m[1]] = parse_atom m[2]
        end
      end
      properties
    end

    private

    #
    # Parse a key in a log entry. Log entries consist of a type, which I
    # consider a key, and a list of key=value pairs.
    #
    def self.parse_key key
      return (parse_atom key).underscore.gsub ".", "_"
    end

    #
    # Parse a value in a Hadoop log.
    #
    def self.parse_atom a
      if /[0-9][ \r\t\n]*\/[ \r\t\n]*[0-9]+/.match a
        # "0/6" -> [0,6]
        return a.split("/").collect{|s| s.to_i}
      elsif /^[0-9,]*$/.match a
        # "224" -> 224
        return a.gsub(',', '').to_i
      else
        # \. -> .
        return a.gsub(/([^\\])\\(.)/, '\1\2')
      end
    end

    #
    # returns a regex that matches until character b. Escaped b's are
    # skipped over.
    #
    def self.scan_until b
      return /(?:[^\\#{b}]|\\.)*/
    end

    #
    # parses counters in a Hadoop log into a hash
    #
    def self.parse_counters counters
      result = {}
      counters.scan /{(#{scan_until '\['})(#{scan_until "\}"})}/ do |counter|
        headers, table = counter
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

  end
end
