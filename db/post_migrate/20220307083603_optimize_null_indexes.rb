# frozen_string_literal: true

class OptimizeNullIndexes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    update_index :conversations, 'index_conversations_on_uri', :uri, unique: true, where: 'uri IS NOT NULL'
    update_index :statuses, 'index_statuses_on_in_reply_to_account_id', :in_reply_to_account_id, where: 'in_reply_to_account_id IS NOT NULL'
    update_index :statuses, 'index_statuses_on_in_reply_to_id', :in_reply_to_id, where: 'in_reply_to_id IS NOT NULL'
    update_index :media_attachments, 'index_media_attachments_on_scheduled_status_id', :scheduled_status_id, where: 'scheduled_status_id IS NOT NULL'
    update_index :media_attachments, 'index_media_attachments_on_shortcode', :shortcode, unique: true, where: 'shortcode IS NOT NULL'
    update_index :users, 'index_users_on_reset_password_token', :reset_password_token, unique: true, where: 'reset_password_token IS NOT NULL'
    update_index :users, 'index_users_on_created_by_application_id', :created_by_application_id, where: 'created_by_application_id IS NOT NULL'
    update_index :statuses, 'index_statuses_on_uri', :uri, unique: true, where: 'uri IS NOT NULL'
    update_index :accounts, 'index_accounts_on_moved_to_account_id', :moved_to_account_id, where: 'moved_to_account_id IS NOT NULL'
    update_index :oauth_access_tokens, 'index_oauth_access_tokens_on_refresh_token', :refresh_token, unique: true, where: 'refresh_token IS NOT NULL'
    update_index :accounts, 'index_accounts_on_url', :url, where: 'url IS NOT NULL'
    update_index :oauth_access_tokens, 'index_oauth_access_tokens_on_resource_owner_id', :resource_owner_id, where: 'resource_owner_id IS NOT NULL'
    update_index :announcement_reactions, 'index_announcement_reactions_on_custom_emoji_id', :custom_emoji_id, where: 'custom_emoji_id IS NOT NULL'
    update_index :appeals, 'index_appeals_on_approved_by_account_id', :approved_by_account_id, where: 'approved_by_account_id IS NOT NULL'
    update_index :account_migrations, 'index_account_migrations_on_target_account_id', :target_account_id, where: 'target_account_id IS NOT NULL'
    update_index :appeals, 'index_appeals_on_rejected_by_account_id', :rejected_by_account_id, where: 'rejected_by_account_id IS NOT NULL'
    update_index :list_accounts, 'index_list_accounts_on_follow_id', :follow_id, where: 'follow_id IS NOT NULL'
    update_index :web_push_subscriptions, 'index_web_push_subscriptions_on_access_token_id', :access_token_id, where: 'access_token_id IS NOT NULL'
  end

  def down
    update_index :conversations, 'index_conversations_on_uri', :uri, unique: true
    update_index :statuses, 'index_statuses_on_in_reply_to_account_id', :in_reply_to_account_id
    update_index :statuses, 'index_statuses_on_in_reply_to_id', :in_reply_to_id
    update_index :media_attachments, 'index_media_attachments_on_scheduled_status_id', :scheduled_status_id
    update_index :media_attachments, 'index_media_attachments_on_shortcode', :shortcode, unique: true
    update_index :users, 'index_users_on_reset_password_token', :reset_password_token, unique: true
    update_index :users, 'index_users_on_created_by_application_id', :created_by_application_id
    update_index :statuses, 'index_statuses_on_uri', :uri, unique: true
    update_index :accounts, 'index_accounts_on_moved_to_account_id', :moved_to_account_id
    update_index :oauth_access_tokens, 'index_oauth_access_tokens_on_refresh_token', :refresh_token, unique: true
    update_index :accounts, 'index_accounts_on_url', :url
    update_index :oauth_access_tokens, 'index_oauth_access_tokens_on_resource_owner_id', :resource_owner_id
    update_index :announcement_reactions, 'index_announcement_reactions_on_custom_emoji_id', :custom_emoji_id
    update_index :appeals, 'index_appeals_on_approved_by_account_id', :approved_by_account_id
    update_index :account_migrations, 'index_account_migrations_on_target_account_id', :target_account_id
    update_index :appeals, 'index_appeals_on_rejected_by_account_id', :rejected_by_account_id
    update_index :list_accounts, 'index_list_accounts_on_follow_id', :follow_id
    update_index :web_push_subscriptions, 'index_web_push_subscriptions_on_access_token_id', :access_token_id
  end

  private

  def update_index(table_name, index_name, columns, **index_options)
    if index_name_exists?(table_name, "#{index_name}_old") && index_name_exists?(table_name, index_name)
      remove_index table_name, index_name
    elsif index_name_exists?(table_name, index_name)
      rename_index table_name, index_name, "#{index_name}_old"
    end

    add_index table_name, columns, **index_options.merge(name: index_name, algorithm: :concurrently)
    remove_index table_name, name: "#{index_name}_old" if index_name_exists?(table_name, "#{index_name}_old")
  end
end
