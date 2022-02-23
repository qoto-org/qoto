# frozen_string_literal: true

class Scheduler::EmailDomainBlockRefreshScheduler
  include Sidekiq::Worker
  include Redisable

  sidekiq_options retry: 0

  def perform
    Resolv::DNS.open do |dns|
      dns.timeouts = 5

      EmailDomainBlock.find_each do |email_domain_block|
        resources = dns.getresources(email_domain_block.domain, Resolv::DNS::Resource::IN::A).to_a + dns.getresources(email_domain_block.domain, Resolv::DNS::Resource::IN::AAAA).to_a
        email_domain_block.update(ips: resources.map { |resource| resource.address.to_s }, last_refresh_at: Time.now.utc)
      end
    end
  end
end
