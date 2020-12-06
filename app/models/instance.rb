# frozen_string_literal: true
# == Schema Information
#
# Table name: instances
#
#  domain :string           primary key
#

class Instance < ApplicationRecord
  self.primary_key = :domain

  belongs_to :domain_block, foreign_key: :domain, primary_key: :domain
  belongs_to :domain_allow, foreign_key: :domain, primary_key: :domain

  scope :matches_domain, ->(domain) { where(arel_table[:domain].matches("%#{value}%")) }

  def readonly?
    true
  end

  def delivery_failure_tracker
    @delivery_failure_tracker ||= DeliveryFailureTracker.new(domain)
  end

  def accounts_count
    cache('accounts_count') { accounts_scope.count }
  end

  def following_count
    cache('following_count') { Follow.where(account: accounts_scope).count }
  end

  def followers_count
    cache('followers_count') { Follow.where(target_account: accounts_scope).count }
  end

  def reports_count
    cache('reports_count') { Report.where(target_account: accounts_scope).count }
  end

  def blocks_count
    cache('blocks_count') { Block.where(target_account: accounts_scope).count }
  end

  def public_comment
    domain_block&.public_comment
  end

  def private_comment
    domain_block&.private_comment
  end

  def media_storage
    cache('media_storage') { MediaAttachment.where(account: accounts_scope).sum(:file_file_size) }
  end

  def to_param
    domain
  end

  def cache_key
    domain
  end

  private

  def accounts_scope
    Account.where(domain: domain)
  end

  def cache(key)
    Rails.cache.fetch("instances/#{cache_key}/#{key}") { yield }
  end
end
