# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class RocketmqAT470 < Formula
  desc "Apache RocketMQ is a distributed messaging and streaming platform with low latency, high performance and reliability, trillion-level capacity and flexible scalability."
  homepage "https://rocketmq.apache.org/"
  url "https://www.apache.org/dyn/closer.cgi?path=rocketmq/4.7.0/rocketmq-all-4.7.0-bin-release.zip"
  sha256 "ea196c0498e340f2cc0feeab8a43dacac3545a5d49849998a2a7e5ad6c431e74"

  bottle :unneeded
  # depends_on "cmake" => :build

  def install
    # Install everything else into package directory
    libexec.install "bin", "conf", "lib"

    inreplace "#{libexec}/conf/logback_namesrv.xml" do |s|
      s.gsub!(/\$\{user\.home\}/, "#{var}/log/rocketmq")
    end

    inreplace "#{libexec}/conf/logback_broker.xml" do |s|
      s.gsub!(/\$\{user\.home\}/, "#{var}/log/rocketmq")
    end

    # Move config files into etc
    (libexec/"conf/broker.conf").rmtree
    (libexec/"conf/broker.conf").write broker_conf
    (etc/"rocketmq").install Dir[libexec/"conf/*"]
    (libexec/"conf").rmtree
    (libexec/"bin/mqlaunch").write launch
    (libexec/"bin/runbroker.sh").rmtree
    (libexec/"bin/runbroker.sh").write runbroker
    chmod 0555, (libexec/"bin/mqlaunch")
    chmod 0555, (libexec/"bin/runbroker.sh")
    Dir.foreach(libexec/"bin") do |f|
      next if f == "." || f == ".." || !File.extname(f).empty?

      bin.install libexec/"bin"/f
    end
    bin.env_script_all_files(libexec/"bin", {})
  end

  def post_install
    (var/"rocketmq").mkpath
    (var/"log/rocketmq").mkpath
    (var/"rocketmq/commitlog").mkpath
    ln_s etc/"rocketmq", libexec/"conf"
  end

  def broker_conf; <<~EOS
      brokerClusterName = DefaultCluster
      brokerName = broker-a
      brokerId = 0
      deleteWhen = 04
      fileReservedTime = 48
      brokerRole = ASYNC_MASTER
      flushDiskType = ASYNC_FLUSH
      storePathRootDir=#{var}/rocketmq
      storePathCommitLog=#{var}/rocketmq/commitlog
      autoCreateTopicEnable=true
  EOS
  end

  def launch; <<~EOS
    #!/bin/sh
    echo 'launch'
    #{libexec}/bin/mqnamesrv &
    #{libexec}/bin/mqbroker -n localhost:9876 -c  #{HOMEBREW_PREFIX}/etc/rocketmq/broker.conf autoCreateTopicEnable=true
  EOS
  end

  def runbroker; <<~EOS
    #!/bin/sh
    error_exit ()
    {
        echo "ERROR: $1 !!"
        exit 1
    }
    
    [ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=$JAVA_HOME
    [ ! -e "$JAVA_HOME/bin/java" ] && error_exit "Please set the JAVA_HOME variable in your environment, We need java(x64)!"
    
    export JAVA_HOME
    export JAVA="$JAVA_HOME/bin/java"
    export BASE_DIR=$(dirname $0)/..
    export CLASSPATH=.:${BASE_DIR}/conf:${CLASSPATH}
    
    #===========================================================================================
    # JVM Configuration
    #===========================================================================================
    # The RAMDisk initializing size in MB on Darwin OS for gc-log
    DIR_SIZE_IN_MB=600
    
    choose_gc_log_directory()
    {
        case "`uname`" in
            Darwin)
                if [ ! -d "/Volumes/RAMDisk" ]; then
                    # create ram disk on Darwin systems as gc-log directory
                    DEV=`hdiutil attach -nomount ram://$((2 * 1024 * DIR_SIZE_IN_MB))` > /dev/null
                    diskutil eraseVolume HFS+ RAMDisk ${DEV} > /dev/null
                    echo "Create RAMDisk /Volumes/RAMDisk for gc logging on Darwin OS."
                fi
                GC_LOG_DIR="/Volumes/RAMDisk"
            ;;
            *)
                # check if /dev/shm exists on other systems
                if [ -d "/dev/shm" ]; then
                    GC_LOG_DIR="/dev/shm"
                else
                    GC_LOG_DIR=${BASE_DIR}
                fi
            ;;
        esac
    }
    
    choose_gc_log_directory
    
    JAVA_OPT="${JAVA_OPT} -server -Xmsg -Xmx2g -Xmn1g"
    JAVA_OPT="${JAVA_OPT} -XX:+UseG1GC -XX:G1HeapRegionSize=16m -XX:G1ReservePercent=25 -XX:InitiatingHeapOccupancyPercent=30 -XX:SoftRefLRUPolicyMSPerMB=0"
    JAVA_OPT="${JAVA_OPT} -verbose:gc -Xloggc:${GC_LOG_DIR}/rmq_broker_gc_%p_%t.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCApplicationStoppedTime -XX:+PrintAdaptiveSizePolicy"
    JAVA_OPT="${JAVA_OPT} -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=30m"
    JAVA_OPT="${JAVA_OPT} -XX:-OmitStackTraceInFastThrow"
    JAVA_OPT="${JAVA_OPT} -XX:+AlwaysPreTouch"
    JAVA_OPT="${JAVA_OPT} -XX:MaxDirectMemorySize=15g"
    JAVA_OPT="${JAVA_OPT} -XX:-UseLargePages -XX:-UseBiasedLocking"
    JAVA_OPT="${JAVA_OPT} -Djava.ext.dirs=${JAVA_HOME}/jre/lib/ext:${BASE_DIR}/lib"
    #JAVA_OPT="${JAVA_OPT} -Xdebug -Xrunjdwp:transport=dt_socket,address=9555,server=y,suspend=n"
    JAVA_OPT="${JAVA_OPT} ${JAVA_OPT_EXT}"
    JAVA_OPT="${JAVA_OPT} -cp ${CLASSPATH}"
    
    numactl --interleave=all pwd > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
      if [ -z "$RMQ_NUMA_NODE" ] ; then
        numactl --interleave=all $JAVA ${JAVA_OPT} $@
      else
        numactl --cpunodebind=$RMQ_NUMA_NODE --membind=$RMQ_NUMA_NODE $JAVA ${JAVA_OPT} $@
      fi
    else
      $JAVA ${JAVA_OPT} $@
    fi

  EOS
  end 

  def caveats
    s = <<~EOS
      Data:    #{var}/rocketmq/commitlog
      Logs:    #{var}/log/rocketmq/
      Config:  #{etc}/rocketmq/broker.conf
    EOS

    s
  end

  plist_options :manual => "setup rocketmq server with two steps: 
        1. mqnamesrv 
        2. mqbroker -n localhost:9876 -c  #{HOMEBREW_PREFIX}/etc/rocketmq/broker.conf autoCreateTopicEnable=true"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      
      <key>ProgramArguments</key>
      <array>
        <string>#{bin}/mqlaunch</string>
      </array>

      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/rocketmq/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/rocketmq/output.log</string>
    </dict>
    </plist>
  EOS
  end



  test do
    system "#{bin}/mqadmin"
  end
end
