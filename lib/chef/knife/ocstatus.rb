# Author:: Paul Mooring <paul@opscode.com>
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module KnifeOCStatus
  class Ocstatus < Chef::Knife
    banner "knife ocstatus [options]"

    deps do
      require 'twitter'
      require 'net/smtp'
    end

    option :smtp_host,
        :long         => "--smtp-server SMTP_SERVER",
        :description  => "The SMTP server",
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_host] = i },
        :default      => 'localhost'

    option :smtp_port,
        :long         => "--smtp-port SMTP_PORT",
        :description  => "The SMTP port",
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_port] = i },
        :default      => 25

    option :smtp_domain,
        :long         => "--smtp-domain HELO_DOMAIN",
        :description  => "The HELO domain for the SMTP server",
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_domain] = i },
        :default      => "localhost"

    option :smtp_tls,
        :long         => "--smtp-tls",
        :description  => "Turns on TLS for the SMTP connection",
        :boolean      => true,
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_tls] = i },
        :default      => false

    option :smtp_auth,
        :long         => "--smtp-auth METHOD",
        :description  => "Supports 'plain', 'login' or 'cram_md5'",
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_auth] = i },
        :default      => nil

    option :smtp_user,
        :long         => "--smtp-user USERNAME",
        :description  => "User for SMTP authentication",
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_user] = i },
        :default      => nil

    option :smtp_pass,
        :long         => "--smtp-pass PASSWORD",
        :description  => "Password for SMTP authentication",
        :proc         => Proc.new { |i| Chef::Config[:knife][:smtp_pass] = i },
        :default      => nil

    option :to_address,
        :long         => "--to-address ADDRESS",
        :description  => "The e-mail address to send to",
        :proc         => Proc.new { |i| Chef::Config[:knife][:to_address] = i },
        :default      => nil

    option :from_address,
        :long         => "--from-address ADDRESS",
        :description  => "The e-mail address to send from",
        :proc         => Proc.new { |i| Chef::Config[:knife][:from_address] = i },
        :default      => nil

    option :subject,
        :long         => "--subject SUBJECT",
        :description  => "Subject for maintenance message",
        :default      => "Maintenance Planned"

    option :message,
        :long         => "--message MESSAGE",
        :description  => "Message to send",
        :default      => nil

    def get_message
      config[:message]
    end

    def twitterize(txt, sub)
      if txt.length > 140
        "#{txt[0..136]}..."
      else
        "#{sub[0..112]}: http://status.opscode.com"
      end
    end
    
    def mailize(txt, sub, to, from)
    "From: Opscode Status <#{from}>
    To: Opscode Status <#{to}>
    Subject: #{sub}
    
    #{txt}"
    end

    def run
      smtp = Net::SMTP.new(config[:smtp_host], config[:smtp_port])
      smtp.enable_starttls_auto if config[:smtp_tls]

      if config[:smtp_auth].nil?
        smtp.start
      else
        smtp_pass = config[:smtp_pass]
        begin
          system "stty -echo"
          print "Password: "
          pass = $stdin.gets.chomp; puts "\n"
          print "Password (repeat): "
          pass_conf = $stdin.gets.chomp; puts "\n"
          if pass == pass_conf
            smtp_pass = pass
          else
            STDERR.puts "Passwords do not match!"
            exit 1
          end
        ensure
          system "stty echo"
        end if smtp_pass.nil?
        smtp.start(config[:smtp_domain], config[:smtp_user], smtp_pass, config[:smtp_auth])
      end

      smtp.send_message(mailize(get_message, config[:subject], config[:from_address], config[:to_address]), config[:from_address], config[:to_address])
      puts "E-mail sent"

      Twitter.update twitterize(get_message, config[:subject])
      puts "Tweet tweeted"
    end
  end
end
