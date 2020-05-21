class A < Formula


  inreplace "#{libexec}/conf/logback_namesrv.xml" do |s| 
    s.gsub!(/\$\{user\.home\}/, "/usr/local/var/log/rocketmq")
  end
 
  end 
