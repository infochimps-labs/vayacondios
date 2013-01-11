require 'stringio'

class Vayacondios

  module Hadoopable

    include Configurable

    #--------------------------------------------------------------------------------
    # Initialize jruby and tell it about hadoop.
    #--------------------------------------------------------------------------------

    begin
      require 'java'
    rescue LoadError => e
      raise "\nJava not found. Are you sure you're running with JRuby?\n#{e.message}"
    end

    hadoop_home = ENV['HADOOP_HOME'] || '/usr/lib/hadoop'

    raise "\nHadoop installation not found. Try setting $HADOOP_HOME\n" unless (hadoop_home and (File.exist? hadoop_home))

    $CLASSPATH << File.join(File.join(hadoop_home, 'conf') || ENV['HADOOP_CONF_DIR'],
                            '') # add trailing slash

    Dir["#{hadoop_home}/{hadoop*.jar,lib/*.jar}"].each{|jar| require jar}

    include_class org.apache.hadoop.mapred.JobConf
    include_class org.apache.hadoop.mapred.JobClient
    include_class org.apache.hadoop.mapred.JobStatus
    include_class org.apache.hadoop.mapred.TIPStatus
    include_class org.apache.hadoop.conf.Configuration
    #--------------------------------------------------------------------------------

    def get_hadoop_conf
      logger.debug "Getting hadoop configuration"

      stderr, $stderr = $stderr, StringIO.new

      conf = Configuration.new

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

      return conf
    ensure
      stderr_lines = $stderr.string.split("\n")
      $stderr = stderr
      stderr_lines.each{|line| logger.debug line}
    end
  end
end
