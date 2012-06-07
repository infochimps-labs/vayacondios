require 'configliere'
require 'logger'

module Vayacondios

  module Configurable

    #
    # Declare a name CONST_NAME = :const_name
    #
    def self.declare_name symbol
      const_set symbol.to_s.upcase.to_sym, symbol
    end

    declare_name :stat_server_port
    declare_name :sleep_seconds
    declare_name :mongo_jobs_db
    declare_name :mongo_job_logs_collection
    declare_name :mongo_job_events_collection
    declare_name :mongo_machine_stats_collection
    declare_name :job_logs_size
    declare_name :job_events_size
    declare_name :machine_stats_size
    declare_name :monitoring_cluster
    declare_name :mongo_ip
    declare_name :log_level

    declare_name :cluster_busy
    declare_name :cluster_quiet
    declare_name :event
    declare_name :time

    attr_reader :logger

    def settings
      init_settings
      return @settings
    end

    def init_settings
      return if defined? @settings
      
      @settings = Configliere::Param.new
      @settings.use :env_var, :config_file, :commandline
      
      @settings.define(SLEEP_SECONDS,
                   :default => 5,
                   :description => "Time to sleep in main loops")
      @settings.define(LOG_LEVEL,
                   :default => "info",
                   :description => "Log level. See standard Logger class")
      @settings.define(MONGO_JOBS_DB,
                   :default => 'job_info',
                   :description => "Mongo database to dump hadoop job information into")
      @settings.define(MONGO_JOB_LOGS_COLLECTION,
                   :default => 'job_logs',
                   :description => "Mongo collection to dump job logs into.")
      @settings.define(MONGO_JOB_EVENTS_COLLECTION,
                   :default => 'job_events',
                   :description => "Mongo collection containing jobs events.")
      @settings.define(MONGO_MACHINE_STATS_COLLECTION,
                   :default => 'machine_stats',
                   :description => "Mongo collection containing machine stats.")
      @settings.define(MONGO_IP,
                   :default => nil,
                   :description => "IP address of Hadoop monitor node")
      @settings.define(JOB_LOGS_SIZE,
                   :default => 10 * (1 << 20),
                   :description => ("Size (in bytes) of Mongo jobs log collection"))
      @settings.define(JOB_EVENTS_SIZE,
                   :default => 10 * (1 << 20),
                   :description => ("Size (in bytes) of Mongo job events collection"))
      @settings.define(MACHINE_STATS_SIZE,
                   :default => 100 * (1 << 20),
                   :description => ("Size (in bytes) of machine stats collection"))
      
      @settings.resolve!

      @logger = Logger.new(STDERR)
      @logger.level = Logger.const_get(@settings[LOG_LEVEL].upcase.to_sym)

      @logger.info "Settings: #{@settings}"

      @settings
    end

    def configure_hadoop_jruby
      begin
        require 'java'
      rescue LoadError => e
        raise "\nJava not found. Are you sure you're running with JRuby?\n#{e.message}"
      end

      logger.debug "Setting up jruby"
      hadoop_home = ENV['HADOOP_HOME']

      raise "\nHadoop installation not found. Try setting $HADOOP_HOME\n" unless (hadoop_home and (File.exist? hadoop_home))

      $CLASSPATH << File.join(File.join(hadoop_home, 'conf') || ENV['HADOOP_CONF_DIR'],
                              '') # add trailing slash
      
      Dir["#{hadoop_home}/{hadoop*.jar,lib/*.jar}"].each{|jar| require jar}

      self.class.class_eval do
        include_class org.apache.hadoop.mapred.JobClient
        include_class org.apache.hadoop.mapred.JobStatus
      end
    end

    def get_hadoop_conf
      logger.debug "Getting hadoop configuration"
      conf = Java::org.apache.hadoop.conf.Configuration.new

      # per-site defaults
      %w[capacity-scheduler.xml core-site.xml hadoop-policy.xml hadoop-site.xml hdfs-site.xml mapred-site.xml].each do |conf_file|
        conf.addResource conf_file
      end
      conf.reload_configuration

      # per-user overrides
      if Swineherd.config[:aws]
        conf.set("fs.s3.awsAccessKeyId",Swineherd.config[:aws][:access_key])
        conf.set("fs.s3.awsSecretAccessKey",Swineherd.config[:aws][:secret_key])

        conf.set("fs.s3n.awsAccessKeyId",Swineherd.config[:aws][:access_key])
        conf.set("fs.s3n.awsSecretAccessKey",Swineherd.config[:aws][:secret_key])
      end

      conf
    end
  end
end
